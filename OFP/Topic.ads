
package Topic is

  -- Allowed topics of the configuration of applications
  type Id_Type
  is ( NONE,     -- when identifying the lack of a topic
       ANY,      -- Special framework topic to register for any topic
       HEARTBEAT,-- framework only topic
       REGISTER, -- framework only topic with REQUEST and RESPONSE
       TEST,     -- App 1 TEST
       TEST2,    -- App 2 TEST
       TRIAL,
       DATABASE, -- to Employee or Expenses Database
       OFP       -- to OFP
     );

  -- Extender of topic.  Normal or Request/Response combination.
  type Extender_Type
  is ( FRAMEWORK, -- framework only topic
       DEFAULT,   -- general message that can be consumed by multiple components
       TABLE,     -- table to pass to OFP
       KEYPUSH,   -- displayed page and key to pass to OFP
       REQUEST,   -- request portion of Request/Response pair of messages
       RESPONSE,  -- response to Request message
       CHANGEPAGE -- change displayed page on CDU
     );

  -- Combination of topic and the extension to form the complete identifier
  type TopicIdType
  is record
    Topic : Id_Type;
    Ext   : Extender_Type;
  end record;

  -- A constant identifying the NONE, DEFAULT topic
  Empty
  : constant TopicIdType
  := ( Topic => NONE,
       Ext   => DEFAULT );

  type CallbackType --EntryPointType
  -- Callback to execute an Event Driven Topic Activation of a participant
  -- component
  is access procedure
 -- ( TopicId : in TopicIdType
    -- Identifier of any topic causing the component of the process to be run.
    -- A null value means execute the Main entry point of the component.
  ( Topic : in Boolean := False
  );

  -- Allowed topic pairings of the configuration of applications
  -- Note: Each time a topic Id is added, the count and list
  --       below need to be updated.
  type TopicIdsArrayType
  is array (1..13) of TopicIdType;

  type TopicIdsType
  is record
    Count : Integer; -- Number of allowed topics in the
                     --  configuration of applications
    List  : TopicIdsArrayType;
  end record;

  TopicIds : TopicIdsType;

  procedure Initialize;

end Topic;
