using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace SocketApplication
{
    class ComCDU
    {
        static private SocketServer socket1from2;
        static private SocketClient socket1to2;

        // This component contains only two topics.  To send the selected CDU
        // key to the remote OFP app and to receive the response.

/*        static private Component.ParticipantKey componentKey;

        static private Topic.TopicIdType changePageTopic;
        static private Topic.TopicIdType keyPushTopic;

        static private Disburse queue; */

        static private CDUForm cduForm = new CDUForm();

        static private byte[] connectMessage = new byte[] {3, 3, 0}; // topic and no data
        static public bool connected = false; // connected to remote app 2

        static private bool responseReceived = false;
        static private CDUForm.Result response = new CDUForm.Result();
        static private string receivedChangePage = "";

        static public void Install()
        {
            // Create Disburse queue
//            queue = new Disburse("ComOFP", true,     // use Timer event wakeup
//                                 false, AnyMessage); // not periodic

//            // Register this component
//            Component.RegisterResult result;
//            result = Component.Register
//                     ("ComOFP", 0, Threads.ComponentThreadPriority.NORMAL, 
//                      MainEntry, queue);
//            componentKey = result.key;
           // Install the component into the Threads package.
           Threads.RegisterResult Result;
           Result = Threads.Install( "ComCDU",
                                     Threads.TableCount(), 
                                     Threads.ComponentThreadPriority.NORMAL,
                                     MainEntry
                                   );
           if (Result.Status == Threads.InstallResult.VALID)
           {

               /*            if (result.status == Component.ComponentStatus.VALID)
                           {
                               Library.AddStatus status;

                               changePageTopic.topic = Topic.Id.OFP;
                               changePageTopic.ext = Topic.Extender.CHANGEPAGE;
                               keyPushTopic.topic = Topic.Id.OFP;
                               keyPushTopic.ext = Topic.Extender.KEYPUSH;

                               // Register to consume the OFP CHANGEPAGE topic
                               status = Library.RegisterTopic
                                        (changePageTopic, result.key,
                                         Delivery.Distribution.CONSUMER, MainEntry);

                               // Register to produce the OFP KEYPUSH topic
                               status = Library.RegisterTopic
                                        (keyPushTopic, result.key,
                                         Delivery.Distribution.PRODUCER, null);
                           } */
               // Install this component via a new instance of the Windows Sockets
               // class with its threads to transmit to ComOFP of the Ada app
               socket1to2 = new SocketClient( "ComCDU",
                                              1,
                                              "ComOFP",
                                              2);
               if (!socket1to2.ValidPair())
               {
                   ConsoleOut.WriteLine(
                       "ERROR: SocketClient not valid for ComCDU 1, ComOFP 2 pair");
               }

               socket1from2 = new SocketServer( "ComCDU",
                                                1,
                                                "ComOFP",
                                                2,
                                                ReceiveCallback);
               if (!socket1from2.ValidPair())
               {
                   ConsoleOut.WriteLine(
                       "ERROR: SocketServer not valid for ComCDU 1, ComOFP 2 pair");
               }

           } // end if

        } // end Install

        // Entry point
        static void MainEntry(int Index)
        {
            while (true) // loop forever
            {
                if (connected)
                {
                    // Wait for event.
            //        string xxx = queue.queueName;
            //        queue.EventWait();
                } 
                // wait for remote app (remoteAppId of 2) before wait for event -
                // inform user that key pushes can now be handled
       /*         else if ((!connected) && (Remote.RegisterAcknowledged(2)))
                {
                    var result = MessageBox.Show("Ok to use keys", "TreatKey",
                                                 MessageBoxButtons.OK);

                    connected = true;
                } */
                else
                {
                    if (!socket1to2.Transmit(1, 2, connectMessage))
                    {
                        Thread.Sleep(100); // wait and check for connected by 
                    }                      //  attempted a new transmit
                    else
                    {
                        var result = MessageBox.Show("Ok to use keys", "TreatKey",
                                                     MessageBoxButtons.OK);
                        connected = true;
                    }
                }

            } // end forever loop

        } // end MainEntry

 /*       static void AnyMessage(Delivery.MessageType message)
        {
            // Treat received message - notify TreatKey that response received
            ConsoleOut.WriteLine("ComOFP AnyMessage " + message.data);
            receivedChangePage = message.data;
            responseReceived = true;

        } // end AnyMessage */
        // Notify of received message
        static void ReceiveCallback(byte[] Message)
        {
            ConsoleOut.Write("ComOFP received a message: "); //+ Message);
            ConsoleOut.Write(Message.Length.ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(Message[0].ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(Message[1].ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(Message[2].ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.WriteLine(Message[3].ToString());
        //    if ((Message.Length > 3) && (Message[0] == 1) && (Message[1] == 2))
            if ((Message[2] > 0) && (Message[0] == 1) && (Message[1] == 2))
            { // valid message
                receivedChangePage = Encoding.ASCII.GetString
                                     (Message, 3, Message[2]);
                responseReceived = true;
            }
            else
            {
                ConsoleOut.WriteLine("ERROR: Invalid message received " + Message[0] +
                    " " + Message[1] + " " + Message[2] + " " + Message.Length);
                //WHAT to do? exit app?
            }
        }


        // Publish key push to be delivered to App2; wait for response
        public CDUForm.Result TreatKey(CDUForm.Key key)
        {
            responseReceived = false;

  //          var result = MessageBox.Show("key " + key.ToString(),
  //                                       "TreatKey", MessageBoxButtons.OK);

   //         Delivery.MessageType keypush;
   //         keypush.data = key.ToString();
  //          Delivery.Publish(keyPushTopic, componentKey, keypush.data);
            string data = key.ToString(); // convert enum to string for message
            byte[] keyMessage = new byte[4 + data.Length];
            keyMessage[0] = 1; // OFP Topic of
            keyMessage[1] = 1; //   Keypush
            keyMessage[2] = (byte)data.Length;
 //           keyMessage[4..4+data.Length] = data.To
            for (int i = 0; i < data.Length; i++)
            {
                keyMessage[3 + i] = (byte)data[i];
            }
            if (!socket1to2.Transmit(1, 2, keyMessage))
            {
                ConsoleOut.WriteLine("ERROR: Couldn't send Key Push message");
                // Return the response to CDUForm
                responseReceived = false; // set in advance of the next request
                response.success = false; // no response received
                response.text = "";       // no string received
                return response;
            }
            //>>> add a timeout to return false
            // Wait until response received
            while (true)
            {
                if (!responseReceived)
                {
                    Thread.Sleep(100); // millisecs
                }
                else
                {
                    break; // exit loop
                }
            }
            // Return the response to CDUForm
            responseReceived = false; // set in advance of the next request
            response.success = true;  // response received
            response.text = receivedChangePage; // the string received
            return response;

        } // end TreatKey

    } // end ComCDU class
} // end namespace
