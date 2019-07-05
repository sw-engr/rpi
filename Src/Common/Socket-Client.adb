
with Delivery;
with ExecItf;
with TextIO;
with Text_IO;

package body Socket.Client is

-- child package of Socket

  package Int_IO is new Text_IO.Integer_IO( Integer );

  function Request
  -- Request a Client component pairing
  ( FromName : in String;
    FromId   : in ComponentIdsType;
    ToName   : in String;
    ToId     : in ComponentIdsType
  ) return Boolean is

    Index : Integer;

    MatchIndex : Delivery.LocationType;
    Partner    : Delivery.LocationType;

    IPAddress  : Delivery.BytesType;
    Port       : Integer;

    function to_Ptr is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => ExecItf.PCSTR );

    use type Delivery.LocationType;

  begin -- Request

    if Data.SenderData.Count < Threads.MaxComponents then
 --<<< needs to be fixed.  MaxComponents includes receive and transmit threads,
 --    and component threads.  Need a lesser or at least different value. >>>
      Index := Data.SenderData.Count + 1;
      Data.SenderData.Count := Index;

      Data.SenderData.List(Index).FromName.Count := FromName'Length;
      Data.SenderData.List(Index).FromName.Value(1..FromName'Length) := FromName;
      Data.SenderData.List(Index).FromId := FromId;
      Data.SenderData.List(Index).ToName.Count := ToName'Length;
      Data.SenderData.List(Index).ToName.Value(1..ToName'Length) := ToName;
      Data.SenderData.List(Index).ToId := ToId;

      -- Find the partner in DeliveryTable.  This is a validation as
      -- well that the invocating component is correct that the from
      -- and to component ids and names match the table.
      MatchIndex := Delivery.Lookup(FromId, ToId);

      -- Set the IP addresses and the ports.
      if MatchIndex > 0 then
        Partner := Delivery.Partner( MatchIndex );

        -- Fill in Data and address of Data
        Data.SenderData.List(Index).Data.SIn_Family := ExecItf.AF_INET;
        IPAddress := Delivery.IP_Address(Partner); --MatchIndex);
        Data.SenderData.List(Index).Data.SIn_Addr :=
          ExecItf.inet_addr(to_Ptr(IPAddress.Bytes'Address));

        Port := Delivery.Port(Delivery.Other, MatchIndex);
        Data.SenderData.List(Index).Data.SIn_Port :=
          ExecItf.htons(ExecItf.USHORT(Port));

        for I in 1..8 loop
          Data.SenderData.List(Index).Data.SIn_Zero(I) := 0;
        end loop;

        Data.SenderData.List(Index).Addr :=
          to_ac_SOCKADDR_t(Data.SenderData.List(Index).Data'address);

        Text_IO.Put( "MatchIndex " );
        Int_IO.Put( Integer(MatchIndex) );
        Text_IO.Put( " " );
        Text_IO.Put( " ClientPort " );
        Int_IO.Put( Integer(Port) );
        Int_IO.Put( Integer(Data.SenderData.List(Index).Data.SIn_Port) );
        Text_IO.Put_Line( " " );
      else
        Text_IO.Put_Line( "ERROR: From-To not valid for Client" );
        return False;
      end if;

      Text_IO.Put( "SenderData count " );
      Int_IO.Put( FromId );
      Text_IO.Put_Line( " " );

      return True;

    else

      Text_IO.Put_Line( "ERROR: Too many Senders" );
      return False;

    end if;

  end Request;

  function Lookup
  ( FromId : in ComponentIdsType;
    ToId   : in ComponentIdsType
  ) return ComponentIdsType is

  begin -- Lookup

    for I in 1..Data.SenderData.Count loop

      if Data.SenderData.List(I).FromId = FromId and then
         Data.SenderData.List(I).ToId = ToId
      then
        return I;
      end if;

    end loop;
    return 0;

  end Lookup;

  function Transmit
  ( FromId  : in ComponentIdsType;
    ToId    : in ComponentIdsType;
    Message : in Itf.BytesType --String
  ) return Boolean is

    Bytes_Written
    -- Number of bytes sent
    : ExecItf.INT;

    Index : ComponentIdsType;

    Status
    -- 0 means function was successful; -1 otherwise
    : ExecItf.INT;

    function to_PCSTR is new Unchecked_Conversion( Source => System.Address,
                                                   Target => ExecItf.PCSTR );


    use type ExecItf.INT;
    use type ExecItf.SOCKET;

  begin -- Transmit

--    if Message'Length = 0 then
    if Message.Count = 0 then
      return False;
    end if;

    Index := Lookup( FromId, ToId );
    if Index <= 0 then
      return False;
    end if;

    -- The sender always starts up on the localhost.

    -- Create a client socket and connect it to the remote
    Data.SenderData.List(Index).Sender :=
      ExecItf.Socket_Func( AF       => ExecItf.AF_INET,       -- address family
                           C_Type   => ExecItf.SOCK_STREAM,   -- connection-oriented
                           Protocol => ExecItf.IPPROTO_TCP ); -- for TCP
    if Data.SenderData.List(Index).Sender = ExecItf.INVALID_SOCKET then

      declare
        Text : Itf.V_80_String_Type;
      begin
        Text.Data(1..32) := "ERROR: Client Socket NOT created";
        Text := TextIO.Concat( Text.Data(1..32), Integer(Index) );
        TextIO.Put_Line( Text );
      end;
      ExecItf.Display_Last_WSA_Error;
      declare
        Text : Itf.V_80_String_Type;
      begin
        Text.Data(1..9) := "WSA Error";
        Text := TextIO.Concat(Text.Data(1..9),Integer(Index));
        TextIO.Put_Line(Text);
      end;

      WSARestart;

      return False;

    end if;

    -- Connect

    Status :=
      ExecItf.Connect( S       => Data.SenderData.List(Index).Sender,
                       Name    => Data.SenderData.List(Index).Addr,
                       NameLen => Data.SenderData.List(Index).Data'size/8 );
    if Status = 0 then
      Text_IO.Put_Line( "Client Socket Connected to Transmit" );

      -- Send
--      -- Convert string to byte array
      declare
--        Msg : Itf.ByteArray(1..Message'Length);
--        for Msg use at Message'Address;
      begin
        Bytes_Written :=
          ExecItf.Send( S     => Data.SenderData.List(Index).Sender,
                        Buf   => to_PCSTR(Message.Bytes'Address), --Msg'Address),
                        Len   => ExecItf.INT(Message.Count), --Message'Length),
                        Flags => 0 );
      end;
      if Bytes_Written /= ExecItf.INT(Message.Count) then --'Length) then
        Text_IO.Put("ERROR: Socket-Client Message Send failed");
        Int_IO.Put(Integer(Bytes_Written));
        Text_IO.Put(" ");
        Text_IO.Put(Data.SenderData.List(Index).ToName.Value
                      (1..Data.SenderData.List(Index).ToName.Count));
        Int_IO.Put(Integer(Index));
        Int_IO.Put(Integer(Data.SenderData.List(Index).Data.SIn_Port));
        Text_IO.Put_Line(" ");
        ExecItf.Display_Last_WSA_Error;

        return False;

      else -- successful

        declare
          Text : Itf.V_80_String_Type;
        begin
          Text := TextIO.Concat
                  ( "Transmit sent using client socket port",
                    Integer(Data.SenderData.List(Index).Data.SIn_Port) );
          TextIO.Put_Line( Text );
        end;

        -- Close the socket since it will be opened again for the next Transmit
        Status := ExecItf.CloseSocket( S => Data.SenderData.List(Index).Sender );
        Data.SenderData.List(Index).Sender := ExecItf.INVALID_SOCKET;

        return True;

      end if;

    else

      ExecItf.Display_Last_WSA_Error;
      WSARestart;

      Status := ExecItf.CloseSocket( S => Data.SenderData.List(Index).Sender );
      Data.SenderData.List(Index).Sender := ExecItf.INVALID_SOCKET;

      return False;

    end if;

  end Transmit;

end Socket.Client;
