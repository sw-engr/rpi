
with Component;
with Configuration;
with Delivery;
with Library;
with Remote;
with Topic;

package body App is

  AllowFrameworkTopics
  -- Only allow FrameworkTopics to be registered until after Remote.  After 
  -- return from the Launch procedure the application specific user components
  -- will be installed where the use of the framework topics can not be 
  -- registered with the Library.
  : Boolean := True;

  -- Common initializations of the framework packages
  procedure InitApplication is
  begin -- InitApplication
    Topic.Initialize;
    Library.Initialize;
    Component.Initialize;
    Delivery.Initialize;
    Configuration.Initialize;
    Remote.Initialize;
  end InitApplication;

  procedure Launch
  ( AppId : Itf.ApplicationIdType
  ) is

  begin -- Launch

    -- Save application id for common access
    Itf.ApplicationId := AppId;

    -- Do the common initializations of the framework packages
    InitApplication;

    -- Do the launch of the Remote package to interface with Receive and Transmit
    Remote.Launch;

    -- Disallow further registration of framework topics.
    AllowFrameworkTopics := False;

  end Launch;

  function FrameworkTopicsAllowed
  return Boolean is
  begin -- FrameworkTopicsAllowed
    return AllowFrameworkTopics;
  end FrameworkTopicsAllowed;

end App;
