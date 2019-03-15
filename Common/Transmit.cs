using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Diagnostics;
using System.Threading;

namespace VisualCompiler
{
    public class Transmit
    {
        // Transmit messages to a remote application.  There is one 
        // instance of this class per remote application.  And one
        // thread will be assigned to each instance.  The messages 
        // to transmit are to be removed from the queue.

        // A separate Timer class is instantiated for the instance of
        // the Transmit class to build and publish Heartbeat messages
        // to be sent to the remote app associated with the Transmit
        // thread.

        // Application identifier of the associated remote application
        private int remoteAppId;

        private int cycles = 0;

        private NamedPipe namedPipe;    // particular instance of NamedPipe class
        private bool connected = false; // whether connected to the pipe
        private bool start = true;      // whether need to start a connection

        public Disburse queue; 

        private UnicodeEncoding streamEncoding;

        private static HeartbeatTimer hTimer; 

        Stopwatch stopWatch = new Stopwatch();

        public Transmit(int index, int appId) // constructor
        {
            // Save identifier of the remote application tied to this
            // instance of the Receive class.
            remoteAppId = appId;

            namedPipe = Remote.remoteConnections.list[index].namedPipe;
            streamEncoding = new UnicodeEncoding();
            connected = false;
            start = true;

            string queueName = "Transmit" + appId;
            
            queue = new Disburse(queueName, true, false, AnyMessage);

            // Create local instance of Timer to publish Heartbeats
            hTimer = new HeartbeatTimer(appId, namedPipe);
            hTimer.StartTimer(2048, 3000);

            stopWatch.Start();

        } // end constructor

        // Set whether the pipe is connected to reopen the pipe if the remote app
        // has disconnected.
        // Note: This will most likely happen if it has been terminated.
        //       Then attempting to reopen will allow it to be launched again.
        private void TreatDisconnected()
        {
            if ((!start) && (namedPipe.pipeServer != null)
                         && (!namedPipe.pipeServer.IsConnected))
            {
                ConsoleOut.WriteLine("Reset connected in Transmit forever loop");
                connected = false; //Remote.connections[remoteAppId].pipeConnected;
                namedPipe.ClosePipes(false); // close Server pipe 
                Remote.connections[remoteAppId].consecutiveValid = 0;
                Remote.connections[remoteAppId].connected = false;
                Remote.connections[remoteAppId].pipeConnected = false;
                Remote.SetRegisterAcknowledged(remoteAppId, false);
                Library.RemoveRemoteTopics(remoteAppId);
                start = true;
            }
        } // end TreatDisconnected

        // Dequeue messages and transmit to remote application.
        public void Callback()
        {
            connected = false;
            start = true;
            while (true) // loop forever
            {
                ConsoleOut.WriteLine("in Transmit " + queue.queueName);
                if ((start) && (!connected))
                {
                    connected = namedPipe.OpenTransmitPipe();
                    start = false;
                    ConsoleOut.WriteLine("Transmit pipe opened " + remoteAppId +
                                         " " + connected );
                }
                // Read messages from the queue and wait for next event.
                queue.EventWait(); 

                //<<< This doesn't seem to be happening.  Why not? That is, no event. >>>
                int managedThreadId = Thread.CurrentThread.ManagedThreadId;
                ConsoleOut.WriteLine("in " + queue.queueName + " after wait " +  
                                  managedThreadId);
                TimeSpan ts = stopWatch.Elapsed;
        //        int cycles = 0;
                Delivery.MessageType messageInstance;
                while (queue.Unread()) 
                {
                    messageInstance = queue.Read();
                    if (connected)
                    {
                        ConsoleOut.WriteLine(queue.queueName + " dequeued message " +
                                           messageInstance.header.id.topic + " " +
                                           messageInstance.header.id.ext + " " +
                                           messageInstance.header.size);

                        byte[] topicMessage = new byte[messageInstance.header.size + 
                                                       Delivery.HeaderSize];
                        topicMessage = ConvertFromTopicMessage(messageInstance);
                        if (topicMessage.Length < Delivery.HeaderSize)
                        {
                            ConsoleOut.WriteLine("ERROR: Message less than " + 
                                Delivery.HeaderSize + " bytes");
                        }
                        else
                        {
                            Topic.TopicIdType topic;
                            topic = messageInstance.header.id;
                            if (!Library.ValidPairing(topic))
                            {
                                ConsoleOut.WriteLine("ERROR: Invalid message to transmit " +
                                                  topic.topic + " " + topic.ext);
                            }
                            else
                            {
                                Thread.Sleep(100); // allow break between messages
                                ConsoleOut.WriteLine(queue.queueName + " " +
                                                  namedPipe.pipeInfo[0].name);
                                ushort crc = CRC.CRC16(topicMessage);
                                byte[] twoBytes = new byte[2];
                                twoBytes[0] = (byte)(crc >> 8);
                                twoBytes[1] = (byte)(crc % 256);
                                ConsoleOut.WriteLine("Transmit CRC " + crc + " " +
                                   twoBytes[0] + " " + twoBytes[1]);
                                topicMessage[0] = twoBytes[0];
                                topicMessage[1] = twoBytes[1];
                                namedPipe.TransmitMessage(topicMessage);
                            }
                        }

                        cycles++;
                    }

                } // end while loop


                TreatDisconnected();

            } // end forever loop
        } // end Callback

        // Convert topic message to byte array
        private byte[] ConvertFromTopicMessage(Delivery.MessageType message)
        {
            byte[] transmitMessage = new byte[message.header.size + Delivery.HeaderSize];

            transmitMessage[0] = 0; // CRC
            transmitMessage[1] = 0;
            transmitMessage[2] = (byte)message.header.id.topic;
            transmitMessage[3] = (byte)message.header.id.ext;
            transmitMessage[4] = (byte)message.header.from.appId;
            transmitMessage[5] = (byte)message.header.from.comId;
            transmitMessage[6] = (byte)message.header.from.subId;
            transmitMessage[7] = (byte)message.header.to.appId;
            transmitMessage[8] = (byte)message.header.to.comId;
            transmitMessage[9] = (byte)message.header.to.subId;
            Int64 referenceNumber = message.header.referenceNumber;
            Int64 x = referenceNumber % 256;      // x100
            Int64 y = referenceNumber % 65536;    // x10000
            y = y >> 8;
            Int64 z = referenceNumber % 16777216; // x1000000
            z = z >> 16;
            referenceNumber = referenceNumber >> 24;
            transmitMessage[10] = (byte)referenceNumber;
            transmitMessage[11] = (byte)z;
            transmitMessage[12] = (byte)y;
            transmitMessage[13] = (byte)x;
            Int32 size = message.header.size;
            size = size >> 8;
            transmitMessage[14] = (byte)size;
            transmitMessage[15] = (byte)(message.header.size % 256);
            for (int i = 0; i < message.header.size; i++)
            {
                transmitMessage[i + Delivery.HeaderSize] = (byte)message.data[i];
            }

            return transmitMessage;

        } // end ConvertToTopicMessage

        // Transmit any message to remote application of this instance of component
        void AnyMessage(Delivery.MessageType message)
        {
            //-->> fill in  Use in place of transmitMessage above or at least from where called.
            //     while changing messageInstance to message.

            //<<< copied this from the forever loop >>>
            ConsoleOut.WriteLine(queue.queueName + " AnyMessage " +
                    message.header.id.topic + " " +
                    message.header.id.ext + " " +
                    message.header.size);

            byte[] topicMessage = new byte[message.header.size +
                                           Delivery.HeaderSize];
            topicMessage = ConvertFromTopicMessage(message);
            if (topicMessage.Length < Delivery.HeaderSize)
            {
                ConsoleOut.WriteLine("ERROR: Message less than " +
                    Delivery.HeaderSize + " bytes");
            }
            else
            {
                Topic.TopicIdType topic;
                topic = message.header.id;
                if (!Library.ValidPairing(topic))
                {
                    ConsoleOut.WriteLine("ERROR: Invalid message to transmit " +
                                      topic.topic + " " + topic.ext);
                }
                else
                {
                    Thread.Sleep(100); // allow break between messages
                    ConsoleOut.WriteLine(queue.queueName + " " +
                                      namedPipe.pipeInfo[0].name);
                    ushort crc = CRC.CRC16(topicMessage);
                    byte[] twoBytes = new byte[2];
                    twoBytes[0] = (byte)(crc >> 8);
                    twoBytes[1] = (byte)(crc % 256);
                    ConsoleOut.WriteLine("Transmit CRC " + crc + " " +
                       twoBytes[0] + " " + twoBytes[1]);
                    topicMessage[0] = twoBytes[0];
                    topicMessage[1] = twoBytes[1];
                    namedPipe.TransmitMessage(topicMessage);
                }
            }

            cycles++;
        } // end AnyMessage

    } // end class Transmit


    // Periodic Timer to Publish Heartbeats
    public class HeartbeatTimer
    {
        private int remoteAppId; // remote app to receive heartbeats
        private NamedPipe namedPipe; // particular instance of NamedPipe class
        private int iterations = 0;
        Stopwatch stopWatch = new Stopwatch();

        public HeartbeatTimer(int appId, NamedPipe pipe) // constructor
        {
            remoteAppId = appId;
            namedPipe = pipe;
            ConsoleOut.WriteLine("HeartbeatTimer " + appId);
        } // end constructor

        public void StartTimer(int dueTime, int period)
        {
            Timer periodicTimer = new Timer(new TimerCallback(TimerProcedure));
            periodicTimer.Change(dueTime, period);
            stopWatch.Start();
        }

        private void TimerProcedure(object state)
        {
            // The state object is the Timer object.
            Timer periodicTimer = (Timer)state;
            stopWatch.Stop();
            TimeSpan ts = stopWatch.Elapsed;
            stopWatch.Start();
            iterations++;
            ConsoleOut.WriteLine("Heartbeat TimerProcedure " +
                remoteAppId + " " + ts + " " + iterations);

            // Build and publish heartbeat to be sent to remote app if the pipe is
            // connected
            if ((namedPipe.pipeServer != null) && (namedPipe.pipeServer.IsConnected))
            {
                Delivery.MessageType message =
                    Format.EncodeHeartbeatMessage(remoteAppId);
                Delivery.Publish(remoteAppId, message);
            }

        } // end TimerProcedure

    } // end HeartbeatTimer

} // end namespace
