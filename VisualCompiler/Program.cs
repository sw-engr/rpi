﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Windows.Forms;

namespace VisualCompiler
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            if (System.Threading.Thread.CurrentThread.Name == null)
            {
                System.Threading.Thread.CurrentThread.Name = "MainThread";
            }
            currentProcess = Process.GetCurrentProcess();

            // Open ConsoleOut text file
            ConsoleOut.Install();

            Component.ApplicationId appId; // the Program.cs version
            appId.name = "App 1";          //   of the Program class
            appId.id = 1;                  //   ids the first application
            // pass appId and where .dat can be found
            App.Launch(appId, "C:\\Source\\XP3\\Try5\\");

            // Install the components of this application.
            App1.Install();

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
            // executed in the ExpenseItForm.
            BuildTableForm buildTableForm;
            buildTableForm = new BuildTableForm();
            Application.Run(buildTableForm);
        } // end Main

        static private Process currentProcess;

    } // end class Program
} // end namespace
