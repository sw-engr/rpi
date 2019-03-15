using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;

namespace VisualCompiler
{
    public class NamedPipeNames
    {   
        public struct NamedPipeNameType
        {
            public string lPipeName; 
            public string rPipeName;
        };

        public class NamedPipeNameTableType
        {
            public int count; // Number of declared possibilities
            public NamedPipeNameType[] list = new
                NamedPipeNameType[4*Configuration.MaxApplications - 1];
        };

        public NamedPipeNameTableType namedPipeName = new NamedPipeNameTableType();

        public NamedPipeNames() // constructor
        {
            namedPipeName.list[0].lPipeName = "1to2"; // App1 the local app
            namedPipeName.list[0].rPipeName = "2to1";
            namedPipeName.count++;
            namedPipeName.list[1].lPipeName = "2to1"; // App2 the local app
            namedPipeName.list[1].rPipeName = "1to2";
            namedPipeName.count++;
            namedPipeName.list[2].lPipeName = "1to3"; // App1 the local app
            namedPipeName.list[2].rPipeName = "3to1";
            namedPipeName.count++;
            namedPipeName.list[3].lPipeName = "3to1"; // App3 the local app
            namedPipeName.list[3].rPipeName = "1to3"; 
            namedPipeName.count++;
            namedPipeName.list[4].lPipeName = "2to3"; // App2 the local app
            namedPipeName.list[4].rPipeName = "3to2";
            namedPipeName.count++;
            namedPipeName.list[5].lPipeName = "3to2"; // App3 the local app
            namedPipeName.list[5].rPipeName = "2to3";
            namedPipeName.count++;
            namedPipeName.list[6].lPipeName = "1to4"; // App1 the local app
            namedPipeName.list[6].rPipeName = "4to1";
            namedPipeName.count++;
            namedPipeName.list[7].lPipeName = "2to4"; // App2 the local app
            namedPipeName.list[7].rPipeName = "4to2";
            namedPipeName.count++;
            namedPipeName.list[8].lPipeName = "3to4"; // App3 the local app
            namedPipeName.list[8].rPipeName = "4to3";
            namedPipeName.count++;
            namedPipeName.list[9].lPipeName = "4to1"; // App4 the local app
            namedPipeName.list[9].rPipeName = "1to4";
            namedPipeName.count++;
            namedPipeName.list[10].lPipeName = "4to2"; // App4 the local app
            namedPipeName.list[10].rPipeName = "2to4";
            namedPipeName.count++;
            namedPipeName.list[11].lPipeName = "4to3"; // App4 the local app
            namedPipeName.list[11].rPipeName = "3to4";
            namedPipeName.count++;
            // can be extended for more combinations
        } // end constructor

    } // end NamedPipeNames class

    static public class Remote
    {

        public struct RemoteConnectionsDataType
        {
            public NamedPipe namedPipe; // instance of NamedPipe framework component
            public ReceiveInterface receiveInterface; // instance of ReceiveInterface
            public Component.ParticipantKey receiveInterfaceComponentKey;
            public int receiveIndex; // increment for naming Receive threads
            public Receive receive; // instance of Receive framework component
            public Thread receiveThread; // thread for Receive
            public Component.ParticipantKey receiveComponentKey;
            public Transmit transmit; // instance of Transmit framework component
            public Component.ParticipantKey transmitComponentKey;
            public int remoteAppId; // remote application
 //           public bool pipeConnected; // client pipe connected to server pipe
 //           public bool connected; // true if connected with remote app via heartbeats
 //           public int consecutiveValid; // consecutive valid heartbeats
            public bool registerSent; // true if REGISTER message sent to remote app
            public bool registerCompleted; // true if REGISTER message acknowledged
        };

        public class RemoteConnectionsTableType
        {
            public int count; // Number of declared connection possibilities
            public RemoteConnectionsDataType[] list = new
                RemoteConnectionsDataType[Configuration.MaxApplications-1];
        };

        static public RemoteConnectionsTableType remoteConnections =
            new RemoteConnectionsTableType();

        public struct ConnectionsDataType
        {
            public bool pipeConnected; // client pipe connected to server pipe
            public bool connected; // true if connected with remote app via heartbeats
            public int consecutiveValid; // consecutive valid heartbeats
        };

        // This array has one unused (that is, extra) position.  This is because
        // references to it use the remote app id as the index and the position 
        // that corresponds to the local app won't be used.
        // The bools and int of this array are referenced from/by other classes
        // with this Remote class only being a "central" location.
        static public ConnectionsDataType[] connections = 
            new ConnectionsDataType[Configuration.MaxApplications];

        static private CircularQueue circularQueue;

        static private int receiveIndex = 0;

        static public void Initialize() // in place of constructor
        {
            remoteConnections.count = 0;
            receiveIndex = 0;

            for (int i = 0; i < Configuration.configurationTable.count; i++)
            {
                connections[i].connected = false;
                connections[i].pipeConnected = false;
                connections[i].consecutiveValid = 0;
            }

            Format.Initialize();

        } // end Initialize

        
        static public void Launch()
        {
            if (Configuration.configurationTable.count > 1)
            { // remote applications exist in the configuration
                // Instantiate a Receive and a Transmit framework 
                // component instance for each remote application.
                for (int i = 0; i < Configuration.configurationTable.count; i++)
                {
                    if (Configuration.configurationTable.list[i].app.id !=
                        App.applicationId) // other app than this one
                    {
                        // Instantiate instance of NamedPipe to communicate
                        // with this remote application.
                        int index = remoteConnections.count;
                        if ((App.applicationId == 1) && // assuming just apps 1, 2 and 3
                            (Configuration.configurationTable.list[i].app.id == 2 ))
                        {
                            remoteConnections.list[index].namedPipe =
                                new NamedPipe(App.applicationId,
                                              Configuration.configurationTable.list[i].app.id,
                                              0); // index into pipe name table
                        }
                        else if ((App.applicationId == 2) && // use the reverse
                                 (Configuration.configurationTable.list[i].app.id == 1))
                        {
                            remoteConnections.list[index].namedPipe =
                               new NamedPipe(App.applicationId,
                                             Configuration.configurationTable.list[i].app.id,
                                             1); // index into pipe name table
                        }                    
                        if ((App.applicationId == 1) && // assuming just apps 1, 2 and 3
                            (Configuration.configurationTable.list[i].app.id == 3))
                        {
                            remoteConnections.list[index].namedPipe =
                                new NamedPipe(App.applicationId,
                                              Configuration.configurationTable.list[i].app.id,
                                              2); // index into pipe name table
                        }
                        else if ((App.applicationId == 3) && // use the reverse
                                 (Configuration.configurationTable.list[i].app.id == 1))
                        {
                            remoteConnections.list[index].namedPipe =
                               new NamedPipe(App.applicationId,
                                             Configuration.configurationTable.list[i].app.id,
                                             3); // index into pipe name table
                        }
                        if ((App.applicationId == 1) && // assuming just apps 1, 2, 3, and 4
                            (Configuration.configurationTable.list[i].app.id == 4))
                        {
                            remoteConnections.list[index].namedPipe =
                                new NamedPipe(App.applicationId,
                                              Configuration.configurationTable.list[i].app.id,
                                              6); // index into pipe name table
                        }
                        if ((App.applicationId == 4) && // assuming just apps 1, 2, 3, and 4
                             (Configuration.configurationTable.list[i].app.id == 1))
                        {
                            remoteConnections.list[index].namedPipe =
                                new NamedPipe(App.applicationId,
                                              Configuration.configurationTable.list[i].app.id,
                                              9); // index into pipe name table
                        }
                        else if ((App.applicationId == 1) && // use the reverse
                                 (Configuration.configurationTable.list[i].app.id == 4))
                        {
                            remoteConnections.list[index].namedPipe =
                               new NamedPipe(App.applicationId,
                                             Configuration.configurationTable.list[i].app.id,
                                             6); // index into pipe name table
                        } if ((App.applicationId == 4) && // assuming just apps 1, 2, 3, and 4
                              (Configuration.configurationTable.list[i].app.id == 2))
                        {
                            remoteConnections.list[index].namedPipe =
                                new NamedPipe(App.applicationId,
                                              Configuration.configurationTable.list[i].app.id,
                                              10); // index into pipe name table
                        }
                        else if ((App.applicationId == 2) && // use the reverse
                                 (Configuration.configurationTable.list[i].app.id == 4))
                        {
                            remoteConnections.list[index].namedPipe =
                               new NamedPipe(App.applicationId,
                                             Configuration.configurationTable.list[i].app.id,
                                             7); // index into pipe name table
                        }
                        if ((App.applicationId == 4) && // assuming just apps 1, 2, 3, and 4
                            (Configuration.configurationTable.list[i].app.id == 3))
                        {
                            remoteConnections.list[index].namedPipe =
                                new NamedPipe(App.applicationId,
                                              Configuration.configurationTable.list[i].app.id,
                                              11); // index into pipe name table
                        }
                        else if ((App.applicationId == 3) && // use the reverse
                                 (Configuration.configurationTable.list[i].app.id == 4))
                        {
                            remoteConnections.list[index].namedPipe =
                               new NamedPipe(App.applicationId,
                                             Configuration.configurationTable.list[i].app.id,
                                             8); // index into pipe name table
                        }  
                        // Instantiate the Remote ReceiveInterface component and 
                        // its thread to retrieve messages from the Receive queue
                        // to validate and forward to the component to treat them.
                        remoteConnections.list[index].remoteAppId =
                            Configuration.configurationTable.list[i].app.id;
                        circularQueue = new CircularQueue(remoteConnections.list[index].remoteAppId);

                        remoteConnections.list[index].receiveInterface =
                             new ReceiveInterface(Configuration.configurationTable.list[i].app.id, circularQueue);
                        Component.RegisterResult result;
                        result = Component.RegisterRemote(
                            "ReceiveInterface",                        // able to do unique
                            remoteConnections.list[index].remoteAppId, //  name for remote
                            remoteConnections.list[index].receiveInterface.Callback);
                        remoteConnections.list[index].receiveInterfaceComponentKey
                            = result.key;
                        ConsoleOut.WriteLine("Remote ReceiveInterface " + result.status);

                        // Supply ReceiveInterface instance to CircularQueue to allow
                        //  signaling of wakeup event.
                        circularQueue.SupplyReceiveInterface
                            (remoteConnections.list[index].receiveInterface);

                        // Instantiate instance of Receive and Transmit framework 
                        // components to communicate with this remote application.
                        // Pass the associated ReceiveInterface to Receive for it
                        // to use to Push its received messages to the interface to
                        // verify and forward for necessary processing.
                        string receiveName = "R" + receiveIndex;
                        remoteConnections.list[index].receive =
                             new Receive( index,
                                          Configuration.configurationTable.list[i].app.id,
                                          remoteConnections.list[index].receiveInterface,
                                          circularQueue, 
                                          remoteConnections.list[index].namedPipe );
                        remoteConnections.list[index].receiveThread =
                             remoteConnections.list[index].receive.threadInstance;
                         
                        remoteConnections.list[index].transmit =
                            new Transmit(index,Configuration.configurationTable.list[i].app.id);

                        remoteConnections.list[index].registerSent = false;
                        remoteConnections.list[index].registerCompleted = false;

                        // Register the framework components.  
                        result = Component.RegisterReceive(receiveName);
                        remoteConnections.list[index].receiveComponentKey = result.key;
                        // Register for Transmit to consume the ANY topic.
                        result = Component.RegisterTransmit
                                     (index, remoteConnections.list[index].transmit);
                        //              remoteConnections.list[index].transmit.waitHandle);
                        remoteConnections.list[index].transmitComponentKey = result.key;
                        remoteConnections.list[index].receiveIndex = receiveIndex;
                        receiveIndex++;

                        // Register for Transmit to consume ANY topic.
                        Topic.TopicIdType topic;
                        Library.AddStatus status;
                        topic.topic = Topic.Id.ANY;
                        topic.ext = Topic.Extender.FRAMEWORK;
                        status = Library.RegisterTopic
                                 (topic, result.key, Delivery.Distribution.CONSUMER,
                                  remoteConnections.list[index].transmit.Callback);

                        // Increment count of remote connections.
                        remoteConnections.count++;
                    } // end if combination of local and remote applications
                } // end for
                
            } // end if more than one application in configuration

        } // end Launch


        // Return whether remote app has acknowledged Register Request.
        static public bool RegisterAcknowledged(int remoteAppId)
        {
            for (int i = 0; i < remoteConnections.count; i++)
            {
                if (remoteConnections.list[i].remoteAppId == remoteAppId)
                {
                    return remoteConnections.list[i].registerCompleted;
                }
            }
            return false;

        } // end RegisterAcknowledged

        // Record that remote app acknowledged the Register Request 
        static public void SetRegisterAcknowledged(int remoteAppId, bool set)
        {
            for (int i = 0; i < remoteConnections.count; i++)
            {
                if (remoteConnections.list[i].remoteAppId == remoteAppId)
                {
                    remoteConnections.list[i].registerCompleted = set; //  true;
                    return;
                }
            }
        } // end SetRegisterAcknowledged

        // Return the ReceiveThread 
        static public System.Threading.Thread ReceiveThread(int instance) //index) 
        {
            for (int i = 0; i < remoteConnections.count; i++)
            {
                if (remoteConnections.list[i].receiveIndex == instance)
                {
                    return (System.Threading.Thread)remoteConnections.list[i].receiveThread;
                }
            }
            return null;
        } // end ReceiveThread

        // Return the instance of the Transmit class for remote app
        static public Transmit TransmitInstance(int remoteAppId)
        {
            for (int i = 0; i < remoteConnections.count; i++)
            {
                if (remoteConnections.list[i].remoteAppId == remoteAppId)
                {
                    return remoteConnections.list[i].transmit;
                }
            }
            return null;
        } // end TransmitInstance

        // Return the instance of the Transmit class for the index
        static public Transmit TransmitClassInstance(int index)
        {
            return remoteConnections.list[index].transmit;
        } // end TransmitClassInstance
 
        static public Component.ParticipantKey EventTimerComponent(int remoteAppId)
        {
            for (int i = 0; i < remoteConnections.count; i++)
            {
                if (remoteConnections.list[i].remoteAppId == remoteAppId)
                {
                    return remoteConnections.list[i].receiveInterfaceComponentKey;
                }
	        }
            return Component.nullKey;
        } // end EventTimerComponent
 
    } // end Remote class

} // end namespace
