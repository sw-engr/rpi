
separate( WinSock.Recv )

procedure ReceiveCreate
( Index : in Connection_Count_Type
) is

  Status
  -- 0 means function was successful; -1 otherwise
  : ExecItf.INT;

  use type ExecItf.SOCKET;
  use type ExecItf.INT;

begin -- ReceiveCreate

  -- Ignore create attempt if configuration doesn't specify that the
  -- method is supported for the remote application.
  -- Notes:
  --   Transmit Supported is whether the remote component supports transmit
  --   via WinSock and hence this application should be able to receive from it.

  if not Comm.Link(Index).Transmit.Supported then
    Text_IO.Put("ReceiveCreate not supported");
    return;
  end if;

  declare
    Text : String(1..21);
  begin
    Text(1..20) := "ReceiveCreate Index ";
    Text(21) := to_Digit(Integer(Index));
    Text_IO.Put_Line(Text);
  end;

  -- Create socket.
  -- Notes:
  --   The socket client receives messages from the server.  The socket
  --   server sends messages to the client.  Therefore, the running
  --   application component acts as the socket client for a particular
  --   connection and the remote application component acts as the server
  --   and transmits the message.  There is a connection pair for each 
  --   component with the running application supporting the component that
  --   is acting as the client for the other side of the component pair that
  --   is used to send messages to this application's component.

  Comm.Link(Index).Receive.Socket.Socket :=
     ExecItf.Socket_Func( AF       => ExecItf.PF_INET,       -- address family
                          C_Type   => ExecItf.SOCK_STREAM,   -- connection-oriented
                          Protocol => ExecItf.IPPROTO_TCP ); -- for TCP
  if Comm.Link(Index).Receive.Socket.Socket = ExecItf.INVALID_SOCKET then

    ExecItf.Display_Last_WSA_Error;
    Status := ExecItf.WSACleanup;

    declare
      Text : String(1..28) := "Client Socket NOT created: x";
    begin
      Text(28) := to_Digit(Integer(Index));
      Text_IO.Put_Line(Text);
    end;

  else -- valid

    -- Connect to server.

    Status :=
      ExecItf.Connect( S       => Comm.Link(Index).Receive.Socket.Socket,
                       Name    => Comm.Link(Index).Receive.Socket.Addr,
                       NameLen => ExecItf.Int(Comm.Link(Index).Receive.Socket.Data'size/8) );

    if Status = 0 then

      Comm.Link(Index).Receive.Connected := True;

      -- Indicate that there is a remote component that can be used by one of
      -- the Client Receive threads in one of the instances of the Recv package.

      Comm.Data(Index).Available := True;

      if Index = 1 then
        Text_IO.Put_Line("Client Socket 1 Connected");
        Text_IO.Put_Line("Comm.Data(1) Available for Client ");
      elsif Index = 2 then
        Text_IO.Put_Line("Client Socket 2 Connected");
        Text_IO.Put_Line("Comm.Data(2) Available for Client ");
      else
        Text_IO.Put_Line("Client Socket 3 Connected");
        Text_IO.Put_Line("Comm.Data(3) Available for Client ");
      end if;

    else

      ExecItf.Display_Last_WSA_Error;
      Status := ExecItf.WSACleanup;

      Status := ExecItf.CloseSocket( S => Comm.Link(Index).Receive.Socket.Socket );
      Comm.Link(Index).Receive.Socket.Socket := ExecItf.INVALID_SOCKET;

      if Index = 1 then
        Text_IO.Put_Line("Client Socket 1 NOT Connected");
        Text_IO.Put_line("ERROR: Client Connect 1 FAILED: ");
      elsif Index = 2 then
        Text_IO.Put_Line("Client Socket 2 NOT Connected");
        Text_IO.Put_line("ERROR: Client Connect 2 FAILED: ");
      else
        Text_IO.Put_Line("Client Socket 3 NOT Connected");
        Text_IO.Put_line("ERROR: Client Connect 3 FAILED: ");
      end if;
      Text_IO.Put(String(Comm.Link(Index).Receive.Name));
      Int_IO.Put(Integer(Index));
      Text_IO.Put_Line(" ");

    end if;

  end if;

  declare
    Txt  : String(1..23);
    Text : Itf.V_80_String_Type;
  begin
    if Comm.Link(Index).Receive.Connected then
      Txt(1..18) := "Receive Connected ";
      Text.Count := 18;
    else
      Txt(1..22) := "Receive NOT Connected ";
      Text.Count := 22;
    end if;
    Text.Count := Text.Count + 1;
    Txt(Text.Count) := To_Digit(Integer(Index));
    Text := TextIO.Concat
            ( Txt(1..Text.Count),
              Integer(Comm.Link(Index).Receive.Socket.Data.SIn_Port) );
    TextIO.Put_Line(Text);
  end;
  if Comm.Link(Index).Receive.Socket.Socket /= ExecItf.INVALID_SOCKET then
    Text_IO.Put_Line("valid socket");
  end if;

end ReceiveCreate;
