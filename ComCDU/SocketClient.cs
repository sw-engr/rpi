using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace SocketApplication
{
    // This class interfaces with Windows Sockets.
    //
    // One instance of this class is needed for each pair of components -- the
    // from component of a message and the component to which it is to be sent.
    // This class is for the component from which the message is sent.
    public class SocketClient
    {

        // Client socket stuff

        // DeliveryTable index of ComId with ToId as Partner.  
        // -1 if instantiation of WinSocket for component pair is invalid
        static public int MatchIndex; 

        // constructor
        public SocketClient( string fromName, // Name and Id of
                             int fromId,      //  sending component
                             string toName,   // Name and Id of
                             int toId )       //   receiving component
        { 
            // save constructor parameters
            int Count = SocketData.SenderData.count;
            SocketData.SenderData.list[Count].FromName = fromName;
            SocketData.SenderData.list[Count].FromId = fromId;
            SocketData.SenderData.list[Count].ToName = toName;
            SocketData.SenderData.list[Count].ToId = toId;


            // Find the partner in DeliveryTable.  This is a validation as 
            // well that the invocating component is correct that the from
            // and to component ids and names match the table.
            MatchIndex = Delivery.Lookup(fromId, toId);

            // Set the IP addresses and the ports.
            if (MatchIndex >= 0)
            {
                int Partner = Delivery.DeliveryTable.list[MatchIndex].Partner;
                SocketData.SenderData.list[Count].FromAddress = 
                    Delivery.DeliveryTable.list[Partner].IP_Address; //MatchIndex].IP_Address;
                SocketData.SenderData.list[Count].FromPort = 
                    Delivery.DeliveryTable.list[MatchIndex].OtherPort;
            }

            SocketData.SenderData.count++;
            ConsoleOut.WriteLine("SenderData count " + SocketData.SenderData.count 
                              + " " + fromId);

        } // end constructor

        // Return whether FromId, ToId pair is available for the Delivery.dat file
        // Note: ValidPair must be called immediately after constructor so not 
        //       overwritten
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

        private int Lookup(int FromId, int ToId)
        {
            for (int i = 0; i < SocketData.SenderData.count; i++)
            {
                if ((SocketData.SenderData.list[i].FromId == FromId) &&
                    (SocketData.SenderData.list[i].ToId == ToId))
                {
                    return i;
                }
            }
            return -1;
        }

        public bool Transmit(int FromId, int ToId, byte[] Message) 
        { // Message to be sent
  //          if (string.IsNullOrEmpty(Message))
            if (Message.Length == 0)
            {
                return false;
            }

            int Index = Lookup(FromId, ToId);
            if (Index < 0)
            {
                return false;
            }

            // The sender always starts up on the localhost
            IPHostEntry hostInfo = 
                Dns.GetHostByName(SocketData.SenderData.list[Index].FromAddress); 
            IPAddress ipAddress = hostInfo.AddressList[0];
            IPEndPoint remoteEP = new 
                IPEndPoint(ipAddress, SocketData.SenderData.list[Index].FromPort);

            ConsoleOut.WriteLine("Transmit " + FromId + " " + 
                SocketData.SenderData.list[Index].FromAddress
                + " " + SocketData.SenderData.list[Index].FromPort);

            // Create a client socket and connect it to the remote
            SocketData.SenderData.list[Index].sender = 
                new System.Net.Sockets.Socket
                    (System.Net.Sockets.AddressFamily.InterNetwork,
                     System.Net.Sockets.SocketType.Stream,
                     System.Net.Sockets.ProtocolType.Tcp);
            try
            {
                SocketData.SenderData.list[Index].sender.Connect(remoteEP);
//                ConsoleOut.WriteLine("Socket connected to {0} by {1}",
//                    SocketData.SenderData.list[Index].sender.RemoteEndPoint.ToString(),
//                    FromId);
                ConsoleOut.Write("Socket connected to ");
                ConsoleOut.Write(SocketData.SenderData.list[Index].sender.RemoteEndPoint.ToString());
                ConsoleOut.Write(" by ");
                ConsoleOut.WriteLine(FromId.ToString());
         //       byte[] byData = System.Text.Encoding.ASCII.GetBytes(Message);
         //       byte[] msg = Encoding.ASCII.GetBytes(Message);
         //       int bytesSent = SocketData.SenderData.list[Index].sender.Send(msg);
                int bytesSent = SocketData.SenderData.list[Index].sender.Send(Message);
                // Release the socket
                SocketData.SenderData.list[Index].sender.Shutdown(SocketShutdown.Send);
                SocketData.SenderData.list[Index].sender.Close();
                return true;
            } // end try
            catch (ArgumentNullException ane)
            {
//                ConsoleOut.WriteLine("ArgumentNullException : {0}", ane.ToString());
                ConsoleOut.Write("ArgumentNullException : ");
                ConsoleOut.WriteLine(ane.ToString());
            }
            catch (SocketException se)
            {
//                ConsoleOut.WriteLine("SocketException : {0}", se.ToString());
                ConsoleOut.WriteLine("SocketException : ");
                ConsoleOut.WriteLine(se.ToString());
            }
            catch (Exception e)
            {
//                ConsoleOut.WriteLine("Unexpected exception : {0}", e.ToString());
                ConsoleOut.WriteLine("Unexpected exception : ");
                ConsoleOut.WriteLine(e.ToString());
            }
            return false;
        } // end Transmit

    } // end class SocketClient

} // end namespace