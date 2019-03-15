
with ExecItf;

generic
-- generic PeriodicTimer

  Index
  -- Instantiation index
  : Integer;

package PeriodicTimer is

  procedure StartTimer
  ( DueTime  : in Integer;
    Period   : in Integer;
    Priority : in Integer;
    Wait     : in ExecItf.HANDLE
  );

end PeriodicTimer;
