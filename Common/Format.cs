﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace VisualCompiler
{
    static public class Format
    {
        static private UnicodeEncoding streamEncoding;

        static private int heartbeatIteration = 0;

        static public void Initialize() // in place of constructor
        {
            streamEncoding = new UnicodeEncoding();
        }

        static public bool DecodeHeartbeatMessage
            (Delivery.MessageType message, int remoteAppId)
        {
            if ((message.header.id.topic == Topic.Id.HEARTBEAT) &&
                (message.header.id.ext == Topic.Extender.FRAMEWORK))
            {
                // assuming rest of header is ok
                if (message.header.size != 15)
                {
                    ConsoleOut.WriteLine("Heartbeat message has a size other than 15");
             //       ConsoleOut.WriteLine("Heartbeat message has a size other than 15 {0}",
             //              message.header.size);
                    return false;
                }

                string numeric = "";
                string subString1 = "";
                string subString2 = "";
                // Find first delimiter, if any.
                int i = message.data.IndexOf('|');
                int l = 0;
                if (i > 0)
                { // Is substring prior to delimiter the message id?
                    subString1 = message.data.Substring(0, i);
                    int j = String.Compare(subString1, "Heartbeat", false);
                    if (j == 0)
                    { // Yes - Heartbeat message
                        l = message.data.Length - i - 1;
                        subString1 = message.data.Substring(i + 1, l);
                        i = subString1.IndexOf('|');
                        numeric = subString1.Substring(0, i);
                        subString2 = subString1.Substring(i + 1, subString1.Length - i - 1);
                        int field;
                        bool result = Int32.TryParse(numeric, out field);
                        if (result)
                        {
                            if (field == remoteAppId)
                            { // 1st field is as expected
                                i = subString2.IndexOf('|');
                                if (i > 0)
                                {
                                    subString1 = subString2.Substring(i + 1, subString2.Length - i - 1);
                                    numeric = subString2.Substring(0, i);
                                    result = Int32.TryParse(numeric, out field);
                                    if (result)
                                    {
                                        if (field == App.applicationId)
                                        { // 2nd field is as expected; finished checking
                                            //      consecutiveValid++;
                                            return true; //heartbeatMessage = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return false;

        } // end DecodeHeartbeatMessage

        static public Delivery.MessageType EncodeHeartbeatMessage
                      (int appId)
        {
            string msg = "Heartbeat|" + App.applicationId + "|" + 
                          appId + "|" + heartbeatIteration;
            Delivery.MessageType message;
            message.header.CRC = 0;
            message.header.id.topic = Topic.Id.HEARTBEAT;
            message.header.id.ext = Topic.Extender.FRAMEWORK;
            Component.ParticipantKey key;
            key.appId = App.applicationId;
            key.comId = 0; // for Framework
            key.subId = 0;
            message.header.from = key;
            key.appId = appId;
            message.header.to = key;
            message.header.referenceNumber = 0;
            message.header.size = (short)msg.Length;
            message.data = msg;
            return message;
        } // end EncodeHeartbeatMessage

        // Decode Register Request topic
        static public Library.TopicListTableType
            DecodeRegisterRequestTopic(Delivery.MessageType message)
        {
            // Extract size from the message.
            int count = (message.header.size + 1) / 5; // bytes per item
            ConsoleOut.WriteLine("Format RegisterRequest " + 
                message.header.from.appId + " " + message.header.to.appId +
                " " + message.header.size + " " + count);

            // Extract topics from the message.
            Library.TopicListTableType topicData = new Library.TopicListTableType();
            topicData.count = 0;
            int size = message.header.size;
            var chars = message.data.ToCharArray();
            ConsoleOut.WriteLine("data size " + size);
            if (size >= 1) ConsoleOut.Write(" " + (Topic.Id)chars[0]);
            if (size >= 2) ConsoleOut.Write(" " + (Topic.Extender)chars[1]);
            if (size >= 3) ConsoleOut.Write(" " + (int)chars[2]);
            if (size >= 4) ConsoleOut.Write(" " + (int)chars[3]);
            if (size >= 5) ConsoleOut.Write(" " + (int)chars[4]);
            if (size >= 6) ConsoleOut.Write(" " + (Topic.Id)chars[5]);
            if (size >= 7) ConsoleOut.Write(" " + (Topic.Extender)chars[6]);
            ConsoleOut.WriteLine("");
            int i = 0;
            int index = 0;
            ConsoleOut.WriteLine("RegisterRequest Components");
            while (size > 0)
            {
                string data = index.ToString();
                topicData.list[index].topic.topic = (Topic.Id)chars[i];
                data += " " + topicData.list[index].topic.topic;
                topicData.list[index].topic.ext = (Topic.Extender)chars[i + 1];
                data += " " + topicData.list[index].topic.ext; 
                topicData.list[index].component.appId = (int)chars[i + 2];
                data += " " + topicData.list[index].component.appId;
                topicData.list[index].component.comId = (int)chars[i + 3];
                data += " " + topicData.list[index].component.comId;
                topicData.list[index].component.subId = (int)chars[i + 4];
                ConsoleOut.WriteLine(data);
                index++;
                topicData.count++;
                i = i + 5;
                size = size - 5;
            }
            return topicData;

        } // DecodeRegisterRequestTopic

        // Format Register Request topic
        static public Delivery.MessageType
            RegisterRequestTopic(int appId,
                                 Library.TopicTableType consumers)
        {
            Component.ParticipantKey key;
            key.appId = App.applicationId;
            key.comId = 0; // for Framework
            key.subId = 0;

            Delivery.MessageType message;
            message.header.CRC = 0;
            message.header.id.topic = Topic.Id.REGISTER;
            message.header.id.ext = Topic.Extender.REQUEST;
            message.header.from = key;
            key.appId = appId;
            message.header.to = key; // pass in the remoteAppId and use here?
            message.header.referenceNumber = 0;

            message.data = "";
            for (int i = 0; i < consumers.count; i++)
            {
                if ((consumers.list[i].id.topic != Topic.Id.ANY) &&      // don't include
                    (consumers.list[i].id.topic != Topic.Id.REGISTER) && // don't include
                    (Library.ValidPairing(consumers.list[i].id)))
                {
                    ConsoleOut.WriteLine("RegisterRequestTopic add " +
                        consumers.list[i].id.topic + " " + consumers.list[i].id.ext
                        + " " + consumers.list[i].component.appId + " " + 
                        consumers.list[i].component.comId);
                    message.data += (char)consumers.list[i].id.topic;
 // need without + or + going to set the pointer for the next usage? 
                    message.data += (char)consumers.list[i].id.ext;
                    message.data += (char)consumers.list[i].component.appId;
                    message.data += (char)consumers.list[i].component.comId;
                    message.data += (char)consumers.list[i].component.subId;
                }
                else
                {
                    ConsoleOut.WriteLine("RegisterRequestTopic invalid pairing " +
                        consumers.list[i].id.topic + " " + consumers.list[i].id.ext 
                        + " " + consumers.list[i].component.appId + " " + 
                        consumers.list[i].component.comId);
                }
            }

            message.header.size = (Int16)message.data.Length;

            return message;

        } // end RegisterRequestTopic

    } // end Format class

} // end namespace
