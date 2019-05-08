
with GNAT.Directory_Operations;

package body Directory is

  function GetCurrentDirectory
  return Itf.V_Long_String_Type is

    Last
    -- Last character written to CurrentDirectory
    : Natural;

    CurrentDir
    : Itf.V_Long_String_Type;

    CurrentDirectory
    : GNAT.Directory_Operations.Dir_Name_Str(1..Itf.Configuration_App_Path_Max)
    := (others => ' ');

  begin -- GetCurrentDirectory

--    CurrentDirectory := GNAT.Directory_Operations.Get_Current_Dir;
    GNAT.Directory_Operations.Get_Current_Dir
    (Dir => CurrentDirectory, Last => Last);

--<<< there may be a trailing '\' which likely should be removed
    for I in reverse 1..CurrentDirectory'Length loop --Itf.Configuration_App_Path_Max loop
      if CurrentDirectory(I) = ' ' then
        CurrentDir.Count := I;
      else
        CurrentDir.Count := I;
        exit;
      end if;
    end loop;
 --   CurrentDir.Count := CurrentDirectory'Length;
    CurrentDir.Data(1..CurrentDir.Count) := CurrentDirectory(1..CurrentDir.Count);
    return CurrentDir;

  end GetCurrentDirectory;

end Directory;
