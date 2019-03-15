using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Diagnostics;
using System.Threading;

namespace VisualCompiler
{
    public class Threads
    {
        // This framework class has the instances of various threads.  One is a 
        // higher priority TimingScheduler thread and the others are threads of
        // a pool of threads for components to run in where a separate thread 
        // is assigned to each installed component.  These component threads
        // are assigned the priorities requested by the component except that
        // no component thread is assigned a priority above normal.

        public enum ComponentThreadPriority
        {
            WHATEVER,
            HIGHEST,
            HIGH,
            NORMAL,
            LOWER,
            LOWEST
        };

        // Component thread data
        private struct ThreadDataType
        {
            public string name;
            public Thread threadInstance;
            public ThreadPriority priority;
        }

        // Component thread list
        private class ComponentThreadType
        {
            public int count; // Number of component threads.  Note: This should
                              //  end up equal to the number of components.
            public ThreadDataType[] list = new ThreadDataType[Component.MaxComponents];
                                    // List of component threads
        }

        // Thread pool of component threads
        static private ComponentThreadType threadTable = new ComponentThreadType();

        // To allow Remote to be invoked for the correct instance 
        // of the receive thread.
        static int receiveIndex = 0;
        
        // To allow ComponentThread to idle until all component threads have started
        static bool allThreadsStarted = false;
 
        // Create the TimingScheduler thread with above normal priority and start it.
        public static void Create()
        {
            var timingScheduler = new Thread(TimingScheduler);
            timingScheduler.Priority = ThreadPriority.AboveNormal;

            // Set the number of threads in the thread pool to the number of components
            threadTable.count = Component.componentTable.count;

            // Start the TimingScheduler
            timingScheduler.Start();
        } // end Create

        // Convert component thread priority to that of Windows
        private static ThreadPriority ConvertThreadPriority(
            Component.ComponentKind kind,
            ComponentThreadPriority priority)
        { // Only for user component threads.
            if (kind == Component.ComponentKind.USER)
            {
                // No component thread is allowed to have a priority above Normal.
                if (priority == ComponentThreadPriority.LOWER) return ThreadPriority.BelowNormal;
                if (priority == ComponentThreadPriority.LOWEST) return ThreadPriority.Lowest;
                return ThreadPriority.Normal;
            }
            else
            {
                // Framework threads are allowed to have their specified priority.
                if (priority == ComponentThreadPriority.HIGHEST) return ThreadPriority.Highest;
                if (priority == ComponentThreadPriority.HIGH) return ThreadPriority.AboveNormal;
                if (priority == ComponentThreadPriority.LOWER) return ThreadPriority.BelowNormal;
                if (priority == ComponentThreadPriority.LOWEST) return ThreadPriority.Lowest;
                return ThreadPriority.Normal;

            }
        } // end ConvertThreadPriority

        // The framework TimingScheduler thread
        private static void TimingScheduler() // thread to manage component threads
        {
            DateTime start = DateTime.Now;
            var stopWatch = Stopwatch.StartNew();

            // Create the component thread pool/factory; one thread for each 
            // component.  Wait until all are created before starting the threads.

            if (threadTable.count > 0)
            {
                int i = 0;
                Component.ComponentKind kind = 
                     Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].name = "ComThread1";
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread1);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 1)
            {
                int i = 1;
                threadTable.list[i].name = "ComThread2";
                Component.ComponentKind kind = 
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread2);
                }

                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 2)
            {
                int i = 2;
                threadTable.list[i].name = "ComThread3";
                Component.ComponentKind kind = 
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind,reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread3);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 3)
            {
                int i = 3;
                threadTable.list[i].name = "ComThread4";
                Component.ComponentKind kind = 
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind,reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread4);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 4)
            {
                int i = 4;
                threadTable.list[i].name = "ComThread5";
                Component.ComponentKind kind = 
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread5);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 5)
            {
                int i = 5;
                threadTable.list[i].name = "ComThread6";
                Component.ComponentKind kind = 
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread6);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 6)
            {
                int i = 6;
                threadTable.list[i].name = "ComThread7";
                 Component.ComponentKind kind = 
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind,reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread7);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 7)
            {
                int i = 7;
                threadTable.list[i].name = "ComThread8";
                Component.ComponentKind kind = 
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind,reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread8);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 8)
            {
                int i = 8;
                threadTable.list[i].name = "ComThread9";
                Component.ComponentKind kind =
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread9);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 9)
            {
                int i = 9;
                threadTable.list[i].name = "ComThread10";
                Component.ComponentKind kind =
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread10);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 10)
            {
                int i = 10;
                threadTable.list[i].name = "ComThread11";
                Component.ComponentKind kind =
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread11);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 11)
            {
                int i = 11;
                threadTable.list[i].name = "ComThread12";
                Component.ComponentKind kind =
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread12);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 12)
            {
                int i = 12;
                threadTable.list[i].name = "ComThread13";
                Component.ComponentKind kind =
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread13);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }
            if (threadTable.count > 13)
            {
                int i = 13;
                threadTable.list[i].name = "ComThread14";
                Component.ComponentKind kind =
                    Component.componentTable.list[i].kind;
                ComponentThreadPriority reqPriority =
                    Component.componentTable.list[i].priority;
                ThreadPriority threadPriority;
                threadPriority = ConvertThreadPriority(kind, reqPriority);
                threadTable.list[i].priority = threadPriority;
                if (kind == Component.ComponentKind.RECEIVE)
                {
                    threadTable.list[i].threadInstance = Remote.ReceiveThread(receiveIndex); //i);
                    receiveIndex++;
                }
                else
                {
                    threadTable.list[i].threadInstance = new Thread(ComThread14);
                }
                threadTable.list[i].threadInstance.Priority = threadPriority;
            }

            // Start the created threads of the component thread pool.
            for (int tIndex = 0; tIndex < threadTable.count; tIndex++)
            {
                string name = Component.componentTable.list[tIndex].name;
                ConsoleOut.WriteLine("TimingScheduler Start "); //{0} {1} {2}", tIndex,
             //       threadTable.list[tIndex].name, 
             //       name);
                threadTable.list[tIndex].threadInstance.Start();
            }
            allThreadsStarted = true;

            // Run the TimingScheduler thread every half a second.
            // What to have this thread do has yet to be decided.
            while (true)
            { // forever loop
                Thread.Sleep(500); // one-half second
            }

        } // end TimingScheduler

  //      public static void TimerProcedure(int location)
  //      {
  //      }

        // The common component thread code.  This code runs in the thread
        // of the invoking component thread.  The input parameter is its
        // location in the component table.
        // Note: There are multiple "copies" of this function running; one
        //       for each component as called by that component's ComThread.
        //       Therefore, the data (such as stopWatch) is on the stack in
        //       a different location for each such thread.
        private static void ComponentThread(int location)
        {
            // Get initial milliseconds; adjust Sleep period to be used below
            Stopwatch stopWatch = new Stopwatch();
            stopWatch.Start();
            int cycleInterval = Component.componentTable.list[location].period;
            if (cycleInterval < 1) // no period supplied
            {
                cycleInterval = 100; // msec 
            }
            int delayInterval = cycleInterval; // initial delay
            Disburse queue = Component.componentTable.list[location].queue;

            // Wait until all component threads have been started
            while (!allThreadsStarted)
            {
                Thread.Sleep(500);
            }

            // Create a Timer to signal the periodic components to resume 
            // when the timeout has been reached.  
            ConsoleOut.WriteLine("Threads ComponentThread " + location);
            MainEntry fMain = Component.componentTable.list[location].fMain;
            if (fMain != null)
            { // component with periodic entry point
                // Create instance of Timer for periodic components
                if (Component.componentTable.list[location].period > 0)
                {
                    PeriodicTimer executeTimer = new PeriodicTimer(location);
                    int period = Component.componentTable.list[location].period;
                    executeTimer.StartTimer(period, period); // milliseconds
                }
                // enter the component's callback to await a resume event
                fMain(); 
                
            }

        } // end ComponentThread

        // Component thread factory -- one thread for each possible component.
        // Only those for the components in the Component componentTable will
        // be run.
        private static void ComThread1()
        {
            ComponentThread(0);
        }
        private static void ComThread2()
        {
            ComponentThread(1);
        }
        private static void ComThread3()
        {
            ComponentThread(2);
        }
        private static void ComThread4()
        {
            ComponentThread(3);
        }
        private static void ComThread5()
        {
            ComponentThread(4);
        }
        private static void ComThread6()
        {
            ComponentThread(5);
        }
        private static void ComThread7()
        {
            ComponentThread(6);
        }
        private static void ComThread8()
        {
            ComponentThread(7);
        }
        private static void ComThread9()
        {
            ComponentThread(8);
        }
        private static void ComThread10()
        {
            ComponentThread(9);
        }
        private static void ComThread11()
        {
            ComponentThread(10);
        }
        private static void ComThread12()
        {
            ComponentThread(11);
        }
        private static void ComThread13()
        {
            ComponentThread(12);
        }
        private static void ComThread14()
        {
            ComponentThread(13);
        }

    } // end class Threads

    // Periodic Component Timer
    public class PeriodicTimer
    {
        private int location; // index into componentTable
        private int iterations = 0; 
        Stopwatch stopWatch = new Stopwatch();
 
        public PeriodicTimer(int index) // constructor
        {
            ConsoleOut.WriteLine("PeriodicTimer " + index);
            location = index;

        } // end constructor

        public void StartTimer(int dueTime, int period)
        {
            Timer periodicTimer = new Timer(new TimerCallback(TimerProcedure));
            periodicTimer.Change(dueTime, period);
            stopWatch.Start();
        }

        public void ResetInvokedTimer()
        {
            ConsoleOut.WriteLine("ResetInvokedTimer entered");
            StartTimer(0, 0);
        } // end ResetInvokedTimer 

        private void TimerProcedure(object state)
        {
            // The state object is the Timer object.
            Timer periodicTimer = (Timer)state;
            stopWatch.Stop();
            TimeSpan ts = stopWatch.Elapsed;
            stopWatch.Start();
            iterations++;
            ConsoleOut.WriteLine("TimerProcedure "); //{0} {1} {2}",
       //         Component.componentTable.list[location].name,
       //         ts, iterations);

            // Invoke component's Signal.
            Component.componentTable.list[location].waitHandle.Set();

        } // end TimerProcedure

    } // end PeriodicTimer

} // end namespace
