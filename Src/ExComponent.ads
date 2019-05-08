
with ExecItf;

package ExComponent is

  -- Return component's wakeup event handle
  function WakeupEvent
  return ExecItf.HANDLE;

  procedure Install;

end ExComponent;
