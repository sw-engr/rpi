
with Component;
with CStrings;
with Delivery;
with Disburse;
with Format;
with Library;
with NamedPipe;
with System;
with Text_IO;
with Topic;
with Unchecked_Conversion;

package body Transmit1 is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  QueueName : Itf.V_Short_String_Type
            := ( Count => 13,
                 Data  => "TransmitQueue       " );

  Key : Itf.ParticipantKeyType := Component.NullKey;
  -- Component's key returned from Register

  Index : Integer;
  RemoteAppId : Itf.Int8;

  TransmitMessageCallback : Itf.TransmitCallbackType;

  RequestTopic : Topic.TopicIdType;

  Connected : Boolean := False; -- whether connected to the pipe
  Start     : Boolean := True;  -- whether need to start a connection

  procedure AnyMessage
  ( Message : in Itf.MessageType );

  package DisburseQueue
  -- Instantiate disburse queue for component
  is new Disburse( QueueName => QueueName'Address,
                   Periodic  => False,
                   Universal => AnyMessage'Address,
                   Forward   => System.Null_Address );

  function DisburseWrite
  -- Callback to write message to the DisburseQueue
  ( Message : in Itf.MessageType
  ) return Boolean;

  TransmitName : Itf.V_Medium_String_Type
  := ( Count => 2,
       Data  => "T1                                                " );

  Result : Component.RegisterResult;

  function Install
  ( IndexIn  : in Integer;
    RemoteId : in Itf.Int8
  ) return Itf.ParticipantKeyType is

    Digit   : String(1..1);
    Status  : Library.AddStatus;
    Success : Boolean;

    use type Component.ComponentStatus;
    use type Library.AddStatus;

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
    TransmitName.Data(2..2) := Digit(1..1);

    Result :=
      Component.RegisterTransmit
      ( Name       => TransmitName,
        RemoteId   => RemoteAppId,
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

  procedure Initialize
  ( TransmitMessage : in Itf.TransmitCallbackType
  ) is

  begin -- Initialize

    TransmitMessageCallback := TransmitMessage;

  end Initialize;

  procedure Main -- callback
  ( Topic : in Boolean := False
  ) is

  begin -- Main

    Connected := False;
    Start := True;

    loop -- forever

      if Start and then not Connected
      then

        Connected := NamedPipe.OpenTransmitPipe(1);
        Start := not Connected;

      end if;

      DisburseQueue.EventWait; -- wait for event

      Text_IO.Put(TransmitName.Data(1..2));
      Text_IO.Put_Line(" ");

    end loop;

  end Main;

  -- Write message to component's queue
  function DisburseWrite
  ( Message : in Itf.MessageType
  ) return Boolean is
  begin -- DisburseWrite
    return DisburseQueue.Write(Message => Message);
  end DisburseWrite;

  -- Convert Topic Id to a String
  function to_Topic( Id : Topic.TopicIdType ) return String is
    Temp : String(1..20) := (others => ' ');
  begin
    case Id.Topic is
      when Topic.NONE  => Temp(1..4) := "NONE";
      when Topic.ANY   => Temp(1..3) := "ANY";
      when Topic.HEARTBEAT => Temp(1..9) := "HEARTBEAT";
      when Topic.REGISTER  => Temp(1..8) := "REGISTER";
      when Topic.TEST  => Temp(1..4) := "TEST";
      when Topic.TEST2 => Temp(1..5) := "TEST2";
      when Topic.TRIAL => Temp(1..5) := "TRIAL";
      when Topic.DATABASE => Temp(1..8) := "DATABASE";
      when Topic.OFP   => Temp(1..3) := "OFP";
    end case;
    case Id.Ext is
      when Topic.FRAMEWORK => Temp(11..19) := "FRAMEWORK";
      when Topic.DEFAULT   => Temp(11..17) := "DEFAULT";
      when Topic.TABLE     => Temp(11..15) := "TABLE";
      when Topic.KEYPUSH   => Temp(11..17) := "KEYPUSH";
      when Topic.REQUEST   => Temp(11..17) := "REQUEST";
      when Topic.RESPONSE  => Temp(11..18) := "RESPONSE";
      when Topic.CHANGEPAGE=> Temp(11..20) := "CHANGEPAGE";
    end case;
    return Temp;
  end to_Topic;

  -- Convert Topic Message to byte array
  procedure ConvertFromTopicMessage
  ( Size      : in Integer; -- total size of message including trailing NUL
    Message   : in Itf.MessageType;
    Converted : in System.Address
  ) is 

    type ByteArray is new Itf.ByteArray(1..Size);

    TransmitMessage : ByteArray;
    for TransmitMessage use at Converted;

    RefNum  : Itf.ByteArray(1..4);
    MsgSize : Itf.ByteArray(1..2);

    function to_Topic
    ( Id : in Topic.Id_Type
    ) return Itf.Byte is
    begin
      return Itf.Byte(Topic.Id_Type'Pos(Id));
    end to_Topic;

    function to_Ext
    ( Ext : in Topic.Extender_Type
    ) return Itf.Byte is
    begin
      return Itf.Byte(Topic.Extender_Type'Pos(Ext));
    end to_Ext;

    function to_Data
    ( Data : in Character
    ) return Itf.Byte is
    begin
      return Itf.Byte(Character'Pos(Data));
    end to_Data;

    function to_Bytes
    ( Data : in Itf.Int16
    ) return Itf.ByteArray is
      TempData  : Integer;
      TempBytes : Itf.ByteArray(1..2);
    begin -- to_Bytes
      TempData := abs(Integer(Data));
      for I in reverse 1..2 loop
        TempBytes(I) := Itf.Byte(TempData mod 256);
        TempData := TempData / 256;
      end loop;
      return TempBytes;
    end to_Bytes;

    function to_Bytes
    ( Size : in Integer;
      Data : in Itf.Int32
    ) return Itf.ByteArray is
      TempData  : Integer;
      TempBytes : Itf.ByteArray(1..Size);
    begin -- to_Bytes
      TempData := abs(Data);
      for I in reverse 1..Size loop
        TempBytes(I) := Itf.Byte(TempData mod 256);
        TempData := TempData / 256;
      end loop;
      return TempBytes;
    end to_Bytes;

    use type Itf.Int16;

  begin -- ConvertFromTopicMessage

    TransmitMessage(1) := 0; -- CRC
    TransmitMessage(2) := 0;
    TransmitMessage(3) := to_Topic(Message.Header.Id.Topic);
    TransmitMessage(4) := to_Ext(Message.Header.Id.Ext);
    TransmitMessage(5) := Itf.Byte(Message.Header.From.AppId);
    TransmitMessage(6) := Itf.Byte(Message.Header.From.ComId);
    TransmitMessage(7) := Itf.Byte(Message.Header.From.SubId);
    TransmitMessage(8) := Itf.Byte(Message.Header.To.AppId);
    TransmitMessage(9) := Itf.Byte(Message.Header.To.ComId);
    TransmitMessage(10) := Itf.Byte(Message.Header.To.SubId);
    -- convert Reference number into 4 bytes 11, 12, 13, 14
    RefNum := to_Bytes(4,Message.Header.ReferenceNumber);
    TransmitMessage(11) := RefNum(1);
    TransmitMessage(12) := RefNum(2);
    TransmitMessage(13) := RefNum(3);
    TransmitMessage(14) := RefNum(4);
    -- convert Size into two 15, 16
    MsgSize := to_Bytes(Message.Header.Size);
    TransmitMessage(15) := MsgSize(1);
    TransmitMessage(16) := MsgSize(2);

    for I in 1..Message.Header.Size loop
      TransmitMessage(Integer(I)+16) :=
        to_Data(Message.Data(Integer(I)));
    end loop;
    TransmitMessage(Size) := 0; -- ASCII.NUL

  end ConvertFromTopicMessage;

  -- Transmit any message to remote application of this instance of component
  procedure AnyMessage
  ( Message : in Itf.MessageType
  ) is

    Success : Boolean;
    Iteration : String(1..4);

  begin -- AnyMessage

    Text_IO.Put("Entered Transmit AnyMessage ");
    Text_IO.Put(TransmitName.Data(1..2));
    Text_IO.Put(" ");
    Int_IO.Put( Integer(Topic.Id_Type'pos(Message.Header.Id.Topic)) );
    Text_IO.Put( to_Topic(Message.Header.Id) );
    Text_IO.Put(" ");
    CStrings.IntegerToString(Message.Header.ReferenceNumber, 4, False,
                             Iteration, Success);
    Text_IO.Put(Iteration(1..4));
    Text_IO.Put(" ");
    Text_IO.Put_Line(Message.Data(1..2));

    if Connected then
      declare -- +1 is for trailing NUL
        Length       : Integer;
        Msg          : Itf.MessageType;
        TopicMessage : Itf.BytesType;
        use type Itf.Int16;
        use type Topic.Id_Type;
      begin
        Length := Integer(Message.Header.Size) + Integer(Itf.HeaderSize);

        if not Library.ValidPairing( Id => Message.Header.Id ) then
            Text_IO.Put("ERROR: Invalid message to transmit ");
            Text_IO.Put_Line(to_Topic(Message.Header.Id));
            return;
        end if;

        if Message.Header.Id.Topic /= Topic.HEARTBEAT then

          ConvertFromTopicMessage
          ( Length+1, -- space for trailing null
            Message,
            TopicMessage.Bytes'Address );

        else -- special message to create a message

          -- Create message to be sent
          Msg := Format.EncodeHeartbeatMessage( RemoteAppId => RemoteAppId );
          Length := Integer(Msg.Header.Size) + Integer(Itf.HeaderSize);

          ConvertFromTopicMessage
          ( Length+1, -- space for trailing null
            Msg,
            TopicMessage.Bytes'Address );

        end if;

        TopicMessage.Count := Length + 1; -- for trailing NUL
        
        -- insert CRC into bytes 1 and 2 after encode it

        TransmitMessageCallback(TopicMessage);

      end;
    end if;

  end AnyMessage;

end Transmit1;
