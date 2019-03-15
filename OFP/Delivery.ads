
with Component;
with Itf;
with Topic;

package Delivery is

  type DistributionType
  is ( CONSUMER,
       PRODUCER
     );

  procedure Initialize;
  -- Initialize Delivery package

  procedure Publish
  ( Message : in Itf.MessageType );
  -- Re-Publish message received from Remote via ReceiveInterface

  procedure Publish
  ( RemoteAppId : in Itf.Int8;
    Message     : in out Itf.MessageType );
  -- Publish message to Remote such as Register Request

  procedure Publish
  ( TopicId      : in Topic.TopicIdType;
    ComponentKey : in Itf.ParticipantKeyType;
    Message      : in String );
  -- Publish local message except for Response message

  procedure Publish
  ( TopicId      : in Topic.TopicIdType;
    ComponentKey : in Itf.ParticipantKeyType;
    From         : in Itf.ParticipantKeyType;
    Message      : in String );
  -- Publish local Response message to specify the source of Request message

end Delivery;
