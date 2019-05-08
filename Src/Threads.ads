
with ExecItf;

package Threads is

  type CallbackType
  -- Callback to enter component in its forever loop
  is access procedure(Id : in Integer);

  type ComponentThreadPriority
  is ( WHATEVER,
       HIGHEST,
       HIGH,
       NORMAL,
       LOWER,
       LOWEST
     );

  type InstallResult
  is ( NONE,
       VALID,
       DUPLICATE,
       INVALID
     );

  type RegisterResult
  is record
    Status : InstallResult;
    Event  : ExecItf.HANDLE;
  end record;

  procedure Create;

  function Install
  ( Name     : in String;
    -- Thread name
    Index    : in Integer;
    -- Index to pass to Callback
    Priority : in ComponentThreadPriority; 
    -- Component priority
    Callback : in CallbackType
    -- Callback entry point to use
  ) return RegisterResult;

end Threads;

