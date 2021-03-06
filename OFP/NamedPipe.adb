
with ExecItf;
with Interfaces.C;
with NamedPipeNames;
with Remote;
with System;
with Text_IO;
with Unchecked_Conversion;

package body NamedPipe is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  function AddrToLPSCSTR -- convert address to ExecItf pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => ExecItf.LPCSTR );
  function toLPDWORD -- convert address to Exec_Itf pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => ExecItf.LPDWORD );
  function toLPVOID -- convert address to Exec_Itf pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => ExecItf.LPVOID );

  type FullPipeName is new String(1..14);

  -- Information about a thread and Microsoft Windows named pipes
  type CommunicationInfoType
  is record
    Name      : FullPipeName; -- must be of the form \\.\pipe\pipename
    -- Name of pipe
    Key       : Itf.ParticipantKeyType;
    -- Key of associated Receive or Transmit component where the local
    -- application is the pipe server
    Created   : Boolean;
    -- Whether pipe between server and client has been created
    Connected : Boolean;
    -- Whether pipe between server and client has connected
    Failed    : Boolean;
    Handle    : ExecItf.HANDLE;
    -- Pipe handle
  end record;

  type CommunicationInfoArrayType
  is array (PipeDirectionType) of CommunicationInfoType;
--  (1..2) of CommunicationInfoType;
--<<< change this array to be over PipeDirectionType? Then Receive Index is 0
--    and Transmit Index is 1 but would use Receive and Transmit as the index.>>>

  type LookupType
  is record
    LocalId  : Itf.Int8;
    RemoteId : Itf.Int8;
  end record;

  type ByPairAppDataType 
  is record
    PipeInfo      : CommunicationInfoArrayType;
    PipePair      : NamedPipeNames.NamedPipeNameType;
    -- Application identifier of the associated remote application
    Pair          : PairType;
    -- Pair index associated with Local and Remote AppIds
    LocalAppId    : Itf.Int8;
    RemoteAppId   : Itf.Int8;
    TransmitIndex : Integer; -- of pipePair
    ReceiveIndex  : Integer; -- of pipePair
  end record;
  
  type ByPairAppArrayType
  is array (PairType) 
  of ByPairAppDataType;

  ByPair : ByPairAppArrayType;
  -- Data for possible connections
  
  NullPipeInfo
  : constant CommunicationInfoType
  := ( Name      => ('\','\','.','\','p','i','p','e','\','M','t','o','N',others=>ASCII.NUL),
       Key       => (0,0,0),
       Created   => False,
       Connected => False,
       Failed    => False,
       Handle    => System.Null_Address
     );


  function LookupPair
  ( FromTo : in LookupType
  ) return PairType;
  -- Find pair from ByPair table

  procedure ReceiveMessage
  ( Pair    : in PairType;
    Message : out Itf.BytesType
  );

  procedure TransmitMessage
  ( Message : in Itf.BytesType
  );

  function toOpenReceive is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Itf.ReceiveOpenCallbackType );
  function toReceive is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => Itf.ReceiveCallbackType );
  function toTransmit is new Unchecked_Conversion
                             ( Source => System.Address,
                               Target => Itf.TransmitCallbackType );

  procedure Initialize
  ( Pair        : in PairType;
    LocalId     : in Itf.Int8;
    OpenReceive : out Itf.ReceiveOpenCallbackType;
    Receive     : out Itf.ReceiveCallbackType;
    Transmit    : out Itf.TransmitCallbackType
  ) is

  begin -- Initialize

    -- Save identifier of the remote application tied to this
    -- instance of the Receive class.
    ByPair(Pair).Pair        := Pair;
    ByPair(Pair).LocalAppId  := LocalId;
    ByPair(Pair).RemoteAppId := RemoteId;

    ByPair(Pair).TransmitIndex := 1; -- transmit
    ByPair(Pair).ReceiveIndex  := 2; -- receive

--ConsoleOut.WriteLine("local pipe {0}",pipePair.lPipeName);
--ConsoleOut.WriteLine("remote pipe {0}",pipePair.rPipeName);

    ByPair(Pair).PipePair := NamedPipeNames.NamedPipeName.List(Index);
    ByPair(Pair).PipeInfo(NamedPipe.Transmit) := NullPipeInfo;
    ByPair(Pair).PipeInfo(NamedPipe.Receive)  := NullPipeInfo;

    for I in 1..4 loop
      -- PipeInfo(LocalIndex).Name(10..13) := PipePair.lPipeName(1..4);
--      PipeInfo(TransmitIndex).Name(I+9) := PipePair.lPipeName(I);
      ByPair(Pair).PipeInfo(NamedPipe.Transmit).Name(I+9) := 
        ByPair(Pair).PipePair.lPipeName(I);
    end loop;
    ByPair(Pair).PipeInfo(NamedPipe.Transmit).Key := TransmitKey;

    for I in 1..4 loop
      ByPair(Pair).PipeInfo(NamedPipe.Receive).Name(I+9) := 
        ByPair(Pair).PipePair.rPipeName(I);
    end loop;
    ByPair(Pair).PipeInfo(NamedPipe.Receive).Key := ReceiveKey;

    OpenReceive := toOpenReceive(OpenReceivePipe'Address);
    Receive  := toReceive( ReceiveMessage'Address);
    Transmit := toTransmit( TransmitMessage'Address );

 --   Delay(1.000); -- 1 second

  end Initialize;

  function Connect
  ( Pair      : in PairType;
    Direction : in PipeDirectionType
  ) return Boolean is

    Handle
    -- Handle of pipe
    : ExecItf.HANDLE;

    Status
    -- True means server connected to client
    : ExecItf.BOOL;

    use type ExecItf.BOOL;

  begin -- Connect

    -- Wait for the client to connect.  If it succeeds, the function returns
    -- a nonzero value.  If the function returns zero, GetLastError returns
    -- ERROR_PIPE_CONNECTED.

    Handle := ByPair(Pair).PipeInfo(Direction).Handle;

    Status := ExecItf.ConnectNamedPipe
              ( NamedPipe  => Handle,
                Overlapped => null );
    if Status = 0 then -- FALSE
--      Display_Last_Error;
--      if String_Tools.Blind_Compare
--         ( Left  => "ERROR_PIPE_CONNECTED",
--           Right => Error_Text(1..Integer(Error_Text_Chars)) ) = String_Tools.Equal
--    then
      ByPair(Pair).PipeInfo(Direction).Connected := False;
    else -- TRUE
      ByPair(Pair).PipeInfo(Direction).Connected := True;
    end if;

    return ByPair(Pair).PipeInfo(Direction).Connected;

  end Connect;

--  function PipeConnected
--  ( Direction : in PipeDirectionType
--  ) return Boolean is

--    use type System.Address;

--  begin -- PipeConnected

----    if Direction = Receive then
----      if PipeInfo(Direction).Handle /= ExecItf.Invalid_Handle_Value and then
----         PipeInfo(Direction).Connected
----      then
----        return True;
----      end if;
----    else
----      if PipeInfo(Direction).Handle /= ExecItf.Invalid_Handle_Value and then
----         PipeInfo(Direction).Connected
----      then
----        return True;
----      end if;
----    end if;
--    if ByPair(PipePair).PipeInfo(Direction).Handle /= ExecItf.Invalid_Handle_Value and then
--       ByPair(PipePair).PipeInfo(Direction).Connected
--    then 
--      return True;
--    else
--      return False;
--    end if;

--  end PipeConnected;

  function LookupPair
  ( FromTo : in LookupType
  ) return PairType is

    use type Itf.Int8;

  begin -- LookupPair

    for I in PairType loop
      if (ByPair(I).LocalAppId = FromTo.LocalId and then
          ByPair(I).RemoteAppId = FromTo.RemoteId) or else
         (ByPair(I).LocalAppId = FromTo.RemoteId and then
          ByPair(I).RemoteAppId = FromTo.LocalId)
      then
        return ByPair(I).Pair; -- should be the same as I index
      end if;
    end loop;
    -- there has to be a match
    return 1; -- for Ada - no invalid value available

  end LookupPair;

  -- Close the Receive and Transmit pipes
  procedure ClosePipes
  ( Pair   : in PairType;
    Client : in Boolean
  ) is

    Status
    -- True means function was successful
    : ExecItf.BOOL;

    use type System.Address;

  begin -- ClosePipes

    if Client then
      if ByPair(Pair).PipeInfo(Receive).Handle /= ExecItf.Invalid_Handle_Value
      then
        Text_IO.Put_Line("ClosePipes closing pipeClient and setting to null");
        Status := ExecItf.DisconnectNamedPipe
                  ( NamedPipe => ByPair(Pair).PipeInfo(Receive).Name'Address );
        ByPair(Pair).PipeInfo(Receive).Handle := System.Null_Address;
      end if;
    else
      if ByPair(Pair).PipeInfo(Transmit).Handle /= ExecItf.Invalid_Handle_Value
      then
        Text_IO.Put_Line("ClosePipes closing pipeServer and setting to null");
 --       PipeServer.Close;
        Status := ExecItf.DisconnectNamedPipe
                  ( NamedPipe => ByPair(Pair).PipeInfo(Transmit).Name'Address );
        ByPair(Pair).PipeInfo(Transmit).Handle := System.Null_Address;
      end if;
    end if;

  end ClosePipes;

  -- Open the Receive Pipe
  function OpenReceivePipe
  ( Pair : in PairType
  ) return Boolean is

    Connected : Boolean;
    
    Name : FullPipeName;

    use type Interfaces.C.unsigned_long;
    use type System.Address;

    function to_Int is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Integer );

  begin -- OpenReceivePipe

    Name := ByPair(Pair).PipeInfo(Receive).Name;
    Text_IO.Put("OpenReceivePipe ");
    Text_IO.Put_Line(String(Name));
    if not ByPair(Pair).PipeInfo(Receive).Created then

--    PipeClient :=
--                new NamedPipeClientStream(".", PipeInfo(2).Name, --index].name,
--                                          PipeDirection.InOut, PipeOptions.None,
--                                          TokenImpersonationLevel.Impersonation);
      ByPair(Pair).PipeInfo(Receive).Handle :=
        ExecItf.CreateFile
        ( FileName            => AddrToLPSCSTR(ByPair(Pair).PipeInfo(Receive).Name'Address),
          DesiredAccess       => ExecItf.GENERIC_READ or ExecItf.GENERIC_WRITE,
          ShareMode           => 0, -- no sharing --ExecItf.FILE_SHARE_READ,
          SecurityAttributes  => null, -- default security attributes
          CreationDisposition => ExecItf.OPEN_EXISTING, -- OPEN_ALWAYS,
          FlagsAndAttributes  => 0, -- default attributes
          TemplateFile        => System.Null_Address -- no template
        );
--        ExecItf.CreateNamedPipe
--        ( Name               => AddrtoLPSCSTR(ByPair(Pair).PipeInfo(Receive).Name'Address),
--          OpenMode           => ExecItf.PIPE_ACCESS_DUPLEX or --16#00000003#, -- Duplex
--                                ExecItf.FILE_FLAG_OVERLAPPED,
--          PipeMode           => ExecItf.PIPE_TYPE_MESSAGE     or   --16#00000004#
--                                ExecItf.PIPE_READMODE_MESSAGE or   --2 (0 is BYTE)
--                                ExecItf.PIPE_WAIT,                 --0
--          MaxInstances       => 1, --ExecItf.PIPE_UNLIMITED_INSTANCES,  --255 (16#00000000# is stream of bytes?)
--          OutBufferSize      => Interfaces.C.unsigned_long(Itf.MessageSize), -- output buffer size
--          InBufferSize       => Interfaces.C.unsigned_long(Itf.MessageSize), -- input buffer size
--          DefaultTimeOut     => ExecItf.PIPE_TIMEOUT, --NMPWAIT_USE_DEFAULT_WAIT, -- client timeout in msec
--          SecurityAttributes => null ); -- default priority attributes --LPSECURITY_ATTRIBUTES
--Use of C++ transmit open whild using Receive pipe name as trial.

--        ExecItf.CreateNamedPipe
--        ( Name               => AddrtoLPSCSTR(PipeInfo(ReceiveIndex).Name'Address),
--          OpenMode           => ExecItf.PIPE_ACCESS_DUPLEX,        --16#00000003#, -- Duplex
--          PipeMode           => ExecItf.PIPE_TYPE_MESSAGE     or   --16#00000004#
--                                ExecItf.PIPE_READMODE_MESSAGE or   --2 (0 is BYTE)
--                                ExecItf.PIPE_WAIT,                 --0
--          MaxInstances       => ExecItf.PIPE_UNLIMITED_INSTANCES,  --255 (16#00000000# is stream of bytes?)
--          OutBufferSize      => Interfaces.C.unsigned_long(Itf.MessageSize), -- output buffer size
--          InBufferSize       => Interfaces.C.unsigned_long(Itf.MessageSize), -- input buffer size
--          DefaultTimeOut     => 0,           -- client timeout in msec
--          SecurityAttributes => null );      -- default priority attributes --LPSECURITY_ATTRIBUTES

      -- Note: The client and server processes in this example are intended
      -- to run on the same computer, so the server name provided to the
      -- NamedPipeClientStream object is ".". If the client and server
      -- processes were on separate computers, "." would be replaced with
      -- the network name of the computer that runs the server process.
--<<< must fix the name in PipeInfo for use by ExecItf >>>

      if ByPair(Pair).PipeInfo(Receive).Handle = ExecItf.Invalid_Handle_Value
      then
        Text_IO.Put_Line("ERROR: PipeClient (Receive) Handle is Invalid");
      else

        Text_IO.Put_Line("Client connecting to server...");
        Int_IO.Put(to_Int(ByPair(Pair).PipeInfo(Receive).Handle));
        Text_IO.Put_Line(" ");
      begin
--        PipeClient.Connect; -- wait for 500 msec
          Connected := Connect( Pair, Receive );
        exception
          when others => null;
        end;
        Text_IO.Put("PipeClient setting Connected ");
        Int_IO.Put(Integer(ByPair(Pair).RemoteAppId));
        Text_IO.Put_Line("");

        if ByPair(Pair).PipeInfo(Receive).Handle = ExecItf.Invalid_Handle_Value then
          Text_IO.Put_Line("ERROR: PipeClient has become null");
        else
          ByPair(Pair).PipeInfo(Receive).Connected := True;
          Text_IO.Put("PipeClient Connected ");
          if ByPair(Pair).PipeInfo(Receive).Connected then
            Text_IO.Put("True ");
          else
            Text_IO.Put("False ");
          end if;
          Int_IO.Put(Integer(ByPair(Pair).RemoteAppId));
          Text_IO.Put_Line(" ");
        end if;
        Remote.SetConnected( ByPair(Pair).RemoteAppId, True );

      end if;

    end if;

    return ByPair(Pair).PipeInfo(Receive).Connected;

  end OpenReceivePipe;

  -- Open the Transmit Pipe
  function OpenTransmitPipe
  ( Pair : in PairType
  ) return Boolean is

    use type Interfaces.C.unsigned_long;
    use type NamedPipeNames.PipeNameType;
    use type System.Address;

    function to_Int is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Integer );

  begin -- OpenTransmitPipe

    Text_IO.Put("OpenTransmitPipe ");
    Text_IO.Put_Line(String(ByPair(Pair).PipeInfo(Transmit).Name));
--    PipeServer :=
--          new NamedPipeServerStream(PipeInfo(1).Name, PipeDirection.InOut, 1);
    if ByPair(Pair).PipeInfo(Transmit).Name /= "" then
--      PipeInfo(TransmitIndex).Handle :=
--        ExecItf.CreateFile
--        ( FileName            => AddrToLPSCSTR(PipeInfo(TransmitIndex).Name'address),
--          DesiredAccess       => ExecItf.GENERIC_READ or ExecItf.GENERIC_WRITE,
--          ShareMode           => 0, -- no sharing --16#00000003#, --share read (01) and write (10) access
--          SecurityAttributes  => null, -- default security attributes --LPSECURITY_ATTRIBUTES
--          CreationDisposition => ExecItf.OPEN_EXISTING, --3 where 4 is OPEN_ALWAYS, create if doesn't exist
--          FlagsAndAttributes  => 0, -- default attributes  --16#40000000#, --FILE_FLAG_OVERLAPPED
--          TemplateFile        => System.Null_Address ); -- no template file
      ByPair(Pair).PipeInfo(Transmit).Handle :=
        ExecItf.CreateNamedPipe
        ( Name               => AddrtoLPSCSTR(ByPair(Pair).PipeInfo(Transmit).Name'Address),
          OpenMode           => ExecItf.PIPE_ACCESS_DUPLEX or --16#00000003#, -- Duplex
                                ExecItf.FILE_FLAG_OVERLAPPED,
          PipeMode           => ExecItf.PIPE_TYPE_MESSAGE     or   --16#00000004#
                                ExecItf.PIPE_READMODE_MESSAGE or   --2 (0 is BYTE)
                                ExecItf.PIPE_WAIT,                 --0
          MaxInstances       => 1, --ExecItf.PIPE_UNLIMITED_INSTANCES,  --255 (16#00000000# is stream of bytes?)
          OutBufferSize      => Interfaces.C.unsigned_long(Itf.MessageSize), -- output buffer size
          InBufferSize       => Interfaces.C.unsigned_long(Itf.MessageSize), -- input buffer size
          DefaultTimeOut     => ExecItf.PIPE_TIMEOUT, --NMPWAIT_USE_DEFAULT_WAIT, -- client timeout in msec
          SecurityAttributes => null ); -- default priority attributes --LPSECURITY_ATTRIBUTES
--        ExecItf.CreateFile
--        ( FileName            => AddrToLPSCSTR(ByPair(Pair).PipeInfo(Transmit).Name'Address),
--          DesiredAccess       => ExecItf.GENERIC_READ or ExecItf.GENERIC_WRITE,
--          ShareMode           => 0, -- no sharing --ExecItf.FILE_SHARE_READ,
--          SecurityAttributes  => null, -- default security attributes
--          CreationDisposition => ExecItf.OPEN_EXISTING, -- OPEN_ALWAYS,
--          FlagsAndAttributes  => 0, -- default attributes
--          TemplateFile        => System.Null_Address -- no template
--        );
-- use of C++ Receive Open (with Transmit pipe name) as a trial

      if ByPair(Pair).PipeInfo(Transmit).Handle /= ExecItf.Invalid_Handle_Value
      then

        ByPair(Pair).PipeInfo(Transmit).Created := True;

        -- Wait for a client to connect
        --ByPair(Pair).PipeInfo(Transmit) --PipeServer.WaitForConnection;

        Text_IO.Put("Server/Transmit connected for remote app ");
        Int_IO.Put(to_Int(ByPair(Pair).PipeInfo(Transmit).Handle));
        Text_IO.Put(" ");
        Text_IO.Put_Line(String(ByPair(Pair).PipeInfo(Transmit).Name));

      end if;

      return ByPair(Pair).PipeInfo(Transmit).Created;

    else -- error creating pipe

      Text_IO.Put_Line("OpenTransmitPipe Server Handle invalid");
        -- close the handle -- first check if pipeServer is non null
      return False;

    end if;

  end OpenTransmitPipe;

  -- Receive a message from the remote pipe client.
--  procedure ReceiveMessage
--  ( Message : out Itf.ByteArray --     public byte[] ReceiveMessage()
  procedure ReceiveMessage
  ( Pair    : in PairType;
    Message : out Itf.BytesType    
  ) is

    use type ExecItf.BOOL;
    use type Itf.Byte;
    use type Itf.BytesType;
    use type System.Address;

    function to_Int is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Integer );

  begin -- ReceiveMessage

    if ByPair(Pair).PipeInfo(Receive).Handle /= ExecItf.Invalid_Handle_Value then

      Text_IO.Put("ReceiveMessage fromServer ");
      Int_IO.Put(Integer(ByPair(Pair).RemoteAppId));
      if Remote.RemoteConnected(ByPair(Pair).RemoteAppId) then
        Text_IO.Put_Line(" True");
      else
        Text_IO.Put_Line(" False");
      end if;

      if ByPair(Pair).PipeInfo(Receive).Connected and then
         Remote.RemoteConnected(ByPair(Pair).RemoteAppId) --.PipeConnected
      then
        declare

          BytesToRead : Interfaces.C.unsigned_long;
          BytesRead   : Integer;
          Start       : Integer;
          FromServer  : Itf.BytesType;
          Status      : ExecItf.BOOL;

        begin
          BytesToRead := Interfaces.C.unsigned_long(FromServer.Bytes'Last);
          Text_IO.Put("do ReadFile");
          Int_IO.Put(Integer(BytesToRead));
          Int_IO.Put(Integer(FromServer.Bytes'Last)); -- be sure this is 250
          Int_IO.Put(to_Int(ByPair(Pair).PipeInfo(Receive).Handle));
          Text_IO.Put_Line(" ");
          Status :=
            ExecItf.ReadFile
            ( File                => ByPair(Pair).PipeInfo(Receive).Handle, -- handle to pipe
              Buffer              => toLPVOID(FromServer.Bytes'address), -- buffer to receive data
              NumberOfBytesToRead => BytesToRead, -- size of the buffer
              NumberOfBytesRead   => toLPDWORD(BytesRead'address),
              Overlapped          => null ); -- not overlapped I/O
          Text_IO.Put("Bytes read ");
          Int_IO.Put(Integer(BytesRead));
          
          if BytesRead > FromServer.Bytes'Last then 
            Text_IO.Put("Too many bytes read ");
            Int_IO.Put(Integer(BytesRead));
            Text_IO.Put_Line(" ");
          end if;
          FromServer.Count := BytesRead;
          if Status /= 0 then -- TRUE
            if FromServer.Count < Integer(Itf.HeaderSize) + 8 then -- including NAKs
              Text_IO.Put("ERROR: Received less than ");
              Int_IO.Put(Integer(Itf.HeaderSize));
              Text_IO.Put(" ");
              Int_IO.Put(Integer(FromServer.Count));
              Text_IO.Put_Line(" ");
            end if;
            -- Remove any leading NAKs from message.
            Start := 0;
            for I in 1..FromServer.Count loop
              if FromServer.Bytes(I) /= 21 then -- NAK
                Start := I;
                Exit; -- loop
              end if;
            end loop;

            declare
              J : Integer := 0;
              Msg : Itf.BytesType;
            begin
              for I in Start..FromServer.Count loop
                J := J + 1;
                Msg.Bytes(J) := FromServer.Bytes(I);
              end loop;
              Msg.Count := J;

              Message := Msg;
              return;
            end;
          end if;

        end;

      else
      
        Text_IO.Put("ReceiveMessage Read not possible");
        if ByPair(Pair).PipeInfo(Receive).Connected then
          Text_IO.Put(" True");
        else
          Text_IO.Put(" False");
        end if;
        if Remote.RemoteConnected(ByPair(Pair).RemoteAppId) then
          Text_IO.Put_Line(" True");
        else
          Text_IO.Put_Line(" False");
        end if;

      end if; -- IsConnected

    else -- no longer connected
      Text_IO.Put("ReceiveMessage not connected ");
      Int_IO.Put(Integer(ByPair(Pair).RemoteAppId));
      Text_IO.Put_Line(" ");
      if ByPair(Pair).PipeInfo(Receive).Connected then -- was connected
        Text_IO.Put("ReceiveMessage calling Remote ");
        Int_IO.Put(Integer(ByPair(Pair).RemoteAppId));
        Text_IO.Put_Line(" ");
        Remote.SetConnected(ByPair(Pair).RemoteAppId,False); --.PipeConnected := False;
        ByPair(Pair).PipeInfo(Receive).Connected := False;
        ClosePipes(Pair, True); -- close receive pipe
      end if;
    end if;

    -- Return a null message if pipeClient is null.
    Message := ( Count => 0,
                 Bytes => ( others => 0 ) );

  end ReceiveMessage;

  -- Transmit a message to the remote pipe server.
  procedure TransmitMessage
  ( Message : in Itf.BytesType --ByteArray
  ) is

    Lookup : LookupType;
    Pair   : PairType;
    Status : ExecItf.BOOL;

    use type System.Address;

  begin -- TransmitMessage

    Lookup.LocalId  := Itf.Int8(Message.Bytes(5));
    Lookup.RemoteId := Itf.Int8(Message.Bytes(8));
    Pair := LookupPair(Lookup);

    if ByPair(Pair).PipeInfo(Transmit).Handle /= ExecItf.Invalid_Handle_Value
    then
      declare -- try

        BytesWritten
        -- Number of bytes written
        : ExecItf.DWORD;

        Msg : Itf.BytesType;

        use type Interfaces.C.unsigned_long;

        function to_Int is new unchecked_conversion
          ( Source => System.Address,
            Target => Integer );

      begin
        -- Prepend 8 NAK's to the beginning of the message.
        for I in 1..8 loop
          Msg.Bytes(I) := 21; -- NAK
        end loop;
        -- Copy the message to follow the NAKs
        for I in 1..Message.Count loop --Length loop
          Msg.Bytes(I + 8) := Message.Bytes(I);
        end loop;
        Msg.Count := Message.Count + 8;

        Text_IO.put("TransmitMessage sending ");
        Int_IO.Put(Integer(Msg.Count));
        Text_IO.Put_Line(" bytes");
        -- Send message via the server process.
        Status := ExecItf.WriteFile
                  ( File                 => ByPair(Pair).PipeInfo(Transmit).Handle, -- handle to pipe
                    Buffer               => toLPVOID(Msg.Bytes'address), -- buffer to write from
                    NumberOfBytesToWrite => ExecItf.ULONG(Msg.Count),
                    NumberOfBytesWritten => toLPDWORD(BytesWritten'address),
                    Overlapped           => null ); -- not overlapped I/O

        if Integer(Status) > 0 then -- Write successful
          if Integer(BytesWritten) /= Msg.Count then
            Text_IO.Put("ERROR: Write of wrong length ");
            Int_IO.Put(Integer(BytesWritten)); --Len);
            Text_IO.Put(" ");
            Int_IO.Put(Integer(Msg.Count));
            Text_IO.Put_Line(" ");
          end if;
        else
          Text_IO.Put("ERROR: Write to pipe failed");
          Int_IO.Put(to_Int(ByPair(Pair).PipeInfo(Transmit).Handle));
          Text_IO.Put_Line(" ");
        end if;
      end;
    else
      Text_IO.Put_Line("ERROR: null pipeServer");
    end if;

    -- Catch the IOException that is raised if the pipe is broken
    -- or disconnected.
  exception -- catch (IOException e)
    when others =>
      Text_IO.Put("ERROR: Setting PipeConnected false for ");
      Int_IO.Put(Integer(ByPair(Pair).RemoteAppId));
      Text_IO.Put_Line(" ");
      Remote.SetConnected(ByPair(Pair).RemoteAppId,False);

  end TransmitMessage;

end NamedPipe;
