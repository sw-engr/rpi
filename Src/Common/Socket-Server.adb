
with CStrings;
with Delivery;
with Interfaces.C;
with System;
with TextIO;
with Text_IO;
with Unchecked_Conversion;

package body Socket.Server is

-- child package of Socket

  package Int_IO is new Text_IO.Integer_IO( Integer );

  procedure Callback
  ( Id : in Integer
  );

  function Request
  -- Request a Server component pairing
  ( FromName     : in String;
    FromId       : in ComponentIdsType;
    ToName       : in String;
    ToId         : in ComponentIdsType;
    RecvCallback : in ReceiveCallbackType
  ) return Boolean is

    Index : Integer;

    MatchIndex : Delivery.LocationType;
    Partner    : Delivery.LocationType;

    IPAddress  : Delivery.BytesType;
    Port       : Integer;
    TDigits    : String(1..2);
    Status
    -- 0 means function was successful; -1 otherwise
    : ExecItf.INT;
    Success    : Boolean;
    ThreadName : String(1..3);

    TransmitResult
    -- Result of Install of Receive with Threads
    : Threads.RegisterResult;

    function to_Callback is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Threads.CallbackType );
    function to_Ptr is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => ExecItf.PCSTR );
    function to_Int is new Unchecked_Conversion
                           ( Source => ExecItf.PSOCKADDR,
                             Target => Integer );

    use type Interfaces.C.Int;
    use type Delivery.LocationType;
    use type ExecItf.SOCKET;
    use type Threads.InstallResult;

  begin -- Request

    if Data.ListenerData.Count < Threads.MaxComponents then
 --<<< needs to be fixed.  MaxComponents includes receive and transmit threads,
 --    and component threads.  Need a lesser or at least different value. >>>
      Index := Data.ListenerData.Count + 1;
      Data.ListenerData.Count := Index;

      Data.ListenerData.List(Index).FromName.Count := FromName'Length;
      Data.ListenerData.List(Index).FromName.Value(1..FromName'Length) := FromName;
      Data.ListenerData.List(Index).FromId := FromId;
      Data.ListenerData.List(Index).ToName.Count := ToName'Length;
      Data.ListenerData.List(Index).ToName.Value(1..ToName'Length) := ToName;
      Data.ListenerData.List(Index).ToId := ToId;
      Data.ListenerData.List(Index).RecvCallback := RecvCallback;

      -- Find the partner in DeliveryTable.  This is a validation as
      -- well that the invocating component is correct that the from
      -- and to component ids and names match the table.
      MatchIndex := Delivery.Lookup(ToId, FromId);

      -- Set the IP addresses and the ports.
      if MatchIndex > 0 then
        Partner := Delivery.Partner( MatchIndex );

        -- Fill in Data and address of Data
        Data.ListenerData.List(Index).Data.SIn_Family := ExecItf.AF_INET;
        IPAddress := Delivery.IP_Address(Partner); --MatchIndex);
        Data.ListenerData.List(Index).Data.SIn_Addr :=
          ExecItf.inet_addr(to_Ptr(IPAddress.Bytes'Address));

        Port := Delivery.Port(Delivery.Other, MatchIndex);
        Data.ListenerData.List(Index).Data.SIn_Port :=
          ExecItf.htons(ExecItf.USHORT(Port));

        for I in 1..8 loop
          Data.ListenerData.List(Index).Data.SIn_Zero(I) := 0;
        end loop;

        Data.ListenerData.List(Index).Addr :=
          to_ac_SOCKADDR_t(Data.ListenerData.List(Index).Data'address);

        Text_IO.Put( "MatchIndex " );
        Int_IO.Put( Integer(MatchIndex) );
        Text_IO.Put( " " );
        Text_IO.Put( " ServerPort " );
        Int_IO.Put( Integer(Port) ); --Delivery.Port(Delivery.Other, Partner)) );
        Int_IO.Put( Integer(Data.ListenerData.List(Index).Data.SIn_Port) );
        Text_IO.Put_Line( " " );
      else
        Text_IO.Put_Line( "ERROR: To-From not valid for Server" );
        return False;
      end if;

      -- Create thread for receive.
      Data.ListenerData.List(Index).ThreadId := Threads.TableCount + 1;
        -- index in table after Install
      ThreadName(1..3) := "R00";
      CStrings.IntegerToString( From    => Index,
                                Size    => 2,
                                CTerm   => False,
                                Result  => TDigits,
                                Success => Success );
      ThreadName(2..3) := TDigits;
      if ThreadName(2) = ' ' then
        ThreadName(2) := '0';
      end if;
      TransmitResult := Threads.Install
                        ( Name     => ThreadName,
                          Index    => Data.ListenerData.List(Index).ThreadId,
                          Priority => Threads.NORMAL,
                          Callback => to_Callback(Callback'Address) );
      if TransmitResult.Status /= Threads.Valid then

        return False;

      end if;

      -- Create a listener socket.
      Data.ListenerData.List(Index).Listener :=
        ExecItf.Socket_Func( AF       => ExecItf.AF_INET,       -- address family
                             C_Type   => ExecItf.SOCK_STREAM,   -- connection-oriented
                             Protocol => ExecItf.IPPROTO_TCP ); -- for TCP
      if Data.ListenerData.List(Index).Listener = ExecItf.INVALID_SOCKET then

        declare
          Text : Itf.V_80_String_Type;
        begin
          Text.Data(1..32) := "ERROR: Server Socket NOT created";
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

      -- Bind server socket
      Status :=
        ExecItf.Bind
        ( S       => Data.ListenerData.List(Index).Listener,
          Addr    => Data.ListenerData.List(Index).Addr,
          NameLen => ExecItf.INT(Data.ListenerData.List(Index).Data'size/8) );

      if Status /= 0 then

        ExecItf.Display_Last_WSA_Error;
        declare
          Text : Itf.V_80_String_Type;
        begin
          Text.Data(1..44) := "ERROR: Server created socket but Bind FAILED";
          Text := TextIO.Concat( Text.Data(1..44), Integer(Index) );
          TextIO.Put_Line( Text );
        end;
        declare
          Text : Itf.V_80_String_Type;
        begin
          Text.Data(1..9) := "WSA Error";
          Text := TextIO.Concat(Text.Data(1..9),Integer(Index));
          TextIO.Put_Line(Text);
        end;

        Status := ExecItf.CloseSocket
                  ( S => Data.ListenerData.List(Index).Listener );
        Data.ListenerData.List(Index).Listener := ExecItf.INVALID_SOCKET;
        WSARestart;
        return False;

      else

        Text_IO.Put("ListenerData count ");
        Int_IO.Put(Data.ListenerData.Count);
        Text_IO.Put(" ");
        Int_IO.Put(fromId);
        Text_IO.Put_Line(" ");

        return True;

      end if;

    else

      Text_IO.Put_Line( "ERROR: Too many Listeners" );
      return False;

    end if;

  end Request;

  function Lookup
  ( Id : in Integer
  ) return ComponentIdsType is

  begin -- Lookup

    for I in 1..Data.ListenerData.Count loop

      if Data.ListenerData.List(I).ThreadId = Id then
        return I;
      end if;

    end loop;
    return 0;

  end Lookup;

  function SocketListen
  ( Index : in ComponentIdsType
  ) return Boolean is

    Status
    -- 0 means function was successful; -1 otherwise
    : ExecItf.INT;

    use type Interfaces.C.int;

  begin -- SocketListen

    if ExecItf.Listen
       ( S       => Data.ListenerData.List(Index).Listener,
         Backlog => 1 ) < 0 -- only allow one connection per remote client
    then

      declare
        Text : Itf.V_80_String_Type;
      begin
        Text.Data(1..27) := "ERROR: Server Listen FAILED";
        Text := TextIO.Concat( Text.Data(1..27), Integer(Index) );
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

      Status := ExecItf.CloseSocket
                ( S => Data.ListenerData.List(Index).Listener );
      Data.ListenerData.List(Index).Listener := ExecItf.INVALID_SOCKET;
      WSARestart;

      return False;

    end if;

    return True;

  end SocketListen;

  function to_Digit
  ( Number : in Integer
  ) return Character is
  -- Convert number from 1 thru 9 to a alpha digit.

  begin -- to_Digit

    case Number is
      when 1 => return '1';
      when 2 => return '2';
      when 3 => return '3';
      when 4 => return '4';
      when 5 => return '5';
      when 6 => return '6';
      when 7 => return '7';
      when 8 => return '8';
      when 9 => return '9';
      when others =>
        Text_IO.Put("ERROR: to_Digit for Number not 1 thru 0");
        Int_IO.Put(Number);
        Text_IO.Put_Line(" ");
        return '0';
    end case;

  end to_Digit;

  -- Forever loop as initiated by Threads to Receive a message
  procedure Callback
  ( Id : in Integer
  ) is
  -- This procedure runs in the particular thread assigned to accept the
  -- connection for a component and receive a message.

    Client_Socket
    -- Accepted client socket
    : ExecItf.SOCKET := ExecItf.INVALID_SOCKET;

    Listen : Boolean;

--    Message
--    -- Message as read from socket
----    : Itf.BytesType; --Message_Buffer_Type;
--    : Data.ListenerData.List(Index).RecvCallback;

    Received_Size
    -- Size of received message
    : ExecItf.INT;

    Result
    -- Return value for Close
    : ExecItf.INT;

    type Int_Ptr_Type is access ExecItf.INT;

    function to_Ptr is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => ExecItf.PSTR );

    use type Interfaces.C.int;

    Index
    -- Index for Component in Data Listener
    : ComponentIdsType;

    use type ExecItf.SOCKET;

  begin -- Callback

    -- Obtain the Index in the Data Listener
    Index := Lookup(Id);

    if Index = 0 then
      Text_IO.Put( "ERROR: No Index for Socket-Server Callback" );
    end if;

    Connect:
    loop

      Listen := SocketListen( Index => Index );
      declare
        Text : Itf.V_80_String_Type;
      begin
        Text.Data(1..27) := "Server Receive after Listen";
        Text := TextIO.Concat(Text.Data(1..27),Integer(Index));
        if Listen then
          Text := TextIO.Concat(Text.Data(1..Text.Count), "True");
        else
          Text := TextIO.Concat(Text.Data(1..Text.Count), "False");
        end if;
        TextIO.Put_Line(Text);
      end;

      -- Accept a client connection.
      Client_Socket :=
        ExecItf.C_Accept( S       => Data.ListenerData.List(Index).Listener,
                          Addr    => null,
                          AddrLen => null );
      if Client_Socket = ExecItf.INVALID_SOCKET then

        Text_IO.Put_Line("ERROR: Server Client Socket NOT accepted");
        ExecItf.Display_Last_WSA_Error;

      else -- Accepted

        declare

          Message
          -- Message as read from socket
          : Itf.BytesType; --Message_Buffer_Type;
--        : Data.ListenerData.List(Index).RecvCallback;
--          : RecvCallback;

          function to_Int is new Unchecked_Conversion
                                 ( Source => System.Address,
                                   Target => Integer );
        begin
          Received_Size :=
            ExecItf.Recv( S     => Client_Socket,
                          Buf   => to_Ptr(Message.Bytes'address),
                          Len   => ExecItf.INT(Message'size/8),
                          Flags => 0 );
--        end;

          if Received_Size < 0 then
            declare
              Text : Itf.V_80_String_Type;
            begin
              Text.Data(1..32) := "ERROR: Socket-Server Recv failed";
              Text := TextIO.Concat( Text.Data(1..32),
                                     Integer(Index) );
              TextIO.Put_Line(Text);
            end;
            ExecItf.Display_Last_WSA_Error;
            Result := ExecItf.CloseSocket( S => Client_Socket );
          elsif Received_Size = 0 then
            Text_IO.Put_Line("ERROR: Socket-Server Receive of 0 bytes");
          elsif Integer(Received_Size) > Itf.MessageSize then
            Text_IO.Put_Line(
              "ERROR: Socket-Server Receive of more than MessageSize bytes");
            --         terminate; -- has to be from elsewhere
            --accept Quit;
            exit; -- has to be from elsewhere

          else

            -- Pass the message to its associated component
--          declare
--            Msg : Itf.BytesType;
--            for Msg.Bytes use at Message'Address;
--          begin
--            Data.ListenerData.List(Index).RecvCallback.Count := Received_Size;
--            Data.ListenerData.List(Index).RecvCallback(Msg);
--          end;
--          Data.ListenerData.List(Index).RecvCallback
--          ( Message => ( Count => Integer(Received_Size),
--                         Bytes => Itf.ByteArray(Message(1..Itf.Message_Size_Type(Received_Size))) ) );
            Message.Count := Integer(Received_Size);
            Data.ListenerData.List(Index).RecvCallback( Message => Message );
--          ( Message => ( Count => Integer(Received_Size),
--                         Bytes => Itf.ByteArray(Message(1..Itf.Message_Size_Type(Received_Size))) ) );

            Result := ExecItf.CloseSocket( S => Client_Socket );

          end if; -- Received_Size < 0
        end;

      end if; -- invalid Client_Socket

    end loop Connect;

  end Callback;

end Socket.Server;
