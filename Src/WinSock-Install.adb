
with CStrings;
with TextIO;
with Threads;

separate( WinSock )

procedure Install
( ComponentId  : in Component_Ids_Type;
  Component    : in String;
  RecvCallback : in ReceiveCallbackType
) is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  Digit
  -- Digit of remote component identifier ('1', '2', '3', '4', ...)
  : Character;

  IC
  -- Index into Comm arrays
  : Connection_Count_Type;

  InitialCommCount
  -- Comm.Count upon entry
  : Connection_Count_Type;

  Index
  -- Index into Temp
  : Integer := 0;

  PCAddress
  -- Server IP address
  : DeliveryBytesType;

  Port
  -- Server port id number
  : Natural;

--  Win_Status
  -- Result of WSAStartup call
--  : ExecItf.INT;

  Default_WinSock_Receive_Component_Name
  -- WinSock receive name without digit identifying client application
  : constant Component_Name_Type --Itf.Component_Name_Type
  := "WinSock Receive 00       ";

  Default_WinSock_Server_Accept_Component_Name
  -- WinSock server accept connection name without digit identifying client application
  : constant Component_Name_Type --Itf.Component_Name_Type
  := "WinSock Server Accept 00 ";

  use type ExecItf.INT;
  use type ExecItf.File_Handle;

  function to_Integer is new Unchecked_Conversion -- for debug
                             ( Source => ExecItf.PSOCKADDR,
                               Target => Integer );
  function to_Ptr is new Unchecked_Conversion
                         ( Source => System.Address,
                           Target => ExecItf.PCSTR );
  function to_Callback is new Unchecked_Conversion
                              ( Source => System.Address,
                                Target => Threads.CallbackType );
  function callback_toInt is new Unchecked_Conversion
                                 ( Source => ReceiveCallbackType,
                                   Target => Integer );

begin -- Install

  -- Reinitialize for a new search for matching components.
  Delivery_Table.Last := 0;
  InitialCommCount := Comm.Count;

  -- Fill in server addresses to allow each remote client that supports
  -- WinSock to connect to a known server if the local app supports WinSock.

  declare

    OtherComponent : Component_Ids_Type;
    -- The other component of the matched Pair
    ComId      : Possible_Pairs_Count_Type;
    Index      : Possible_Pairs_Count_Type;
    Indexes    : Delivery_Table_Positions_Type;
    ItemAdded  : Boolean;
    Matched    : Boolean; -- True if Pair matched to Delivery_Table entries
    Pair       : Component_Id_Pair_Type;

  begin

    ComId      := Possible_Pairs_Count_Type(ComponentId);
    Index      := 1;

    FindPair:
    for I in Possible_Pairs_Index_Type'range loop
      ItemAdded := False;
      Pair := Possible_Pair_Indexes(I);
      DeliveryLookup( ComId   => ComponentId,
                      Pair    => Pair,
                      Matched => Matched,
                      OtherId => OtherComponent,
                      Indexes => Indexes);
      if Matched then
        IC := Connection_Count_Type(Index) + InitialCommCount;
        Comm.Data(IC).Pair := Pair;
        Comm.Data(IC).Local_Com := ComponentId;
        if Pair(1) = ComponentId then
          Comm.Data(IC).Receive_Callback := RecvCallback;
          Comm.Data(IC).Remote_Com := Pair(2);
        else -- Pair(2) = ComponentId
          Comm.Data(IC).Receive_Callback := RecvCallback;
          Comm.Data(IC).Remote_Com := Pair(1);
         end if;
         Comm.Data(IC).DeliveryPosition := Indexes;

        -- display possible pair 
        declare
          Text : Itf.V_80_String_Type;
        begin
          Text.Data(1..28) := "Items added - Possible_Pairs";
          Text := TextIO.Concat( Text.Data(1..28), Integer(IC) );
          Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(Pair(1)) );
          Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(Pair(2)) );
          Text := TextIO.Concat( Text.Data(1..Text.Count), "Comm.Data" );
          Text := TextIO.Concat( Text.Data(1..Text.Count),
                                 Integer(Comm.Data(IC).Local_Com) );
          Text := TextIO.Concat( Text.Data(1..Text.Count),
                                 Integer(Comm.Data(IC).Remote_Com) );
          Text := TextIO.Concat( Text.Data(1..Text.Count),
                                 callback_toInt(Comm.Data(IC).Receive_Callback) );
          TextIO.Put_Line(Text);
        end;

        ItemAdded := True;
        Comm.Count := Comm.Count + 1;

      end if; -- Matched

      exit when Index = Possible_Pairs_Index_Type'last or else
                ( Possible_Pair_Indexes(I)(1) > ComponentId and then
                  Possible_Pair_Indexes(I)(2) > ComponentId );
      
      if ItemAdded then
        Index := Index + 1;
      end if;
    end loop FindPair; -- for I in range
  end;

  -- Finish initialize of communication array.
  -- Notes:
  --   The array has been set to null when declared.  The Comm.Link Transmit
  --   Socket will be filled in when a connection is accepted.

  declare
    CIndex : Possible_Pairs_Count_Type; -- Client/Receive index
    SIndex : Possible_Pairs_Count_Type; -- Server/Transmit index
  begin
    for I in InitialCommCount+1..Comm.Count loop
      CIndex := Possible_Pairs_Count_Type(
                  Comm.Data(Connection_Count_Type(I)).DeliveryPosition(2));
      SIndex := Possible_Pairs_Count_Type(
                  Comm.Data(Connection_Count_Type(I)).DeliveryPosition(1));
      Port := Delivery_Table.List(Delivery_Table_Count_Type(CIndex)).PortClient;
      PCAddress := Delivery_Table.List(Delivery_Table_Count_Type(CIndex)).PCAddress;
      Comm.Link(I).Receive.Socket.Data.SIn_Family :=
        ExecItf.AF_INET; -- Internet address family
      Comm.Link(I).Receive.Socket.Data.SIn_Port :=
        ExecItf.htons(ExecItf.USHORT(Port));
      Comm.Link(I).Receive.Socket.Data.SIn_Addr :=
        ExecItf.inet_addr(to_Ptr(PCAddress.Bytes'Address));
      Comm.Link(I).Receive.Socket.Addr :=
        to_ac_SOCKADDR_t(Comm.Link(I).Receive.Socket.Data'address);
      -- Note: The Server/Transmit index is that of the 2nd DeliveryPosition.
      --       However, setting the Port continues to use the Client/Receive
      --       index since it uses the .PortServer selection.  That is, the
      --       other half of the pair of ports that are reversed in the Delivery
      --       file since the first of the pair is the Client/Receive port and
      --       the second is the Server/Transmit port.
      -- Note: The Transmit socket will be modified when the connection is accepted.
      Port := Delivery_Table.List(Delivery_Table_Count_Type(CIndex)).PortServer;
      PCAddress := Delivery_Table.List(Delivery_Table_Count_Type(SIndex)).PCAddress;
      Comm.Link(I).Transmit.Socket.Data.SIn_Family :=
        ExecItf.AF_INET; -- Internet address family
      Comm.Link(I).Transmit.Socket.Data.SIn_Port :=
        ExecItf.htons(ExecItf.USHORT(Port));
      Comm.Link(I).Transmit.Socket.Data.SIn_Addr :=
        ExecItf.inet_addr(to_Ptr(PCAddress.Bytes'Address));
      Comm.Link(I).Transmit.Socket.Addr :=
        to_ac_SOCKADDR_t(Comm.Link(I).Transmit.Socket.Data'address);
      declare
        Text : Itf.V_80_String_Type;
      begin
        Text.Data(1..28) := "Comm.Link for Receive Socket";
        Text := TextIO.Concat( Text.Data(1..28), Integer(I) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), "SIn_Port" );
        Text := TextIO.Concat( Text.Data(1..Text.Count),
                               Integer(Comm.Link(I).Receive.Socket.Data.SIn_Port) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), "SIn_Addr" );
        Text := TextIO.Concat( Text.Data(1..Text.Count),
                               Integer(Comm.Link(I).Receive.Socket.Data.SIn_Addr) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), "Addr" );
        Text := TextIO.Concat( Text.Data(1..Text.Count),
                               to_Integer(Comm.Link(I).Receive.Socket.Addr) );
        TextIO.Put_Line( Text );
      end;
      declare
        Text : Itf.V_80_String_Type;
        IPAddr : Itf.ByteArray(1..4);
        for IPAddr use at Comm.Link(I).Receive.Socket.Data.SIn_Addr'address;
      begin
        Text.Count := 8;
        Text.Data(1..8) := "SIn_Addr";
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(1)) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(2)) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(3)) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(4)) );
        TextIO.Put_Line( Text );
      end;
      declare
        Text : Itf.V_80_String_Type;
      begin
        Text.Data(1..29) := "Comm.Link for Transmit Socket";
           --              1234567890123456789012345678
        Text := TextIO.Concat( Text.Data(1..29), Integer(I) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), "SIn_Port" );
        Text := TextIO.Concat( Text.Data(1..Text.Count),
                               Integer(Comm.Link(I).Transmit.Socket.Data.SIn_Port) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), "SIn_Addr" );
        Text := TextIO.Concat( Text.Data(1..Text.Count),
                               Integer(Comm.Link(I).Transmit.Socket.Data.SIn_Addr) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), "Addr" );
        Text := TextIO.Concat( Text.Data(1..Text.Count),
                               to_Integer(Comm.Link(I).Transmit.Socket.Addr) );
        TextIO.Put_Line( Text );
      end;
      declare
        Text : Itf.V_80_String_Type;
        IPAddr : Itf.ByteArray(1..4);
        for IPAddr use at Comm.Link(I).Transmit.Socket.Data.SIn_Addr'address;
      begin
        Text.Count := 8;
        Text.Data(1..8) := "SIn_Addr";
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(1)) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(2)) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(3)) );
        Text := TextIO.Concat( Text.Data(1..Text.Count), Integer(IPAddr(4)) );
        TextIO.Put_Line( Text );
      end;
      declare
        Text : Itf.V_80_String_Type;
        Byte_Data : Itf.ByteArray(1..24);
        for Byte_Data use at Comm.Link(I).Transmit.Socket'address;
      begin
        Text.Count := 1;
        Text.Data(1..1) := " ";
        for B in 1..12 loop
          Text := TextIO.Concat( Text.Data(1..Text.Count),  Integer(Byte_Data(B)) );
        end loop;
 --       TextIO.Put_Line( Text );
        for B in 13..24 loop
          Text := TextIO.Concat( Text.Data(1..Text.Count),  Integer(Byte_Data(B)) );
        end loop;
        TextIO.Put_Line( Text );
      end;
--    Text_IO.Put("Comm.Link for Receive Socket");
--    Int_IO.put(integer(I));
--    Text_IO.Put_Line(" ");
--    Text_IO.Put("SIn_Port");
--    Int_IO.Put(Integer(Comm.Link(I).Receive.Socket.Data.SIn_Port));
--    Text_IO.Put_Line(" ");
--    Text_IO.Put("SIn_Addr");
--    Int_IO.Put(Integer(Comm.Link(I).Receive.Socket.Data.SIn_Addr));
--    Text_IO.Put_Line(" ");
--    Text_IO.Put("Addr");
--    Int_IO.Put(to_Integer(Comm.Link(I).Receive.Socket.Addr));
--    Text_IO.Put_Line(" ");
--    Text_IO.Put("Comm.Link for Transmit Socket");
--    Int_IO.put(integer(I));
--    Text_IO.Put_Line(" ");
--    Text_IO.Put("SIn_Port");
--    Int_IO.Put(Integer(Comm.Link(I).Transmit.Socket.Data.SIn_Port));
--    Text_IO.Put_Line(" ");
--    Text_IO.Put("SIn_Addr");
--    Int_IO.Put(Integer(Comm.Link(I).Transmit.Socket.Data.SIn_Addr));
--    Text_IO.Put_Line(" ");
--    Text_IO.Put("Addr");
--    Int_IO.Put(to_Integer(Comm.Link(I).Transmit.Socket.Addr));
--    Text_IO.Put_Line(" ");

      Digit := to_Digit(Integer(I));
      Comm.Link(I).Receive.Name := Default_WinSock_Receive_Component_Name;
      Comm.Link(I).Receive.Name(18) := Digit;
      Comm.Link(I).Transmit.Name := Default_WinSock_Server_Accept_Component_Name;
      Comm.Link(I).Transmit.Name(24) := Digit;

    end loop;

  end;

end Install;
