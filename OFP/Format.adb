
with Component;
with CStrings;
with Itf;
with System;
with Text_IO;
with Topic;

package body Format is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  HeartbeatIteration : Integer := 0;

  procedure Initialize is
  begin -- Initialize
    null;
  end Initialize;

  function DecodeHeartbeatMessage
  ( Message     : in Itf.MessageType;
    RemoteAppId : in Itf.Int8
  ) return Boolean is

    I : CStrings.StringOffsetType;
    -- Index into string
    J : CStrings.CompareResultType;
    -- 0 if two strings compare
    L : CStrings.StringOffsetType;
    -- Length of substring

    Msg
    : CStrings.StringType := Message.Data'Address;

    use type Itf.Int16;
    use type Topic.Extender_Type;
    use type Topic.Id_Type;

  begin -- DecodeHeartbeatMessage

    if Message.Header.Id.Topic /= Topic.HEARTBEAT or else
       Message.Header.Id.Ext /= Topic.FRAMEWORK
    then
      Text_IO.Put_Line("Heartbeat message Topic invalid ");
      return False;
    end if;

    -- assuming rest of header is ok
    if Message.Header.Size /= 15 then
      Text_IO.Put("Heartbeat message has a size other than 15 ");
      Int_IO.Put(Integer(Message.Header.Size));
      Text_IO.Put_Line(" ");
      return False;
    end if;

    -- Find first delimiter, if any.
    I := CStrings.IndexOf1(Msg, '|');
    L := 0;
    if I > 0 then -- delimiter found
      -- Is substring prior to delimiter the message id?
      declare
        SubString1
        -- String where NUL will be located at position corresponding to '|'
        : String(1..I);
        Heartbeat : String(1..10);
      begin
        SubString1 := CStrings.Substring(Msg, 1, I-1); -- string prior to '|'
        SubString1(I) := ASCII.NUL;
        Heartbeat(1..9) := "Heartbeat";
        Heartbeat(10) := ASCII.NUL;
        J := CStrings.Compare(Substring1'Address, Heartbeat'Address, False);
        if J /= 0 then
          -- miscompare
          return False; -- not Heartbeat message
        end if;
      end;
    else
      return False; -- not Heartbeat message
    end if;

    -- Heartbeat message
    L := Integer(Message.Header.Size) - I + 1; -- where I is location of the '|'
    declare
      SubString1 : String(1..L);
      -- String where NUL will be located at position corresponding to '|'
      Msg1 : CStrings.StringType := CStrings.AddToAddress(Msg,I);
    begin

      SubString1 := CStrings.Substring(Msg1, 1, L-1);
      SubString1(L) := ASCII.NUL;
      I := CStrings.IndexOf1(SubString1'Address,'|');

      declare
        Numeric    : String(1..I);
        SubString2 : String(1..SubString1'Length-I+1);
        Field      : Integer;
        Result     : Boolean;
        Msg2       : CStrings.StringType := CStrings.AddToAddress(Msg1,I);
      begin

        Numeric := CStrings.Substring(SubString1'Address, 1, I-1);
        Numeric(I) := ASCII.NUL;
        L := SubString1'Length - I -1;
        CStrings.TryParse(Numeric'Address, Numeric'Length, Field, Result);
        if not Result then
          return False;
        end if;
        if Field /= Integer(remoteAppId) then -- 1st field not as expected
          return False;
        end if;

        -- Get "to" app id
        SubString2 := CStrings.SubString(Msg2, 1, L+1);
        SubString2(L) := ASCII.NUL;
        I := CStrings.IndexOf1(SubString2'Address,'|');
        Numeric := CStrings.Substring(SubString2'Address, 1, I-1);
        Numeric(I) := ASCII.NUL;
        L := SubString1'Length - I -1;
        CStrings.TryParse(Numeric'Address, Numeric'Length, Field, Result);
        if not Result then
          return False;
        end if;
        if Field /= Integer(Itf.ApplicationId.Id) then -- 2nd field not as expected
          return False;
        end if;

        -- Get Heartbeat Iteration.  Otherwise ignore it for now.
--        declare
--          SubString3 : String(1..SubString2'Length-I);--width with up to | removed
--          Msg3 : CStrings.StringType := CStrings.AddToAddress(Msg2,I);
--        begin
--          SubString3 := CStrings.SubString(Msg3, 1, L+1);
--        end;
      end;
    end;

    return True;

  end DecodeHeartbeatMessage;

  function EncodeHeartbeatMessage
  ( RemoteAppId : in Itf.Int8
  ) return Itf.MessageType is

    Success : Boolean;
    Id      : String(1..2);

    Message : Itf.MessageType; -- message to be returned

    Msg : String(1..25) := (others => ASCII.NUL); -- enough space for Data

    for Msg use at Message.Data'address;

  begin -- EncodeHeartbeatMessage

    Msg(1..10) := "Heartbeat|";
    CStrings.IntegerToString( Integer(Itf.ApplicationId.Id), 1, True, Id, Success );
    Msg(11) := Id(1);
    Msg(12..12) := "|";
    CStrings.IntegerToString( Integer(RemoteAppId), 1, True, Id, Success );
    Msg(13) := Id(1);
    Msg(14..14) := "|";
    CStrings.IntegerToString( HeartbeatIteration, 1, True, Id, Success );
    Msg(15) := Id(1);

    Message.Header.CRC := 0;
    Message.Header.Id.Topic := Topic.HEARTBEAT;
    Message.Header.Id.Ext := Topic.FRAMEWORK;
    Message.Header.From.AppId := Itf.ApplicationId.Id;
    Message.Header.From.ComId := 0;
    Message.Header.From.SubId := 0;
    Message.Header.To.AppId := RemoteAppId;
    Message.Header.To.ComId := 0;
    Message.Header.To.SubId := 0;
    Message.Header.ReferenceNumber := 0;
    Message.Header.Size := 15;

    return Message;

  end EncodeHeartbeatMessage;

  function DecodeRegisterRequestTopic
  ( Message : in Itf.MessageType
  ) return Library.TopicListTableType is

    Count : Integer;
    Size  : Integer;
    Index : Integer;
    I     : Integer;

    TopicData : Library.TopicListTableType;

    Msg : String(1..Integer(Message.Header.Size)+1); -- +1 for trailing NUL
    for Msg use at Message.Data'Address;

  begin -- DecodeRegisterRequestTopic

    -- Extract size from the message
    Count := (Integer(Message.Header.Size) + 1) / 5; -- bytes per item

    -- Extract topics from the message
    TopicData.Count := 0;
    Size := Integer(Message.Header.Size);
    I := 1;
    Index := 1;

    while Size > 0 loop
      declare
        Id : Topic.Id_Type;
        for Id use at Msg(I)'Address;
        Ext : Topic.Extender_Type;
        for Ext use at Msg(I+1)'Address;
        AId : Itf.Int8;
        for AId use at Msg(I+2)'Address;
        CId : Itf.Int8;
        for CId use at Msg(I+3)'Address;
        SId : Itf.Int8;
        for SId use at Msg(I+4)'Address;
      begin
        TopicData.List(Index).TopicId.Topic := Id;
        TopicData.List(Index).TopicId.Ext := Ext;
        TopicData.List(Index).ComponentKey.AppId := AId;
        TopicData.List(Index).ComponentKey.ComId := CId;
        TopicData.List(Index).ComponentKey.SubId := SId;
      end;
      Index := Index + 1;
      TopicData.Count := TopicData.Count + 1;
      I := I + 5;
      Size := Size - 5;
    end loop;

    return TopicData;

  end DecodeRegisterRequestTopic;

  function RegisterRequestTopic
  ( AppId     : in Itf.Int8;
    Consumers : in Library.TopicTableType
  ) return Itf.MessageType is

    Index : Integer;
    Key : Itf.ParticipantKeyType;

    Message : Itf.MessageType;

    Msg : String(1..200); -- sufficient size
    for Msg use at Message.Data'Address;

    use type Topic.Id_Type;

  begin -- RegisterRequestTopic

    Key.AppId := Itf.ApplicationId.Id;
    Key.ComId := 0; -- for
    Key.SubId := 0; --   Framework

    Message.Header.CRC := 0;
    Message.Header.Id.Topic := Topic.REGISTER;
    Message.Header.Id.Ext := Topic.REQUEST;
    Message.Header.From := Key;
    Key.AppId := Itf.Int8(AppId);
    Message.Header.To := Key;
    Message.Header.ReferenceNumber := 0;

    Index := 1;
    for I in 1..Consumers.Count loop

      if Consumers.List(I).Id.Topic /= Topic.ANY and then      -- don't
         Consumers.List(I).Id.Topic /= Topic.REGISTER and then --  include
         Library.ValidPairing(Consumers.List(I).Id)
      then
        declare
          Id : Topic.Id_Type;
          for Id use at Msg(Index)'Address;
          Ext : Topic.Extender_Type;
          for Ext use at Msg(Index+1)'Address;
          AId : Itf.Int8;
          for AId use at Msg(Index+2)'Address;
          CId : Itf.Int8;
          for CId use at Msg(Index+3)'Address;
          SId : Itf.Int8;
          for SId use at Msg(Index+4)'Address;
        begin
          Id := Consumers.List(I).Id.Topic;
          Ext := Consumers.List(I).Id.Ext;
          AId := Consumers.List(I).ComponentKey.AppId;
          CId := Consumers.List(I).ComponentKey.ComId;
          SId := Consumers.List(I).ComponentKey.SubId;
        end;
        Index := Index + 5;
      else
        Text_IO.Put_Line("RegisterRequestTopic Invalid Pairing");
      end if;
    end loop;
    Msg(Index) := ASCII.NUL; -- append terminating NUL

    Message.Header.Size := Itf.Int16(Index-1);

    return Message;

  end RegisterRequestTopic;

end Format;
