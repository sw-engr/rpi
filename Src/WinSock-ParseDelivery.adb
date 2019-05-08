
with CStrings;

separate( WinSock )

procedure ParseDelivery is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  Max_File_Size
  : constant Integer := 1000;

  type FileDataType is new String(1..Max_File_Size);

  CR1         : Itf.Byte := 16#0D#; --'\r'
  CR          : Character;
  for CR use at CR1'Address;
  NL1         : Itf.Byte := 16#0A#; -- '\n'
  NL          : Character;
  for NL use at NL1'Address;
  Delimiter   : Character := '|';

  Bytes_Read
  -- Number of bytes read from Delivery.dat file
  : Integer := 0;

  Delivery_Data
  -- Data read from Delivery.dat file
  : FileDataType;

  Field
  -- Field of record being parsed
  : Integer := 0;

  I 
  -- Index into Delivery_Data
  : Integer := 0;

  Index
  -- Index into Temp
  : Integer := 0;

  Result
  -- last error result
  : Integer;

  Success
  -- ReadFile return
  : Boolean;

  Temp
  : String(1..40); 

  use type ExecItf.File_Handle;
  
begin -- ParseDelivery

  Delivery_Table.Count := 0;
  Delivery_Error := False;

  -- Obtain the IP address associated with the PC and that assigned to this
  -- component.

  -- First, obtain the path of the delivery file containing what should be a
  -- representation of the PC's static route table and open it.
  Delivery_File := FindDeliveryFile;

  -- Return if Configuration File not opened
  if Delivery_File.Handle = ExecItf.Invalid_File_Handle then
    Text_IO.Put_Line("ERROR: Delivery file not found");
    Delivery_Error := True;
    return;
  end if;
  
  -- Fill-in the Delivery_Table from the Delivery_File
  Bytes_Read := ExecItf.Read_File
                ( File => Delivery_File.Handle,  -- handle of disk file
                  Addr => Delivery_Data'address, -- buffer to receive data
                  Num  => Max_File_Size );       -- size of the buffer
  if Bytes_Read <= 0 then
    Result := Integer(ExecItf.GetLastError);
    Delivery_Error := True;
    return;
  end if;

  -- Close the file
  Success := ExecItf.Close_File( Handle => Delivery_File.Handle );

  -- Parse the delivery file data.
  Field := 0;
  I := 0;
  while I < Bytes_Read loop
    I := I + 1;
    if Field = 6 then
      -- Bypass end of line characters
      if Delivery_Data(I) = CR or else Delivery_Data(I) = NL then
        null;
      else
        Index := Index + 1;
        Temp(Index) := Delivery_Data(I); -- retain character for next phase
        Field := 0; -- start over for next application
       end if;
    else -- parse within the record
      if Delivery_Data(I) /= Delimiter then
        Index := Index + 1;
        Temp(Index) := Delivery_Data(I); -- retain byte
      else -- treat field prior to delimiter
        if Field = 0 then -- First get component id
          declare
            Success : Boolean;
          begin
            Delivery_Table.Count := Delivery_Table.Count + 1;
            Temp(Index+1) := ASCII.NUL; -- append trailing NUL
            CStrings.TryParse( From    => Temp'Address,
                               Size    => Index,
                               Result  => Delivery_Table.List(Delivery_Table.Count).ComId,
                               Success => Success );
          end;
          Index := 0;
          
        elsif Field = 1 then -- Next get component name
          declare
            StrData : String(1..Index);
            for StrData use at Temp'Address;
          begin
            Delivery_Table.List(Delivery_Table.Count).ComName.Value :=
              ( others => ' ' );
            Delivery_Table.List(Delivery_Table.Count).ComName.Count := Index;
            for J in 1..Index loop
              Delivery_Table.List(Delivery_Table.Count).ComName.Value(J) := 
                StrData(J);
            end loop;
          end;
          Index := 0;
        elsif Field = 2 then -- IP address of PC 
          declare
            ByteData : Itf.ByteArray(1..Index);
            for ByteData use at Temp'Address;
          begin
            Delivery_Table.List(Delivery_Table.Count).PCAddress.Bytes :=
              ( others => 0 );
            Delivery_Table.List(Delivery_Table.Count).PCAddress.Count := Index;
            Delivery_Table.List(Delivery_Table.Count).PCAddress.Bytes(1..Index) :=
              ByteData(1..Index);
          end;
          Index := 0;
        elsif Field = 3 then -- Route Table IP address of component
          declare
            ByteData : Itf.ByteArray(1..Index);
            for ByteData use at Temp'Address;
          begin
            Delivery_Table.List(Delivery_Table.Count).ComRoute.Bytes :=
              ( others => 0 );
            Delivery_Table.List(Delivery_Table.Count).ComRoute.Count := Index;
            Delivery_Table.List(Delivery_Table.Count).ComRoute.Bytes(1..Index) :=
              ByteData(1..Index);
          end;
          Index := 0;
        elsif Field = 4 then -- Port to use for Server
          declare
            Success : Boolean;
          begin
            Temp(Index+1) := ASCII.NUL; -- append trailing NUL
            CStrings.TryParse( From    => Temp'Address,
                               Size    => Index,
                               Result  => Delivery_Table.List(Delivery_Table.Count).PortServer,
                               Success => Success );
            if not Success then
              Text_IO.Put_Line
                ("ERROR: Delivery.dat contains non-numeric value for Server Port");
            end if;
          end;
          Index := 0;
        else -- Port to use for Client
          declare
            Success : Boolean;
          begin
            Temp(Index+1) := ASCII.NUL; -- append trailing NUL
            CStrings.TryParse( From    => Temp'Address,
                               Size    => Index,
                               Result  => Delivery_Table.List(Delivery_Table.Count).PortClient,
                               Success => Success );
            if not Success then
              Text_IO.Put_Line
                ("ERROR: Delivery.dat contains non-numeric value for Client Port");
            end if;
          end;
          Index := 0;
        end if;
        Field := Field + 1;
      end if;
    end if;
  end loop;

end ParseDelivery;
