using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;

namespace VisualCompiler
{
    public class DisburseForward
    {
        public string queueName;
        
        private int iteration = 0;

        // Queued items will be removed from the queue as they are read.
        public struct QueueDataType // Queued topic messages
        {
            public Delivery.MessageType message;
        };

        public struct DisburseDataType
        {
            public Topic.TopicIdType topic;
            public Forward forward;
        }

        // Table of topics to disburse to their callback
        public class DisburseTableType
        {
            public int count;
            public DisburseDataType[] list = new DisburseDataType[10];
        }

        public DisburseTableType forwardTopicTable = 
                                 new DisburseTableType();

        const int size = 10;
        private class QueueForwardType
        {
            public string name; // Name given to the queue by the component
            public bool wait;
            public bool unread; 
            public int nextReadIndex;
            public int nextWriteIndex;
            public int threadId;
            public EventWaitHandle waitHandle;
            public QueueDataType[] list = new QueueDataType[size];
        };

        private QueueForwardType queue = new QueueForwardType();

    //    static private EventWaitHandle waitHandle;

        public DisburseForward(string name, DisburseTableType table) // constructor
        {
            queueName = name;
            queue.name = name;
            queue.wait = true;
            queue.unread = false;
            queue.nextReadIndex = 0;
            queue.nextWriteIndex = 0;
            
            forwardTopicTable.count = table.count;
            for (int i = 0; i < table.count; i++)
            {
                forwardTopicTable.list[i] = table.list[i];
            }

            Thread thread = Thread.CurrentThread;
            queue.threadId = thread.ManagedThreadId;

            // Obtain a wait handle for the component that instantiated the queue
            queue.waitHandle =
               new EventWaitHandle(false, EventResetMode.ManualReset);

        } // end constructor DisburseForward


        private void ForwardMessage()
        {
            int managedThreadId = Thread.CurrentThread.ManagedThreadId;
            Console.WriteLine("Disburse signaled for {0} {1} {2}", 
                              queue.name, iteration, managedThreadId);

            Delivery.MessageType message;
            Forward forward = null;

            while (Unread())
            {   // Read message from queue
                message = Read();
                Console.WriteLine("Disburse Read message {0} {1} {2} {3}",
                                   queueName, iteration,
                                   message.header.id.topic,
                                   message.data);
                // Lookup callback associated with message topic
                for (int i = 0; i < forwardTopicTable.count; i++)
                {
                    if ((message.header.id.topic == 
                         forwardTopicTable.list[i].topic.topic) 
                     && (message.header.id.ext == 
                         forwardTopicTable.list[i].topic.ext))
                    {
                        forward = forwardTopicTable.list[i].forward;
                        break; // exit loop
                    }
                }

                // Invoke the callback passing the received message
                if (forward != null)
                {
                    forward(message);
                }
                else if (forwardTopicTable.count > 0)
                {
                    Console.WriteLine(
                        "ERROR: No forward callback for topic {0} {1} {2}",
                        queueName,
                        message.header.id.topic, message.header.id.ext);
                }
 //               else
 //               {
 //                   queue.Universal(message);
 //               }
            } // end while
        } // end ForwardMessage

        // Wait for the event issued by Write.
        public void EventWait() 
        {
            iteration++;
            Console.WriteLine("Disburse {0} entered EventWait {1}", 
                               queue.name, iteration);
            // Reset the wait handle
            bool signaled = false;
            bool waitResult = false;
            queue.waitHandle.Reset(); // reset the wait handle

            // Wait for the event to be signaled.
            Console.WriteLine("Disburse {0} waiting {1}", queue.name, iteration);
            signaled = queue.waitHandle.WaitOne(Timeout.Infinite, waitResult);

            if (forwardTopicTable.count > 0)
            {
                ForwardMessage();
            }
        } // end EventWait

        public void Clear()
        {
            queue.unread = false;
            queue.nextReadIndex = 0;
            queue.nextWriteIndex = 0;
        } // end Clear

        public Delivery.MessageType Read()
        {
            bool rtnNone = false;
            int savedReadIndex;
            if (queue.nextReadIndex == queue.nextWriteIndex)
            {
                Console.WriteLine("Disburse Read NRI == nWI");
                queue.unread = false;
                rtnNone = true;
            }
            savedReadIndex = queue.nextReadIndex;
            if ((queue.nextReadIndex + 1) >= size)
            {
                queue.nextReadIndex = 0;
            }
            else
            {
                queue.nextReadIndex++;
            }
            if (queue.nextReadIndex == queue.nextWriteIndex)
            {
                queue.unread = false;
            }
            else
            {
                queue.unread = true;
            }
            if (rtnNone)
            {
                Console.WriteLine("Disburse Read {0} no message", queueName);
                return Delivery.nullMessage;
            }
            else
            {
                Console.WriteLine("Disburse Read {0} message", queueName);
                return queue.list[savedReadIndex].message;
            }
        } // end Read

        public bool Unread()
        {
            Console.WriteLine("Disburse Unread {0} {1} {2}",
                queueName, iteration, queue.unread);
            return queue.unread;
        } // end Unread

        public bool Write(Delivery.MessageType message)
        {
            bool rtn = true;

            int currentIndex = queue.nextWriteIndex;
            int nextIndex = currentIndex + 1;
            if ((nextIndex) >= size)
            {
                nextIndex = 0;
            }
            if (nextIndex == queue.nextReadIndex)
            { // queue overrun
                Console.WriteLine("ERROR: Disburse {0} overrun", queueName);
                rtn = false;
            }
            if (rtn)
            {
                string xxx = queue.name;
                queue.list[currentIndex].message = message;
                queue.nextWriteIndex = nextIndex;
                queue.unread = true;
                Console.WriteLine("Disburse {0} set unread", queueName);
            }
            if (queue.wait)
            {
                Console.WriteLine("Disburse {0} signal wakeup {1}",
                    queueName, iteration);
                // signal wakeup of the component that instantiated the queue
                queue.waitHandle.Set();
            }
            return rtn;
        } // end Write

    } // end DisburseForward class

} // end namespace
