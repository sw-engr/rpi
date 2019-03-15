using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading; // for ManagedThreadId

namespace VisualCompiler
{
    // The ReceiveInerface is the class and component that is the interface
    // between Receive and the components that are to deliver the received
    // messages.
    //
    // The Receive thread queues the received messages to the ReceiveInterface
    // queue.  Then the CircularQueue Write function publishes an event that
    // is fielded by the forever loop of the Callback that forwards it for
    // processing in the rest of ReceiveInterface and the C# classes to which
    // it interfaces.  This allows the Receive thread to immediately return to
    // the named pipe client to receive the next message.  
    //
    // That is, Write is executed in the Receive thread but all the other
    // processing executes in the ReceiveInterface thread.

    public class ReceiveInterface
    {
        // The framework class to be instantiated by the Remote class to
        // transfer messages received by the Receive thread via NamedPipe
        // to Delivery, Library, etc for decoding and treatment.  Except
        // for Write, the functions of this class and the class functions
        // that it invokes run in the ReceiveInterface thread.

        public int remoteAppId; // remote app associated with instance of class

        private CircularQueue circularQueue;

        private UnicodeEncoding streamEncoding;

        // Define the EventWaitHandle
        public EventWaitHandle waitHandle;

        // List of messages
        public class ReceivedMessageListTableType
        {
            public int count;      // number of entries 
            public int newlyAdded; // number not yet Popped
            public Delivery.MessageType[] list = new Delivery.MessageType[10];
        }

        // Table of received messages
        public ReceivedMessageListTableType msgTable = new ReceivedMessageListTableType();

        Stopwatch timingWatch = new Stopwatch();

        private byte[] none = new byte[0]; 
        
        public ReceiveInterface() // null constructor
        {
        }

        public ReceiveInterface(int appId, CircularQueue queue) // constructor
        {
            ConsoleOut.WriteLine("ReceiveInterface constructor entered "); //{0}", appId);
            remoteAppId = appId;
            circularQueue = queue;

            streamEncoding = new UnicodeEncoding();

            timingWatch = Stopwatch.StartNew();

            waitHandle = new EventWaitHandle(false, EventResetMode.ManualReset);

        } // end constructor

        public void Signal()
        {
            waitHandle.Set();
        }

        // The functions to validate the received message and forward it are below.
        // These functions execute in the ReceiveInterface thread via the Callback
        // forever loop started by the event initiated by Signal.

        private void AnnounceError(byte[] recdMessage)
        {
            int length = recdMessage.Length;
            int i = 0;
            int zeroCount = 0;
            int zeroStart = 0;
            for (int j = 0; j < length; j++)
            {
                if (recdMessage[j] == 0)
                {
                    zeroCount++;
                }
                else
                {
                    zeroCount = 0;
                    zeroStart = j;
                }
            }
            while (length > 0)
            {
                if (i > zeroStart + 28) break;
                if (length >= Delivery.HeaderSize) //14)
                {
                    ConsoleOut.WriteLine(
                        recdMessage[i] + " " + recdMessage[i + 1] + " " + recdMessage[i + 2]
                        + " " + recdMessage[i + 3] + " " + recdMessage[i + 4] + " " + 
                        recdMessage[i + 5] + " " + recdMessage[i + 6] + " " +
                        recdMessage[i + 7] + " " + recdMessage[i + 8] + " " +
                        recdMessage[i + 9] + " " + recdMessage[i + 10] + " " +
                        recdMessage[i + 11] + " " + recdMessage[i + 12] + " " +
                        recdMessage[i + 13] + " " + recdMessage[i + 14] + " " + recdMessage[i + 15]);
                    length = length - Delivery.HeaderSize; //14;
                    i = i + Delivery.HeaderSize; //14;
                }
                else
                {
                    for (int j = i; j < length; j++)
                    {
                        ConsoleOut.Write(" " + recdMessage[j]);
                    }
                    ConsoleOut.WriteLine(" ");
                    length = 0;
                }
            }
        } // end AnnounceError

        // Copy message into table
        private void CopyMessage(int m, byte[] recdMessage)
        {
            int index = msgTable.count;
            Int32 size = recdMessage[m+0];
            size = 256 * size + recdMessage[m+1];
            msgTable.list[index].header.CRC = (Int16)size;
            msgTable.list[index].header.id.topic = (Topic.Id)recdMessage[m+2];
            msgTable.list[index].header.id.ext = (Topic.Extender)recdMessage[m+3];
            msgTable.list[index].header.from.appId = recdMessage[m+4];
            msgTable.list[index].header.from.comId = recdMessage[m+5];
            msgTable.list[index].header.from.subId = recdMessage[m+6];
            msgTable.list[index].header.to.appId = recdMessage[m+7];
            msgTable.list[index].header.to.comId = recdMessage[m+8];
            msgTable.list[index].header.to.subId = recdMessage[m+9];
            Int64 referenceNumber = recdMessage[m+10];
            referenceNumber = 256 * referenceNumber + recdMessage[m+11];
            referenceNumber = 256 * referenceNumber + recdMessage[m+12];
            referenceNumber = 256 * referenceNumber + recdMessage[m+13];
            msgTable.list[index].header.referenceNumber = referenceNumber;
            size = recdMessage[m+14];
            size = 256 * size + recdMessage[m+15];
            msgTable.list[index].header.size = (Int16)size;
            msgTable.list[index].data = "";
            for (int i = 0; i < size; i++)
            {
                msgTable.list[index].data += 
                    (char)recdMessage[m + i + Delivery.HeaderSize]; //14];
            }
            msgTable.count++;

        } // end CopyMessage 

        private void ParseRecdMessages(byte[] recdMessage)
        {
            int m = 0;
            while (m < recdMessage.Length)
            {
                if ((m + Delivery.HeaderSize) <= recdMessage.Length) // space for header
                {
                    Topic.TopicIdType topic;
                    topic.topic = (Topic.Id)recdMessage[m + 2];
                    topic.ext = (Topic.Extender)recdMessage[m + 3];
                    if (Library.ValidPairing(topic))
                    { // assuming if Topic is valid that the remaining data is
                        int size = recdMessage[m + 14] * 256; // 8 bit shift
                        size = size + recdMessage[m + 15]; // data size
                        if ((m + size + Delivery.HeaderSize) <= recdMessage.Length) // space for message
                        {
                            CopyMessage(m, recdMessage);
                        }
                        m = m + size + Delivery.HeaderSize; //14;
                    }
                    else // scan for another message
                    {
                        for (int n = m; n < recdMessage.Length; n++)
                        {
                            topic.topic = (Topic.Id)recdMessage[n];
                            if ((n+1) >= recdMessage.Length) return; // no space left
                            topic.ext = (Topic.Extender)recdMessage[n + 1];
                            if (Library.ValidPairing(topic))
                            {
                                m = n;
                                ConsoleOut.WriteLine("new valid topic starting " +
                                    topic.topic + " " + topic.ext + " " + n);
                                break; // exit inner loop
                            }
                        }
                    }
                }
                else
                {
                    break; // exit outer loop
                }
            }

        } // end ParseRecdMessages
 

        // Non-Heartbeat Messages have to be messages formatted as framework
        // topic messages.  Otherwise, they will be discarded.  These topic
        // messages will be forwarded to the component(s) that has/have
        // registered to consume them.  
        private void ForwardMessage(Delivery.MessageType message)
        {
            // Check if a framework Register message.
            if (message.header.id.topic == Topic.Id.REGISTER)
            { // Check if acknowledge
                if (message.header.id.ext == Topic.Extender.RESPONSE)
                {
                    Remote.SetRegisterAcknowledged(remoteAppId, true);
                }
                else // register Request message
                {
                    int size = message.header.size;
                    var chars = message.data.ToCharArray();
                    int i = 0;
                    while (size > 0)
                    {
                        Topic.Id id = (Topic.Id)chars[i];
                        Topic.Extender ext = (Topic.Extender)chars[i + 1];
                        size = size - 5;
                        i = i + 5;
                    }
                    Library.RegisterRemoteTopics(remoteAppId, message);
                }
            }
            else
            { // Forward other messages
                Delivery.Publish(message);
            }

        } // end ForwardMessage

        // Determine if 3 or more consecutive heartbeats have been received
        // and the Register Request has been acknowledged or the needs to
        // be sent.
        private void TreatHeartbeatMessage(int remoteAppId) 
        {
            ConsoleOut.WriteLine("TreatHeartbeatMessage " +
                remoteAppId + " " + 
                Remote.connections[remoteAppId].consecutiveValid);
            if (Remote.connections[remoteAppId].consecutiveValid >= 3) // then connection established
            {
                Remote.connections[remoteAppId].connected = true;
                bool acknowledged = Remote.RegisterAcknowledged(remoteAppId);
                if ((!acknowledged) && 
                    ((Remote.connections[remoteAppId].consecutiveValid % 3) == 0))
                { // where only every 3rd time to allow acknowledged to be set
                    Library.SendRegisterRequest(remoteAppId);
                }
                else
                {
                }
            }
//            else
//            {
//                Remote.connections[remoteAppId].connected = false;
//            }
        } // end TreatHeartbeatMessage

        // Validate any heartbeat message.  
        // Notes: A heartbeat message must identify that it is meant for this
        //        application and originated in the remote application for
        //        which this instantiation of the Receive thread is responsible.
        private bool HeartbeatMessage(Delivery.MessageType recdMessage) //, int count) 
        {
            bool heartbeatMessage = false;

            heartbeatMessage = Format.DecodeHeartbeatMessage(recdMessage, remoteAppId);
            if (heartbeatMessage)
            {
                Remote.connections[remoteAppId].consecutiveValid++;
            }
            else
            {
                Remote.connections[remoteAppId].consecutiveValid = 0;
            }

            // Return whether a Heartbeat message; whether or not valid.
            return heartbeatMessage;

        } // end HeartbeatMessage

        public void TreatMessage()
        {
            byte[] recdMessage = new byte[250];
            recdMessage = circularQueue.Read();
            if (recdMessage.Length > 0)
            { // message to be converted and treated

                string receivedMessage = "";
                receivedMessage = streamEncoding.GetString(recdMessage);
                if (recdMessage.Length >= Delivery.HeaderSize) // message can have a header
                {
                    Topic.TopicIdType topic;
                    topic.topic = (Topic.Id)recdMessage[2];
                    topic.ext = (Topic.Extender)recdMessage[3];
                    ConsoleOut.WriteLine("TreatMessage " + topic.topic + " " + topic.ext);
                    bool valid = Library.ValidPairing(topic);
                    if (!valid)
                    {
                        ConsoleOut.WriteLine("ERROR: Received Invalid Topic " +
                            topic.topic + " " + topic.ext);
                        AnnounceError(recdMessage);
                    }
                    else
                    {
                        // Convert received message(s) to topic messages.
                        msgTable.count = 0;
                        ParseRecdMessages(recdMessage);
                        if (msgTable.count > 0)
                        {
                            for (int m = 0; m < msgTable.count; m++)
                            {
                                ConsoleOut.WriteLine( 
                                    msgTable.list[m].header.id.topic + " " +
                                    msgTable.list[m].header.id.ext + " " + 
                                    msgTable.list[m].header.size);
                                if ((msgTable.list[m].header.id.topic == Topic.Id.HEARTBEAT) &&
                                    (msgTable.list[m].header.id.ext == Topic.Extender.FRAMEWORK))
                                {
                                    if (HeartbeatMessage(msgTable.list[m])) //,count))
                                    {
                                        TreatHeartbeatMessage(remoteAppId); //,count);
                                    }
                                    else
                                    {
                                        Remote.connections[remoteAppId].connected = false;
                                    }
                                }
                                else
                                {
                                    ForwardMessage(msgTable.list[m]);
                                }
                            }
                        } // end if 
                    } // valid pairing
                } // end if Length large enough
                else
                {
                    try
                    {
                        ConsoleOut.WriteLine("ERROR: Received message less than " +
                            Delivery.HeaderSize + " bytes " + recdMessage.Length);
                        AnnounceError(recdMessage);
                    }
                    catch
                    {
                        ConsoleOut.WriteLine("ERROR: Catch of Received message less than " 
                            + Delivery.HeaderSize + " bytes " +
                            receivedMessage.Length);
                        if (receivedMessage.Length > 0)
                        {
                            AnnounceError(recdMessage);
                        }
                    }

                }
            } // end if recdMessage.Length > 0
        } // end TreatMessage

        // Pop messages from queue and forward
        public void Callback()
        {

            while (true)
            {
                int managedThreadId = Thread.CurrentThread.ManagedThreadId;
                ConsoleOut.WriteLine("receiveInterface callback " + 
                    managedThreadId);

                // Wait for event
                bool signaled = false;
                bool waitResult = false;
                waitHandle.Reset();

                signaled = waitHandle.WaitOne(Timeout.Infinite, waitResult);

                int mThreadId = Thread.CurrentThread.ManagedThreadId;
                ConsoleOut.WriteLine("receiveInterface after Wait " +
                    remoteAppId + " " + mThreadId);

                if (circularQueue.Unread())
                {
                    TreatMessage();
                }
                else // debug
                {
                    ConsoleOut.WriteLine("ReceiveInterface circularQueue NOT Unread");
                }

            } // end forever loop

        } // end Callback

    } // end class ReceiveInterface

} // end namespace
