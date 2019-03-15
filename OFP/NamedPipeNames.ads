
with Configuration;

package NamedPipeNames is

  -- These types are included so that NamedPipe can reference the
  -- NamedPipeName table directly.

  type PipeNameType is new String(1..4);

  type NamedPipeNameType
  is record
    lPipeName : PipeNameType;
    rPipeName : PipeNameType;
  end record;

  type NamedPipeNameArrayType
  is array(1..4*Configuration.MaxApplications - 1) of NamedPipeNameType;

  type NamedPipeNameTableType
  is record
    Count : Integer;
    List  : NamedPipeNameArrayType;
  end record;

  NamedPipeName
  : NamedPipeNameTableType;

  procedure Initialize;

end NamedPipeNames;
