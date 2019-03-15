using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace VisualCompiler
{
    static public class CRC
    {
        static public ushort CRC16(byte[] bytes)
        {
            // Notes:
            //   Taken from the internet as published by AnandTech.
            //   The byte array contains the first two bytes that are reserved
            //   for the CRC.  Therefore, these two bytes are ignored in the
            //   for loop below.

            ushort crc = 0xFFFF;

            for (int j = 2; j < bytes.Length; j++)
            {
                crc = (ushort)(crc ^ bytes[j]);
                for (int i = 0; i < 8; i++)
                {
                    if ((crc & 0x0001) == 1)
                        crc = (ushort)((crc >> 1) ^ 0x8408);
                    else
                        crc >>= 1;
                }
            }
            return (ushort)~(uint)crc;
        } // end CRC16

     } // end CRC class
} // end namespace
