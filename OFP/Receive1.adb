
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

package body Receive1 is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  Key : Itf.ParticipantKeyType := Component.NullKey;
  -- Component's key returned from Register

  Index : Integer;
  RemoteAppId : Itf.Int8;
  
  ReceiveOpenCallback    : Itf.ReceiveOpenCallbackType;
  ReceiveMessageCallback : Itf.ReceiveCallbackType;

  Connected : Boolean := False; -- whether connected to the pipe
  Start     : Boolean := True;  -- whether need to start a connection

  qMessage    : Itf.BytesType; -- VerifyMessage won't allow long messages

  ReceiveName : Itf.V_Medium_String_Type
  := ( Count => 2,
       Data  => "R1                                                " );

  Result : Component.RegisterResult;

  function Install
  ( IndexIn  : in Integer;
    RemoteId : in Itf.Int8
  ) return Itf.ParticipantKeyType is

    Digit   : String(1..1);
    Success : Boolean;

    use type Component.ComponentStatus;

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
    --       its NamedPipe thread and then queues them to ReceiveInterface.
    Result :=
      Component.RegisterReceive
      ( Name     => ReceiveName,
        Callback => to_Callback(ReceiveThread'Address)
      );
    if Result.Status = Component.VALID then
      Key := Result.Key;
    end if;

    return Key;

  end Install;

  function Initialize
  ( PipeOpen       : in Itf.ReceiveOpenCallbackType;
    ReceiveMessage : in Itf.ReceiveCallbackType
  ) return System.Address is

  begin -- Initialize

    ReceiveOpenCallback    := PipeOpen;
    ReceiveMessageCallback := ReceiveMessage;

    return ReceiveThread'Address;

  end Initialize;

  -- Set whether the pipe is connected to reopen the pipe if the remote app
  -- has disconnected.
  -- Note: This will most likely happen if it is terminated.
  --       Then attempting to reopen will allow it to be launched again.
  procedure TreatDisconnected is

  begin -- TreatDisconnected

    if not Start and then
       not Remote.RemoteConnected(RemoteAppId)
    then
      Remote.SetRegisterAcknowledged(RemoteAppId, False);
      Connected := False;
      Start := True;
      Library.RemoveRemoteTopics(RemoteAppId);
      Text_IO.Put_Line("Reset connected in Receive forever loop");
    end if;

  end TreatDisconnected;

  procedure VerifyMessage
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
      MsgOut.Count := 0;
      return;
    elsif Length >= Integer(Itf.HeaderSize) then
      -- Enough for a header.  Compare checksum.
    --declare
    --  CRC      : Itf.Word;
    --  TwoBytes : Itf.Bytes(1..2);
    --begin
     -- CRC := CRC.CRC16(MsgIn);
    --  TwoBytes(1) := Itf.Byte(CRC >> 8); -- need Ada shift
    --  TwoBytes(2) := Itf.Byte(CRC mod 256);
    --  if TwoBytes(1) = Message(1) and then TwoBytes(2) = Message(2)
    --  then
 Text_IO.Put("Received CRC");
 Int_IO.Put(Integer(MsgIn.Bytes(1)));
 Int_IO.Put(Integer(MsgIn.Bytes(2)));
 Text_IO.Put_Line(" ");
          -- Get data size.
--          Size := Integer(MsgIn.Bytes(14));
--          Size := 256 * Size + Integer(MsgIn.Bytes(15));
          Size := Integer(MsgIn.Bytes(15));
          Size := 256 * Size + Integer(MsgIn.Bytes(16));
          MsgLen := Size + Integer(Itf.HeaderSize);

          Index := MsgIn.Count - 1;
          for I in 1..MsgIn.Count loop
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
    --  else --  checksums don't compare
    --    Text_IO.Put_Line("ERROR: Checksums don't compare");
    --    MsgOut.Count := 2; -- fail the received message
    --    MsgOut.Bytes(1) := Message(1);
    --    MsgOut.Bytes(2) := Message(2);
    --    return MsgOut;
    --  end if;
    --end;
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
  -- Note: This procedure is named Main in other components.
  procedure ReceiveThread -- callback
  ( Topic : in Boolean := False
  ) is

    Success     : Boolean; -- whether write to ReceiveInterface successful
    RecdMessage : Itf.BytesType;

    use type Itf.Byte;

  begin -- ReceiveThread

    Start     := True;
    Connected := False;

    while (True) loop -- forever
      -- Open the NamedPipe for Receive from the remote application.
      -- Note: It isn't necessary to check whether the pipe has been created
      --       because that is done before threads begin running.
      if Start then
        Connected := NamedPipe.OpenReceivePipe(1); -- where passing that this is
                                                   -- for the first pipe pair
        Start := not Connected;
      end if;

      TreatDisconnected;

      if Connected then -- waiting for message

        ReceiveMessageCallback(1, RecdMessage); -- Receive1 is for first pair

        if RecdMessage.Count > 0 then
          VerifyMessage( RecdMessage,
                         qMessage );
          if qMessage.Count = 4    and then qMessage.Bytes(1) = 0 and then
             qMessage.Bytes(2) = 0 and then qMessage.Bytes(3) = 0 and then
             qMessage.Bytes(4) = 0
          then -- disconnected
            null;
          else
            Success := ReceiveInterface.DisburseWrite(qMessage);
if Success then
  Text_IO.Put_Line("Receive1 returned with Success");
else
  Text_IO.Put_Line("Receive1 returned with Failure");
end if;
          end if;
        end if;

      end if; -- Connected
  --    delay(0.25); -- to delay next loop cycle

    end loop; -- forever

  end ReceiveThread;

end Receive1;
