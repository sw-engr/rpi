﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace VisualCompiler
{

    static public class Delivery
    {
        // This class implements a portion of the framework meant to deliver
        // messages (that is, instances of topics) to the components that
        // have registered to consume the topic.  This is straight forward
        // for the default topics with Publish looking up in the Library
        // those components that have registered to consume the topic.
        //
        // A Request/Response topic can have multiple components that publish 
        // the request topic but only one consumer of the topic.  The consumer 
        // component analyses the request and produces the response.  Delivery 
        // must discover which component published the request and deliver the
        // response to that component.

        public enum Distribution
        {
            CONSUMER,
            PRODUCER
        };

        public struct HeaderType
        {
            public Int16 CRC;                     // message CRC
            public Topic.TopicIdType id;          // topic of the message
            public Component.ParticipantKey from; // publishing component
            public Component.ParticipantKey to;   // consumer component
            public Int64 referenceNumber;         // reference number of message
            public Int16 size;                    // size of data portion of message
        }

        public const Int16 HeaderSize = 16;

        // A message consists of the header data and the actual data of the
        // message
        public struct MessageType
        {
            public HeaderType header;
            public string data;
        }

        static public MessageType nullMessage;

        static public Int64 referenceNumber; // ever increasing message reference number

        // Initialize data that would otherwise be done in a constructor.
        static public void Initialize()
        {
            referenceNumber = 0;

            nullMessage.header.CRC = 0;
            nullMessage.header.from.appId = 0;
            nullMessage.header.from.comId = 0;
            nullMessage.header.from.subId = 0;
            nullMessage.header.to.appId = 0;
            nullMessage.header.to.comId = 0;
            nullMessage.header.to.subId = 0;
            nullMessage.header.referenceNumber = 0;
            nullMessage.header.size = 0;
            nullMessage.data = null;
        } // end Initialize

        static private void PublishResponseToRequestor
                            (Topic.TopicIdType topic,
                             Library.TopicTableType consumers,
                             MessageType msg)
        {
            bool found = false;
            for (int i = 0; i < consumers.count; i++)
            {
                if (Component.CompareParticipants(msg.header.to, 
                                                  consumers.list[i].component))
                {
                    // Return response to the requestor
                    consumers.list[i].referenceNumber = 0;
                    Disburse queue =
                        Component.GetQueue(consumers.list[i].component);
                    if (queue != null)
                    {
                        queue.Write(msg);
                        found = true;
                        break; // exit inner loop
                    }
                } 
            } // end for

            if (!found)
            {
                ConsoleOut.WriteLine
                    ("ERROR: Delivery couldn't find requestor for response");
            }

        } // end PublishResponseToRequestor

        // Publish an instance of a topic message by a component
        static public void Publish(Topic.TopicIdType topic,
                                   Component.ParticipantKey component,
                                   string message)
        { // forward for treatment
            Publish(topic, component, Component.nullKey, message);
        } // Publish

        // Publish an instance of a response topic message by a component 
        static public void Publish(Topic.TopicIdType topic,
                                   Component.ParticipantKey component, 
                                   Component.ParticipantKey from, 
                                   string message)
        { 
            // Increment the reference number associated with all new messages
            referenceNumber++;

            // Initialize an instance of a message
            MessageType msg;
            msg.header.CRC = 0;
            msg.header.id = topic;
            msg.header.from = component;
            msg.header.to = from; 
            msg.header.referenceNumber = referenceNumber;
            msg.header.size = (Int16)message.Length;
            msg.data = message;

            // Get the set of consumers of the topic
            Library.TopicTableType consumers = Library.TopicConsumers(topic);

            Topic.TopicIdType requestTopic = topic;
            if (topic.ext == Topic.Extender.RESPONSE) // the message has to be delivered
            {                                         //   to the particular requestor
                // Get the consumer of the request topic
                requestTopic.ext = Topic.Extender.REQUEST;
                Library.TopicTableType requestConsumers =
                    Library.TopicConsumers(requestTopic);
                if (Component.CompareParticipants(msg.header.to,
                                                  Component.nullKey))
                {
                    ConsoleOut.WriteLine("ERROR: No 'To' address for Response");
                    return;
                }
                if (msg.header.to.appId != App.applicationId)
                { // send to remote application
                    Publish(msg.header.to.appId, msg);
                    return;
                }

                PublishResponseToRequestor(topic, consumers, msg);

            } // end if published topic is a Response

            else if (topic.ext == Topic.Extender.REQUEST) // only one consumer possible
            {
                if (consumers.count > 0)
                { // forward request to the lone consumer of request topic
                    msg.header.to = consumers.list[0].component;
                    consumers.list[0].requestor = component;
                    consumers.list[0].referenceNumber = referenceNumber;
                    if (msg.header.to.appId != App.applicationId)
                    { // send to remote app
                        Publish(msg.header.to.appId, msg);
                    }
                    else
                    { // forward to local consumer
                        bool found = false;
                        Disburse queue =
                            Component.GetQueue(consumers.list[0].component);
                        if (queue != null)
                        {
                            queue.Write(msg);
                            found = true;
                        }

                        if (!found)
                        {
                            ConsoleOut.WriteLine(
                               "ERROR: Delivery didn't have queue for request");
                        }
                    }
                }
                else
                {
                    ConsoleOut.WriteLine(
                        "ERROR: Delivery couldn't find consumer for request");
                }
            }

            // the published topic has to be the Default - can be multiple consumers
            else
            {
                if (consumers.count > 0)
                {
                    for (int i = 0; i < consumers.count; i++)
                    {
                        msg.header.to = consumers.list[i].component;

                        // Avoid sending topic back to the remote app that 
                        // transmitted it to this app or forwarding a remote
                        // message that is to be delivered to a different 
                        // component.
                        if (Ignore(msg, consumers.list[i].component))
                        {
                            // ignore
                        }
                        else // publish to local or remote component
                        {
                            if (msg.header.to.appId != App.applicationId)
                            { // Deliver message to remote application
                                Publish(msg.header.to.appId, msg);
                            }
                            else
                            { // Deliver message to local application by copying to
                                // consumer's queue
                                consumers.list[i].requestor = component;
                                consumers.list[i].referenceNumber = 0;
                                bool found = false;
                                Disburse queue =
                                   Component.GetQueue(consumers.list[i].component);
                                if (queue != null)
                                {
                                    queue.Write(msg);
                                    found = true;
                                }
                                if (!found)
                                {
                                    ConsoleOut.WriteLine(
                                       "ERROR: local default Delivery couldn't find queue for consumer");
                                }
                            }
                        } // end if Ignore
                    } // end for
                } // end if
                else
                {
                    ConsoleOut.WriteLine("ERROR: No Consumers of the topic");
                }

            } // end if 

        } // end Publish
 
        // Publish an instance of a remote topic message forwarded by Receive
        static public void Publish(MessageType message)
        {
            // Get the set of consumers of the topic
            Library.TopicTableType consumers = 
                Library.TopicConsumers(message.header.id);

            if (message.header.id.ext == Topic.Extender.REQUEST)
            { // forward the request topic to its consumer
                for (int i = 0; i < consumers.count; i++)
                {
                    if (message.header.id.topic == consumers.list[i].id.topic)
                    { // the only possible consumer of the request topic  
                        consumers.list[i].requestor = message.header.from; // component;
                        consumers.list[i].referenceNumber = 
                            message.header.referenceNumber;
                        bool found = false;
                        Disburse queue =
                            Component.GetQueue(consumers.list[i].component);
                        if (queue != null)
                        {
                            queue.Write(message);
                            found = true;
                        }
                        if (!found)
                        {
                            ConsoleOut.WriteLine(
                                "ERROR: remote Request Delivery couldn't find queue for consumer");
                        }
                        return; // can only be one consumer
                    }
                }
            } // end for
            else if (message.header.id.ext == Topic.Extender.RESPONSE)
            { // forward the response topic to the request publisher
                for (int i = 0; i < consumers.count; i++)
                {
                    ConsoleOut.WriteLine("Delivery Response consumers "); //{0} {1} {2} {3} {4} {5} {6}",
                //        consumers.count, message.header.id.topic, 
                //        consumers.list[i].id.topic,
                //        consumers.list[i].component.appId, 
                //        consumers.list[i].component.comId,
                //        message.header.to.appId, message.header.to.comId);
                    if ((message.header.id.topic == consumers.list[i].id.topic)
                        && (Component.CompareParticipants(
                               consumers.list[i].component,
                               message.header.to)))
                    { // found the publisher of the Request  
                        bool found = false;
                        Disburse queue =
                            Component.GetQueue(message.header.to);
                        if (queue != null)
                        {
                            ConsoleOut.WriteLine("queued the message");
                            queue.Write(message);
                            found = true;
                        }
                        if (!found)
                        {
                            ConsoleOut.WriteLine(
                                "ERROR: Remote Response Delivery couldn't find queue for consumer");
                        }
                        break; // exit loop
                    }
                } // end for
            }
            else // Default topic - forward to possible multiple consumers
            {
                for (int i = 0; i < consumers.count; i++)
                {
                    if (message.header.id.topic == Topic.Id.HEARTBEAT)
                    {
                        ConsoleOut.WriteLine("Deliver HEARTBEAT " +
                            message.header.to.appId + " " + message.header.to.comId
                            + " " + message.header.from.appId + " " +
                            message.header.from.comId);
                    }
                    // Avoid sending topic back to the remote app that 
                    // transmitted it to this app or forwarding a remote
                    // message that is to be delivered to a different 
                    // component.
                    if ((consumers.list[i].id.topic == message.header.id.topic)
                        && (consumers.list[i].id.ext == message.header.id.ext)
                        && (Ignore(message.header.to, message.header.from, 
                                consumers.list[i].component)))
                    {
                        ConsoleOut.WriteLine("Remote message ignored "); //{0} {1} {2} {3} {4} {5}",
                    //        message.header.to.appId, message.header.to.comId,
                    //        message.header.from.appId, message.header.from.comId,
                    //        consumers.list[i].component.appId, 
                    //        consumers.list[i].component.comId);
                    }
                    else
                    { // Deliver message to local application by copying to its queue
                        consumers.list[i].requestor = message.header.from; 
                        consumers.list[i].referenceNumber = 0;
                        if (consumers.list[i].component.appId == 
                            App.applicationId)
                        {
                            bool queueFound = false;
                            Disburse queue =
                               Component.GetQueue(consumers.list[i].component);
                            if (queue != null)
                            {
                                queue.Write(message);
                                queueFound = true;
                            }
                            if (!queueFound)
                            {
                                ConsoleOut.WriteLine("ERROR: Remote default Delivery couldn't find queue for consumer");
                            }
                        }
                    } // end if Ignore
                }

            }

        } // end Publish (from remote)
 
        // Remote messages are to be ignored if the From and To components are
        // the same since this would transmit the message back to the remote app.
        // Remote messages are only to be forwarded to the To component and not
        // to all the components of the consumers list since separate messages
        // are sent by the remote component for each local consumer.
        static private bool Ignore(MessageType message, 
                                   Component.ParticipantKey component)
        {
            bool equal = Component.CompareParticipants(
                                     message.header.from, message.header.to);
            if ((equal) && (message.header.to.appId != App.applicationId))
            { // same from and to component and remote message
                return true;
            }
            if (message.header.from.appId != App.applicationId) 
            { // remote message; check if consumer component is 'to' participant 
                if (!Component.CompareParticipants(message.header.to,
                                                   component))
                {
                    return true;
                }
            }
            return false;
        } // end Ignore
        
        // Remote messages are to be ignored if the From and To components are
        // the same since this would transmit the message back to the remote app.
        // Remote messages are only to be forwarded to the To component and not
        // to all the components of the consumers list since separate messages
        // are sent by the remote component for each local consumer.
        static private bool Ignore(Component.ParticipantKey to, 
                                   Component.ParticipantKey from,
                                   Component.ParticipantKey component)
        {
            bool equal = Component.CompareParticipants(from, to);
            if ((equal) && (to.appId != App.applicationId))
            { // same from and to component and remote message
                return true;
            }
            if ((from.appId != App.applicationId) &&    // from is remote
                (component.appId == App.applicationId)) // component is local
            { // remote message; check if consumer component is 'to' participant 
                if (!Component.CompareParticipants(to, component))
                {
                    return true;
                }
            }
            return false;
        } // end Ignore

        // Deliver message to remote app
        static public void Publish(int remoteAppId, MessageType message)
        {
            // Obtain instance of Transmit class to which the message is to be delivered
            Transmit transmit = Remote.TransmitInstance(remoteAppId); 
            ConsoleOut.WriteLine("Publish to Transmit queue " + transmit.queue.queueName);
            if (transmit == null)
            {
                ConsoleOut.WriteLine(
                    "ERROR: No Transmit class instance for Publish");
            }

            else
            {
                // Increment the reference number associated with all new 
                // messages
                referenceNumber++;
                message.header.referenceNumber = referenceNumber;

                // Get the queue associated with the instance of the class
                if (transmit.queue != null)
                {
                    ConsoleOut.WriteLine("Publish to Remote app " + // {4}",
                         message.header.id.topic + " " + message.header.id.ext 
                         + " " + remoteAppId + " " + //transmit.queue.queueTable.toAppId,
                         message.header.referenceNumber);
                    transmit.queue.Write(message); 
                }
                else
                {
                    ConsoleOut.WriteLine(
                        "ERROR: Transmit queue for remote transmit is null");
                }
            }
        } // end Publish

    } // end Delivery class

} // end namespace

