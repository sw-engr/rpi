using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading; // to store event wait handle

public delegate void MainEntry(); // callback entry
public delegate void Callback();  //  points
public delegate void Forward(VisualCompiler.Delivery.MessageType message); 

namespace VisualCompiler
{
    static public class Component
    {
        //  Framework class that keeps track of registered components.

        public const int MaxUserComponents = 8;
        // Maximum allowed number of user (non-framework) components
        public const int MaxComponents = 8 + (2 * (Configuration.MaxApplications - 1));

        // Register result possibilities
        public enum ComponentStatus
        {
            NONE,
            VALID,
            DUPLICATE,
            INVALID,
            INCONSISTENT,
            INCOMPLETE
        };

        public enum ComponentKind
        {
            USER,
            FRAMEWORK,
            RECEIVE,   // special framework component
            TRANSMIT   // special framework component
        };

        public enum ComponentSpecial
        {
            NORMAL,
            RECEIVE,
            RECEIVEINTERFACE,
            TRANSMIT
        };

        // Identifier of application
        public struct ApplicationId
        {
            public string name; // application name
            public int id; // application numeric id
        }

        // Identifier of component
        public struct ParticipantKey
        {
            public int appId; // application identifier
            public int comId; // component identifier
            public int subId; // subcomponent identifier
        };

        static public ParticipantKey nullKey;
 
        // Determine if two components are the same
        static public bool CompareParticipants(ParticipantKey left, ParticipantKey right)
        {
            if ((left.appId == right.appId) &&
                (left.comId == right.comId) &&
                (left.subId == right.subId))
            {
                return true;
            }
            else
            {
                return false;
            }
        } // end CompareParticipants 

        public struct RegisterResult
        {
            public ComponentStatus status;
            public ParticipantKey key;
        };

        // Component data from registration as well as run-time status
        public struct ComponentDataType
        {
            public ComponentKind kind;
            // Whether user component or a framework component
            public string name;
            // Component name 
            public ParticipantKey key;
            // Component key (application and component identifiers)
            public int period;
            // Periodic interval in milliseconds; 0 if only message consumer
            public Threads.ComponentThreadPriority priority;
            // Requested priority for component
            public MainEntry fMain;
            // Main entry point of the component
            public Disburse queue; //disburseQueue;
            // Alternate message queue of the component
            public ComponentSpecial special;
            // Special processing
            public PeriodicTimer timer;
            // Thread timer of special components
            public EventWaitHandle waitHandle;
            // Wait Handle to use to signal end of wait
        };

        // List of components
        public class ComponentTableType
        {
            public bool allowComponentRegistration;
            // True indicates that components are allowed to register themselves
            public int count;
            // Number of registered components of the application
            public ComponentDataType[] list = new ComponentDataType[MaxComponents];
            // Registration supplied data concerning the component as well as 
            // run-time status data
        };

        // Component table containing registration data as well as run-time status data
        // Note: I would like to keep this table hidden from components but I don't 
        //       know how to structure C# so that classes of a certain kind (that is,
        //       App, Component, Threads, etc) aren't directly visible to components
        //       such as ComPeriodic.
        // Note: There must be one creation of a new table.  Only one instance.
        static public ComponentTableType componentTable = new ComponentTableType();

        // true if Component class has been initialized
        static public bool componentInitialized = false;

        // Find the index into the registered Application table of the currently
        // running application and return it.
        static private int ApplicationIndex()
        {
            int index; // Index of hosted function application in Application table

            // Find index to be used for hosted function application processor
            index = App.applicationId;
            if (index == 0)
            {
                ConsoleOut.WriteLine("ERROR: Application Index doesn't exist");
            }
            return index;

        } // end ApplicationIndex;    

        static public Disburse GetQueue(ParticipantKey component)
        {
            for (int i = 0; i < componentTable.count; i++)
            {
                if (CompareParticipants(componentTable.list[i].key, component))
                {
                    return componentTable.list[i].queue;
                }
            }
            return null;
        } // end GetQueue

        // Initialize the component table.  Substitute for constructor.
        static public void Initialize()
        {
            nullKey.appId = 0;
            nullKey.comId = 0;
            nullKey.subId = 0;

            componentTable.count = 0;
            componentTable.allowComponentRegistration = false;
        }

        // Look up the Name in the registered component and return the index of
        // where the data has been stored.  Return zero if the Name is not in 
        // the list.
        static private int Lookup(string name)
        {
            int app; // Application id
            int idx; // Index of component in registry

            app = ApplicationIndex();

            idx = 0;
            for (int i = 0; i < componentTable.count - 1; i++)
            {
                if (String.Compare(name, componentTable.list[i].name, false) == 0)
                {
                    idx = i;
                    break; // exit loop
                }
            } // end loop;

            // Return the index.
            return idx;

        } // end Lookup;

        // Increment the identifier of the component key and then return it with
        // the application identifier as the next available component key.
        static private ParticipantKey NextComponentKey()
        {
            int app; // Index of current application

            app = ApplicationIndex();

            ParticipantKey returnApp;
            if (componentTable.count < MaxComponents)
            {
                componentTable.count = componentTable.count + 1;
                returnApp.appId = app;
                returnApp.comId = componentTable.count;
                returnApp.subId = 0;
                return returnApp;
            }
            else
            {
                ConsoleOut.WriteLine("ERROR: More components than can be accommodated");
                return nullKey;
            }

        } // end NextComponentKey

        // Register a periodic callback component.
        static public RegisterResult Register
                      (string name,         // name of component
                       int period,  // # of millisec at which Main() function to cycle
                       Threads.ComponentThreadPriority priority, // Requested priority of thread
                       MainEntry callback,  // Callback() function of component
                       Disburse queue)      // message queue of component
        {
            int app;      // Index of current application
            int cIndex;   // Index of component; 0 if not found
            int location; // Location of component in the registration table
            ParticipantKey newKey; // Component key of new component
            newKey = nullKey;

            RegisterResult result;
            result.status = ComponentStatus.NONE; // unresolved
            result.key = nullKey;

            // Find index to be used for application
            app = ApplicationIndex();

            // Look up the component in the Component Table
            cIndex = Lookup(name);

            // Return if component has already been registered
            if (cIndex > 0) // duplicate registration
            {
                result.status = ComponentStatus.DUPLICATE;
                return result;
            }

            // Add new component to component registration table.
            //
            //   First obtain the new table location and set the initial values.
            newKey = NextComponentKey();

            location = componentTable.count - 1;

            componentTable.list[location].kind = ComponentKind.USER;
            componentTable.list[location].name = name;
            componentTable.list[location].key = newKey;
            componentTable.list[location].period = period;
            componentTable.list[location].priority = priority;
            componentTable.list[location].fMain = (MainEntry)callback;
            componentTable.list[location].queue = queue;
            componentTable.list[location].special = ComponentSpecial.NORMAL;
            componentTable.list[location].timer = null;
            if (period > 0) 
            { // end of wait is signaled by Timer of Threads.cs
                componentTable.list[location].waitHandle = queue.QueueWaitHandle();
            }
            else
            { // end of wait is signaled by Write of new message
                componentTable.list[location].waitHandle = null;
            }

            // Return status and the assigned component key.
            result.status = ComponentStatus.VALID;
            result.key = newKey;
            return result;
        } // end Register
        
        // Register a callback component.
        static public RegisterResult Register
                      (string name,         // name of component
                       Threads.ComponentThreadPriority priority, // Requested priority of thread
                       MainEntry callback,  // Callback() function of component
                       Disburse queue)      // message queue of component
        {
            return Register(name, 0, priority, callback, queue);
        } // end Register

        // Register a component.
        static public RegisterResult Register
                      (string name, // name of component
                       int period,  // # of millisec at which Main() function to cycle
                       Threads.ComponentThreadPriority priority, // Requested priority of thread
                       MainEntry fMain,      // Main() function of component
                       Disburse queue,       // message queue of component
                       EventWaitHandle waitHandle) // wait handle for wakeup signal
        {
            int app;      // Index of current application
            int cIndex;   // Index of component; 0 if not found
            int location; // Location of component in the registration table
            ParticipantKey newKey; // Component key of new component
            newKey = nullKey;

            RegisterResult result;
            result.status = ComponentStatus.NONE; // unresolved
            result.key = nullKey;

            // Find index to be used for application
            app = ApplicationIndex();

            // Look up the component in the Component Table
            cIndex = Lookup(name);

            // Return if component has already been registered
            if (cIndex > 0) // duplicate registration
            {
                result.status = ComponentStatus.DUPLICATE;
                return result;
            }

            // Return if component is periodic but without a Main() entry point.
            if (period > 0)
            {
                if (fMain == null)
                {
                    result.status = ComponentStatus.INVALID;
                    return result;
                }
            }

            // Add new component to component registration table.
            //
            //   First obtain the new table location and set the initial values.
            newKey = NextComponentKey();

            location = componentTable.count - 1;

            componentTable.list[location].kind = ComponentKind.USER;
            componentTable.list[location].name = name;
            componentTable.list[location].key = newKey;
            componentTable.list[location].period = period;
            componentTable.list[location].priority = priority;
            componentTable.list[location].fMain = fMain;
            componentTable.list[location].queue = queue;
            componentTable.list[location].special = ComponentSpecial.NORMAL;
            componentTable.list[location].timer = null;
            componentTable.list[location].waitHandle = waitHandle;

            // Return status and the assigned component key.
            result.status = ComponentStatus.VALID;
            result.key = newKey;
            return result;
        } // end Register

        static public RegisterResult RegisterRemote(string name, int remoteAppId, MainEntry fMain)
        {
            int app;      // Index of current application
            int location; // Location of component in the registration table
            ParticipantKey newKey; // Component key of new component
            newKey = nullKey;

            RegisterResult result;
            result.status = ComponentStatus.NONE; // unresolved
            result.key = nullKey;

            // Find index to be used for application
            app = ApplicationIndex();

            // Since a framework component register, assuming not a duplicate.
            // Add new component to component registration table.
            //
            //   First obtain the new table location and set the initial values.
            newKey = NextComponentKey();

            location = componentTable.count - 1;

            componentTable.list[location].kind = ComponentKind.FRAMEWORK;
            componentTable.list[location].name = name + remoteAppId;
            componentTable.list[location].key = newKey;
            componentTable.list[location].period = 0; // to avoid a Timer
            componentTable.list[location].priority = Threads.ComponentThreadPriority.HIGH;
            componentTable.list[location].fMain = fMain; 
            componentTable.list[location].queue = null; // uses circular queue instead
            componentTable.list[location].special = ComponentSpecial.RECEIVEINTERFACE;
            componentTable.list[location].timer = null;
            componentTable.list[location].waitHandle = null; // waitHandle supplied differently

            // Return status and the assigned component key.
            result.status = ComponentStatus.VALID;
            result.key = newKey;
            return result;
        } // end RegisterRemote

        static public RegisterResult RegisterReceive(string name)
        {
            int app;      // Index of current application
            int location; // Location of component in the registration table
            ParticipantKey newKey; // Component key of new component
            newKey = nullKey;

            RegisterResult result;
            result.status = ComponentStatus.NONE; // unresolved
            result.key = nullKey;

            // Find index to be used for application
            app = ApplicationIndex();

            // Since a framework register, assuming not a duplicate.
            // Add new component to component registration table.
            //
            //   First obtain the new table location and set the initial values.
            newKey = NextComponentKey();

            location = componentTable.count - 1;

            componentTable.list[location].kind = ComponentKind.RECEIVE;
            componentTable.list[location].name = name; // "R" + name;
            componentTable.list[location].key = newKey;
            componentTable.list[location].period = 0;
            componentTable.list[location].priority = Threads.ComponentThreadPriority.HIGH;
            componentTable.list[location].fMain = null;
            componentTable.list[location].queue = null;
            componentTable.list[location].special = ComponentSpecial.RECEIVE;
            componentTable.list[location].timer = null;
            componentTable.list[location].waitHandle = null;

            // Return status and the assigned component key.
            result.status = ComponentStatus.VALID;
            result.key = newKey;
            return result;
        } // end RegisterReceive

        static public RegisterResult RegisterTransmit(int name, Transmit transmit)
        {
            int app;      // Index of current application
            int location; // Location of component in the registration table
            ParticipantKey newKey; // Component key of new component
            newKey = nullKey;

            RegisterResult result;
            result.status = ComponentStatus.NONE; // unresolved
            result.key = nullKey;

            // Find index to be used for application
            app = ApplicationIndex();

            // Since a framework register, assuming not a duplicate.

            // Add new component to component registration table.
            //
            //   First obtain the new table location and set the initial values.
            newKey = NextComponentKey();

            location = componentTable.count - 1;

            componentTable.list[location].kind = ComponentKind.TRANSMIT;
            componentTable.list[location].name = "T" + name;
            componentTable.list[location].key = newKey;
            componentTable.list[location].period = 0; // not periodic
            componentTable.list[location].priority = Threads.ComponentThreadPriority.HIGH;
            componentTable.list[location].fMain = transmit.Callback;
            componentTable.list[location].queue = transmit.queue;
            componentTable.list[location].queue = null;
            componentTable.list[location].special = ComponentSpecial.TRANSMIT;
            componentTable.list[location].timer = null;
            componentTable.list[location].waitHandle = null; 

            // Return status and the assigned component key.
            result.status = ComponentStatus.VALID;
            result.key = newKey;
            return result;
        } // end RegisterTransmit

    } // end Component class
} // end namespace