
with Disburse;
with Library;
with Remote;
with System;
with Text_IO;
with Unchecked_Conversion;

package body Delivery is

  package Int_IO is new Text_IO.Integer_IO( Integer ); -- for debug

  ReferenceNumber : Itf.Int32; -- ever increasing message reference number

  type QueueCallbackType
  -- Callback to execute a Queue Write
  is access function
  ( Message : in Itf.MessageType
  ) return Boolean;

  function to_Ptr is new Unchecked_Conversion
                         ( Source => System.Address,
                           Target => QueueCallbackType );

  procedure Initialize is
  begin -- Initialize

    ReferenceNumber := 0; -- ever increment for each message

  end Initialize;

  procedure PublishResponseToRequestor
  ( TopicId   : in Topic.TopicIdType;
    Consumers : in out Library.TopicTableType;
    Msg       : in Itf.MessageType
  ) is

    Found : Boolean := False;

    use type System.Address;

  begin -- PublishResponseToRequestor
    for I in 1..Consumers.Count loop
      if Component.CompareParticipants( Msg.Header.To,
                                        Consumers.List(I).ComponentKey )
      then -- return response to the requestor
        Consumers.List(I).ReferenceNumber := 0;
        Found := Component.DisburseWrite( Consumers.List(I).ComponentKey,
                                          Msg );
      end if;
    end loop;

    if not Found then
      Text_IO.Put_Line("ERROR: Delivery couldn't find requestor for response");
    end if;

  end PublishResponseToRequestor;

  -- Remote messages are to be ignored if the From and To components are
  -- the same since this would transmit the message back to the remote app.
  -- Remote messages are only to be forwarded to the To component and not
  -- to all the components of the consumers list since separate messages
  -- are sent by the remote component for each local consumer.
  function Ignore
  ( Message      : in Itf.MessageType;
    ComponentKey : in Itf.ParticipantKeyType
  ) return Boolean is

    Equal : Boolean;

    use type Itf.Int8;

  begin -- Ignore

    Equal := Component.CompareParticipants
             ( Message.Header.From, Message.Header.To);
    if Equal and then Message.Header.To.AppId /= Itf.ApplicationId.Id then
      -- same from and to component and remote message
      return True;
    end if;
    if Message.Header.From.AppId /= Itf.ApplicationId.Id then
      -- remote message; check if consumer component is 'to' participant
      if not Component.CompareParticipants
             ( Message.Header.To, ComponentKey )
      then
        return True;
      end if;
    end if;
    return False;

  end Ignore;

  -- Remote messages are to be ignored if the From and To components are
  -- the same since this would transmit the message back to the remote app.
  -- Remote messages are only to be forwarded to the To component and not
  -- to all the components of the consumers list since separate messages
  -- are sent by the remote component for each local consumer.
  function Ignore
  ( To           : in Itf.ParticipantKeyType;
    From         : in Itf.ParticipantKeyType;
    ComponentKey : in Itf.ParticipantKeyType
  ) return Boolean is

    Equal : Boolean;

    use type Itf.Int8;

  begin -- Ignore

    Equal := Component.CompareParticipants(From, To);
    if Equal and then To.AppId /= Itf.ApplicationId.Id then
      -- same from and to component and remote message
      return True;
    end if;
    if From.AppId /= Itf.ApplicationId.Id and then -- from is remote
       ComponentKey.AppId = Itf.ApplicationId.Id   -- component is local
    then -- remote message; check if consumer component is 'to' participant
      if not Component.CompareParticipants(To, ComponentKey) then
        return True;
      end if;
    end if;
    return False;

  end Ignore;

  procedure Publish
  ( Message : in Itf.MessageType
  ) is

    Consumers : Library.TopicTableType;
    Found     : Boolean;

    use type Itf.Int8;
    use type System.Address;
    use type Topic.Extender_Type;
    use type Topic.Id_Type;

  begin -- Publish

    -- Get the set of consumers of the topic
    Consumers := Library.TopicConsumers(Message.Header.Id);

    if Message.Header.Id.Ext = Topic.REQUEST then
      -- forward the request topic to its consumer
      for I in 1..Consumers.Count loop
        if Message.Header.Id.Topic = Consumers.List(I).Id.Topic then
          -- the only possible consumer of the request topic
          Consumers.List(I).Requestor := Message.Header.From;
          Consumers.List(I).ReferenceNumber := Message.Header.ReferenceNumber;
          Found := Component.DisburseWrite( Consumers.List(I).ComponentKey,
                                            Message );
          if not Found then
            Text_IO.Put
            ("ERROR: remote Request Delivery couldn't find queue for consumer ");
            Int_IO.Put(Integer(Message.Header.From.AppId));
            Text_IO.Put(" ");
            Int_IO.Put(Integer(Message.Header.From.ComId));
            Text_IO.Put(" ");
            Int_IO.Put(Integer(Message.Header.To.AppId));
            Text_IO.Put(" ");
            Int_IO.Put(Integer(Message.Header.To.ComId));
            Text_IO.Put(" Topic ");
            Int_IO.Put(Integer(Topic.Id_Type'pos(Message.Header.Id.Topic)));
            Text_IO.Put(" ");
            Int_IO.Put(Integer(Topic.Extender_Type'pos(Message.Header.Id.Ext)));
            Text_IO.Put_Line(" ");
          else
            return; -- can only be one consumer
          end if;
        end if;
      end loop;
    elsif Message.Header.Id.Ext = Topic.RESPONSE then
      -- forward the response topic to the request publisher
      for I in 1..Consumers.Count loop
        if Message.Header.Id.Topic = Consumers.List(I).Id.Topic and then
           Component.CompareParticipants(Consumers.List(I).ComponentKey,
                                         Message.Header.To)
        then -- found the publisher of the Request
          Found := Component.DisburseWrite( Consumers.List(I).ComponentKey,
                                            Message );
          if not Found then
            Text_IO.Put_Line(
              "ERROR: Remote Response Delivery couldn't find queue for consumer");
          end if;
          Exit; -- loop
        end if;
      end loop;
    else -- Default topic - forward to possible multiple consumers

Text_IO.Put("Delivery of topic ");
Int_IO.Put(Topic.Id_Type'pos(Message.Header.Id.Topic));
Int_IO.Put(Consumers.Count);
Text_IO.Put_Line(" ");
      for I in 1..Consumers.Count loop
Int_IO.Put(Topic.Id_Type'pos(Consumers.List(I).Id.Topic));
Text_IO.Put_Line(" ");

        if Message.Header.Id.Topic = Topic.HEARTBEAT then
          null;
        end if;
        -- Avoid sending topic back to the remote app that transmitted it to
        -- this app or forwarding a remote message that is to be delivered to
        -- a different component.
        if Consumers.List(I).Id.Topic = Message.Header.Id.Topic and then
           Consumers.List(I).Id.Ext = Message.Header.Id.Ext and then
           Ignore(Message.Header.To, Message.Header.From,
                  Consumers.List(I).ComponentKey)
        then
Text_IO.Put("Ignore the topic ");
Int_IO.Put(integer(Message.Header.To.AppId));
Int_IO.Put(integer(Message.Header.From.AppId));
Text_IO.Put_Line(" ");
          null;
        else -- Deliver message to local application by copying to its queue
Text_IO.Put("Deliver the topic ");
int_io.put(integer(Consumers.List(I).Requestor.AppId));
int_io.put(integer(Consumers.List(I).Requestor.ComId));
int_io.put(integer(Itf.ApplicationId.Id));
Text_IO.Put_Line(" ");
          Consumers.List(I).Requestor := Message.Header.From;
          Consumers.List(I).ReferenceNumber := 0;
          if Consumers.List(I).ComponentKey.AppId = Itf.ApplicationId.Id then
            Found := Component.DisburseWrite( Consumers.List(I).ComponentKey,
                                              Message );
            if not Found then
              Text_IO.Put_Line("ERROR: Remote default Delivery couldn't find queue for consumer");
              Int_IO.Put(Integer(Message.Header.From.AppId));
              Text_IO.Put(" ");
              Int_IO.Put(Integer(Message.Header.From.ComId));
              Text_IO.Put(" ");
              Int_IO.Put(Integer(Message.Header.To.AppId));
              Text_IO.Put(" ");
              Int_IO.Put(Integer(Message.Header.To.ComId));
              Text_IO.Put(" Topic ");
              Int_IO.Put(Integer(Topic.Id_Type'pos(Message.Header.Id.Topic)));
              Text_IO.Put(" ");
              Int_IO.Put(Integer(Topic.Extender_Type'pos(Message.Header.Id.Ext)));
              Text_IO.Put_Line(" ");
            end if;
          end if;
        end if; -- Ignore

      end loop;

    end if;

  end Publish; -- (from remote)

  procedure Publish
  ( RemoteAppId : in Itf.Int8;
    Message     : in out Itf.MessageType
  ) is

    Found : Boolean;

--    use type System.Address;

  begin -- Publish

    -- Increment the reference number associated with all new messages
    ReferenceNumber := ReferenceNumber + 1;
    Message.Header.ReferenceNumber := ReferenceNumber;

    -- Forward Message to instance of Transmit to send to the Remote App
    Found := Component.TransmitWrite( RemoteAppId,
                                      Message );

  end Publish;

  procedure Publish
  ( TopicId      : in Topic.TopicIdType;
    ComponentKey : in Itf.ParticipantKeyType;
    Message      : in String
  ) is
  begin -- Publish
    -- forward for treatment
    Publish(TopicId, ComponentKey, Component.NullKey, Message);
  end Publish;

  procedure Publish
  ( TopicId      : in Topic.TopicIdType;
    ComponentKey : in Itf.ParticipantKeyType;
    From         : in Itf.ParticipantKeyType;
    Message      : in String
  ) is

    Consumers : Library.TopicTableType;
    Found     : Boolean;
    Length    : Integer := 0;
    RequestConsumers : Library.TopicTableType;
    RequestTopic : Topic.TopicIdType;
    Msg : Itf.MessageType;

    use type Itf.Int8;
    use type Itf.Int16;
    use type System.Address;
    use type Topic.Extender_Type;

  begin -- Publish

    -- Increment the reference number associated with all new messages
    ReferenceNumber := referenceNumber + 1;

    -- Initialize an instance of a message
    Msg.Header.CRC := 0;
    Msg.Header.Id := TopicId;
    Msg.Header.From := ComponentKey;
    Msg.Header.To := From;
    Msg.Header.ReferenceNumber := ReferenceNumber;
    Found := False;
    for I in 1..Itf.Int16(Message'Length) loop
      Length := Integer(I);
      Msg.Data(Length) := Message(Length);
      Msg.Header.Size := I; -- in case there is no NUL
      if Message(Length) = ASCII.NUL then
        Found := True;
        Msg.Header.Size := I-1;
        exit; -- loop
      end if;
    end loop;
    if not Found then -- need to add trailing NUL in case message sent to C#
      Msg.Data(Length+1) := ASCII.NUL;
    end if;

    -- Get the set of consumers of the topic
    Consumers := Library.TopicConsumers(TopicId);

    RequestTopic := TopicId;
    if TopicId.Ext = Topic.RESPONSE then -- the message has to be delivered
                                         --   to the particular requestor
      -- Get the consumer of the request topic
      RequestTopic.Ext := Topic.REQUEST;
      RequestConsumers := Library.TopicConsumers(RequestTopic);
      if Component.CompareParticipants(Msg.Header.To, Component.NullKey) then
        Text_IO.Put_Line("ERROR: No 'To' address for Response");
        return;
      end if;
      if Msg.Header.To.AppId /= Itf.ApplicationId.Id then
        -- send to remote application
        Publish(Msg.Header.To.AppId, Msg);
        return;
      end if;

      PublishResponseToRequestor(TopicId, Consumers, Msg);

    elsif TopicId.Ext = Topic.REQUEST then -- only one consumer possible
      if Consumers.Count > 0 then
        -- forward request to the lone consumer of request topic
        Msg.Header.To := Consumers.List(1).ComponentKey;
        Consumers.List(1).Requestor := ComponentKey;
        Consumers.List(1).ReferenceNumber := ReferenceNumber;
        if Msg.Header.To.AppId /= Itf.ApplicationId.Id then
          -- send to remote app
          Publish(Msg.Header.To.AppId, Msg);
        else -- forward to local consumer
          Found := Component.DisburseWrite( Consumers.List(1).ComponentKey,
                                            Msg );
          if not Found then
            Text_IO.Put_Line("ERROR: Delivery didn't have queue for request");
          end if;
        end if;
      else
        Text_IO.Put_Line("ERROR: Delivery couldn't find consumer for request");
      end if;

    -- the published topic has to be the Default - can be multiple consumers
    elsif Consumers.Count > 0 then
      for I in 1..Consumers.Count loop
        Msg.Header.To := Consumers.List(I).ComponentKey;

        -- Avoid sending topic back to the remote app that transmitted it to
        -- this app or forwarding a remote message that is to be delivered to
        -- a different component.
        if Ignore(Msg, Consumers.List(I).ComponentKey) then
          null; -- ignore
        else -- publish to local or remote component
          if Msg.Header.To.AppId /= Itf.ApplicationId.Id then
            -- Deliver message to remote application
            Publish(Msg.Header.To.AppId, Msg);
          else -- Deliver message to local application by copying to
            -- consumer's queue
            Consumers.List(I).Requestor := ComponentKey;
            Consumers.List(I).ReferenceNumber := 0;
            Found := Component.DisburseWrite( Consumers.List(I).ComponentKey,
                                              Msg );
            if not Found then
              Text_IO.Put_Line(
                "ERROR: local default Delivery couldn't find queue for consumer");
            end if;
          end if;
        end if; -- Ignore
      end loop;
    else
      Text_IO.Put_Line("ERROR: No Consumers of the topic");
    end if;

  end Publish;

end Delivery;
