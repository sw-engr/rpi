with CStrings;
with TextIO;

separate( WinSock )

procedure Transmit
( DeliverTo : in Component_Ids_Type;
  Count     : in Itf.Message_Size_Type;
  Message   : in System.Address
) is

  Bytes_Written
  -- Number of bytes sent
  : ExecItf.INT;

  Index
  -- Index into Comm array
  : Connection_Count_Type := 0;

  function to_PCSTR is new Unchecked_Conversion( Source => System.Address,
                                                 Target => ExecItf.PCSTR );

  use type ExecItf.INT;

begin -- Transmit

--declare
--  Msg : String(1..integer(Count));
--  for Msg use at Message;
--begin
--  text_io.Put_Line(msg);
--  if msg = "Component1 message for 4" then
--    text_io.Put_Line("for component4");
--  end if;
--end;
  -- Find location of pair for remote application and set Index into Comm.
  for I in 1..Comm.Count loop
    if Comm.Data(I).DeliveryId = DeliverTo then
      Index := I;
declare
text : string(1..28) := "Transmit Index N DeliverTo D";
                     --  1234567890123456789012345678
begin
text(16) := to_Digit(Integer(Index));
text(28) := to_Digit(Integer(DeliverTo));
--Int_IO.Put(Integer(Index));
--Int_IO.Put(Integer(DeliverTo));
Text_IO.Put_Line(text);      
end;
      exit;
    end if;
  end loop;

  -- Return if remote component doesn't exist for this configuration.
  if Index = 0 then
    return;
  end if;

  -- Return if the select socket isn't available; i.e., connected.
  if not Comm.Link(Index).Transmit.Connected then
if Index = 1 then
text_io.Put_Line("Transmit 1 not connected, returning");
elsif Index = 2 then
text_io.Put_Line("Transmit 2 not connected, returning");
else
text_io.Put_Line("Transmit 3 not connected, returning");
end if;
    return;
  end if;
    
  Bytes_Written :=
    ExecItf.Send( S     => Comm.Link(Index).Transmit.Socket.Socket, --Win_Socket,
                  Buf   => to_PCSTR(Message),
                  Len   => ExecItf.INT(Count),
                  Flags => 0 );
  if Bytes_Written /= ExecItf.INT(Count) then
    Text_IO.Put("ERROR: WinSock Message Send failed");
    Int_IO.Put(Integer(Bytes_Written));
    Text_IO.Put(" ");
    Text_IO.Put(String(Comm.Link(Index).Transmit.Name(1..25)));
    Int_IO.Put(Integer(Index));
    Int_IO.Put(Integer(Comm.Link(Index).Transmit.Socket.Data.SIn_Port));
    Text_IO.Put_Line(" ");
    ExecItf.Display_Last_WSA_Error;
  else
    declare
      Text : Itf.V_80_String_Type;
    begin
      Text := TextIO.Concat
              ( "Transmit sent using socket port",
                Integer(Comm.Link(Index).Transmit.Socket.Data.SIn_Port) );
      TextIO.Put_Line( Text );
    end;
  end if;

end Transmit;
