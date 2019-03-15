using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;

namespace VisualCompiler
{
    public class Receive
    {
        // Receive messages from a remote applications.  There is one 
        // instance of this class per remote application.  And one
        // thread will be assigned to each instance.
        public Thread threadInstance;

        private NamedPipe namedPipe; // particular instance of NamedPipe class
        private bool connected = false; // whether connected to the pipe
        private bool start = true;      // whether need to start a connection

        private CircularQueue queue;

        // Application identifier of the associated remote application
        private int remoteAppId;
        
        // To time interval between receive of valid Heartbeat messages
        Stopwatch stopWatch = new Stopwatch();
        Stopwatch timingWatch = new Stopwatch();

        byte[] qMessage;

        public Receive(int index, int appId, ReceiveInterface recInf, // constructor
                       CircularQueue cQueue, NamedPipe pipe) 
        {
            // Save identifier of the remote application tied to this
            // instance of the Receive class.
            remoteAppId = appId;
            namedPipe = pipe;
            connected = false;
            start = true;

            queue = cQueue; 
  //          ConsoleOut.WriteLine("Receive constructor {0} {1} {2} {3}",index, appId, recInf, 
  //                            namedPipe.pipePair.rPipeName);
            qMessage = new byte[250]; // VerifyMessage won't allow long messages

            // Create instance of the receive thread.
            threadInstance = new Thread(ReceiveThread);

        } // end Receive constructor

        // Set whether the pipe is connected to reopen the pipe if the remote app
        // has disconnected.
        // Note: This will most likely happen if it is terminated.  
        //       Then attempting to reopen will allow it to be launched again.
        private void TreatDisconnected()
        {
            if ((!start) && (namedPipe.pipeClient != null)
                         && (!namedPipe.pipeClient.IsConnected))
            {
                namedPipe.pipeInfo[1].connected = false;
                namedPipe.ClosePipes(true); // close Client pipe
                Remote.connections[remoteAppId].consecutiveValid = 0;
                Remote.connections[remoteAppId].connected = false;
                Remote.connections[remoteAppId].pipeConnected = false;
                Remote.SetRegisterAcknowledged(remoteAppId, false);
                connected = false;
                start = true;
                Library.RemoveRemoteTopics(remoteAppId);
                ConsoleOut.WriteLine("Reset connected in Receive forever loop");
            }
        } // end TreatDisconnected


        private byte[] VerifyMessage(byte[] message)
        {
            int length = message.Length;
            if (message.Length == 0)
            {
               return message;
            }
            else if (message.Length >= Delivery.HeaderSize)
            {
                // Enough for a header.  Compare checksum.
                ushort crc = CRC.CRC16(message);
                byte[] twoBytes = new byte[2];
                twoBytes[0] = (byte)(crc >> 8);
                twoBytes[1] = (byte)(crc % 256);
ConsoleOut.WriteLine("CRC received " + twoBytes[0] + " " + twoBytes[1] + " " + message[0] + " " + message[1]);
                if ( ((twoBytes[0] == message[0]) && (twoBytes[1] == message[1])) ||
                     ((message[0] == 0) && (message[1] == 0)) ) // ignore CRC if not provided
                {
                    // Get data size.
                    Int32 size = message[14];
                    size = 256 * size + message[15];
                    int messageLength = size + Delivery.HeaderSize;

                    int index = message.Length - 1;
                    for (int i = 0; i < message.Length; i++)
                    {
                        if (message[index] != 0)
                        {
                            length = index + 1;
                            break; // exit loop
                        }
                        if ((index + 1) == messageLength)
                        {
                            length = messageLength;
                            break; // exit loop -- don't remove any more 0s
                        }
                        index--;
                    }
                }
                else
                { // checksums don't compare
                    ConsoleOut.WriteLine("ERROR: Checksums don't compare");
                    length = 2; // fail the received message
                    byte[] msg = new byte[2];
                    msg[0] = message[0];
                    msg[1] = message[1];
                    return msg;
                }
            }
            else
            { // message too short for header
                length = message.Length; 
            }
            for (int i = 0; i < length; i++)
            {
                ConsoleOut.Write(" " + message[i]);
            }
            ConsoleOut.WriteLine("");
            if (length >= Delivery.HeaderSize)
            {
                byte[] msg = new byte[length];
                msg = message.ToArray();
                return msg;
            }
            else
            { // return the short message
                return message; 
            }

        } // end VerifyMessage

        // The framework Receive thread to monitor for messages from its
        // remote application.
        public void ReceiveThread()
        {
            start = true;
            connected = false;
            byte[] recdMessage;
            while (true) // forever loop
            {
                if (namedPipe.pipeClient == null)
                {   
                    // Open the NamedPipe for Receive from the remote application.
                    // Note: It isn't necessary to check whether the pipe has been
                    //       created because that is done before threads begin
                    //       running.
                    if ((start) && (!connected))
                    {
                        connected = namedPipe.OpenReceivePipe();
                        start = false;
                    }
                    if (connected)
                    {
                        ConsoleOut.WriteLine("Receive pipe opened " +
                            namedPipe.pipeInfo[1].name);
                    }
                    else
                    { // pipe not connected
                        ConsoleOut.WriteLine("waiting in ReceiveThread " + 
                                          namedPipe.pipeInfo[1].name);
                    }
                }

                TreatDisconnected();

                if (connected)
                {
                    // Waiting for message 

                    recdMessage = namedPipe.ReceiveMessage();

                    int managedThreadId = Thread.CurrentThread.ManagedThreadId;

                    ConsoleOut.WriteLine("received message " + 
                        namedPipe.pipeInfo[1].name + " " + recdMessage.Length +
                        " " + remoteAppId + " " + managedThreadId);
                    qMessage = VerifyMessage(recdMessage);
                    if ((qMessage.Length == 4) && (qMessage[0] == 0) &&
                        (qMessage[1] == 0) && (qMessage[2] == 0) && (qMessage[2] == 0))
                    { // Disconnected
                    }
                    else
                    {
                        queue.Write(qMessage);
                    }
 
                } // end if connected
 
             } // end while forever
        } // end ReceiveThread

    } // end Receive class

} // end namespace
