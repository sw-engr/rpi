
with CStrings;
with Interfaces.C;
with TextIO;
with Threads;

separate( WinSock )

package body Recv is

  type Received_Message_Connection_Type
  -- Connection of received message
  is record
    Remote : Connection_Count_Type;
    -- Remote connection of received message
    Length : Integer;
    -- Length of received message
  end record;

  function to_Ptr is new Unchecked_Conversion
                         ( Source => System.Address,
                           Target => ExecItf.PSTR );
    
  procedure Callback
  ( Id : in Integer
  );

  procedure ReceiveCreate
  ( Index : in Connection_Count_Type
  );
  
  procedure Install
  ( Id : in Connection_Count_Type
  ) is
  -- This procedure runs in the startup thread.

    Name  : String(1..25);

    ReceiveResult 
    -- Result of Install of Receive with Threads
    : Threads.RegisterResult;

    use type Threads.InstallResult;

    function to_Callback is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Threads.CallbackType );

  begin -- Install

    Name := Comm.Link(Id).Receive.Name;
    Text_IO.Put("Install Recv ");
    Text_IO.Put(Name);
    Int_IO.Put(Integer(Id));
    Text_IO.Put_Line(" ");

    -- Install client thread for receive.
    ReceiveResult := Threads.Install
                     ( Name     => Name,
                       Index    => Integer(Id), 
                       Priority => Threads.HIGH,
                       Callback => to_Callback(Callback'Address) );
    if ReceiveResult.Status = Threads.Valid then
      Comm.Data(Id).Receive_Wait := ReceiveResult.Event;
    end if;

  end Install;

  -- Forever loop as initiated by Threads to connect to the remote component
  -- and then receive messages from it.
  -- Notes:
  --   o The data for the socket to be used between the local and remote components
  --     is stored in the WinSock table available by the Index of Id.
  --   o This procedure is that of one of the threads.  Therefore, there is not a
  --     calling procedure that can be returned to.  Hence, there cannot be a
  --     return from this procedure.
  procedure Callback
  ( Id : in Integer
  ) is
  -- This procedure runs in the particular thread to wait for a message for
  -- the component of the Id.  The Id is passed by the Threads package as passed
  -- to it via the Install.

    Index
    -- Index into Comm.Link as passed in from Threads
    : Connection_Count_Type;

    Message
    -- Message as read from socket
    : Itf.Message_Buffer_Type;

    Received_Size
    -- Size of received message
    : ExecItf.INT;

    Result
    -- Return value for Close
    : ExecItf.INT;

    use type ExecItf.SOCKET;
    use type Interfaces.C.Int;

  begin -- Callback

    declare
      Text : String(1..26);
    begin
      Text(1..25) := "in WinSock Recv callback ";
      Text(26) := to_Digit(Integer(Id));
      Text_IO.Put_Line(Text);
    end;
    Index := Connection_Count_Type(Id);

    Forever:
    loop

      -- If the receive socket has not been connected, do so.
      if not Comm.Link(Index).Receive.Connected then
        ReceiveCreate( Index => Index );
      end if;

      -- Read from the socket and treat it.  Avoid the read if the socket
      -- has been closed.
      -- Notes:
      --   Since this is a separate process/thread, there can be no return
      --   from it when the socket is closed.

      if Comm.Link(Index).Receive.Connected and then
         Comm.Link(Index).Receive.Socket.Socket /= ExecItf.INVALID_SOCKET
      then

        declare
          function to_Int is new Unchecked_Conversion
                                 ( Source => System.Address,
                                   Target => Integer );
        begin
          Received_Size :=
            ExecItf.Recv( S     => Comm.Link(Index).Receive.Socket.Socket,
                          Buf   => to_Ptr(Message'address),
                          Len   => ExecItf.INT(Message'size/8),
                          Flags => 0 );
        end;

        if Received_Size < 0 then
          declare
            Text : Itf.V_80_String_Type;
          begin
            Text.Data(1..29) := "ERROR: WinSock Receive failed";
            Text := TextIO.Concat( Text.Data(1..29),
                                   Integer(Index) );
            TextIO.Put_Line(Text);
          end;
          ExecItf.Display_Last_WSA_Error;
          Result := ExecItf.CloseSocket
                    ( S => Comm.Link(Index).Receive.Socket.Socket );
          Comm.Link(Index).Receive.Socket.Socket := ExecItf.INVALID_SOCKET;
        elsif Received_Size = 0 then
          Text_IO.Put_Line("ERROR: WinSock Receive of 0 bytes");
        else

          -- Pass the message to its associated component
          declare
            Msg : String(1..Integer(Received_Size));
            for Msg use at Message'Address;
            function callback_toInt is new Unchecked_Conversion
                                           ( Source => ReceiveCallbackType,
                                             Target => Integer );
          begin
            Comm.Data(Index).Receive_Callback(Msg);
          end;

          -- If the received message isn't valid, close the socket since a
          -- hacker may be using it for access.

--          if Invalid then
--            Text_IO.Put( "ERROR: WinSock closing receive socket");
--            Int_IO.Put(Integer(Index));
--            Text_IO.Put_Line(" ");
--            Result := ExecItf.CloseSocket
--                      ( S => Comm.Link(Index).Receive.Socket.Socket );
--            Comm.Link(Index).Receive.Socket.Socket := ExecItf.INVALID_SOCKET;
--          end if;

        end if; -- Received_Size < 0

      else -- not Comm(Index)(Receive).Socket_Connected

        delay 0.5; -- seconds and then return to try once more

      end if; -- Comm(Index)(Receive).Socket_Connected

    end loop Forever;

  end Callback;

  procedure ReceiveCreate
  ( Index : in Connection_Count_Type
  ) is separate;

end Recv;
