
with Component;
with Configuration;
with Delivery;
with Itf;
with Topic;

package Library is

  -- A library of registered message topics with their producer
  -- and consumer components.

  -- Possible results of attempt to register a topic
  type AddStatus
  is ( SUCCESS,   -- Topic added to the library
       DUPLICATE, -- Topic already added for the component
       FAILURE,   -- Topic not added
       NOTALLOWED -- Topic not allowed, such as for second consumer of REQUEST
     );

  -- Component data from registration as well as run-time status
  type TopicDataType
  is record
    Id              : Topic.TopicIdType;
    -- complete topic identifier
    ComponentKey    : Itf.ParticipantKeyType;
    -- component that produces the topic
    Distribution    : Delivery.DistributionType;
    -- whether consumed or produced
    fEntry          : Topic.CallbackType; --   EntryPointType;
    -- callback, if any to consume the messages
    Requestor       : Itf.ParticipantKeyType;
    -- component that produced REQUEST topic
    ReferenceNumber : Itf.Int32;
    -- reference number of a REQUEST topic
  end record;

  type TopicTableArrayType
  is array(1..Configuration.MaxApplications*Component.MaxComponents)
  of TopicDataType;

  type TopicTableType
  is record
    Count : Integer;
    -- Number of declared topics of the configuration of applications
    List  : TopicTableArrayType;
  end record;

  -- Data of Remote Request topic
  type TopicListDataType
  is record
    TopicId      : Topic.TopicIdType;
    ComponentKey : Itf.ParticipantKeyType;
  --Requestor    : Itf.ParticipantKeyType;
  end record;

  -- List of topics
  type TopicListTableArrayType
  is array(1..25)
  of TopicListDataType;

  type TopicListTableType
  is record
    Count : Integer;
    List  : TopicListTableArrayType;
  end record;

  procedure Initialize;

  function RegisterTopic
  ( Id           : in Topic.TopicIdType;
    ComponentKey : in Itf.ParticipantKeyType;
    Distribution : in Delivery.DistributionType;
    fEntry       : in Topic.CallbackType
  ) return AddStatus;

  procedure RegisterRemoteTopics
  ( RemoteAppId : in Itf.Int8;
    Message     : in Itf.MessageType
  );

  procedure RemoveRemoteTopics
  ( RemoteAppId : in Itf.Int8
  );

  -- Send the Register Request message to the remote app.
  procedure SendRegisterRequest
  ( RemoteAppId : in Itf.Int8
  );

  function TopicConsumers
  ( Id : in Topic.TopicIdType
  ) return TopicTableType;

  -- Determine if supplied topic is a known pairing.
  function ValidPairing
  ( Id : in Topic.TopicIdType
  ) return Boolean;

end Library;
