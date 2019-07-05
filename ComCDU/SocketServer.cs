using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

namespace SocketApplication
{
    // This class interfaces with Windows Sockets.
    //
    // One instance of this class is needed for each pair of components -- the
    // from component of a message and the component to which it is to be sent.
    // This class is for the component to which the message is sent.
    public class SocketServer
    {
        // Server socket stuff

        // DeliveryTable index of ComId with ToId as Partner.  
        // -1 if instantiation of WinSocket for component pair is invalid
        static public int MatchIndex; 

        // constructor
        public SocketServer( string toName,             // Name and Id of the
                             int toId,                  //   local component
                             string fromName,           // Name and Id of the
                             int fromId,                //  remote component 
    	                     ReceiveCallback callback ) // Callback to forward message
    	{ 
            // save constructor parameters
            int Count = SocketData.ListenerData.count;
            SocketData.ListenerData.list[Count].FromName = fromName;
            SocketData.ListenerData.list[Count].FromId = fromId;
            SocketData.ListenerData.list[Count].recdCallback = callback;
            SocketData.ListenerData.list[Count].ToName = toName;
            SocketData.ListenerData.list[Count].ToId = toId;

            // Find the partner in DeliveryTable.  This is a validation as 
            // well that the invocating component is correct that the from
            // and to component ids and names match the table.
            MatchIndex = Delivery.Lookup(toId, fromId);

            // Set the IP addresses and the ports.
            if (MatchIndex >= 0)
            {
                int Partner = Delivery.DeliveryTable.list[MatchIndex].Partner;
                SocketData.ListenerData.list[Count].ToAddress =
//                    Delivery.DeliveryTable.list[Partner].IP_Address;
                  Delivery.DeliveryTable.list[MatchIndex].IP_Address;
                SocketData.ListenerData.list[Count].ToPort =
                    Delivery.DeliveryTable.list[Partner].OtherPort; 
                ConsoleOut.WriteLine("MatchIndex " + MatchIndex + " " +
                    SocketData.ListenerData.list[Count].ToAddress +
                    " ServerPort " + SocketData.ListenerData.list[Count].ToPort);
            }

            // Create thread for receive.
            Threads.RegisterResult Result;
            int id = Threads.TableCount(); // index in table after Install
            SocketData.ListenerData.list[SocketData.ListenerData.count].ThreadId = id;
            Result = Threads.Install("Receive" + id,
                                      id,
                                      Threads.ComponentThreadPriority.HIGH,
                                      Receive
                                    );
            if (Result.Status == Threads.InstallResult.VALID)
            {
                IPHostEntry hostInfo = Dns.GetHostByName(
                    SocketData.ListenerData.list[Count].ToAddress);
                IPAddress serverAddr = hostInfo.AddressList[0];
                var serverEndPoint = new IPEndPoint(
                    serverAddr, SocketData.ListenerData.list[Count].ToPort);

                // Create a listener socket.
                SocketData.ListenerData.list[Count].listener = 
                    new System.Net.Sockets.Socket
                               (System.Net.Sockets.AddressFamily.InterNetwork,
                                System.Net.Sockets.SocketType.Stream,
                                System.Net.Sockets.ProtocolType.Tcp);
                try
                {
                    SocketData.ListenerData.list[Count].listener.Bind(serverEndPoint);
                    SocketData.ListenerData.list[Count].serverInfo =
                        SocketData.ListenerData.list[Count].listener.LocalEndPoint.ToString();
                     ConsoleOut.WriteLine("Server started at:" +
                                 SocketData.ListenerData.list[Count].serverInfo + " " +
                                 SocketData.ListenerData.list[Count].ToId);
                                 SocketData.ListenerData.list[Count].serverInfo = Listen(Count);
                     ConsoleOut.WriteLine(SocketData.ListenerData.list[Count].serverInfo);
                }
                catch (Exception e)
                {
                    var w32ex = e as Win32Exception;
                    if (w32ex == null)
                    {
                        w32ex = e.InnerException as Win32Exception;
                    }
                    if (w32ex != null)
                    {
                        int code = w32ex.ErrorCode;
                    }
                } 
            }

            SocketData.ListenerData.count++;
            ConsoleOut.WriteLine("ListenerData count " + SocketData.ListenerData.count + " " + fromId);

        } // end constructor


        // Return whether ToId, From pair is available for the Delivery.dat file
        public bool ValidPair()
        {
            if (MatchIndex < 0)
            {
                return false;
            }
            else
            {
                return true;
            }

        } // end ValidPair

        // Lookup location in array of thread id
        static private int Lookup(int threadId)
        {
            for (int i = 0; i < SocketData.ListenerData.count; i++)
            {
                if (SocketData.ListenerData.list[i].ThreadId == threadId)
                {
                    return i;
                }
            }
            return -1;
        }

        static public string Listen(int index)
        {
            try
            {
                SocketData.ListenerData.list[index].listener.Listen(1);
                return "Server listening " + 
                       SocketData.ListenerData.list[index].ToId;
            }
            catch (Exception ex)
            {
                return "Failed to listen" + ex.ToString();
            }
        } // end Listen

        // Entry point from Threads to receive messages
        static void Receive(int Index)
        {
            byte[] bytes = new Byte[1024];
      //      string data = null;
            ConsoleOut.WriteLine("WinSocket Receive " + Index);
            while (true) // loop forever
            {
                int index = Lookup(Index); // lookup index matching thread Index
                if (index < 0)
                {
                    ConsoleOut.WriteLine("WinSocket Receive with failed lookup " + 
                                      Index + " " + SocketData.ListenerData.count);
                    Thread.Sleep(500); // 0.5 sec  
                }
                else
                {
                    ConsoleOut.WriteLine("WinSocket Receive " + Index + " entered for "
                        + index + " " + SocketData.ListenerData.list[index].ToId + 
                        " " + SocketData.ListenerData.list[index].ToPort);

                    // Listen for a remote request to Connect
                    ConsoleOut.WriteLine("Server Listen info: " +
                        SocketData.ListenerData.list[index].serverInfo + " " +
                        SocketData.ListenerData.list[index].ToId);
                    SocketData.ListenerData.list[index].serverInfo = Listen(index);
                    ConsoleOut.WriteLine(SocketData.ListenerData.list[index].serverInfo);

                    Socket handler = 
                        SocketData.ListenerData.list[index].listener.Accept();
                    int bytesrecd = handler.Receive(bytes);
               //     data = Encoding.ASCII.GetString(bytes, 0, bytesrecd);
                    handler.Close();
                    // Transfer message to the component's callback
                    SocketData.ListenerData.list[index].recdCallback(bytes); //data);
                }
            } // end forever loop
        } // end Receive

    } // end class SocketServer

} // end namespace