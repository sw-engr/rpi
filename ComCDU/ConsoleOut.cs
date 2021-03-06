using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace SocketApplication
{
    public class ConsoleOut
    {

        private static string path = "C:\\Source\\XP3\\Sockets\\ConsoleOut.txt";

        private static bool finishedWrite = true;

        private static string partialText = "";

        private static bool doOutput = false;

        // Install by creating the txt file
        static public void Install()
        {
            MessageBoxButtons buttons = MessageBoxButtons.YesNo;
            DialogResult result;
            string message = "String output to replace Console is in " + path;
            string caption = "Info";
            result = MessageBox.Show(message, caption, buttons);
            if (result == DialogResult.Yes)
            {
            	doOutput = true;
            }
            else
            {
            	doOutput = false;
            }
            if (doOutput)
            {
                if (System.IO.File.Exists(path))
                {
                    try
                    {
                        System.IO.File.Delete(@path);
                    }
                    catch (System.IO.IOException e)
                    {
                        ConsoleOut.WriteLine(e.Message);
                        return;
                    }
                }
                using (System.IO.FileStream textfile = System.IO.File.Create(path))
                {
                }
            }

        } // end Install

        static public void Write(string text)
        {
            partialText += text;
        } // Write

        static public void WriteLine(String text)
        {
            if (!doOutput)
            {
                return;
            }
            if ((text == "") || (text == " "))
            {
                if (!finishedWrite)
                {
                    while (!finishedWrite) // wait while another thread finishes write
                    {
                        Thread.Sleep(10); // 10 milliseconds
                    }
                }
                finishedWrite = false;
                using (System.IO.StreamWriter textFile =
                    new System.IO.StreamWriter(@path, true))
                {
                    textFile.WriteLine(partialText);
                    partialText = ""; // clear for the next time
                }
                finishedWrite = true;
            }
            else
            {
                if (!finishedWrite)
                {
                    while (!finishedWrite) // wait while another thread finishes write
                    {
                        Thread.Sleep(10); // 10 milliseconds
                    }
                }
                finishedWrite = false;
                while (true)
                {
                    try
                    {
                        using (System.IO.StreamWriter textFile =
                               new System.IO.StreamWriter(@path, true))
                        {
                            textFile.WriteLine(text);
                        }
                        break; // exit loop
                    }
                    catch (IOException)
                   {
                   }
                }
                finishedWrite = true;
            }
        } // end WriteLine


    } // end ConsoleOut class

} // end namespace
