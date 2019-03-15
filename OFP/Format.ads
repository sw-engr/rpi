
with Itf;
with Library;

package Format is

  procedure Initialize;

  function DecodeHeartbeatMessage
  ( Message     : in Itf.MessageType;
    RemoteAppId : in Itf.Int8
  ) return Boolean;

  function DecodeRegisterRequestTopic
  ( Message : in Itf.MessageType
  ) return Library.TopicListTableType;

  function EncodeHeartbeatMessage
  ( RemoteAppId : in Itf.Int8
  ) return Itf.MessageType;

  function RegisterRequestTopic
  ( AppId     : in Itf.Int8;
    Consumers : in Library.TopicTableType
  ) return Itf.MessageType;

 end Format;
