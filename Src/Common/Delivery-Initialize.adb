with CStrings;
with GNAT.OS_Lib;
with Text_IO;

separate ( Delivery )

procedure Initialize is
-- Read and parse Delivery.dat file to create DeliveryTable

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

  BytesRead
  -- Number of bytes read from Delivery.dat file
  : Integer := 0;

  DeliveryData
  -- Data read from Delivery.dat file
  : FileDataType;

  Field
  -- Field of record being parsed
  : Integer := 0;

  I
  -- Index into DeliveryData
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

begin -- Initialize

  DeliveryTable.Count := 0;
  DeliveryError := False;

  -- Obtain the IP address associated with the PC and that assigned to this
  -- component.

  -- First, obtain the path of the delivery file containing what should be a
  -- representation of the PC's static route table and open it.
  Delivery_File := FindDeliveryFile;

  -- Return if Configuration File not opened
  if Delivery_File.Handle = ExecItf.Invalid_File_Handle then
    Text_IO.Put_Line("ERROR: Delivery file not found");
    DeliveryError := True;
    return;
  end if;

  -- Fill-in the Delivery_Table from the DeliveryFile
  BytesRead := ExecItf.Read_File
               ( File => Delivery_File.Handle, -- handle of disk file
                 Addr => DeliveryData'address, -- buffer to receive data
                 Num  => Max_File_Size );      -- size of the buffer
  if BytesRead <= 0 then
    Result := Integer(ExecItf.GetLastError);
    DeliveryError := True;
    return;
  end if;

  -- Close the file
  Success := ExecItf.Close_File( Handle => Delivery_File.Handle );

  -- Parse the delivery file data.
  Field := 0;
  I := 0;
  while I < BytesRead loop
    I := I + 1;
    if Field = 5 then
      -- Bypass end of line characters
      if DeliveryData(I) = CR or else DeliveryData(I) = NL then
        null;
      else
        Index := Index + 1;
        Temp(Index) := DeliveryData(I); -- retain character for next phase
        Field := 0; -- start over for next application
       end if;
    else -- parse within the record
      if DeliveryData(I) /= Delimiter then
        Index := Index + 1;
        Temp(Index) := DeliveryData(I); -- retain byte
      else -- treat field prior to delimiter
        if Field = 0 then -- First get component id
          declare
            Success : Boolean;
          begin
            DeliveryTable.Count := DeliveryTable.Count + 1;
            Temp(Index+1) := ASCII.NUL; -- append trailing NUL
            CStrings.TryParse
              ( From    => Temp'Address,
                Size    => Index,
                Result  => DeliveryTable.List(DeliveryTable.Count).ComId,
                Success => Success );
          end;
          Index := 0;

        elsif Field = 1 then -- Next get component name
          declare
            StrData : String(1..Index);
            for StrData use at Temp'Address;
          begin
            DeliveryTable.List(DeliveryTable.Count).ComName.Value :=
              ( others => ' ' );
            DeliveryTable.List(DeliveryTable.Count).ComName.Count := Index;
            for J in 1..Index loop
              DeliveryTable.List(DeliveryTable.Count).ComName.Value(J) :=
                StrData(J);
            end loop;
          end;
          Index := 0;
        elsif Field = 2 then -- IP address of PC
          declare
            ByteData : Itf.ByteArray(1..Index);
            for ByteData use at Temp'Address;
          begin
            DeliveryTable.List(DeliveryTable.Count).PCAddress.Bytes :=
              ( others => 0 );
            DeliveryTable.List(DeliveryTable.Count).PCAddress.Count := Index;
            DeliveryTable.List(DeliveryTable.Count).PCAddress.Bytes(1..Index) :=
              ByteData(1..Index);
          end;
          Index := 0;
        elsif Field = 3 then -- Port to use for Server
          declare
            Success : Boolean;
          begin
            Temp(Index+1) := ASCII.NUL; -- append trailing NUL
            CStrings.TryParse
              ( From    => Temp'Address,
                Size    => Index,
                Result  => DeliveryTable.List(DeliveryTable.Count).PortServer,
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
            CStrings.TryParse
              ( From    => Temp'Address,
                Size    => Index,
                Result  => DeliveryTable.List(DeliveryTable.Count).PortClient,
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

  -- Validate that table doesn't contain extraneous entries
  if not Validate then
    -- quit if Delivery.dat built an invalid table
    GNAT.OS_Lib.OS_Exit(0);
  end if;

end Initialize;
