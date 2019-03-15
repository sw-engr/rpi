using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace VisualCompiler
{
    class ComOFP
    {
        // This component contains only two topics.  To send the selected CDU
        // key to the remote OFP app and to receive the response.

        static private Component.ParticipantKey componentKey;

        static private Topic.TopicIdType changePageTopic;
        static private Topic.TopicIdType keyPushTopic;

        static private Disburse queue;

        static private CDUForm cduForm = new CDUForm();

        static public bool connected = false; // connected to remote app 2

        static private bool responseReceived = false;
        static private CDUForm.Result response = new CDUForm.Result();
        static private string receivedChangePage = "";

        static public void Install()
        {
            // Create Disburse queue
            queue = new Disburse("ComOFP", true,     // use Timer event wakeup
                                 false, AnyMessage); // not periodic

            // Register this component
            Component.RegisterResult result;
            result = Component.Register
                     ("ComOFP", 0, Threads.ComponentThreadPriority.NORMAL, 
                      MainEntry, queue);
            componentKey = result.key;

            if (result.status == Component.ComponentStatus.VALID)
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
            }

        } // end Install

        // Entry point
        static void MainEntry()
        {
            while (true) // loop forever
            {
                if (connected)
                {
                    // Wait for event.
                    string xxx = queue.queueName;
                    queue.EventWait();
                }
                // wait for remote app (remoteAppId of 2) before wait for event -
                // inform user that key pushes can now be handled
                else if ((!connected) && (Remote.RegisterAcknowledged(2)))
                {
                    var result = MessageBox.Show("Ok to use keys", "TreatKey",
                                                 MessageBoxButtons.OK);

                    connected = true;
                }
                else
                {
                    Thread.Sleep(100); // wait and check for connected
                }

            } // end forever loop

        } // end MainEntry

        static void AnyMessage(Delivery.MessageType message)
        {
            // Treat received message - notify TreatKey that response received
            ConsoleOut.WriteLine("ComOFP AnyMessage " + message.data);
            receivedChangePage = message.data;
            responseReceived = true;

        } // end AnyMessage

        // Publish key push to be delivered to App2; wait for response
        public CDUForm.Result TreatKey(CDUForm.Key key)
        {
            responseReceived = false;

  //          var result = MessageBox.Show("key " + key.ToString(),
  //                                       "TreatKey", MessageBoxButtons.OK);

            Delivery.MessageType keypush;
            keypush.data = key.ToString();
            Delivery.Publish(keyPushTopic, componentKey, keypush.data);

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
            responseReceived = false;
            response.success = true;
            response.text = receivedChangePage;
            return response;

        } // end TreatKey

    } // end ComOFP class
} // end namespace
