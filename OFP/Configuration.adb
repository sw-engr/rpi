
--with Console;
with CStrings;
with Directory;
with ExecItf;
with GNAT.IO;
with Itf;
with Remote;
with Text_IO;

package body Configuration is

  Bytes_Read
  -- Number of bytes of configuration data read
  : Integer;

  -- for Parse
  CR1         : Itf.Byte := 16#0D#; --'\r'
  CR          : Character;
  for CR use at CR1'Address;
  NL1         : Itf.Byte := 16#0A#; -- '\n'
  NL          : Character;
  for NL use at NL1'Address;
  Delimiter   : Character := '|';
  DecodePhase : Integer := 0;
  AppCount    : Integer := 1; -- preset for first app
  Field       : Integer := 0;
  Index       : Integer := 0;
  Temp        : String(1..140); -- enough for a long path

  Max_File_Size
  : constant Integer := 1000;

  subtype FileDataType is String(1..Max_File_Size);

  type File_Type
  -- Configuration name and handle
  is record
    Name   : ExecItf.Config_File_Name_Type;
    -- Name of configuration data file for applications
    Handle : ExecItf.File_Handle;
    -- Handle of configuration data file after created
  end record;

  Config_File
  -- Name and Handle of Apps-Configuration.dat file
  : File_Type;

  function FindConfigurationFile
  return File_Type;

  procedure Parse
  ( FileData : FileDataType
  );

  procedure Initialize is

    Configuration_Error
    -- True if an error in the Configuation file has been detected
    : Boolean := False;

    Data
    -- Data from config file
    : FileDataType;

    Result
    -- Create result
    : Integer;

    Success
    -- ReadFile return
    : Boolean;

    use type ExecItf.File_Handle;

  begin -- Initialize

    -- Obtain the path of the configuration file and open it.
    Config_File := FindConfigurationFile;

    -- Return if Configuration File not opened
    if Config_File.Handle = ExecItf.Invalid_File_Handle then
      return;
    end if;

    -- Read the configuration file.
    Bytes_Read := ExecItf.Read_File
                  ( File => Config_File.Handle, -- handle of disk file
                    Addr => Data'address,       -- buffer to receive data
                    Num  => Max_File_Size );    -- size of the buffer
    if Bytes_Read <= 0 then
      Result := Integer(ExecItf.GetLastError);
      Configuration_Error := True;
      return;
    end if;

    -- Close the file
    Success := ExecItf.Close_File( Handle => Config_File.Handle );

    -- Parse the configuration file data.
    Parse(Data);

    -- Set not yet connected. << does this go to Remote ? >>
    for I in 1..ConfigurationTable.Count loop
      ConfigurationTable.List(I).Connected := False;
    end loop;

  end Initialize;

  function FindConfigurationFile
  return File_Type is
  -- Notes: If running via GPS the folder that contains the gpr file seems to be
  --        the current directory.  If running from a DOS window of the Build
  --        folder, that is the current directory.  If run the exe file while
  --        in the folder of .dat file, that's the current directory.

    ConfigurationFile
    : Itf.V_Long_String_Type;

    Last
    : String(1..5);

    Path
    : Itf.V_Long_String_Type;

    Result
    -- Create result
    : Integer;

    use type ExecItf.File_Handle;
--    use type String_Tools.Comparison_Type;

  begin -- FindConfigurationFile

    -- Get the current directory/folder.
    Path := Directory.GetCurrentDirectory;
--console.Write(Path.Data(1..Path.Count));

    -- Attempt to open "Apps-Configuration.dat" file containing the current
    -- configuration of applications.
    ConfigurationFile.Data(1..Path.Count) := Path.Data(1..Path.Count);
    ConfigurationFile.Data(Path.Count+1..Path.Count+22) :=
      "Apps-Configuration.dat";
    ConfigurationFile.Count := Path.Count+22;

    Config_File := ( Name   => ( others => ASCII.NUL ),
                     Handle => ExecItf.Invalid_File_Handle );
    Config_File.Name(1..ConfigurationFile.Count) :=
      ConfigurationFile.Data(1..ConfigurationFile.Count);

    Config_File.Handle := ExecItf.Open_Read( Name => Config_File.Name );

    if Config_File.Handle = ExecItf.Invalid_File_Handle then
      Result := Integer(ExecItf.GetLastError);
--      Console.Write("Apps Configuration file doesn't exist",Integer(Result));

      -- Not in current directory.  Try previous directories.
      WhileLoop:
      while Config_File.Handle = ExecItf.Invalid_File_Handle loop
        for I in reverse 1..Path.Count-1 loop
          -- Find the previous backslash.
          if Path.Data(I) = '\' then
            ConfigurationFile.Data(1..I) := Path.Data(1..I);
            ConfigurationFile.Data(I+1..I+22) :=
              "Apps-Configuration.dat";
            ConfigurationFile.Count := I+22;
 Text_IO.Put_Line(ConfigurationFile.Data(1..I+22));
 --console.write(" ",ConfigurationFile.Count);
            Path.Count := I; -- where '\' was found
            Text_IO.Put("next path that will be searched ");
            Text_IO.Put_Line(Path.Data(1..Path.Count));

            Config_File := ( Name   => ( others => ASCII.NUL ),
                             Handle => ExecItf.Invalid_File_Handle );
            Config_File.Name(1..ConfigurationFile.Count) :=
              ConfigurationFile.Data(1..ConfigurationFile.Count);

            Config_File.Handle := ExecItf.Open_Read( Name => Config_File.Name );
            if Config_File.Handle = ExecItf.Invalid_File_Handle then
              if I < 5 then
                exit WhileLoop; -- not going to be found in the path
              end if;
            else
              exit WhileLoop;
            end if;
          end if;
        end loop;
      end loop WhileLoop;

      if Config_File.Handle = ExecItf.Invalid_File_Handle then
        -- Not in previous directories.  Prompt for the Path.
        Text_IO.Put("Enter the path to the Apps-Configuration.dat file: ");
        GNAT.IO.Get_Line( ConfigurationFile.Data, ConfigurationFile.Count );
        -- Check whether the .dat file was included
        Last(1..4) := ConfigurationFile.Data
                      (ConfigurationFile.Count-3..ConfigurationFile.Count);
        Last(5) := ASCII.NUL;
--        if String_Tools.Blind_Compare( Last, ".dat" ) /= String_Tools.Equal then
        declare
          Dat : String(1..5) := ".dat ";
        begin
          Dat(5) := ASCII.NUL;
          if (CStrings.Compare(Last'Address,Dat'Address,true) = 0) then
            -- Check whether the trailing \ was entered
            if ConfigurationFile.Data(ConfigurationFile.Count) /= '\' then
              ConfigurationFile.Count := ConfigurationFile.Count + 1;
              ConfigurationFile.Data(ConfigurationFile.Count) := '\';
            end if;
            -- Append the file name
            ConfigurationFile.Data(ConfigurationFile.Count+1..
                                   ConfigurationFile.Count+22) :=
              "Apps-Configuration.dat";
            Config_File.Name := ( others => ASCII.NUL );
            Config_File.Name(1..ConfigurationFile.Count+22) :=
              ConfigurationFile.Data(1..ConfigurationFile.Count+22);
            Text_IO.Put("New path ");
            Text_IO.Put_Line(ConfigurationFile.Data(1..ConfigurationFile.Count+22));
            -- Attempt to open the file
            Config_File.Handle := ExecItf.Open_Read( Name => Config_File.Name );
            if Config_File.Handle = ExecItf.Invalid_File_Handle then
              Result := Integer(ExecItf.GetLastError);
              Text_IO.Put("Entered Configuration file of ");
              Text_IO.Put(Config_File.Name(1..ConfigurationFile.Count));
              Text_IO.Put_Line(" doesn't exist");
            end if;
          end if;
        end;
      end if;

    end if;

    return Config_File;

  end FindConfigurationFile;

  procedure ParseData
  ( FileData : in FileDataType;
    I        : in Integer
  ) is

  begin -- ParseData

    if Field = 5 then
      -- bypass end of line characters
      if FileData(I) = CR or else FileData(I) = NL then
        null;
      else
        Index := Index + 1;
        Temp(Index) := FileData(I); -- retain character for next phase
        Field := 0; -- start over for next application
       end if;
    else -- parse within the line
      -- Get Application Id and Name, etc
      if FileData(I) /= Delimiter then
        Index := Index + 1;
        Temp(Index) := FileData(I); -- retain byte
      else -- treat field prior to delimiter
        if Field = 0 then -- decode application id
          declare
            AppId : Integer;
            Id : String(1..Index);
            for Id use at Temp'Address;
            Success : Boolean;
          begin
      --      ConfigurationTable.List(AppCount).App.Id :=
            CStrings.TryParse(Id'Address,Index,AppId,Success);
            if Success and then AppId > 0 and then AppId <= 9
            then
              ConfigurationTable.List(AppCount).App.Id := Itf.Int8(AppId);
            else
              Text_IO.Put_Line("Application Id not between 1 and 9");
            end if;
          end;
          Index := 0; -- initialize for next field
          Field := Field + 1;
          return;
        else
          if Field = 1 then -- decode application name
            declare
              Name : String(1..Index);
              for Name use at Temp'Address;
            begin
              ConfigurationTable.List(AppCount).App.Name := (others => ' ');
              ConfigurationTable.List(AppCount).App.Name(1..Index) := Name;
            end;
            Index := 0; -- initialize for next field
            Field := Field + 1;
            return;
          end if;
          if Field = 2 then -- decode communication method
            declare
              Method : String(1..Index);
              for Method use at Temp'Address;
            begin
              if Method = "MSPipe" then
                ConfigurationTable.List(AppCount).CommMethod := Itf.MS_PIPE;
              else
                if Method = "TCPIP" then
                  ConfigurationTable.List(AppCount).CommMethod := Itf.TCP_IP;
                else
                  ConfigurationTable.List(AppCount).CommMethod := Itf.NONE;
                end if;
              end if;
              Index := 0; -- initialize for next field
              Field := Field + 1;
              return;
            end;
          end if;
          if Field = 3 then -- decode required computer name
            declare
              Name : String(1..Index);
              for Name use at Temp'Address;
            begin
              ConfigurationTable.List(AppCount).ComputerId.Length :=
                Computer_Name_Length_Type(Index);
              ConfigurationTable.List(AppCount).ComputerId.Name := (others=>' ');
              ConfigurationTable.List(AppCount).ComputerId.Name(1..Index) := Name;
              Index := 0; -- initialize for next field
              Field := Field + 1;
            end;
            return;
          end if;
          if Field = 4 then -- decode path of executable
            declare
              Path : String(1..Index);
              for Path use at Temp'Address;
            begin
              ConfigurationTable.List(AppCount).AppPath.Count := Index;
              ConfigurationTable.List(AppCount).AppPath.Data := (others => ' ');
              ConfigurationTable.List(AppCount).AppPath.Data(1..Index) := Path;
              Index := 0; -- initialize for next field
              Field := Field + 1;
            end;
            AppCount := AppCount + 1; -- increment index for list
--            if AppCount = ConfigurationTable.Count then
            if AppCount > ConfigurationTable.Count then
              return; -- done with Parse
            end if;
          end if;
        end if;
      end if;
    end if;
  end ParseData;

  procedure ParseHeader
  ( FileData : in FileDataType;
    I        : in Integer
  ) is

  begin -- ParseHeader

    if Field = 3 then
      -- bypass end of line characters
      if FileData(I) = CR or else FileData(I) = NL then
        null;
      else
        Index := Index + 1;
        Temp(Index) := FileData(I); -- retain byte for next phase
        Field := 0;
        DecodePhase := DecodePhase + 1; -- end of first phase
      end if;
    else -- parse within the line
      -- Get Count, Language, and Framework
      if FileData(I) /= Delimiter then
        Index := Index + 1;
        Temp(Index) := FileData(I);
      else -- treat field prior to delimiter
        if Field = 0 then
          declare
            Result : Integer := 0;
            Success : Boolean;
            Count : String(1..Index);
            for Count use at Temp'Address;
          begin
--            ConfigurationTable.Count :=
--              Numeric_Conversion.ASCII_to_Integer(Count);
--<<< going to need to put trailing NUL at end of Count?? >>>
            CStrings.TryParse(Count'Address,Index,Result,Success);
 --           if Success then
            ConfigurationTable.Count := Result;
 --           end if;
          end;

          Index := 0; -- initialize for next field
          Field := Field + 1;
        elsif Field = 1 then -- initialize for next field
          Index := 0; -- initialize for next field
          Field := Field + 1;
        elsif Field = 2 then -- initialize for next field
          Index := 0; -- initialize for next field
          Field := Field + 1;
        end if;
      end if;
    end if;

  end ParseHeader;

  procedure Parse
  ( FileData : in FileDataType
  ) is

  begin -- Parse

    for I in 1..Bytes_Read loop
      if DecodePhase = 0 then
        ParseHeader(FileData, I);
      else
        ParseData(FileData, I);
        if AppCount > ConfigurationTable.Count then
          return; -- done with Parse
        end if;
      end if;
    end loop;

    Text_IO.Put_Line("ERROR: Invalid Apps-Configuration.dat file");

  end Parse;

end Configuration;


