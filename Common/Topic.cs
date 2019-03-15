using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace VisualCompiler
{
    static public class Topic
    {
        // An enumeration of possible topics for the configuration
        // of applications.

        // Allowed topics of the configuration of applications
        public enum Id
        {
            NONE,     // when identifying the lack of a topic
            ANY,      // Special framework topic to register for any topic
            HEARTBEAT,// framework only topic
            REGISTER, // framework only topic with REQUEST and RESPONSE
            TEST,     // App 1 TEST
            TEST2,    // App 2 TEST
            TRIAL,
            DATABASE, // to Employee or Expenses Database
            OFP       // to OFP
//            EMPLOYEEADD,   // Add, Update, etc an employee
//            EMPLOYEEMODIFY
        };

        // Extender of topic.  Normal or Request/Response combination.
        public enum Extender
        {
            FRAMEWORK,  // framework only topic
            DEFAULT,    // general message that can be consumed by multiple components
            TABLE,      // table to pass to OFP
            KEYPUSH,    // displayed page and key to pass to OFP
            REQUEST,    // request portion of Request/Response pair of messages
            RESPONSE,   // response to Request message
            CHANGEPAGE  // change displayed page on CDU
 //           ADD,        // add an employee
 //           ADDRESPONSE // response to the add of an employee
        };

        // Combination of topic and the extension to form the complete identifier
        public struct TopicIdType
        { public Id topic; public Extender ext; };

        // A "constant" identifying the NONE, DEFAULT topic
        public static TopicIdType empty;

        // Allowed topic pairings of the configuration of applications
        // Note: Each time a topic Id is added, the count and list
        //       below need to be updated.
        public class TopicIds
        {
            static public int count = 13; // Number of allowed topics in the 
                                          //  configuration of applications
            static public TopicIdType[] list = new TopicIdType[count];
        }

 //       Id[] topics;
 //       public class Topics[] topics

        // Initialize. A replacement for a constructor.
        static public void Initialize()
        {
            empty.topic = Id.TEST;
            empty.ext = Extender.DEFAULT;

            TopicIds.list[0].topic = Id.HEARTBEAT;
            TopicIds.list[0].ext = Extender.FRAMEWORK;
            TopicIds.list[1].topic = Id.ANY;
            TopicIds.list[1].ext = Extender.FRAMEWORK;
            TopicIds.list[2].topic = Id.REGISTER;
            TopicIds.list[2].ext = Extender.REQUEST;
            TopicIds.list[3].topic = Id.REGISTER;
            TopicIds.list[3].ext = Extender.RESPONSE;
            TopicIds.list[4].topic = Id.TEST;
            TopicIds.list[4].ext = Extender.DEFAULT;
            TopicIds.list[5].topic = Id.TEST2;
            TopicIds.list[5].ext = Extender.DEFAULT;
            TopicIds.list[6].topic = Id.TRIAL;
            TopicIds.list[6].ext = Extender.REQUEST;
            TopicIds.list[7].topic = Id.TRIAL;
            TopicIds.list[7].ext = Extender.RESPONSE;
            TopicIds.list[8].topic = Id.DATABASE;
            TopicIds.list[8].ext = Extender.REQUEST;
            TopicIds.list[9].topic = Id.DATABASE;
            TopicIds.list[9].ext = Extender.RESPONSE;
            TopicIds.list[10].topic = Id.OFP;
            TopicIds.list[10].ext = Extender.TABLE;
            TopicIds.list[11].topic = Id.OFP;
            TopicIds.list[11].ext = Extender.KEYPUSH;
            TopicIds.list[12].topic = Id.OFP;
            TopicIds.list[12].ext = Extender.CHANGEPAGE;
            /*         TopicIds.list[8].topic = Id.EMPLOYEEADD;
                                                        TopicIds.list[8].ext = Extender.REQUEST; // ADD;
                                                        TopicIds.list[9].topic = Id.EMPLOYEEADD;
                                                        TopicIds.list[9].ext = Extender.RESPONSE; // ADDRESPONSE;
                                                        TopicIds.list[10].topic = Id.EMPLOYEEMODIFY;
                                                        TopicIds.list[10].ext = Extender.REQUEST;
                                                        TopicIds.list[11].topic = Id.EMPLOYEEMODIFY;
                                                        TopicIds.list[11].ext = Extender.RESPONSE; */
        }

    } // end Topic class
} // end namespace
