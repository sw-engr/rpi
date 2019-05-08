
with ExecItf;

package Component2 is

  -- Return component's wakeup event handle
  function WakeupEvent
  return ExecItf.HANDLE;

  procedure Install;

end Component2;
