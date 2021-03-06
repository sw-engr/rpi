
with Component;
with Delivery;
with DisburseBytes;
with ExecItf;
with Format;
with Library;
with Remote;
with System;
with Text_IO;
with Topic;
with Unchecked_Conversion;

package body ReceiveInterface is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  QueueName : Itf.V_Short_String_Type
            := ( Count => 19,
                 Data  => "ReceiveIntfaceQueue " );

  Key : Itf.ParticipantKeyType := Component.NullKey;
  -- Component's key returned from Register

  -- List of messages
  type ReceivedMessageArrayType
  is array (1..10) of Itf.MessageType;

  type ReceivedMessageListTableType
  is record
    Count      : Integer; -- number of entries
    NewlyAdded : Integer; -- number not yet Popped
    List       : ReceivedMessageArrayType;
  end record;
--<< won't need newlyadded

  -- Table of received messages
  MsgTable : ReceivedMessageListTableType;

  RequestTopic : Topic.TopicIdType;

  package DisburseQueue
  -- Instantiate disburse queue for the component
  is new DisburseBytes( QueueName => QueueName'Address,
                        Periodic  => False,
                        Universal => System.Null_Address,
                        Forward   => System.Null_Address );

  ReceiveInterfaceName : Itf.V_Medium_String_Type
  := ( Count => 16,
       Data  => "ReceiveInterface                                  " );

  Result : Component.RegisterResult;

  function to_Callback is new Unchecked_Conversion
                              ( Source => System.Address,
                                Target => Topic.CallbackType );

  procedure Main -- Threads callback
  ( T : in Boolean := False );

  -- Install the ReceiveInterface framework package to treat Receive messages
  function Install
  return Itf.ParticipantKeyType is

    Status : Library.AddStatus;

    use type Component.ComponentStatus;
    use type Library.AddStatus;

  begin -- Install

    -- Note: ReceiveInterface is not Transmit but it needs a way to register
    --       its queue as well as have its higher priority assigned.
    Result :=
      Component.RegisterTransmit
      ( Name       => ReceiveInterfaceName,
        RemoteId   => 0, -- not sending to remote app
        Callback   => to_Callback(Main'Address),
        Queue      => DisburseQueue.Location,
        QueueWrite => DisburseWrite'Address );
    if Result.Status = Component.VALID then
      DisburseQueue.ProvideWaitEvent( Event => Result.Event );
      Key := Result.Key;
      RequestTopic.Topic := Topic.ANY;
      RequestTopic.Ext   := Topic.FRAMEWORK;
      Status := Library.RegisterTopic( RequestTopic, Result.Key,
                                       Delivery.CONSUMER,
                                       to_Callback(Main'Address) );
      if Status /= Library.SUCCESS then
        Text_IO.Put_Line( "ERROR: Register of Topic failed" );
      end if;
    end if;

    return Key;

  end Install;

  -- The methods to validate the received message and forward it are below.
  -- These methods execute in the ReceiveInterface thread via the Callback
  -- forever loop started by the event initiated by the signal to end the wait.

  procedure AnnounceError
  ( RecdMessage : in Itf.BytesType
  ) is

    Length    : Integer := RecdMessage.Count;
    I         : Integer := 0;
    ZeroCount : Integer := 0;
    ZeroStart : Integer := 0;

    use type Itf.Byte;

  begin -- AnnounceError

    for J in 1..Length loop
      if RecdMessage.Bytes(J) = 0 then
        ZeroCount := ZeroCount + 1;
      else
        ZeroCount := 0;
        ZeroStart := J;
      end if;
    end loop;
    while Length > 0 loop
      if I > ZeroStart + 28 then
        exit;
      end if;
      if Length >= Integer(Itf.HeaderSize) then
        Text_IO.Put("ERROR: ");
        Int_IO.Put(Integer(recdMessage.Bytes(i)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+1)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+2)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+3)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+4)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+5)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+6)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+7)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+8)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+9)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+10)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+11)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+12)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+13)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+14)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+15)));
        Int_IO.Put(Integer(recdMessage.Bytes(i+16)));
        Text_IO.Put_Line(" ");
        Length := Length - Integer(Itf.HeaderSize);
        I := I + Integer(Itf.HeaderSize);
      else
   --     for J in I+1..Length loop
          -- TEXT_IO.Put("{0} ", recdMessage[j]);
   --     end loop;
   --     TEXT_IO.Put_Line(" ");
        Length := 0;
      end if;
    end loop;

  end AnnounceError;

  -- Copy message into table
  procedure CopyMessage
  ( M           : in Integer;
    RecdMessage : in Itf.BytesType
  ) is

    CRC   : Integer;
    type Unsigned32
    is record
      LowPart  : Itf.Int16;
      HighPart : Itf.Int16;
    end record;
    HiLow : Unsigned32;
    for HiLow use at CRC'Address;

    Index : Integer;
    Size  : Itf.Int16;
    ReferenceNumber : Itf.Int32;

    use type Itf.Int16;

  begin -- CopyMessage

    MsgTable.Count := MsgTable.Count + 1;
    Index := MsgTable.Count;

text_io.Put_Line("CopyMessage");
    CRC := Integer(RecdMessage.Bytes(M+1));
    CRC := 256 * CRC + Integer(RecdMessage.Bytes(M+2));
    MsgTable.List(Index).Header.CRC := HiLow.LowPart;
    MsgTable.List(Index).Header.Id.Topic := Topic.Id_Type'Val(RecdMessage.Bytes(M+3));
    MsgTable.List(Index).Header.Id.Ext := Topic.Extender_Type'Val(RecdMessage.Bytes(M+4));
    MsgTable.List(Index).Header.From.AppId := Itf.Int8(RecdMessage.Bytes(M+5));
    MsgTable.List(Index).Header.From.ComId := Itf.Int8(RecdMessage.Bytes(M+6));
    MsgTable.List(Index).Header.From.SubId := Itf.Int8(RecdMessage.Bytes(M+7));
    MsgTable.List(Index).Header.To.AppId := Itf.Int8(RecdMessage.Bytes(M+8));
    MsgTable.List(Index).Header.To.ComId := Itf.Int8(RecdMessage.Bytes(M+9));
    MsgTable.List(Index).Header.To.SubId := Itf.Int8(RecdMessage.Bytes(M+10));
    ReferenceNumber := Integer(RecdMessage.Bytes(M+11));
    ReferenceNumber := 256 * ReferenceNumber + Integer(RecdMessage.Bytes(M+12));
    ReferenceNumber := 256 * ReferenceNumber + Integer(RecdMessage.Bytes(M+13));
    ReferenceNumber := 256 * ReferenceNumber + Integer(RecdMessage.Bytes(M+14));
    MsgTable.List(Index).Header.ReferenceNumber := ReferenceNumber;
    Size := Itf.Int16(RecdMessage.Bytes(M+15));
    Size := 256 * Size + Itf.Int16(RecdMessage.Bytes(M+16));
text_io.Put("CopyMessage");
int_io.Put(integer(ReferenceNumber));
int_io.Put(integer(size));
text_io.put_line(" ");
    MsgTable.List(Index).Header.Size := Itf.Int16(Size);
    MsgTable.List(Index).Data := (others => ' ');
    for I in 1..Integer(Size) loop
      declare
        Pos  : Integer := Integer(RecdMessage.Bytes(M+I+Integer(Itf.HeaderSize)));
        Item : Character;
        for Item use at Pos'Address;
      begin
        MsgTable.List(Index).Data(I) := Item;
      end;
    end loop;
text_io.put_line("exit from CopyMessage");

  end CopyMessage;

  procedure ParseRecdMessages
  ( RecdMessage : in Itf.BytesType
  ) is

    M    : Integer := 0;
    Id   : Topic.TopicIdType; -- topic;
    Size : Integer;

    use type Itf.Byte;

  begin -- ParseRecdMessages

text_io.Put_Line("ParseRecdMessages");
    while M <= RecdMessage.Count loop
      if (M + Integer(Itf.HeaderSize)) <= RecdMessage.Count then -- space for header
        Id.Topic := Topic.Id_Type'val(RecdMessage.Bytes(M + 3));
        Id.Ext := Topic.Extender_Type'val(RecdMessage.Bytes(M + 4));
        if Library.ValidPairing(Id) then
          -- assuming if Topic Id is valid that the remaining data is as well
          Size := Integer(RecdMessage.Bytes(M + 15)) * 256;  -- 8 bit shift
          Size := Size + Integer(RecdMessage.Bytes(M + 16)); -- data size
text_IO.put("message data size ");
int_io.put(Size);
text_io.Put_Line(" ");
          if (M + Size + Integer(Itf.HeaderSize)) <= RecdMessage.Count then
            -- space for message
            CopyMessage(M, RecdMessage);
          end if;
          M := M + Size + Integer(Itf.HeaderSize);
        end if;
      else -- scan for another message
        for N in M..RecdMessage.Count loop
          Id.Topic := Topic.Id_Type'val(RecdMessage.Bytes(N));
          --                  topic.topic = (Topic.Id)recdMessage[n];
          if (N+1) >= RecdMessage.Count then
            return; -- no space left
          end if;
          --                  topic.ext = (Topic.Extender)recdMessage[n + 1];
          Id.Ext := Topic.Extender_Type'val(RecdMessage.Bytes(N + 1));
          if Library.ValidPairing(Id) then
            M := N;
         --   Console.WriteLine("new valid topic starting {0} {1} {2}",
         --     topic.topic, topic.ext, n);
            exit; -- inner loop
          end if;
        end loop;
      end if;
      exit; -- outer loop
    end loop;

  end ParseRecdMessages;

  -- Determine if 3 or more consecutive heartbeats have been received and
  -- the Register Request has been acknowledged or the needs to be sent.
  procedure TreatHeartbeatMessage
  ( RemoteAppId : in Itf.Int8
  ) is

    Acknowledged : Boolean;
    ConsecutiveValid : Integer
      := Remote.ConsecutiveValidHeartbeats(RemoteAppId);

  begin -- TreatHeartbeatMessage

    Text_IO.Put("TreatHeartbeatMessage ");
    Int_IO.Put(Integer(RemoteAppId));
    Text_IO.Put(" ");
    Int_IO.Put(ConsecutiveValid);
    Text_IO.Put_Line(" ");
    if ConsecutiveValid >= 3 then -- connection established
      Remote.SetConnected(RemoteAppId, True);
      Acknowledged := Remote.RegisterAcknowledged(RemoteAppId);
      if not Acknowledged and then
         (ConsecutiveValid mod 3) = 0
      then -- where only every 3rd time to allow acknowledged to be set
        Library.SendRegisterRequest(RemoteAppId);
      end if;
--    else -- use revised most inclusive method for when to disconnect
--      Remote.Connections(RemoteAppId).Connected := False;
--      Remote.SetConnected(RemoteAppId, False);
    end if;

  end TreatHeartbeatMessage;

  -- Validate any heartbeat message.
  -- Notes: A heartbeat message must identify that it is meant for this
  --        application and originated in the remote application for
  --        which this instantiation of the Receive thread is responsible.
  function HeartbeatMessage
  ( RecdMessage : in Itf.MessageType;
    RemoteAppId : in Itf.Int8
  ) return Boolean is

    HeartbeatMessage : Boolean := False;
    ConsecutiveValid : Integer
      := Remote.ConsecutiveValidHeartbeats(RemoteAppId);

  begin -- HeartbeatMessage

text_IO.Put_Line("HeartbeatMessage");
    HeartbeatMessage := Format.DecodeHeartbeatMessage(RecdMessage, RemoteAppId);
text_IO.Put_Line("HeartbeatMessage return from Format");
    if HeartbeatMessage then
      ConsecutiveValid := ConsecutiveValid + 1;
    else
      ConsecutiveValid := 0;
    end if;
text_IO.Put_Line("HeartbeatMessage to invoke Consecutive...");
    Remote.ConsecutiveValidHeartbeats( RemoteAppId, ConsecutiveValid );

    -- Return whether a Heartbeat message; whether or not valid.
text_IO.Put_Line("HeartbeatMessage return");
    return HeartbeatMessage;

  end HeartbeatMessage;

  -- Non-Heartbeat Messages have to be messages formatted as framework topic
  -- messages.  Otherwise, they will be discarded.  These topic messages will
  -- be forwarded to the component(s) that has/have registered to consume them.
  procedure ForwardMessage
  ( Message : in Itf.MessageType
  ) is

    use type Topic.Extender_Type;
    use type Topic.Id_Type;

  begin -- ForwardMessage

    -- Check if a framework Register message.
    if Message.Header.Id.Topic = Topic.REGISTER then -- Check if acknowledge
text_IO.put_line("Register Message");
      if Message.Header.Id.Ext = Topic.RESPONSE then
        Remote.SetRegisterAcknowledged(Message.Header.From.AppId, True);
      else -- register Request message
--        Size := Message.Header.Size;
--        declare
--        begin
--        var chars = message.data.ToCharArray();
--          while Size > 0 loop
--                        Topic.Id id = (Topic.Id)chars[i];
--                        Topic.Extender ext = (Topic.Extender)chars[i + 1];
--                        size = size - 5;
--                        i = i + 5;
--          end loop;
        Library.RegisterRemoteTopics(Message.Header.From.AppId, Message);
      end if;
    else -- Forward other messages
text_IO.put("Forward Delivery Publish ");
--text_IO.Put(Topic.Id_Type'val(Message.Header.Id.Topic));
int_IO.Put(Topic.Id_Type'pos(Message.Header.Id.Topic));
text_io.Put_Line(" ");
      Delivery.Publish(Message);
    end if;

  end ForwardMessage;

  procedure Main -- callback
  ( T : in Boolean := False
  ) is

--    RecdLength  : Integer;
--    RecdMessage : Itf.ByteArray(1..250); -- do String(1..250)?
    RecdMessage : Itf.BytesType;

  begin -- Main

    Text_IO.Put_Line("in ReceiveInterface callback");

    loop -- forever

  text_IO.Put_Line("ReceiveInterface wait for event");
      DisburseQueue.EventWait; -- wait for event
  text_IO.Put_Line("ReceiveInterface wait satisfied");

      loop -- until queue is empty

 --       DisburseQueue.Read( RecdMessage ); --Count => RecdLength,
                            --Bytes => RecdMessage ); --'Address );
        if DisburseQueue.Unread then

          RecdMessage := DisburseQueue.Read;
Text_IO.Put("ReceiveInterface RecdMessage ");
Int_IO.Put(Integer(RecdMessage.Count));
Text_IO.Put_Line(" ");

--            byte[] recdMessage = new byte[250];
--            recdMessage = circularQueue.Read();
          if RecdMessage.Count > 0 then
            -- message to be converted and treated

          --      string receivedMessage = "";
          --      receivedMessage = streamEncoding.GetString(recdMessage);
            if RecdMessage.Count >= Integer(Itf.HeaderSize) then -- message can have a header
              declare
                TopicId : Topic.TopicIdType;
                Valid   : Boolean;
              begin
                TopicId.Topic := Topic.Id_Type'val(RecdMessage.Bytes(3));
                TopicId.Ext := Topic.Extender_Type'val(RecdMessage.Bytes(4));
 --                   Console.WriteLine("TreatMessage {0} {1}", topic.topic, topic.ext);
                Valid := Library.ValidPairing(TopicId);
                if not Valid then
 --                       Console.WriteLine("ERROR: Received Invalid Topic {0} {1}",
 --                           topicid.topic, topicid.ext);
                  AnnounceError(RecdMessage);

                else -- Convert received message(s) to topic messages.

                  MsgTable.Count := 0;
                  ParseRecdMessages(recdMessage);
                  if msgTable.count > 0 then
                    for M in 1..MsgTable.Count loop
 --                               Console.WriteLine("{0} {1} {2}",
 --                                   msgTable.list[m].header.id.topic,
 --                                   msgTable.list[m].header.id.ext,
 --                                   msgTable.list[m].header.size);
                      declare
                        Msg : Itf.MessageType;
                        for Msg use at MsgTable.List(M)'address;
                        use type Topic.Extender_Type;
                        use type Topic.Id_Type;
                      begin
                        if ((Msg.Header.Id.Topic = Topic.HEARTBEAT) and then
                            (Msg.Header.Id.Ext = Topic.FRAMEWORK))
                        then
text_IO.Put_Line("HeartbeatMessage to be called");
--<<< need to change this back to use MsgTable.List(M)???
                          if HeartbeatMessage(Msg,Msg.Header.From.AppId) then --MsgTable.List(M))) then
text_IO.Put_Line("TreatHeartbeatMessage to be called");
                            TreatHeartbeatMessage(Msg.Header.From.AppId); --RemoteAppId);
text_IO.Put_Line("return from TreatHeartbeatMessage");
--<<< not by remote anymore.  So where to get RemoteAppId?  From Header.From.AppId
                          else
text_IO.Put_Line("SetConnected to be called for False");
                            Remote.SetConnected(Msg.Header.From.AppId,False); --RemoteAppId,False);
                          end if;
                        else
text_IO.Put_Line("ForwardMessage to be called");
                          ForwardMessage(Msg); --MsgTable.List(M));
                        end if;
                      end;
                    end loop;
                  end if; -- MsgTable.Count > 0
                end if; -- valid pairing
              end; -- declare block
            end if; -- Length large enough
     --   else
     --           {
     --               try
     --               {
     --                   Console.WriteLine("ERROR: Received message less than {0} bytes {1}",
     --                       Delivery.HeaderSize, recdMessage.Length);
     --                   AnnounceError(recdMessage);
     --               }
     --               catch
     --               {
     --                   Console.WriteLine("ERROR: Catch of Received message less than {0} bytes {1}",
     --                       Delivery.HeaderSize, receivedMessage.Length);
     --                   if (receivedMessage.Length > 0)
     --                   {
     --                       AnnounceError(recdMessage);
     --                   }
     --               }

      --          }
          end if; -- RecdMessage.Length > 0
        else -- DisburseQueue has no messages to read
      --    Delay(0.250); -- wait a quarter second
          exit; -- the inner loop
        end if; -- DisburseQueue.Unread

      end loop; -- until queue empty

    end loop; -- forever

  end Main;

  -- Write a message to the DisburseQueue from multiple Receive threads
  -- Note: Doing this write will queue the message in the thread of the
  --       particular Receive thread.  The forever loop will then have its
  --       wait signaled to continue and the queue can be read in the thread
  --       of this component to treat the message and deliver it.
  function DisburseWrite
  ( Message : in Itf.BytesType
  ) return Boolean is
  begin -- DisburseWrite
Text_IO.Put("DisburseBytes Write to be done");
Int_IO.Put(Message.Count);
Text_IO.Put_Line(" ");
    return DisburseQueue.Write(Message);
  end DisburseWrite;

end ReceiveInterface;
