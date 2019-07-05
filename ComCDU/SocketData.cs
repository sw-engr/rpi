using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace SocketApplication
{
    // This class contains the tables to support Windows Sockets.
    static public class SocketData
    {
        const int MaxComponents = 16;

        // Sender data

        public struct SenderDataType
        {
            public string FromName; // Name and Id of the invoking component 
            public int FromId;      //   from which message is to be sent
            public int ToId;        // Name and Id of remote component Name and Id of remote component 
            public string ToName;   //   to be sent the message  

            public string FromAddress; // the sending component
            public int FromPort;       //  IP address and port

            public System.Net.Sockets.Socket sender;
            public string clientInfo;
        };

        public class SenderType
        {
            public int count;
            // Number of registered senders of the application
            public SenderDataType[] list = new SenderDataType[MaxComponents];
            // Registration supplied data concerning the component as well as 
            // run-time status data
        };

        // Retained data for multiple sender instantiations
        static public SenderType SenderData = new SenderType();

        // Listener Data

        public struct ListenerDataType
        {
            public int ToId;         // Name and Id of this component waiting to
            public string ToName;    //   receive the message and the callback 
            public ReceiveCallback recdCallback; // to return the message
            public string FromName;  // Name and Id of the component from
            public int FromId;       //   which message is to be received

            public string ToAddress; // the listening component
            public int ToPort;       //  IP address and port

            public int ThreadId;     // Id of Receive thread

            public System.Net.Sockets.Socket listener;
            public string serverInfo;
        };

        public class ListenerType
        {
            public int count;
            // Number of registered senders of the application
            public ListenerDataType[] list = new ListenerDataType[MaxComponents];
            // Registration supplied data concerning the component as well as 
            // run-time status data
        };

        // Retained data for multiple sender instantiations
        static public ListenerType ListenerData = new ListenerType();

//        public bool AddSender(SenderDataType data)
//        {
//            if (SenderData.count < MaxComponents)
//            {

//            }
//            else
//            {
//                ConsoleOut.WriteLine("ERROR: Too many sender " + data.FromName 
//                   + " " + data.FromId);
//                return false;
//            }
//        }

//        public bool AddListener(ListenerDataType data)
//        {
//        }

    } // end class SocketData

} // end namespace