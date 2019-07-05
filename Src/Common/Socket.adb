
with System;
with Text_IO;
with Unchecked_Conversion;

package body Socket is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  WSAData
  -- Windows structure that contains the information on the configuration of
  -- the WinSock DLL, including the highest version available.  This structure
  -- is a record that contains
  --   wVersion      : Exec_Itf.WORD;
  --   wHighVersion  : Exec_Itf.WORD;
  --   szDescription : Exec_Itf.WSA_CHAR_Array(0..WSADESCRIPTION_LEN);
  --   szSystemStatus: Exec_Itf.WSA_CHAR_Array(0..WSASYS_STATUS_LEN);
  --   iMaxSockets   : Exec_Itf.USHORT;
  --   iMaxUdpDg     : Exec_Itf.USHORT;
  --   lpVendorInfo  : Exec_Itf.PSTR;
  : ExecItf.WSADATA;

  function to_LPWSADATA -- convert address to ExecItf.WinSock pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => ExecItf.LPWSADATA );

  lpWSAData
  -- Pointer to Windows WSADATA structure that contains the information on the
  -- configuration of the WinSock DLL, including the highest version available
  : constant ExecItf.LPWSADATA
  := to_LPWSADATA(WSAData'address);


  procedure WSARestart is

    Status
    -- Result of WSAStartup call
    : ExecItf.INT;

    use type ExecItf.INT;

  begin -- WSARestart

    -- Do WSA Cleanup
    Status := ExecItf.WSACleanup;

    -- Followed by WSA Startup
    Status := ExecItf.WSAStartup( VersionRequired => 16#0202#, -- version 2.2
                                  WSAData         => lpWSAData );
    if Status /= 0 then
      Text_IO.Put("ERROR: WinSock WSAStartup failed");
      Int_IO.Put(Integer(Status));
      Text_IO.Put_Line(" ");
      return;
    end if;

  end WSARestart;


  package body Data is separate;

begin -- initialize
  declare
    Win_Status
    -- Result of WSAStartup call
    : ExecItf.INT;

    use type ExecItf.INT;
  begin
Text_IO.Put_Line("Do WSAStartup");
    -- Do the Windows sockets initialization.
    Win_Status := ExecItf.WSAStartup( VersionRequired => 16#0202#, -- version 2.2
                                      WSAData         => lpWSAData );
    if Win_Status /= 0 then
      Text_IO.Put("ERROR: WinSock WSAStartup failed");
      Int_IO.Put(Integer(Win_Status));
      Text_IO.Put_Line(" ");
    end if;
  end;

end Socket;
