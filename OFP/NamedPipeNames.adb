
package body NamedPipeNames is

  procedure Initialize is

  begin -- Initialize

    -- Set the local and remote app basic pipe names of each possible pair

    NamedPipeName.List(1).lPipeName := "1to2"; -- App1 the local app
    NamedPipeName.List(1).rPipeName := "2to1";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(2).lPipeName := "2to1"; -- App2 the local app
    NamedPipeName.List(2).rPipeName := "1to2";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(3).lPipeName := "1to3"; -- App1 the local app
    NamedPipeName.List(3).rPipeName := "3to1";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(4).lPipeName := "3to1"; -- App3 the local app
    NamedPipeName.List(4).rPipeName := "1to3";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(5).lPipeName := "1to4"; -- App1 the local app
    NamedPipeName.List(5).rPipeName := "4to1";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(6).lPipeName := "4to1"; -- App4 the local app
    NamedPipeName.List(6).rPipeName := "1to4";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(7).lPipeName := "2to3"; -- App2 the local app
    NamedPipeName.List(7).rPipeName := "3to2";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(8).lPipeName := "3to2"; -- App3 the local app
    NamedPipeName.List(8).rPipeName := "2to3";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(9).lPipeName := "2to4"; -- App2 the local app
    NamedPipeName.List(9).rPipeName := "4to2";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(10).lPipeName := "4to2"; -- App4 the local app
    NamedPipeName.List(10).rPipeName := "2to4";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(11).lPipeName := "3to4"; -- App3 the local app
    NamedPipeName.List(11).rPipeName := "4to3";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    NamedPipeName.List(12).lPipeName := "4to3"; -- App4 the local app
    NamedPipeName.List(12).rPipeName := "3to4";
    NamedPipeName.Count := NamedPipeName.Count + 1;
    -- can be extended for more combinations

  end Initialize;

end NamedPipeNames;
