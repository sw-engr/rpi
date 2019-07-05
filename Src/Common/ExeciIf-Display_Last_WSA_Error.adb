
separate( ExecItf )

procedure Display_Last_WSA_Error is
-- Get last error and display it along with the system text for it.

  package Int_IO is new Text_IO.Integer_IO( Integer );

  Last_Error
  -- Error code returned by LastError
  : Integer;

begin -- Display_Last_WSA_Error

  Last_Error := GetLastError;

--  Text(1).Item := Console.Int;
--  Text(1).Value := ( Count => 5, Value => Integer(Last_Error) );
--  Text(2).Item := Console.Done;

  Text_IO.Put( "ERROR: WSA LastError");
  Int_IO.Put( Last_Error );
  Text_IO.Put_Line(" ");

  if Last_Error = 10053 then
    Text_IO.Put_Line("Check that Anti-Virus / Firewall not blocking application");
    raise Program_Error;
  end if;

end Display_Last_WSA_Error;
