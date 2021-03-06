
with Component;
with CStrings;
with Library;
with NamedPipe;
with NamedPipeNames;
with ReceiveInterface;
with Remote;
with System;
with Text_IO;
with Topic;
with Unchecked_Conversion;

-- Index and the Remote App to receive from are specified by the
-- instantiation parameters

package body Receive3 is

  package Int_IO is new Text_IO.Integer_IO( Integer );

--  QueueName : Itf.V_Short_String_Type
--            := ( Count => 12,
--                 Data  => "ReceiveQueue        " );

  Key : Itf.ParticipantKeyType := Component.NullKey;
  -- Component's key returned from Register

  Index : Integer;
  RemoteAppId : Itf.Int8;
  
  ReceiveOpenCallback    : Itf.ReceiveOpenCallbackType;
  ReceiveMessageCallback : Itf.ReceiveCallbackType;

  Connected : Boolean := False; -- whether connected to the pipe
  Start     : Boolean := True;  -- whether need to start a connection

--  recdMessage : Itf.ByteArray(1..500); -- ReceivedMessage
  qMessage    : Itf.BytesType; --VerifyMessage won't allow long messages

--  procedure AnyMessage
--  ( Message : in Itf.MessageType );

--  package DisburseQueue
  -- Instantiate disburse queue for component
--  is new Disburse( QueueName => QueueName'Address,
--                   Periodic  => False,
--                   Universal => System.Null_Address, --AnyMessage'Address,
--                   Forward   => System.Null_Address );

--  function DisburseWrite
  -- Callback to write message to the DisburseQueue
--  ( Message : in Itf.MessageType
--  ) return Boolean;

  ReceiveName : Itf.V_Medium_String_Type
  := ( Count => 2,
       Data  => "R1                                                " );

  Result : Component.RegisterResult;

--  procedure Main -- callback
--  ( Topic : in Boolean := False );
--  procedure ReceiveThread -- callback
--  ( Topic : in Boolean := False
--  );

  function Install
  ( IndexIn  : in Integer;
    RemoteId : in Itf.Int8
  ) return Itf.ParticipantKeyType is

    Digit   : String(1..1);
----    Status  : Library.AddStatus;
    Success : Boolean;

    use type Component.ComponentStatus;
----    use type Library.AddStatus;

    function to_Callback is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Topic.CallbackType );

  begin -- Install

    Index := IndexIn;
    RemoteAppId := RemoteId;

    CStrings.IntegerToString
    ( From    => Index,
      Size    => 1,     -- assuming never more than 9 remote applications
      CTerm   => False, -- no termination NUL for string
      Result  => Digit,
      Success => Success );
    ReceiveName.Data(2..2) := Digit(1..1);

    -- Note: Receive doesn't have a queue since it receives its messages from
    --       its NamedPipe and then queues them to ReceiveInterface.
    Result :=
      Component.RegisterReceive
      ( Name     => ReceiveName,
  --      Callback => to_Callback(Main'Address) ); --, Does it even need a callback?
        Callback => to_Callback(ReceiveThread'Address)
      );
 --       Queue      => System.Null_Address, --DisburseQueue.Location,
 --       QueueWrite => System.Null_Address ); --DisburseWrite'Address );
    if Result.Status = Component.VALID then
 --     DisburseQueue.ProvideWaitEvent( Event => Result.Event );
      Key := Result.Key;
--<< no need for this since incoming messages are just going to get passed along?? >>>
--      RequestTopic.Topic := Topic.ANY;
--      RequestTopic.Ext   := Topic.FRAMEWORK;
--      Status := Library.RegisterTopic( RequestTopic, Result.Key,
--                                       Delivery.CONSUMER,
--                                       to_Callback(Main'Address) );
--      if Status /= Library.SUCCESS then
--        Text_IO.Put_Line( "ERROR: Register of Topic failed" );
--      end if;
    end if;

    return Key;

  end Install;

--  procedure Initialize
  function Initialize
  ( PipeOpen       : in Itf.ReceiveOpenCallbackType;
    ReceiveMessage : in Itf.ReceiveCallbackType
  ) return System.Address is

  begin -- Initialize

    ReceiveOpenCallback    := PipeOpen;
    ReceiveMessageCallback := ReceiveMessage;

return ReceiveThread'Address;
  end Initialize;

--  procedure Main -- callback
--  ( Topic : in Boolean := False
--  ) is

--  begin -- Main

--    Text_IO.Put("in Receive ");
--    Text_IO.Put(ReceiveName.Data(1..2));
--    Text_IO.Put_Line(" callback");

--    loop -- forever

---- if need a forever loop than need to do the event wait separate from queue.
---- however, Receive will just loop waiting for NamedPipe to return a message.
--      DisburseQueue.EventWait; -- wait for event

--      Text_IO.Put(ReceiveName.Data(1..2));
--      Text_IO.Put_Line(" ");

--    end loop;

--  end Main;

  -- Set whether the pipe is connected to reopen the pipe if the remote app
  -- has disconnected.
  -- Note: This will most likely happen if it is terminated.
  --       Then attempting to reopen will allow it to be launched again.
  procedure TreatDisconnected is

  begin -- TreatDisconnected

    if (not Start) and then  --(NamedPipe.PipeClient /= null) and then
                             --  (not NamedPipe.PipeClient.IsConnected)
       not Remote.RemoteConnected(RemoteAppId)
    then
 --     NamedPipe.PipeInfo(2).Connected := False;       <<< do in NamedPipe
 --     NamedPipe.ClosePipes(True); -- close Client pipe  <<< do in NamedPipe
--      Remote.ResetConnected(RemoteAppId);
--      Remote.SetConnected(RemoteAppId,False); --don't need since just checked
text_io.put("Disconnected ");
int_IO.Put(integer(RemoteAppId));
text_io.put_line(" ");
      Remote.SetRegisterAcknowledged(RemoteAppId, False);
      Connected := False;
      Start := True;
      Library.RemoveRemoteTopics(RemoteAppId);
      Text_IO.Put_Line("Reset connected in Receive forever loop");
    end if;

  end TreatDisconnected;

  procedure VerifyMessage
--  ( MsgIn  : in System.Address;
--    InLen  : in Integer;
--    MsgOut : in System.Address;
--    OutLen : out Integer
  ( MsgIn  : in Itf.BytesType;
    MsgOut : out Itf.BytesType
  ) is

    Index  : Integer;
    Length : Integer := MsgIn.Count;
    MsgLen : Integer;
    Size   : Integer;

    use type Itf.Byte;

  begin -- VerifyMessage

    if Length = 0 then
      --return message;
      MsgOut.Count := 0;
      return;
    elsif Length >= Integer(Itf.HeaderSize) then
      -- Enough for a header.  Compare checksum.
      --          ushort crc = CRC.CRC16(message);
      --          byte[] twoBytes = new byte[2];
      --          twoBytes[0] = (byte)(crc >> 8);
      --          twoBytes[1] = (byte)(crc % 256);
      --          if ((twoBytes[0] == message[0]) && (twoBytes[1] == message[1]))
      --          {
 Text_IO.Put("Received CRC");
 Int_IO.Put(Integer(MsgIn.Bytes(1)));
 Int_IO.Put(Integer(MsgIn.Bytes(2)));
 Text_IO.Put_Line(" ");
        -- Get data size.
        Size := Integer(MsgIn.Bytes(14));
        Size := 256 * Size + Integer(MsgIn.Bytes(15));
        MsgLen := Size + Integer(Itf.HeaderSize);

        Index := MsgIn.Count - 1;
        for I in 1..MsgIn.Count loop --(int i = 0; i < message.Length; i++)
          if MsgIn.Bytes(Index) /= 0 then
            Length := Index + 1;
            Exit; -- loop
          end if;
          if (Index + 1) = MsgIn.Count then
            Length := MsgLen;
            Exit; -- loop -- don't remove any more 0s
          end if;
          Index := Index - 1;
        end loop;
  --  else
    --  checksums don't compare
    --  Text_IO.Put_Line("ERROR: Checksums don't compare");
    --  OutLen := 2; -- fail the received message
    --              byte[] msg = new byte[2];
    --                msg[0] = message[0];
    --                msg[1] = message[1];
    --               return msg;
   -- end if;
    else -- message too short for header
      MsgOut.Count := MsgIn.Count;
    end if;
    for I in 1..Length loop
      Int_IO.Put(Integer(MsgIn.Bytes(I)));
      Text_IO.Put(" ");
    end loop;
    Text_IO.Put_Line("");
    if Length >= Integer(Itf.HeaderSize) then
      for I in 1..Length loop
        MsgOut.Bytes(I) := MsgIn.Bytes(I);
        MsgOut.Count := Length;
      end loop;
    else -- return the short message
      MsgOut.Bytes(1..MsgIn.Count) := MsgIn.Bytes(1..MsgIn.Count);
      MsgOut.Count := MsgIn.Count;
    end if;
  end VerifyMessage;

  -- The framework Receive thread to monitor for messages from its
  -- remote application.
--  procedure ReceiveThread is
  procedure ReceiveThread -- callback
  ( Topic : in Boolean := False
  ) is

    Success : Boolean; -- whether write to ReceiveInterface successful
    RecdMessage : Itf.BytesType;

    use type Itf.Byte;

  begin -- ReceiveThread

    Start := True;
    Connected := False;
 --           byte[] recdMessage;
    while (True) loop -- forever
 text_IO.Put_Line("ReceiveThread wait loop");
 
--      if NamedPipe.PipeClient = null then
        -- Open the NamedPipe for Receive from the remote application.
        -- Note: It isn't necessary to check whether the pipe has been created
        --       because that is done before threads begin running.
        if Start and then not Connected then
text_io.put_line("to invoke the OpenReceivePipe callback");
delay(0.25); -- to allow text output
  --      Connected := NamedPipe.OpenReceivePipe;
--          Connected := ReceiveOpenCallback(RemoteAppId);
--try calling directly -- problem trying to pass RemoteAppId when OpenReceivePipe
--                        doesn't have a parameter???
          Connected := NamedPipe.OpenReceivePipe(3);
text_io.put("returned from the OpenReceivePipe callback");
if Connected then      
text_io.Put_Line(" with Connected");
else
text_io.Put_Line(" with NOT Connected");
end if;
          Start := not Connected; --False;
if Start then      
text_io.Put_Line("Start True");
else
text_io.Put_Line("Start False");
end if;
        end if;
        if Connected then
          Text_IO.Put("waiting in ReceiveThread ");
          Text_IO.Put_Line--( NamedPipe.PipeInfo(2).Name);
            (String(NamedPipeNames.NamedPipeName.List(Index).rPipeName));
        end if;
 --     end if;

      TreatDisconnected;

      if Connected then -- waiting for message

 --       RecdMessage := --NamedPipe.ReceiveMessage; --<< need to change to return count
                                                 --   to set range in recdMessage >>
                                                 -- and set recdMessageLength
        ReceiveMessageCallback(3, RecdMessage);
Text_IO.Put("Receive after ReceiveMessageCallback ");
Int_IO.Put(Integer(RecdMessage.Count));
Text_IO.Put_Line(" ");

        if RecdMessage.Count > 0 then
          VerifyMessage( RecdMessage, --'Address,
      --                 recdMessageLength,
                         qMessage ); --'Address,
      --                 qMessageLength );
          if qMessage.Count = 4 and then qMessage.Bytes(1) = 0 and then
             qMessage.Bytes(2) = 0 and then qMessage.Bytes(3) = 0 and then
             qMessage.Bytes(4) = 0
          then -- disconnected
            null;
          else
            Success := ReceiveInterface.DisburseWrite(qMessage);
          end if;
        end if;

      end if; -- Connected
delay(0.25); -- to delay next loop cycle

    end loop; -- forever

  end ReceiveThread;

end Receive3;
