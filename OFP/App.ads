
with Itf;

package App is

  procedure Launch
  ( AppId : Itf.ApplicationIdType
  );

  function FrameworkTopicsAllowed
  return Boolean;
  -- Return whether framework topics can be registered to the Library

end App;
