﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
//using System.Windows.Forms;

namespace VisualCompiler
{
    static public class Library
    {
        // A library of registered message topics with their producer
        // and consumer components.

        // Component data from registration as well as run-time status
        public struct TopicDataType
        {
            public Topic.TopicIdType id;               // complete topic identifier
            public Component.ParticipantKey component; // component that registers the topic
            public Delivery.Distribution distribution; // whether consumed or produced
            public Callback fEntry;                    // callback, if any, to consume the messages
            public Component.ParticipantKey requestor; // component that produced a REQUEST topic
            public Int64 referenceNumber;              // reference number of a REQUEST topic
        };

        public class TopicTableType
        {
            public int count; // Number of declared topics of the configuration of applications
            public TopicDataType[] list = 
                new TopicDataType[Configuration.MaxApplications*Component.MaxComponents];
            // will need to be expanded
        };

        // Library of topic producers and consumers
        static private TopicTableType topicTable = new TopicTableType();

        // Data of Remote Request topic
        public struct TopicListDataType
        {
            public Topic.TopicIdType topic;
            public Component.ParticipantKey component;
            //public Component.ParticipantKey requestor;
        };

        // List of topics
        public class TopicListTableType
        {
            public int count;
            public TopicListDataType[] list = new TopicListDataType[25];
        }

        public struct CallbackDataType
        {
            public Callback cEntry; // Any entry point to consume the message
//            public ComponentQueue queue; // Queue associated with component
        };

        public class CallbackTableType
        {
            public int count; // Number of messages in the table
            public CallbackDataType[] list = new CallbackDataType[Component.MaxComponents];
        }

   //     static private bool keypushOK = false;
        
   //     static private bool bothRegisterMsgs = false;

   //     static public bool KeypushOK()
   //     {
   //         return bothRegisterMsgs;
   //     }

        // Initialize. A replacement for a constructor.
        static public void Initialize()
        {
            topicTable.count = 0;
        } // end Initialize

        // Possible results of attempt to register a topic
        public enum AddStatus
        {
            SUCCESS,   // Topic added to the library
            DUPLICATE, // Topic already added for the component
            FAILURE,   // Topic not added
            NOTALLOWED // Topic not allowed, such as for second consumer of REQUEST
        };

        // Determine if supplied topic is a known pairing.
        static public bool ValidPairing(Topic.TopicIdType id)
        {
            for (int i = 0; i < Topic.TopicIds.count; i++)
            {
            	if ((id.topic == Topic.TopicIds.list[i].topic) && // then known 
                    (id.ext == Topic.TopicIds.list[i].ext))       //   topic pairing
            	{
                    return true;
                }
            }
            return false;
        } // end ValidPairing

        // Add a topic with its component, whether producer or consumer, and entry for consumer
        static public AddStatus RegisterTopic
                      (Topic.TopicIdType id, Component.ParticipantKey component,
                       Delivery.Distribution distribution, Callback fEntry) 
        {
            // Determine if supplied topic is a known pairing.
            bool entryFound = false;
            entryFound = ValidPairing(id);
            if (!entryFound)
            {
            	return AddStatus.NOTALLOWED;
            }	
            
            // Determine if a framework topic.  That is, a user component 
            // shouldn't be registering these topics to the Library.
            if (((id.topic >= Topic.Id.NONE) && 
                 (id.topic <= Topic.Id.REGISTER)) ||
                (id.ext == Topic.Extender.FRAMEWORK) &&
                (!App.FrameworkTopicsAllowed()))
            {
                return AddStatus.NOTALLOWED;
            }

            // Determine if topic has already been added to the library.
            entryFound = false;
            for (int i = 0; i < topicTable.count; i++)
            {
                if (id.topic == topicTable.list[i].id.topic) // topic id already in table
                { // Be sure this new registration isn't for a request consumer
                    if ((id.ext == topicTable.list[i].id.ext) &&
                        (id.ext == Topic.Extender.REQUEST) &&
                        (distribution == Delivery.Distribution.CONSUMER))
                    {
                        if (Component.CompareParticipants(component,
                            topicTable.list[i].component))
                        {
                            ConsoleOut.WriteLine(
                                  "ERROR: Only one Consumer of a Request allowed "); //{0} {1} {2}",
                          //         topicTable.list[i].id.topic, component.appId,
                          //         component.comId);
                            entryFound = true;
                            return AddStatus.NOTALLOWED;
                        }
                    }
                } // end if topic in table
            } // end for

            // Check that consumer component has a queue
            if (distribution == Delivery.Distribution.CONSUMER)
            {
                for (int k = 0; k < Component.componentTable.count; k++)
                {
                    if (Component.CompareParticipants(
                           component, Component.componentTable.list[k].key))
                    {
//                        if ((Component.componentTable.list[k].queue == null) &&
//                            (Component.componentTable.list[k].circularQueue == null) &&
//                            (Component.componentTable.list[k].disburseQueue == null))
                        if (Component.componentTable.list[k].queue == null)
                        {
                            return AddStatus.NOTALLOWED;
                        }
                    }
                } // end for
            }  

            if (!entryFound) // add the topic with its component to the table
            {
                int k = topicTable.count;
                topicTable.list[k].id = id;
                topicTable.list[k].component = component;
                topicTable.list[k].distribution = distribution;
                topicTable.list[k].fEntry = fEntry;
                topicTable.count++;
//                ConsoleOut.WriteLine("Library Add {0} {1} {2} {3} {4} {5}", k, 
//                    id.topic, id.ext, component.appId,
//                    component.comId, distribution);
                return AddStatus.SUCCESS;
            }

            return AddStatus.FAILURE;

        } // end RegisterTopic function
//<<< this doesn't need a locked version since only called at startup prior to 
//    separate threads.  What about other methods? >>>

        static public void RegisterRemoteTopics(int remoteAppId, Delivery.MessageType message)
        {
            // Check if topics from remote app have already been registered.
            ConsoleOut.WriteLine("RegisterRemoteTopics " + remoteAppId + " count " + 
                topicTable.count);
            for (int i = 0; i < topicTable.count; i++)
            {
 //               ConsoleOut.WriteLine("Library Topics list {0} {1} {2} {3} {4}",
 //                   i, topicTable.list[i].component.appId, 
 //                   topicTable.list[i].requestor.appId, topicTable.list[i].id.topic,
 //                   topicTable.list[i].id.ext);
                if (topicTable.list[i].component.appId == remoteAppId)
                {
                    ConsoleOut.WriteLine("RegisterRemoteTopics already in table");
                    // Send Response to the remote app again.
                    SendRegisterResponse(remoteAppId);
                    return; // since topicTable already contains entries from remote app
                }
 
            }

            // Decode Register Request topic.
            Library.TopicListTableType topics = new Library.TopicListTableType();
            topics = Format.DecodeRegisterRequestTopic(message);
            //            ConsoleOut.WriteLine("Decode Register Request {0}", topics.count);

            // Add the topics from remote app as ones that it consumes.
            int index = topicTable.count;
            for (int i = 0; i < topics.count; i++)
            {
                // ignore local consumer being returned in Register Request
                if (topics.list[i].component.appId != App.applicationId)
                {
                    topicTable.list[index].id = topics.list[i].topic;
                    ConsoleOut.WriteLine("RegisterRequest topic " + index + " " +
                        topicTable.list[index].id.topic + " " + 
                        topicTable.list[index].id.ext);
                    topicTable.list[index].component.appId = topics.list[i].component.appId;
                    topicTable.list[index].component.comId = topics.list[i].component.comId;
                    topicTable.list[index].component.subId = topics.list[i].component.subId;
                    topicTable.list[index].distribution = Delivery.Distribution.CONSUMER;
                    topicTable.list[index].fEntry = null;
                    topicTable.list[index].requestor.appId = remoteAppId;
                    topicTable.list[index].requestor.comId = 0; // add for Request message
                    topicTable.list[index].requestor.subId = 0; //  sometime
                    topicTable.list[index].referenceNumber = 0;
                    index++;
                }
                else
                {
                    ConsoleOut.WriteLine("ERROR: Register Request contains local component "
                        + topics.list[i].component.appId + " " + topics.list[i].component.comId);
                }
            }
            topicTable.count = index;

            ConsoleOut.WriteLine("topicTable after Decode");
            for (int i = 0; i < topicTable.count; i++)
            {
         //       ConsoleOut.WriteLine("{0} {1} {2} {3} {4} {5}", i, topicTable.list[i].id.topic,
         //           topicTable.list[i].id.ext, topicTable.list[i].distribution,
         //           topicTable.list[i].component.appId, topicTable.list[i].component.comId );
            }

            // Send Response to the remote app.
            SendRegisterResponse(remoteAppId);

// NO NO, want the receipt of the Register Response from App2.  Not the receipt of its
// Register Request. 
//            var result = MessageBox.Show("Ok to use keys",
//                                         "TreatKey", MessageBoxButtons.OK);
//            bothRegisterMsgs = true;
 
        } // end RegisterRemoteTopics

        static public void RemoveRemoteTopics(int remoteAppId)
        {
            ConsoleOut.WriteLine("RemoveRemoteTopics " + remoteAppId + " count " +
                 topicTable.count);
            int newCount = topicTable.count;
            int index = topicTable.count - 1;
            int newIndex;
            for (int i = 0; i < topicTable.count; i++)
            {
                if (topicTable.list[index].component.appId == remoteAppId)
                {
                    ConsoleOut.WriteLine("RemoteTopic in table " +
                        topicTable.list[index].id.topic + " " + topicTable.list[index].id.ext);
                    // Move up any entries that are after this one
                    newIndex = index;
                    for (int j = index + 1; j < newCount; j++)
                    {
                        topicTable.list[newIndex] = topicTable.list[j];
                        newIndex++;
                    }
                    newCount = newIndex;
                }
                index--;
            } // end for
            topicTable.count = newCount;

            ConsoleOut.WriteLine("topicTable after Decode");
            for (int i = 0; i < topicTable.count; i++)
            {
           //     ConsoleOut.WriteLine("{0} {1} {2} {3} {4} {5}", i, topicTable.list[i].id.topic,
           //         topicTable.list[i].id.ext, topicTable.list[i].distribution,
           //         topicTable.list[i].component.appId, topicTable.list[i].component.comId);
            }

        } // end RemoveRemoteTopics

        // Send the Register Request message to the remote app.  This
        // message is to contain the topics of the local app for which
        // there are consumers so that the remote app will forward 
        // any of those topics that it publishes.
        static public void SendRegisterRequest(int remoteAppId)
        {
            // Build table of all non-framework topics that have local consumers.
            TopicTableType topicConsumers = new TopicTableType();
            for (int i = 0; i < topicTable.count; i++)
            {
                if ((topicTable.list[i].id.topic != Topic.Id.REGISTER) &&
                    (topicTable.list[i].id.ext != Topic.Extender.FRAMEWORK))
                {
                    if ((topicTable.list[i].distribution ==
                         Delivery.Distribution.CONSUMER) && 
                        (topicTable.list[i].component.appId == App.applicationId))
                    {
 //                       ConsoleOut.WriteLine("RegisterRequest {0} {1} {2}",
 //                           topicTable.list[i].component.appId,
 //                           topicTable.list[i].id.topic, topicTable.list[i].id.ext);
                        topicConsumers.list[topicConsumers.count] = topicTable.list[i];
                        topicConsumers.count++;
                    }
                }
            }

            // Build Register Request topic of these topics.
            Delivery.MessageType message = 
                Format.RegisterRequestTopic(remoteAppId, topicConsumers);

            ConsoleOut.WriteLine("Publish of Register Request");
            Delivery.Publish(remoteAppId, message);
            // if this works then Format doesn't really need to fill in header.
            // or do a new Publish for this.

        } // end SendRegisterRequest

        static private void SendRegisterResponse(int remoteAppId)
        {
            Delivery.MessageType responseMessage;
            responseMessage.header.CRC = 0;
            responseMessage.header.id.topic = Topic.Id.REGISTER;
            responseMessage.header.id.ext = Topic.Extender.RESPONSE;
            responseMessage.header.from = Component.nullKey;
            responseMessage.header.from.appId = App.applicationId;
            responseMessage.header.to = Component.nullKey;
            responseMessage.header.to.appId = remoteAppId;
            responseMessage.header.referenceNumber = 0;
            responseMessage.header.size = 0;
            responseMessage.data = "";

            Delivery.Publish(remoteAppId, responseMessage);

        } // end SendRegisterResponse

        // Return list of callback consumers
        static public CallbackTableType Callbacks(Component.ParticipantKey id)
        {
            CallbackTableType EntryPoints = new CallbackTableType();
            EntryPoints.count = 0;
            for (int i = 0; i < topicTable.count; i++)
            {
                if ((Component.CompareParticipants(topicTable.list[i].component,
                                                   id)) &&
                    (topicTable.list[i].fEntry != null))
                {
                    EntryPoints.list[EntryPoints.count].cEntry = 
                        topicTable.list[i].fEntry;
                    EntryPoints.count++;
                }
            }
            return EntryPoints;
        } // end Callbacks

        // Return list of consumers of the specified topic
        static public TopicTableType TopicConsumers(Topic.TopicIdType id)
        {
            //debug
            bool heartbeat = false;
            if (id.topic == Topic.Id.HEARTBEAT) heartbeat = true;
            
            TopicTableType topicConsumers = new TopicTableType();
            for (int i = 0; i < topicTable.count; i++)
            {
                if ((id.topic == topicTable.list[i].id.topic) &&
                    (id.ext == topicTable.list[i].id.ext))
                {
                    if (topicTable.list[i].distribution == 
                        Delivery.Distribution.CONSUMER)
                    {
                    	if (heartbeat)
                    	{
                    	    ConsoleOut.Write("Consume Heartbeat " +
                    	        topicTable.list[i].component.appId + " " +
                    	        topicTable.list[i].component.comId);
                    	}
                        topicConsumers.list[topicConsumers.count] = 
                            topicTable.list[i];
//                        ConsoleOut.WriteLine("Library {0} {1} {2}", 
//                            topicTable.list[i].id.topic,
//                            topicTable.list[i].component.appId,
//                            topicTable.list[i].component.comId);
                        topicConsumers.count++;
                    }
                }
            }
            return topicConsumers;
        }

    } // end Library class

} // end namespace