using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Windows.Forms;

namespace SocketApplication
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
/*            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Form1()); */
            if (System.Threading.Thread.CurrentThread.Name == null)
            {
                System.Threading.Thread.CurrentThread.Name = "MainThread";
            }
            currentProcess = Process.GetCurrentProcess();

            // Open ConsoleOut text file
            ConsoleOut.Install();

            // Locate, read, and parse Delivery.dat to build DeliveryTable
            Delivery.Initialize();

            // Install the components of this application.
            ComCDU.Install();

            // Now, after all the components have been installed, create the 
            // threads for the components to run in.
            //  o In addition, the TimingScheduler thread will be created.
            //  o There will be a return from Create and then the created threads
            //    will begin to execute.  And the main procedure application
            //    thread will no longer be executed -- instead, the created 
            //    threads will be the only threads running.
            Threads.Create();

            // Except, that with this framework plus Windows Forms application,
            // this main procedure application thread will continue to be
            // executed in the CDUForm.
            CDUForm cduForm;
            cduForm = new CDUForm();
            Application.Run(cduForm);
        } // end Main

        static private Process currentProcess;

    } // end class Program
} // end namespace