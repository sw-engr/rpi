
with App;
with Format;
with Itf;
with System;
with Text_IO;
with Topic;

package body Library is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  -- Library of topic producers and consumers
  TopicTable : TopicTableType;

  type CallbackDataType
  is record
    cEntry : Topic.CallbackType; -- Any entry point to consume the message
  end record;

  type CallbackDataArrayType
  is array(1..Component.MaxComponents) of CallbackDataType;

  type CallbackTableType
  is record
    Count : Integer;
    List  : CallbackDataArrayType;
  end record;

  procedure SendRegisterResponse
  (RemoteAppId : in Itf.Int8);


  procedure Initialize is
  begin -- Initialize
    TopicTable.Count := 0;
  end Initialize;

  -- Add a topic with its component, whether producer or consumer, and entry for consumer
  function RegisterTopic
  ( Id           : in Topic.TopicIdType;
    ComponentKey : in Itf.ParticipantKeyType;
    Distribution : in Delivery.DistributionType;
    fEntry       : in Topic.CallbackType
  ) return AddStatus is

    EntryFound
    : Boolean;

    use type Delivery.DistributionType;
    use type System.Address;
    use type Topic.Extender_Type;
    use type Topic.Id_Type;

  begin -- RegisterTopic

    -- Determine if supplied topic is a known pairing.
    EntryFound := ValidPairing(Id);
    if (not EntryFound) then
      return NOTALLOWED;
    end if;

    -- Determine if a framework topic.  That is, a user component shouldn't be
    -- registering these topics to the Library.
    if (Id.Topic in Topic.NONE..Topic.REGISTER or else
        Id.Ext = Topic.FRAMEWORK) and then
       not App.FrameworkTopicsAllowed
    then
      return NOTALLOWED;
    end if;

    -- Determine if topic has already been added to the library.
    -- Note: A REQUEST message of a particular Topic should only be registered
    --       for one consumer.  Delivery will only route the REQUEST to one
    --       consumer.  That is, REQUEST messages are paired with a RESPONSE
    --       message with only one component to be designated to produce the
    --       RESPONSE.  There can be multiple requestors and the response will
    --       be delivered to the requesting component.
    EntryFound := False;
    for I in 1..TopicTable.Count loop
      if Id.Topic = TopicTable.List(I).Id.Topic then -- topic id already in table
        -- Be sure this new registration isn't for a second request consumer
        if (Id.Ext = TopicTable.List(I).Id.Ext and then
            Id.Ext = Topic.REQUEST and then
            Distribution = Delivery.CONSUMER)
        then
          if not Component.CompareParticipants -- different components
             ( ComponentKey,
               TopicTable.List(I).ComponentKey ) and then
             TopicTable.List(I).Distribution = Delivery.CONSUMER -- 2nd Consumer
          then
            EntryFound := True;
            return NOTALLOWED;
          end if;
        end if;
      end if; -- topic in table
    end loop;

    -- Check that consumer component has a queue
    if Distribution = Delivery.CONSUMER then
      for K in 1..Component.ComponentTable.Count loop
        if Component.CompareParticipants(
             ComponentKey, Component.ComponentTable.List(K).Key)
        then
          if Component.ComponentTable.List(K).Queue = System.Null_Address then
            return NOTALLOWED;
          end if;
        end if;
      end loop;
    end if;

    if not EntryFound then -- add the topic with its component to the table
      declare
        K : Integer := TopicTable.Count + 1;
      begin
        TopicTable.List(K).Id := Id;
        TopicTable.List(K).ComponentKey := ComponentKey;
        TopicTable.List(K).Distribution := Distribution;
        TopicTable.List(K).fEntry := fEntry;
        TopicTable.Count := K;
        return SUCCESS;
      end;
    end if;

    return FAILURE;

  end RegisterTopic;

  procedure RegisterRemoteTopics
  ( RemoteAppId : in Itf.Int8;
    Message     : in Itf.MessageType
  ) is

    Index  : Integer;
    Topics : Library.TopicListTableType;

    use type Itf.Int8;

  begin -- RegisterRemoteTopics

    -- Check if topics from remote app have already been registered.
    for I in 1..TopicTable.Count loop
      if TopicTable.List(I).ComponentKey.AppId = RemoteAppId then
        Text_IO.Put_Line("RegisterRemoteTopics already in table");
        -- Send Response to the remote app again.
        SendRegisterResponse(RemoteAppId);
        return; -- since topicTable already contains entries from remote app
      end if;

    end loop;

    -- Decode Register Request topic.
    Topics := Format.DecodeRegisterRequestTopic(Message);

    -- Add the topics from remote app as ones that it consumes.
    Index := TopicTable.Count + 1;
    for I in 1..Topics.Count loop
      -- Ignore local consumer being returned in Register Request
      if Topics.List(I).ComponentKey.AppId /= Itf.ApplicationId.Id then
        TopicTable.list(Index).Id := Topics.List(I).TopicId;
        Text_IO.Put("RegisterRequest topic");
        Int_IO.Put(Index);
        Int_IO.Put(Topic.Id_Type'pos(TopicTable.List(Index).Id.Topic));
        Int_IO.Put(Topic.Extender_Type'pos(TopicTable.List(Index).Id.Ext));
        Text_IO.Put(" ");
        Int_IO.Put(Index);
        Int_IO.Put(Topic.Id_Type'pos(TopicTable.List(Index).Id.Topic));
        Int_IO.Put(Topic.Extender_Type'pos(TopicTable.List(Index).Id.Ext));
        TopicTable.List(Index).ComponentKey.AppId := Topics.List(I).ComponentKey.AppId;
        TopicTable.List(Index).ComponentKey.ComId := Topics.List(I).ComponentKey.ComId;
        TopicTable.List(Index).ComponentKey.SubId := Topics.List(I).ComponentKey.SubId;
        TopicTable.List(Index).Distribution := Delivery.CONSUMER;
        TopicTable.List(Index).fEntry := null;
        TopicTable.List(Index).Requestor.AppId := Itf.Int8(RemoteAppId);
        TopicTable.List(Index).Requestor.ComId := 0; -- add for Request message
        TopicTable.List(Index).Requestor.SubId := 0; --  sometime
        TopicTable.List(Index).ReferenceNumber := 0;
        Index := Index + 1;
        TopicTable.Count := Index;
      else
        Text_IO.Put("ERROR: Register Request contains local component");
        Int_IO.Put(Integer(Topics.List(I).ComponentKey.AppId));
        Int_IO.Put(Integer(Topics.List(I).ComponentKey.ComId));
        Text_IO.Put(" ");
      end if;
    end loop;

    Text_IO.Put_Line("TopicTable after Decode");

    -- Send Response to the remote app.
    SendRegisterResponse(RemoteAppId);

  end RegisterRemoteTopics;

  procedure RemoveRemoteTopics
  ( RemoteAppId : in Itf.Int8
  ) is

    NewCount : Integer := TopicTable.Count;
    Index    : Integer := TopicTable.Count;
    NewIndex : Integer;

    use type Itf.Int8;

  begin -- RemoveRemoteTopics

    Text_IO.Put("RemoveRemoteTopics count=");
    Int_IO.Put(TopicTable.Count);
    Text_IO.Put(" RemoteAppId");
    Int_IO.Put(Integer(RemoteAppId));
    Text_IO.Put_Line(" ");
    -- Actually working backwards so will only have topics from another
    -- remote app to move up to replace those of the disconnected app.
    for I in 1..TopicTable.Count loop
      if (TopicTable.List(Index).ComponentKey.AppId = RemoteAppId) then
        Text_IO.Put("RemoteTopic in Library table");
        Int_IO.Put(Topic.Id_Type'pos(TopicTable.List(Index).Id.Topic));
        Int_IO.Put(Topic.Extender_Type'pos(TopicTable.List(Index).Id.Ext));
        Text_IO.Put_Line(" ");
        -- Move up any entries that are after this one
        NewIndex := Index;
        for J in Index+1..NewCount loop
          TopicTable.List(NewIndex) := TopicTable.List(J);
          NewIndex := NewIndex + 1;
        end loop;
        NewCount := NewIndex;
      end if;
      Index := Index - 1;
    end loop;
    TopicTable.Count := NewCount;

    Text_IO.Put("TopicTable after Decode");
    Int_IO.Put(TopicTable.Count);
    Text_IO.Put_Line(" ");
    for I in 1..TopicTable.Count loop
      Int_IO.Put(I);
      Int_IO.Put(Topic.Id_Type'pos(TopicTable.List(Index).Id.Topic));
      Int_IO.Put(Topic.Extender_Type'pos(TopicTable.List(Index).Id.Ext));
      Int_IO.Put(Integer(TopicTable.List(I).ComponentKey.AppId));
      Int_IO.Put(Integer(TopicTable.List(I).ComponentKey.ComId));
      Text_IO.Put_Line(" ");
    end loop;

  end RemoveRemoteTopics;

  -- Send the Register Request message to the remote app.  This
  -- message is to contain the topics of the local app for which
  -- there are consumers so that the remote app will forward
  -- any of those topics that it publishes.
  procedure SendRegisterRequest
  ( RemoteAppId : in Itf.Int8
  ) is

    Message : Itf.MessageType;
    TopicConsumers : TopicTableType;

    use type Delivery.DistributionType;
    use type Itf.Int8;
    use type Topic.Extender_Type;
    use type Topic.Id_Type;

  begin -- SendRegisterRequest

    -- Build table of all non-framework topics that have local consumers.
    TopicConsumers.Count := 0;
    for I in 1..TopicTable.Count loop
      if TopicTable.List(I).Id.Topic /= Topic.REGISTER and then
         TopicTable.List(I).Id.Ext /= Topic.FRAMEWORK
      then
        if TopicTable.List(I).Distribution = Delivery.CONSUMER and then
           TopicTable.List(I).ComponentKey.AppId = Itf.ApplicationId.Id
        then
          Text_IO.Put("RegisterRequest");
          Int_IO.Put(Integer(TopicTable.List(I).ComponentKey.AppId));
          Int_IO.Put(Topic.Id_Type'pos(TopicTable.List(I).Id.Topic));
          Int_IO.Put(Topic.Extender_Type'pos(TopicTable.List(I).Id.Ext));
          Text_IO.Put_Line(" ");
          TopicConsumers.Count := TopicConsumers.Count + 1;
          TopicConsumers.List(TopicConsumers.Count) := TopicTable.List(I);
        end if;
      end if;
    end loop;

    -- Build Register Request topic of these topics.
    Message := Format.RegisterRequestTopic(RemoteAppId, TopicConsumers);

    Text_IO.Put_Line("Publish of Register Request");
    Delivery.Publish(RemoteAppId, Message);
    -- if this works then Format doesn't really need to fill in header.
    -- or do a new Publish for this.

  end SendRegisterRequest;

  procedure SendRegisterResponse
  ( RemoteAppId : in Itf.Int8
  ) is

    ResponseMessage : Itf.MessageType;

  begin  -- SendRegisterResponse

    ResponseMessage.Header.CRC := 0;
    ResponseMessage.Header.Id.Topic := Topic.REGISTER;
    ResponseMessage.Header.Id.Ext := Topic.RESPONSE;
    ResponseMessage.Header.From := Component.nullKey;
    ResponseMessage.Header.From.AppId := Itf.ApplicationId.Id;
    ResponseMessage.Header.To := Component.nullKey;
    ResponseMessage.Header.To.AppId := RemoteAppId;
    ResponseMessage.Header.ReferenceNumber := 0;
    ResponseMessage.Header.Size := 0;
    ResponseMessage.Data(1) := ' ';

    Delivery.Publish( RemoteAppId, ResponseMessage );

  end SendRegisterResponse;

  -- Return list of callback consumers
  function Callbacks
  ( Id : in Itf.ParticipantKeyType
  ) return CallbackTableType is

    EntryPoints : CallbackTableType;

    use type Topic.CallbackType;

  begin -- Callbacks

    EntryPoints.Count := 0;
    for I in 1..TopicTable.Count loop
      if ((Component.CompareParticipants(TopicTable.List(I).ComponentKey, Id))
      and then
          (TopicTable.List(I).fEntry /= null))
      then
        EntryPoints.List(EntryPoints.Count).cEntry := TopicTable.List(I).fEntry;
        EntryPoints.Count := EntryPoints.Count + 1;
      end if;
    end loop;
    return EntryPoints;

  end Callbacks;

  -- Return list of consumers of the specified topic
  function TopicConsumers
  ( Id : in Topic.TopicIdType
  ) return TopicTableType is
    --debug
    Heartbeat : Boolean := False;

    TopicConsumers : TopicTableType;

    use type Delivery.DistributionType;
    use type Topic.Extender_Type;
    use type Topic.Id_Type;

  begin -- TopicConsumers

    if (Id.Topic = Topic.HEARTBEAT) then
      Heartbeat := True;
    end if;

    TopicConsumers.Count := 0;
    for I in 1..TopicTable.Count loop
      if ((Id.Topic = TopicTable.List(I).Id.Topic) and then
          (Id.Ext = TopicTable.List(I).Id.Ext))
      then
        if (TopicTable.List(I).Distribution = Delivery.CONSUMER) then
          --  if (heartbeat) then
             --  Console.Write("Consume Heartbeat {0} {1}",
             --       	        topicTable.list[i].component.appId,
             --       	        topicTable.list[i].component.comId);
          --  end if;
          TopicConsumers.Count := TopicConsumers.Count + 1;
          TopicConsumers.List(TopicConsumers.Count) := TopicTable.List(I);
        end if;
      end if;
    end loop;

    return TopicConsumers;

  end TopicConsumers;

  function ValidPairing
  ( Id : in Topic.TopicIdType
  ) return Boolean is

    use type Topic.Id_Type;
    use type Topic.Extender_Type;

  begin -- ValidPairing

    for I in 1..Topic.TopicIds.Count loop
      if ((Id.Topic = Topic.TopicIds.List(I).Topic) and then -- then known
          (Id.Ext = Topic.TopicIds.List(I).Ext)) then        --   topic pairing
        return True;
      end if;
    end loop;
    return False;

  end ValidPairing;

end Library;
