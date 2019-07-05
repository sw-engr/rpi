with CStrings;
with Directory;
with GNAT.IO;
with Text_IO;

separate( Delivery )

function FindDeliveryFile
return FileType is
-- Notes: If running via GPS the folder that contains the gpr file seems to be
--        the current directory.  If running from a DOS window of the Build
--        folder, that is the current directory.  If run the exe file while
--        in the folder of .dat file, that's the current directory.

  package Int_IO is new Text_IO.Integer_IO( Integer );

  DeliveryFile
  : Itf.V_Long_String_Type;

  Last
  : String(1..5);

  Path
  : Itf.V_Long_String_Type;

  Result
  -- Create result
  : Integer;

  use type ExecItf.File_Handle;

begin -- FindDeliveryFile

  -- Get the current directory/folder.
  Path := Directory.GetCurrentDirectory;

  -- Attempt to open "Delivery.dat" file containing the current WinSock data
  -- to deliver messages.
  DeliveryFile.Data(1..Path.Count) := Path.Data(1..Path.Count);
  DeliveryFile.Data(Path.Count+1..Path.Count+12) := "Delivery.dat";
  DeliveryFile.Count := Path.Count+12;

  Delivery_File := ( Name   => ( others => ASCII.NUL ),
                     Handle => ExecItf.Invalid_File_Handle );
  Delivery_File.Name(1..DeliveryFile.Count) :=
    DeliveryFile.Data(1..DeliveryFile.Count);

  Delivery_File.Handle := ExecItf.Open_Read( Name => Delivery_File.Name );

  if Delivery_File.Handle = ExecItf.Invalid_File_Handle then
    Result := Integer(ExecItf.GetLastError);
    Text_IO.Put("Delivery file doesn't exist");
    Int_IO.Put(Integer(Result));
    Text_IO.Put_Line(" ");

    -- Not in current directory.  Try previous directories.
    WhileLoop:
    while Delivery_File.Handle = ExecItf.Invalid_File_Handle loop
      for I in reverse 1..Path.Count-1 loop
        -- Find the previous backslash.
        if Path.Data(I) = '\' then
          DeliveryFile.Data(1..I) := Path.Data(1..I);
          DeliveryFile.Data(I+1..I+12) := "Delivery.dat";
          DeliveryFile.Count := I+12;
          Path.Count := I; -- where '\' was found
          Text_IO.Put("next path that will be searched ");
          Text_IO.Put_Line(Path.Data(1..Path.Count));

          Delivery_File := ( Name   => ( others => ASCII.NUL ),
                             Handle => ExecItf.Invalid_File_Handle );
          Delivery_File.Name(1..DeliveryFile.Count) :=
            DeliveryFile.Data(1..DeliveryFile.Count);

          Delivery_File.Handle := ExecItf.Open_Read
                                  ( Name => Delivery_File.Name );
          if Delivery_File.Handle = ExecItf.Invalid_File_Handle then
            if I < 5 then
              exit WhileLoop; -- not going to be found in the path
            end if;
          else
            exit WhileLoop;
          end if;
        end if;
      end loop;
    end loop WhileLoop;

    if Delivery_File.Handle = ExecItf.Invalid_File_Handle then
      -- Not in previous directories.  Prompt for the Path.
      Text_IO.Put("Enter the path to the Delivery.dat file: ");
      GNAT.IO.Get_Line( DeliveryFile.Data, DeliveryFile.Count );
      -- Check whether the .dat file was included
      Last(1..4) := DeliveryFile.Data
                    (DeliveryFile.Count-3..DeliveryFile.Count);
      Last(5) := ASCII.NUL;
      declare
        Dat : String(1..5) := ".dat ";
      begin
        Dat(5) := ASCII.NUL;
        if (CStrings.Compare(Last'Address,Dat'Address,true) = 0) then
          -- Check whether the trailing \ was entered
          if DeliveryFile.Data(DeliveryFile.Count) /= '\' then
            DeliveryFile.Count := DeliveryFile.Count + 1;
            DeliveryFile.Data(DeliveryFile.Count) := '\';
          end if;
          -- Append the file name
          DeliveryFile.Data(DeliveryFile.Count+1..DeliveryFile.Count+12) :=
            "Delivery.dat";
          Delivery_File.Name := ( others => ASCII.NUL );
          Delivery_File.Name(1..DeliveryFile.Count+12) :=
            DeliveryFile.Data(1..DeliveryFile.Count+12);
          Text_IO.Put("New path ");
          Text_IO.Put_Line(DeliveryFile.Data(1..DeliveryFile.Count+12));
          -- Attempt to open the file
          Delivery_File.Handle := ExecItf.Open_Read( Name => Delivery_File.Name );
          if Delivery_File.Handle = ExecItf.Invalid_File_Handle then
            Result := Integer(ExecItf.GetLastError);
            Text_IO.Put("Entered Configuration file of ");
            Text_IO.Put(Delivery_File.Name(1..DeliveryFile.Count));
            Text_IO.Put_Line(" doesn't exist");
          end if;
        end if;
      end;
    end if;

  end if;

  return Delivery_File;

end FindDeliveryFile;
