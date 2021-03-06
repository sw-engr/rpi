
package body Topic is

  procedure Initialize is

  begin -- Initialize

    TopicIds.Count := 13;
--    Empty.Topic := TEST;
--    Empty.Ext := DEFAULT;

    TopicIds.List(1).Topic := HEARTBEAT;
    TopicIds.List(1).Ext := FRAMEWORK;
    TopicIds.List(2).Topic := ANY;
    TopicIds.List(2).Ext := FRAMEWORK;
    TopicIds.List(3).Topic := REGISTER;
    TopicIds.List(3).Ext := REQUEST;
    TopicIds.List(4).Topic := REGISTER;
    TopicIds.List(4).Ext := RESPONSE;
    TopicIds.List(5).Topic := TEST;
    TopicIds.List(5).Ext := DEFAULT;
    TopicIds.List(6).Topic := TEST2;
    TopicIds.List(6).Ext := DEFAULT;
    TopicIds.List(7).Topic := TRIAL;
    TopicIds.List(7).Ext := REQUEST;
    TopicIds.List(8).Topic := TRIAL;
    TopicIds.List(8).Ext := RESPONSE;
    TopicIds.List(9).Topic := DATABASE;
    TopicIds.List(9).Ext := REQUEST;
    TopicIds.List(10).Topic := DATABASE;
    TopicIds.List(10).Ext := RESPONSE;
    TopicIds.List(11).Topic := OFP;
    TopicIds.List(11).Ext := TABLE;
    TopicIds.List(12).Topic := OFP;
    TopicIds.List(12).Ext := KEYPUSH;
    TopicIds.List(13).Topic := OFP;
    TopicIds.List(13).Ext := CHANGEPAGE;

  end Initialize;

end Topic;
