﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
//using System.Windows.Forms;
//using System.Drawing;

namespace VisualCompiler
{
    static public class Configuration
    {
        // Maintain the configuration of applications

 //       static public ConsoleForm = new ConsoleForm;
 //       private static ConsoleForm consoleForm = new ConsoleForm();
//        private static ConsoleForm consoleForm;

        public const int MaxApplications = 4;
        // Maximum allowed number of allowed applications

        // Possible methods of inter-application communications
        //--> move to Remote class
        public enum CommMethod
        {
            NONE,    // Topic added to the library
            MS_PIPE, // Topic already added for the component
            TCP_IP   // Topic not added
        };


        // Note: The executable can be in either the Debug or Release folders.
        public struct ConfigurationDataType
        {
            public Component.ApplicationId app; // name and id
            public CommMethod commMethod; // communication method
            public string computerId; // expected computer identifier
            public string appPath; // path to application executable

            public bool connected; // true if connected to the remote app
        };

        public class ConfigurationTableType
        {
            public int count; // Number of declared applications
            public ConfigurationDataType[] list = new ConfigurationDataType[MaxApplications];
            // will need to be expanded
        };

        static public ConfigurationTableType configurationTable = new ConfigurationTableType();

        public struct ParseParameters
        {
            public char delimiter; // = '|';
            public int decodePhase; // = 0;
            public int appCount; // = 0;
            public int field; // = 0;
            public string temp; // = "";
        };

        static public void Initialize() //string path)
        {
 //           consoleForm = ConsoleForm.consoleForm; //new ConsoleForm();
 //           consoleForm = Program.consoleForm;
            // Obtain the path of the configuration file.
            string configurationFile = FindConfigurationFile(); //path);
            if (configurationFile.Length < 22)
            {
                ConsoleOut.WriteLine("ERROR: No Apps-Configuration.dat file found");
                return;
            }

            // Open and parse the configuration file.
            using (FileStream fs = File.Open(configurationFile, FileMode.Open,
                                             FileAccess.Read, FileShare.None))
            {
                byte[] fileData = new byte[1024];
                UTF8Encoding temp = new UTF8Encoding(true);

                while (fs.Read(fileData, 0, fileData.Length) > 0)
                {
        //            if (consoleForm == null)
        //            {

        //            }
        //            ConsoleForm.WriteLine(temp.GetString(fileData));
                    ConsoleOut.WriteLine(temp.GetString(fileData));
        //            VisualCompiler.ConsoleForm.WriteLine(temp.GetString(fileData));
                }

                Parse(fileData);

                for (int i = 0; i < configurationTable.count; i++)
                {
                    configurationTable.list[i].connected = false;
                }
            }

        }  // end Initialize
        
        // Locate the configuration data file in the path of application execution.
        static private string FindConfigurationFile() //string path1)
        {
            string nullFile = "";

            // Get the current directory/folder.
            string path = Directory.GetCurrentDirectory();
//            string path = "C:\\Source\\XP3\\Try5\\VisualComputer";
//  		    string message = "Please entey You did not enter a server name. Cancel this operation?";
//                       string caption = "Error Detected in Input";
//		MessageBoxButtons buttons = MessageBoxButtons.YesNo;
//		DialogResult result;

		// Displays the MessageBox.

//		result = MessageBox.Show(message, caption, buttons);
//            MessageBox.
//            string value = "";
//            if (Tmp.InputBox(".dat Location", "Enter path to .dat file:", ref value) == DialogResult.OK)
//            {
//                myDocument.Name = value;
//            }
            // Find the Apps-Configuration.dat file in the path.
            bool notFound = true;
            while (notFound)
            {
                // Look for the file in this directory
                string newPath;
                char backSlash = '\\';
                int index = path.Length - 1;
                for (int i = 0; i < path.Length; i++)
                {
                    int equal = path[index].CompareTo(backSlash);
                    if (equal == 0)
                    {
                        newPath = path.Substring(0, index); // the portion of path
                                                      // that ends just before '\'
                        string[] dirs = Directory.GetFiles(newPath, "*.dat");
                        string file = "Apps-Configuration.dat";
                        int fileLength = file.Length;
                        foreach (string dir in dirs)
                        {
                            string datFile = dir.Substring(index+1, fileLength);
                            equal = datFile.CompareTo(file);
                            if (equal == 0)
                            {
                                return dir;
                            }
                        }
                        path = newPath; // reduce path to look again
                        if (path.Length < 10)
                        { return nullFile; }
                   }
                   index--;

                    // what if newPath has become C: or such with no file found
                }
            } // end while loop

            // Read and decode the configuration file into the table

            return nullFile;

        } // end FindConfigurationFile

        static private ParseParameters p;

        static private void Parse(byte[] data)
        {
            p.delimiter = '|';
            p.decodePhase = 0;
            p.appCount = 0;
            p.field = 0;
            p.temp = "";
            for (int i = 0; i < data.Length; i++)
            {
                if (p.decodePhase == 0)
                {  // decode header
                    ParseHeader(data, i);
                } // end headerPhase
                else
                { // decode application data
                    ParseData(data, i);
                    if (p.appCount == configurationTable.count)
                    {
                        return; // done with Parse
                    }
                } // end application data parse

            } // end for loop

            ConsoleOut.WriteLine("ERROR: Invalid Apps-Configuration.dat file");

        } // end Parse

        static private void ParseHeader(byte[] data, int i)
        {
       	    // Check for end-of-line first
            if (p.field == 3)
            { // bypass end of line characters
                if ((data[i] == '\r') || (data[i] == '\n'))
                {
                }
                else
                {
                    p.temp += (char)data[i]; // retain char for next phase
                    p.field = 0;
                    p.decodePhase++; // end first phase
                }
            }
            else // parse within the line
            { // Get Count, Language, and Framework
                if (data[i] != p.delimiter)
                {
                    p.temp += (char)data[i];
                }
                else
                { // treat field prior to delimiter
                    if (p.field == 0)
                    {
                        try
                        {
                            configurationTable.count = Convert.ToInt32(p.temp);
                        }
                        catch (OverflowException)
                        {
                            ConsoleOut.WriteLine("ERROR: " + p.temp + 
                                 " is outside the range of the Int32 type." );
                        }
                        catch (FormatException)
                        {
                            ConsoleOut.WriteLine("ERROR: The " + p.temp.GetType().Name + 
                                " value " + p.temp + " is not in a recognizable format." );
                        }
                        p.temp = ""; // initialize for next field
                        p.field++;
                    }
                    else if (p.field == 1)
                    {
                        p.temp = ""; // initialize for next field
                        p.field++;
                    }
                    else if (p.field == 2)
                    {
                        p.temp = ""; // initialize for next field
                        p.field++;
                    }

                } // end treat field prior to delimiter
            }

        } // end ParseHeader


        static private void ParseData(byte[] data, int i)
        {
            if (p.field == 5)
            { // bypass end of line characters
                if ((data[i] == '\r') || (data[i] == '\n'))
                {
                }
                else
                {
                    p.temp += (char)data[i]; // retain char for next phase
                    p.field = 0;  // start over for next application
                }
            }
            else // not end-of-line
            { // Get application id and name, etc
                if (data[i] != p.delimiter) 
                {
                    p.temp += (char)data[i];
                }
                else
                { // treat field prior to delimiter
                    if (p.field == 0)
                    { // decode application id
                        try
                        {
                            configurationTable.list[p.appCount].app.id = Convert.ToInt32(p.temp);
                        }
                        catch (OverflowException)
                        {
                            ConsoleOut.WriteLine("ERROR: " + p.temp + 
                                                  " is outside the range of the Int32 type." );
                        }
                        catch (FormatException)
                        {
                            ConsoleOut.WriteLine("ERROR: The " + p.temp.GetType().Name + " value " 
                                                  + p.temp + " is not in a recognizable format." );
                        }

                        p.temp = ""; // initialize for next field
                        p.field++;
                    }
                    else if (p.field == 1)
                    { // decode application name
                        configurationTable.list[p.appCount].app.name = p.temp;

                        p.temp = ""; // initialize for next field
                        p.field++;
                    }
                    else if (p.field == 2)
                    { // decode communication method
                        if (String.Compare("MSPipe", p.temp, true) == 0)
                        {
                            configurationTable.list[p.appCount].commMethod = CommMethod.MS_PIPE;
                        }
                        else if (String.Compare("TCPIP", p.temp, true) == 0)
                        {
                            configurationTable.list[p.appCount].commMethod = CommMethod.TCP_IP;
                        }
                        else
                        {
                            configurationTable.list[p.appCount].commMethod = CommMethod.NONE;
                        }

                        p.temp = ""; // initialize for next field
                        p.field++;
                    }
                    else if (p.field == 3)
                    { // decode required computer name
                        configurationTable.list[p.appCount].computerId = p.temp;

                        p.temp = ""; // initialize for next field
                        p.field++;
                    }
                    else if (p.field == 4)
                    { // decode path of executable
                        configurationTable.list[p.appCount].appPath = p.temp;

                        p.temp = ""; // initialize for next field
                        p.field++;

                        p.appCount++; // increment index for list
                        if (p.appCount == configurationTable.count)
                        {
                            return; // done with Parse
                        }
                    }
                } // end treat field prior to delimiter
            } // end else
       } // end ParseData

    } // end Configuration

} // end namespace
