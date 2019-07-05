using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace SocketApplication
{
    // The Delivery class locates the Delivery.dat file, inputs and parses it
    // to create the Delivery Table for the instances of the Socket class to
    // access, validates it, and locates the component partners in the table.
    static public class Delivery
    {
      const int maxEntries = 16; // maximum number of Delivery Table entries

      const int ComponentIdsRange = 63; // maximum of 63 components

      public struct IPAddressType
      {
        public byte quad1;
        public byte quad2;
        public byte quad3;
        public byte quad4;
      }
 
      // Delivery table data type
      public struct DataType 
      {
        public int ComId;         // numeric id of component
        public string ComName;    // name of component
        public bool validIP;      // true if dotted quad notation
        public string IP_Address; // IP address as string
        public IPAddressType IPAddress; // IP address as 4 bytes
        public int MyPort;        // server port
        public int OtherPort;     // client port
        public int Partner;       // index of component with opposite ports
      };
        
      // Delivery table
      public class TableType
      {
        public int count;
        public DataType[] list = new DataType[maxEntries];
      };

      static public TableType DeliveryTable = new TableType();

      static public bool DeliveryError = false;


      // Locate Delivery.dat file and parse to create DeliveryTable
      static public bool Initialize()
      {
        bool Valid = true;

        // Obtain the path of the delivery file.
        string deliveryFile = FindDeliveryFile();
        if (deliveryFile.Length < 8)
        {
          ConsoleOut.WriteLine("ERROR: No Delivery.dat file found");
          return false;
        }

        // Open and parse the configuration file.
        using (FileStream fs = File.Open(deliveryFile, FileMode.Open,
                                         FileAccess.Read, FileShare.None))
        {
          byte[] fileData = new byte[1024];
          UTF8Encoding temp = new UTF8Encoding(true);

          while (fs.Read(fileData, 0, fileData.Length) > 0)
          {
            ConsoleOut.WriteLine(temp.GetString(fileData));
          }
          fs.Close();

          Parse(fileData);

          ConsoleOut.WriteLine("Delivery Table");
          for (int i = 0; i < DeliveryTable.count; i++)
          {
            ConsoleOut.Write(DeliveryTable.list[i].ComId.ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(DeliveryTable.list[i].ComName);
            ConsoleOut.Write(" ");
            ConsoleOut.Write(DeliveryTable.list[i].IPAddress.quad1.ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(DeliveryTable.list[i].IPAddress.quad2.ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(DeliveryTable.list[i].IPAddress.quad3.ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(DeliveryTable.list[i].IPAddress.quad4.ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.Write(DeliveryTable.list[i].MyPort.ToString());
            ConsoleOut.Write(" ");
            ConsoleOut.WriteLine(DeliveryTable.list[i].OtherPort.ToString());
          }
        } // end using
          
        // Validate the parsed table and match up component partners
        if (!Validate())
        {
            return false;
        }

        return Valid;

      }  // end Initialize

      // Lookup and return location of ComId with a Partner of OtherId
      static public int Lookup(int ComId, int OtherId)
      {
        int location = -1;

        for (int i = 0; i < DeliveryTable.count; i++)
        {
          if (DeliveryTable.list[i].ComId == ComId)
          {
//                for (int j = 0; j < DeliveryTable.count; j++)
//                {
//                    if (DeliveryTable.list[j].ComId == OtherId)
//                    {
//                        return i;
//                    }
//                }
            int Partner = DeliveryTable.list[i].Partner;
            if (DeliveryTable.list[Partner].ComId == OtherId)
            {
              return i;
            }
          }
        } // end for

        return location;

      } // end Lookup

      // Locate the Delivery.dat file in the path of application execution.
      static private string FindDeliveryFile()
      {
        string nullFile = "";

        // Get the current directory/folder.
        string path = Directory.GetCurrentDirectory();

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
              newPath = path.Substring(0, index); // the portion of path that
                                                  //  ends just before '\'
              string[] dirs = Directory.GetFiles(newPath, "*.dat");
              string file = "Delivery.dat";
              int fileLength = file.Length;
              foreach (string dir in dirs)
              {
                string datFile = dir.Substring(index + 1, fileLength);
                equal = datFile.CompareTo(file);
                if (equal == 0)
                {
                  return dir;
                }
              }
              path = newPath; // reduce path to look again
              if (path.Length < 10)
              { return nullFile; }
            } // end equal == 0
            index--;

          } // end for loop
        } // end while loop

        return nullFile;

      } // end FindConfigurationFile

      public struct ParseParameters
      {
        public char delimiter; 
        public int decodePhase; 
        public int comCount; 
        public int field; 
        public string temp; 
      };

      static private ParseParameters p;

      static private void Parse(byte[] data)
      {
        // Initialize
        DeliveryTable.count = 0;
        DeliveryError = false;

        p.delimiter = '|';
        p.decodePhase = 0;
        p.comCount = 0;
        p.field = 0;
        p.temp = "";
 
        // Decode application data
        for (int i = 0; i < data.Length; i++)
        { 
          if (p.field == 5)
          { // Bypass end of line characters
            if ((data[i] == '\r') || (data[i] == '\n'))
            {
            }
            else
            {
              p.temp += (char)data[i]; // retain char for next phase
              p.field = 0;  // start over for next application
            }
          }
          else // not end-of-line; parse within the record
          { // Get component id
            if (data[i] != p.delimiter)
            {
              p.temp += (char)data[i];
            }
            else
            { // treat field prior to delimiter
              if (p.field == 0)
              { // initialize IP address for dotted quad
                DeliveryTable.list[p.comCount].validIP = true;
                // decode component id
                try
                {
                  DeliveryTable.list[p.comCount].ComId = Convert.ToInt32(p.temp);
                }
                catch (OverflowException)
                {
//                  ConsoleOut.WriteLine(
//                      "ERROR: {0} is outside the range of the Int32 type.",
//                      p.temp);
                    ConsoleOut.Write("ERROR: ");
                    ConsoleOut.Write(p.temp.ToString());
                    ConsoleOut.WriteLine(" is outside the range of the Int32 type.");
                }
                catch (FormatException)
                {
//                  ConsoleOut.WriteLine(
//                      "ERROR: The {0} value '{1}' is not in a recognizable format.",
//                      p.temp.GetType().Name, p.temp);
                    ConsoleOut.Write("ERROR: The ");
                    ConsoleOut.Write(p.temp.GetType().Name);
                    ConsoleOut.Write(" value ");
                    ConsoleOut.Write(p.temp);
                    ConsoleOut.WriteLine(" is not in a recognizable format.");
                }

                p.temp = ""; // initialize for next field
                p.field++;
              }
              else if (p.field == 1)
              { // decode component name
                DeliveryTable.list[p.comCount].ComName = p.temp;

                p.temp = ""; // initialize for next field
                p.field++;
              }
              else if (p.field == 2)
              { // decode IP Address of form nnn.nnn.n.nn
                DeliveryTable.list[p.comCount].IPAddress = DecodeIP(p.temp);
                DeliveryTable.list[p.comCount].IP_Address = p.temp;
                p.temp = ""; // initialize for next field
                p.field++;
              }
              else if (p.field == 3)
              { // decode first port
                DeliveryTable.list[p.comCount].MyPort = DecodePort(p.temp);

                p.temp = ""; // initialize for next field
                p.field++;
              }
              else if (p.field == 4)
              { // decode second port
                DeliveryTable.list[p.comCount].OtherPort = DecodePort(p.temp);

                p.temp = ""; // initialize for next field
                p.field++;

                p.comCount++; // increment index for the list

                DeliveryTable.count++;
              }
            }
          }
        } // end for loop

      } // end Parse

      static private Int32 DecodePort(string Port)
      {
        Int32 port = 0;
        try
        {
          port = Convert.ToInt32(Port);
          return port;
        }
        catch (FormatException e)
        {
          ConsoleOut.WriteLine(
                "ERROR: Input string is not a sequence of digits.");
        }
        catch (OverflowException e)
        {
          ConsoleOut.WriteLine(
                "ERROR: The number cannot fit in an integer.");
        }
        return 0;

      } // end DecodePort
        
      static IPAddressType IP;

      static private IPAddressType DecodeIP(string Addr)
      {
        IP.quad1 = 0;
        IP.quad2 = 0;
        IP.quad3 = 0;
        IP.quad4 = 0;

        int loc = 0;
        int count = 0; // number of '.' found
        string quad4 = "";

        for (int i = 0; i < Addr.Length; i++)
        {
          if (Addr[i] != '.')
          {
            quad4 += Addr[i];
            if (i + 1 == Addr.Length)
            {
              if (!DecodeIPQuad(loc, quad4))
              {
                  DeliveryTable.list[p.comCount].validIP = false;
              }
            }
          }
          else 
          {
            count++;
            if (!DecodeIPQuad(loc, quad4))
            {
                DeliveryTable.list[p.comCount].validIP = false;
            }
            quad4 = "";
            loc++;
          }
        } // end for
        return IP;
      } // end DecodeIP
 
      static private bool DecodeIPQuad(int loc, string quad)
      {
        bool valid = false;
        byte quadByte = 0;
        try
        {
          quadByte = Convert.ToByte(quad);
          valid = true;
        }
        catch (FormatException e)
        {
          ConsoleOut.WriteLine(
                "ERROR: Input string is not a sequence of digits.");
        }
        catch (OverflowException e)
        {
          ConsoleOut.WriteLine(
                "ERROR: The number cannot fit in a byte.");
        }
        switch (loc)
        {
          case 0:
            IP.quad1 = quadByte;
            break;
          case 1:
            IP.quad2 = quadByte;
            break;
          case 2:
            IP.quad3 = quadByte;
            break;
          case 3:
            IP.quad4 = quadByte;
            break;
        }
        return valid;
      } // end DecodeIPQuad

      // Validate the parsed table and match up component partners
      static private bool Validate()
      {
        bool valid = true;

        for (int i = 0; i < DeliveryTable.count; i++)
        {
            DeliveryTable.list[i].Partner = 0;

            // Check that ComId is within range
            if ((DeliveryTable.list[i].ComId > 0) &&
                (DeliveryTable.list[i].ComId <= ComponentIdsRange))
            {
            }
            else
            {
                ConsoleOut.WriteLine("ERROR: Delivery.dat ComId of " +
                  DeliveryTable.list[i].ComId + " is out-of-range");
                valid = false;
            }

            // Check that an entry with a duplicate ComId has the same ComName
            for (int j = i + 1; j < DeliveryTable.count; j++)
            {
                if (DeliveryTable.list[j].ComId == DeliveryTable.list[i].ComId)
                {
                    if (DeliveryTable.list[j].ComName != DeliveryTable.list[i].ComName)
                    {
                        ConsoleOut.WriteLine(
                          "WARNING: ComponentName mismatch between Delivery.dat records at "
                          + i + " and " + j);
                    }
                }
            } // end loop

            // Check PortServer and PortClient for some range of values
            if (((DeliveryTable.list[i].MyPort < 8000) ||
                 (DeliveryTable.list[i].MyPort > 9999)) ||
                ((DeliveryTable.list[i].OtherPort < 8000) ||
                 (DeliveryTable.list[i].OtherPort > 9999)))
            {
                ConsoleOut.WriteLine(
                  "ERROR: Server or Client Port not within selected range of 8000-9999");
                valid = false;
            } // end if

            // Check that another record doesn't have the same MyPort or OtherPort
            for (int j = 0; j < DeliveryTable.count; j++)
            {
              if (i != j) // avoid current entry
              {
                if (DeliveryTable.list[i].MyPort ==
                    DeliveryTable.list[j].MyPort)
                {
                  ConsoleOut.WriteLine("ERROR: Repeated use of MyPort of " +
                                    DeliveryTable.list[i].MyPort);
                  valid = false;
                }
                if (DeliveryTable.list[i].OtherPort ==
                    DeliveryTable.list[j].OtherPort)
                {
                  ConsoleOut.WriteLine("ERROR: Repeated use of OtherPort of " +
                                    DeliveryTable.list[i].OtherPort);
                  valid = false;
                }

              } // if i = j

            } // end for loop

          // Find component partner of this entry
          for (int j = 0; j < DeliveryTable.count; j++)
          {
            if (i != j) // avoid current entry
            {
              if ((DeliveryTable.list[i].MyPort ==
                   DeliveryTable.list[j].OtherPort) &&
                  (DeliveryTable.list[i].OtherPort ==
                   DeliveryTable.list[j].MyPort))
              {
                DeliveryTable.list[i].Partner = j;
                break; // exit inner loop; can't be more than one partner
              }
            } // end if i = j
          } // end loop

        } // end loop over i

        return valid;

      } // end Validate

    } // end Delivery class

} // end namespace
