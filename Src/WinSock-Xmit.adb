
with CStrings;
with Interfaces.C;
with TextIO;
with Threads;

separate( WinSock )

package body Xmit is

  procedure Callback
  ( Id : in Integer
  );

  -- Bind the socket
  function SocketBind
  ( Index : in Connection_Count_Type
  ) return Boolean;

  -- Listen for an incoming connection
  function SocketListen
  ( Index : in Connection_Count_Type
  ) return Boolean;

  procedure Install
  ( Id : in Connection_Count_Type
  ) is
  -- This procedure runs in the startup thread.

    Name : String(1..25);

    Result : Boolean;

    TransmitResult
    -- Result of Install of Transmit with Threads
    : Threads.RegisterResult;

    use type ExecItf.SOCKET;
    use type Interfaces.C.int;
    use type Threads.InstallResult;

    function to_Callback is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Threads.CallbackType );

  begin -- Install

    Name := Comm.Link(Id).Transmit.Name;

    -- Install thread for the server
    TransmitResult := Threads.Install
                      ( Name     => Name,
                        Index    => Integer(Id),
                        Priority => Threads.NORMAL,
                        Callback => to_Callback(Callback'Address) );
    if TransmitResult.Status = Threads.Valid then
      Comm.Data(Id).Transmit_Wait := TransmitResult.Event;
      Text_IO.Put("Install Xmit ");
      Text_IO.Put(Name);
      Int_IO.Put(Integer(Id));
      Text_IO.Put_Line(" ");
    end if;

    -- Create the socket for Transmit.
    --  The socket server receives accepts a client connection from a
    --  remote/other component.  After a connection has been established
    --  with the other component, the Transmit procedure can send messages
    --  to it.  The Bind and Listen are done here and the Accept is done
    --  in the particular thread associated with the component pair in
    --  via the callback.

    -- Bind server socket and indicate socket is bound if bind successful
    Result := SocketBind( Id );

    -- Listen for a connection and indicate created if successful
    if Result then
      Result := SocketListen( Id );
    end if;

  end Install;

  function SocketBind
  ( Index : in Connection_Count_Type
  ) return Boolean is

    Status
    -- 0 means function was successful; -1 otherwise
    : ExecItf.INT;

    use type ExecItf.SOCKET;
    use type Interfaces.C.int;

  begin -- SocketBind

    Comm.Link(Index).Transmit.Socket.Socket :=
      ExecItf.Socket_Func( AF       => ExecItf.PF_INET,       -- address family
                           C_Type   => ExecItf.SOCK_STREAM,   -- connection-oriented
                           Protocol => ExecItf.IPPROTO_TCP ); -- for TCP
    if Comm.Link(Index).Transmit.Socket.Socket = ExecItf.INVALID_SOCKET then

      Text_IO.Put_Line("ERROR: Server Socket NOT created");
      ExecItf.Display_Last_WSA_Error;

      Status := ExecItf.WSACleanup;

      return False;

    end if;

--  else -- valid
if Index = 1 then
text_io.put("Xmit 1 TransmitCreate");
elsif Index = 2 then
text_io.put("Xmit 2 TransmitCreate");
else
text_io.put("Xmit 3 TransmitCreate");
end if;
int_io.put(integer(Comm.Link(Index).Transmit.Socket.Socket));
text_io.Put_line(" ");

    -- Bind server socket and indicate socket created if bind successful.

    Status :=
      ExecItf.Bind
      ( S       => Comm.Link(Index).Transmit.Socket.Socket,
        Addr    => Comm.Link(Index).Transmit.Socket.Addr,
        NameLen => ExecItf.INT(Comm.Link(Index).Transmit.Socket.Data'size/8) );

    if Status /= 0 then

      ExecItf.Display_Last_WSA_Error;
      Text_IO.Put("ERROR: Server created socket but Bind FAILED" );
      Int_IO.Put(Integer(Status));
      Text_IO.Put_Line(" ");

      Status := ExecItf.CloseSocket( S => Comm.Link(Index).Transmit.Socket.Socket );
      Comm.Link(Index).Transmit.Socket.Socket := ExecItf.INVALID_SOCKET;
      Status := ExecItf.WSACleanup;
      return False;

    else

      Comm.Data(Index).Bound := True;

      return True;

    end if;

  end SocketBind;

  function SocketListen
  ( Index : in Connection_Count_Type
  ) return Boolean is

    Status
    -- 0 means function was successful; -1 otherwise
    : ExecItf.INT;

    use type Interfaces.C.int;

  begin -- SocketListen

    if ExecItf.Listen( S       => Comm.Link(Index).Transmit.Socket.Socket,
                       Backlog => 1 ) < 0 -- only allow one connection per remote client
    then

      Comm.Link(Index).Transmit.Created := False;
      Text_IO.Put_Line("ERROR: Server bound socket but Listen FAILED" );
      ExecItf.Display_Last_WSA_Error;

      Status := ExecItf.CloseSocket
                ( S => Comm.Link(Index).Transmit.Socket.Socket );
      Comm.Link(Index).Transmit.Socket.Socket := ExecItf.INVALID_SOCKET;
      Status := ExecItf.WSACleanup;

      return False;

    else

      Comm.Link(Index).Transmit.Created := True;
if Index = 1 then
Text_IO.Put_line("Xmit 1 Transmit Created");
elsif Index = 2 then
Text_IO.Put_line("Xmit 2 Transmit Created");
else
Text_IO.Put_line("Xmit 3 Transmit Created");
end if;

    end if;

    return True;

  end SocketListen;

  -- Forever loop as initiated by Threads
  procedure Callback
  ( Id : in Integer
  ) is
  -- This procedure runs in the particular thread assigned to accept the
  -- connection for a component.

    Client_Socket
    -- Accepted client socket
    : ExecItf.SOCKET := ExecItf.INVALID_SOCKET;

    type Int_Ptr_Type is access ExecItf.INT;

    use type Interfaces.C.int;

    Index
    -- Index for Component for Comm.Link
    : Connection_Count_Type
    := Connection_Count_Type(Id);

    Client_Address_Size
    -- Size of socket address structure
    : ExecItf.INT
    := Comm.Link(Index).Transmit.Socket.Data'size/8;

    use type ExecItf.SOCKET;

    function to_Int_Ptr is new Unchecked_Conversion( Source => System.Address,
                                                     Target => Int_Ptr_Type );
    function to_Integer is new Unchecked_Conversion -- for debug
                               ( Source => ExecItf.PSOCKADDR,
                                 Target => Integer );

  begin -- Callback

    Connect:
    loop

declare
text : string(1..28);
begin
 text(1..19) := "Xmit Callback loop ";
 text(20) := to_digit(integer(Id));
 text(21) := ' ';
 text(22) := to_digit(integer(Index));
if Comm.Link(Index).Transmit.Created then
 text(23..28) := " True ";
else
 text(23..28) := " False";
end if;
 text_io.put_line(text);
end;
if index = 1 then
text_io.put_line("index of 1");
elsif Index = 2 then
text_io.put_line("index of 2");
else
text_io.put_line("index of 3");
end if;

      if Comm.Link(Index).Transmit.Created and then
         Comm.Link(Index).Receive.Connected and then
         not Comm.Link(Index).Transmit.Connected
      then

        -- Accept a client connection.
        Client_Socket :=
--          ExecItf.C_Accept( S       => Comm.Link(Index).Transmit.Socket.Socket,
--                            Addr    => Comm.Link(Index).Transmit.Socket.Addr,
--                            AddrLen => to_Int_Ptr(Client_Address_Size'address) );
          ExecItf.C_Accept( S       => Comm.Link(Index).Transmit.Socket.Socket,
                            Addr    => null,
                            AddrLen => null );
declare
  Text : Itf.V_80_String_Type;
begin
  Text := TextIO.Concat("Xmit after C_Accept",Integer(Index));
  TextIO.Put_Line(Text);
end;
        if Client_Socket = ExecItf.INVALID_SOCKET then

          Text_IO.Put_Line("ERROR: Server Client Socket NOT accepted");
          ExecItf.Display_Last_WSA_Error;

        else -- Accepted

          Comm.Link(Index).Transmit.Connected := True;
          Comm.Link(Index).Transmit.Socket.Socket := Client_Socket;

          exit Connect; -- loop

        end if; -- invalid Client_Socket

      end if; -- Comm.Link(Index).Transmit.Created

      Text_IO.Put_Line("Xmit Callback initial loop end");

      delay(1.0*Duration(Index)); -- seconds

    end loop Connect;

    -- Nothing else for the thread to do.
    Forever:
    loop
      -- Wait until connected before read messages from queue
      if not Comm.Link(Index).Transmit.Connected then
--if Index = 1 then
--text_io.Put_Line("Transmit 1 not connected, waiting");
--elsif Index = 2 then
--text_io.Put_Line("Transmit 2 not connected, waiting");
--else
--text_io.Put_Line("Transmit 3 not connected, waiting");
--end if;
        delay 3.0; -- seconds

      end if; -- not connected
    end loop Forever;

  end Callback;

end Xmit;
