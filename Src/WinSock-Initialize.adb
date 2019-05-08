
with CStrings;
with GNAT.OS_Lib;
with Text_IO;

separate( WinSock )

procedure Initialize is

  Win_Status
  -- Result of WSAStartup call
  : ExecItf.INT;

  use type ExecItf.INT;

begin -- Initialize

  --   Do the Windows sockets initialization.
  Win_Status := ExecItf.WSAStartup( VersionRequired => 16#0202#, -- version 2.2
                                    WSAData         => lpWSAData );
  if Win_Status /= 0 then
    Text_IO.Put("ERROR: WinSock WSAStartup failed");
    Int_IO.Put(Integer(Win_Status));
    Text_IO.Put_Line(" ");
    return;
  end if;

  -- Initialize communication array.
  -- Notes:
  --   The array has been set to null when declared.  The Comm.Link Transmit
  --   Socket will have its last value filled in when a connection is accepted.

  Comm.Count := 0;
  for I in Connection_Index_Type loop
    Comm.Data(I) := Null_Data_Info;
    Comm.Link(I).Receive  := Null_Communication_Connection_Data;
    Comm.Link(I).Transmit := Null_Communication_Connection_Data;
  end loop;

  -- Build Delivery_Table from Delivery.dat file
  ParseDelivery;
  -- Validate that table doesn't contain extraneous entries
  if not ValidateDelivery then
    -- quit if Delivery.dat built an invalid table
    GNAT.OS_Lib.OS_Exit(0);
  end if;

  Delivery_Table.Last := 0;
  for I in 1..Delivery_Table.Count loop
    Int_IO.Put(Integer(Delivery_Table.List(I).ComId));
    Text_IO.Put(" ");
    Text_IO.Put(String(Delivery_Table.List(I).ComName.Value));
    Int_IO.Put(Integer(Delivery_Table.List(I).Partner));
    Text_IO.Put_Line(" ");
  end loop;

  -- Initialize Possible Pairs
  for I in Possible_Pairs_Index_Type'range loop
    Possible_Pairs(I) := ( 0, 0 );
  end loop;

  -- Look up name of host PC and display
  -- Look up applications in configuration for possible pairs
  declare
    HostLen  : Integer := 0;
    HostName : String(1..25) := ( others => ASCII.Nul );
    Prefix   : String(1..11) := "Host Name  ";
    ResultStr: String(1..40);
    Result   : CStrings.SubStringType;
    function to_PSTR is new Unchecked_Conversion( Source => System.Address,
                                                  Target => ExecItf.PSTR );
  begin
    Win_Status := ExecItf.GetHostName( Name    => to_PSTR(HostName'address),
                                       NameLen => 20 );
    if Win_Status = 0 then
      for I in 1..25 loop
        if HostName(I) = ASCII.Nul then
          HostLen := I - 1;
          exit;
        end if;
      end loop;
      Prefix(11) := ASCII.NUL;
      if HostLen > 0 then
        Result := (40,ResultStr'Address);
        CStrings.Append(Prefix'Address, HostName'Address, Result);
        Text_IO.Put_Line(ResultStr(1..Result.Length));
      end if;
    end if;
  end;

end Initialize;
