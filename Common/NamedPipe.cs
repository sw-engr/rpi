using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Pipes;
using System.Security.Principal;
using System.Text;
using System.Threading;

namespace VisualCompiler
{
    public class NamedPipe
    {
        // Class to communicate between applications via Named Pipes.

        public struct CommunicationInfoType
        { // Information about a thread and Microsoft Windows named pipes
            public string name; // must be of the form \\.\pipe\pipename
            // Name of pipe
            public bool created;
            // Whether pipe between server and client has been created
            public bool connected;
            // Whether pipe between server and client has connected
            public bool failed;
         }

        // Application identifier of the associated remote application
        private int localAppId;
        private int remoteAppId;
        private int localIndex;  // of pipePair
        private int remoteIndex; // of pipePair

        private NamedPipeNames nPN = new NamedPipeNames();
        public NamedPipeNames.NamedPipeNameType pipePair;
 
        public CommunicationInfoType[] pipeInfo = new CommunicationInfoType[2];

//        private NamedPipeServerStream pipeServer = null;
        public NamedPipeServerStream pipeServer = null;
        public NamedPipeClientStream pipeClient = null;

        public NamedPipe(int localId, int remoteId, int index) // constructor
        {
            // Save identifier of the remote application tied to this
            // instance of the Receive class.
            localAppId = localId;
            remoteAppId = remoteId;

            localIndex = 0;
            remoteIndex = 1;

            pipePair = nPN.namedPipeName.list[index];
            ConsoleOut.WriteLine("index " + index);
ConsoleOut.WriteLine("local pipe " + pipePair.lPipeName);
ConsoleOut.WriteLine("remote pipe " + pipePair.rPipeName);

            pipeInfo[localIndex].name = pipePair.lPipeName;
            pipeInfo[localIndex].created = false;
            pipeInfo[localIndex].connected = false;
            pipeInfo[localIndex].failed = false;

            pipeInfo[remoteIndex].name = pipePair.rPipeName;
            pipeInfo[remoteIndex].created = false;
            pipeInfo[remoteIndex].connected = false;
            pipeInfo[remoteIndex].failed = false;

            Thread.Sleep(2000); // 2 seconds
  
         } // constructor

        // Close the Receive and Transmit pipes
        public void ClosePipes(bool Client)
        {
            if (Client)
            {
                if (pipeClient != null)
                {
                    ConsoleOut.WriteLine("ClosePipes closing pipeClient and setting to null");
                    pipeClient.Close();
                    pipeClient = null;
                }
            }
            else
            {
                if (pipeServer != null)
                {
                    ConsoleOut.WriteLine("ClosePipes closing pipeServer and setting to null");
                    pipeServer.Close();
                    pipeServer = null;
                }
            }

        } // end ClosePipes

        // Open the Receive Pipe
        public bool OpenReceivePipe()
        {
            // remoteIndex is 1
//            ConsoleOut.WriteLine("OpenReceivePipe {0} {1}", pipeInfo[index].name, index+1);
            ConsoleOut.WriteLine("OpenReceivePipe " + pipeInfo[1].name);
            // Below matches Microsoft online document.  The type for pipeClient
            // of NamedPipeClientStream is declared as public above.
            pipeClient =
                new NamedPipeClientStream(".", pipeInfo[1].name, 
                                          PipeDirection.InOut, PipeOptions.None,
                                          TokenImpersonationLevel.Impersonation);
            // Note: The client and server processes in this example are intended 
            // to run on the same computer, so the server name provided to the
            // NamedPipeClientStream object is ".". If the client and server
            // processes were on separate computers, "." would be replaced with
            // the network name of the computer that runs the server process.

            ConsoleOut.WriteLine("Connecting to server...");
            try
            { 
                pipeClient.Connect(); 
            }
            catch
            {
            }
            ConsoleOut.WriteLine("pipeClient setting Connected " + remoteAppId);
            if (pipeClient == null)
            {
                ConsoleOut.WriteLine("ERROR: pipeClient has become null");
            }
            else
            {
                pipeInfo[1].connected = pipeClient.IsConnected;
                ConsoleOut.WriteLine("pipeClient Connected " + pipeInfo[1].connected +
                     " " + remoteAppId);
            }
            Remote.connections[remoteAppId].pipeConnected = true;
 
            return pipeInfo[1].connected;
        } // end OpenReceivePipe

        // Open the Transmit Pipe
        public bool OpenTransmitPipe() //int index)
        {
            ConsoleOut.WriteLine("OpenTransmitPipe " + pipeInfo[0].name);
            // Below matches Microsoft online document.  The type for pipeServer
            // of NamedPipeServerStream is declared above.  1 is the number of
            // threads. <<is it really? How many Transmit threads?>>
            pipeServer =
               new NamedPipeServerStream(pipeInfo[0].name, PipeDirection.InOut, 1);

       //     int threadId = Thread.CurrentThread.ManagedThreadId;
            
//            ConsoleOut.WriteLine("Wait to connect to client");

            // Wait for a client to connect
            pipeServer.WaitForConnection();

            ConsoleOut.WriteLine("Server connected for remote app " + //on thread {1}", 
                               pipeInfo[0].name ); //, threadId);

  //          Remote.IsConnectedToRemoteApp(remoteAppId, pipeServer != null);
            return (pipeServer != null);
        } // end OpenTransmitPipe

        // Receive a message from the remote pipe client.
        public byte[] ReceiveMessage()
        { 
            if (pipeClient != null)
            {
                StreamString ss = new StreamString(pipeClient);
 
                ConsoleOut.WriteLine("ReceiveMessage to fromServer " + remoteAppId
                    + " " + Remote.connections[remoteAppId].pipeConnected);

 //               if (pipeClient.IsConnected)
 //               if ((pipeClient.IsConnected) && (pipeInfo[1].connected))
                if ((pipeClient.IsConnected) && 
                    (Remote.connections[remoteAppId].pipeConnected))
                {
                    byte[] fromServer = ss.ReadBytes();

                    DateTime localDate = DateTime.Now;
                    ConsoleOut.WriteLine("ReceiveMessage " + localDate.Second);

//                    if (fromServer.Length < 14 + 8) // including NAKs //14) 
                    if (fromServer.Length < Delivery.HeaderSize + 8) // including NAKs //14) 
                    {
                        ConsoleOut.WriteLine("ERROR: Received less than " + Delivery.HeaderSize
                            + " bytes " + fromServer.Length);
                        for (int i = 0; i < fromServer.Length; i++)
                        {
                            ConsoleOut.Write(fromServer[i] + " ");
                        }
                        ConsoleOut.WriteLine(" ");
                        //--> for 4 byte message, say 3 in a row, disconnect from
                        //    the remote app and force Receive to Connect again.
                    }
                    // Remove any leading NAKs from message.
                    int start = 0;
                    for (int i = 0; i < fromServer.Length; i++)
                    {
                        if (fromServer[i] != 21) // NAK
                        {
                            start = i;
                            break; // exit loop
                        }
                    }
                    byte[] msg = new byte[fromServer.Length - start];
                    int j = 0;
                    for (int i = start; i < fromServer.Length; i++)
                    {
                        msg[j] = fromServer[i];
                        j++;
                    }

                    return msg; // fromServer; // line;
                } // end if IsConnected
                else
                { // no longer connected
                    ConsoleOut.WriteLine("ReceiveMessage not connected " + remoteAppId);
                    if (pipeInfo[1].connected) // was connected
                    {
                        ConsoleOut.WriteLine("ReceiveMessage calling Remote " + remoteAppId);
      //                  Remote.IsConnectedToRemoteApp(remoteAppId, false);
                        Remote.connections[remoteAppId].pipeConnected = false;
                        pipeInfo[1].connected = false;
                    }
                }
            } 

            // Return a null message if pipeClient is null.
            return BitConverter.GetBytes(0);

        } // end ReceiveMessage

        // Transmit a message to the remote pipe server.
        public void TransmitMessage(byte[] message)
        {
            if (pipeServer != null)
            {
                DateTime localDate = DateTime.Now;

                ConsoleOut.WriteLine("TransmitMessage " + pipeInfo[0].name + " Msg " +
                    message[2] + " " + message[3] + " From " + message[4] + " To " +
                    message[7] + " " + localDate.Second);
                try
                {
                    // Prepend 8 NAK's to the beginning of the message.
                    byte[] msg = new byte[message.Length + 8];
                    for (int i = 0; i < 8; i++)
                    {
                        msg[i] = 21; // NAK
                    }
                    // Copy the message to follow the NAKs
                    for (int i = 0; i < message.Length; i++)
                    {
                        msg[i + 8] = message[i];
                    }
                    // Send message via the server process.
                    StreamString ss = new StreamString(pipeServer);
                    int len = ss.WriteBytes(msg); //message);
//                    if (len != msg.Length + 2) //message.Length + 2)
                    if (len != msg.Length)
                    {
                        ConsoleOut.WriteLine("ERROR: Write of wrong length " +
                            len + " " + msg.Length); //essage.Length);
                    }
                }
                // Catch the IOException that is raised if the pipe is broken
                // or disconnected.
                catch (IOException e)
                {
                    ConsoleOut.WriteLine("ERROR: " + e.Message);
                    ConsoleOut.WriteLine("Setting pipeConnected false for " + remoteAppId);
                    Remote.connections[remoteAppId].pipeConnected = false;
                }
            }
            else
            {
                ConsoleOut.WriteLine("ERROR: null pipeServer");
            }

        } // end TransmitMessage

    } // end NamedPipe class

    // Define the data protocol for reading and writing byte arrays on the Stream.
    // Note: This class is from a Microsoft pair of examples for Server and
    //       Client.
    public class StreamString
    {
        private Stream ioStream;

        public StreamString(Stream ioStream) // constructor
        {
            this.ioStream = ioStream;
        } // end constructor


        public byte[] ReadBytes()
        {
//            ConsoleOut.WriteLine("ReadBytes entered");
            int len = 0;
            len = ioStream.ReadByte() * 256;
            len += ioStream.ReadByte();
            if (len > 0)
            {
                byte[] inBuffer = new byte[len];
                ioStream.Read(inBuffer, 0, len);
                return inBuffer;
            }
            else
            {
                byte[] inBuffer = new byte[4];
                inBuffer[0] = 0;
                inBuffer[1] = 0;
                inBuffer[2] = 0;
                inBuffer[3] = 0;
                return inBuffer;
            }
//            ConsoleOut.WriteLine("ReadBytes {0}", len);
        } // end ReadBytes

        public int WriteBytes(byte[] outBuffer)
        {
            int len = outBuffer.Length;
            if (len > UInt16.MaxValue)
            {
                len = (int)UInt16.MaxValue;
            }
            if (len < 22) // including 8 NAKs
            {
                ConsoleOut.WriteLine("ERROR: Attempting to write less than " + 
                    Delivery.HeaderSize + " bytes of " + len);
                ioStream.Flush();
                return 0;
            }
//            ioStream.WriteByte((byte)(len / 256));
//            ioStream.WriteByte((byte)(len & 255));
            ioStream.Write(outBuffer, 0, len);
            ioStream.Flush();
            return outBuffer.Length; // + 2;
        } // end WriteBytes 

    } // end StreamString class

} // end namespace
