using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;

namespace VisualCompiler
{
    public class Disburse
    {
        public string queueName;

        public struct DisburseDataType
        {
            public Topic.TopicIdType topic;
            public Forward forward;
        }

        private int iteration = 0;

        // Queued items will be removed from the queue as they are read.
        public struct QueueDataType // Queued topic messages
        {
            public Delivery.MessageType message;
        };

        int size = 10;
        private class QueueType
        {
            public string name; // Name given to the queue by the component
            public bool wait;
            public bool periodic; 
            public Forward universal;
            public bool unread;
            public int nextReadIndex;
            public int nextWriteIndex;
            public int threadId;
            public EventWaitHandle waitHandle;
            public QueueDataType[] list = new QueueDataType[10]; // i.e., size
        };

    //    static private EventWaitHandle waitHandle;

        private QueueType queue = new QueueType();

        public Disburse() // constructor
        {
        }

        public Disburse(string name, bool waitEvent,         // constructor
                        bool periodic, Forward universal) 
        {
            queueName = name;
            queue.name = name;
            queue.wait = waitEvent;      // Wait Event of queue
            queue.periodic = periodic;   // whether component using queue is periodic
            queue.universal = universal; // general callback to treat message
            queue.unread = false;
            queue.nextReadIndex = 0;
            queue.nextWriteIndex = 0;

            Thread thread = Thread.CurrentThread;
            queue.threadId = thread.ManagedThreadId;

            // create the wait handle
            queue.waitHandle =
                new EventWaitHandle(false, EventResetMode.ManualReset);
     //       queue.waitHandle = waitHandle;

            ConsoleOut.WriteLine("Disburse constructor " + queue.name + " " +
                                  thread.ManagedThreadId + " " +
                                  queue.waitHandle.Handle.ToString());

        } // end constructor Disburse

        public EventWaitHandle QueueWaitHandle()
        {
            return queue.waitHandle;
        } // end QueueWaitHandle
        
        private void ForwardAnyMessage()
        {
            int managedThreadId = Thread.CurrentThread.ManagedThreadId;
            ConsoleOut.WriteLine("Disburse ForwardAnyMessage " +
                //                         queueTable[queueIndex].queue.name +
                                 queue.name +
                                 " " + iteration + " " + managedThreadId);

            Delivery.MessageType message;

            while (Unread())
            {   // Read message from queue
                message = Read();
                ConsoleOut.WriteLine("Disburse Read Universal message " +
                                   queue.name + " " + iteration + " " +
                                   message.header.id.topic + " " +
                                   message.data);

                // Invoke the universal callback passing the received message
                queue.universal(message);

            } // end while
        } // ForwardAnyMessage

        // Wait for the event issued by Write.
        public virtual void EventWait()
        {
            iteration++;
            Thread thread = Thread.CurrentThread;
            ConsoleOut.WriteLine("Disburse " + queue.name + " entered EventWait "
                              + thread.ManagedThreadId + " " +
                              queue.waitHandle.Handle.ToString());
            // Reset the wait handle
            bool signaled = false;
            bool waitResult = false;
            queue.waitHandle.Reset(); // reset the wait handle

            // Wait for the event to be signaled.
            ConsoleOut.WriteLine("Disburse " + queue.name + " waiting " + iteration);
            signaled = queue.waitHandle.WaitOne(Timeout.Infinite, waitResult);

            if (queue.universal != null)
            {
                ForwardAnyMessage();
            }

        } // end 


        // Clear the queue if case don't want to instantiate the queue again
        public virtual void Clear()
        {
            queue.unread = false;
            queue.nextReadIndex = 0;
            queue.nextWriteIndex = 0;
        } // end Clear

        public virtual Delivery.MessageType Read()
        {
            bool rtnNone = false;
            int savedReadIndex;
            if (queue.nextReadIndex == queue.nextWriteIndex)
            {
                ConsoleOut.WriteLine("Disburse Read NRI == nWI");
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
                ConsoleOut.WriteLine("Disburse Read " +  queue.name + " message" );
                return Delivery.nullMessage;
            }
            else
            {
                ConsoleOut.WriteLine("Disburse Read " +  queue.name + " message" );
                return queue.list[savedReadIndex].message;
            }
        } // end Read

        public virtual bool Unread()
        {
            Thread thread = Thread.CurrentThread;
            ConsoleOut.WriteLine("Disburse Unread " +
                queue.name + " " + iteration + " " + queue.unread + " " + thread.ManagedThreadId);
            return queue.unread;
        } // end Unread

        public virtual bool Write(Delivery.MessageType message)
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
                ConsoleOut.WriteLine("ERROR: Disburse " + queue.name + " overrun" );
                rtn = false;
            }
            if (rtn)
            {
                queue.list[currentIndex].message = message;
                queue.nextWriteIndex = nextIndex;
                queue.unread = true;
                ConsoleOut.WriteLine("Disburse " + queue.name + " set unread");
            }
            if ((queue.wait) && (!queue.periodic))
            {
                ConsoleOut.WriteLine("Disburse " + queue.name + " signal wakeup " +
                    iteration + " " + queue.waitHandle.Handle.ToString());
                // signal wakeup of the component that instantiated the queue
                queue.waitHandle.Set();
            }
            return rtn;
        } // end Write

    } // end Disburse class

} // end namespace
