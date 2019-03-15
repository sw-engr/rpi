
with Itf;

package Remote is

  procedure Initialize;

  procedure Launch;

  -- Return whether remote app has acknowledged Register Request.
  function RegisterAcknowledged
  ( RemoteAppId : in Itf.Int8
  ) return Boolean;

  -- Record that remote app acknowledged the Register Request.
  procedure SetRegisterAcknowledged
  ( RemoteAppId : in Itf.Int8;
    Set         : in Boolean
  );

  -- Record that whether or not connected to Remote App
  procedure SetConnected
  ( RemoteAppId : in Itf.Int8;
    Set         : in Boolean
  );

  -- Return whether remote app is connected
  function RemoteConnected
  ( RemoteAppId : in Itf.Int8
  ) return Boolean;

  -- Return consecutive valid heartbeats
  function ConsecutiveValidHeartbeats
  ( RemoteAppId : in Itf.Int8
  ) return Integer;

  -- Update consecutive valid heartbeats
  procedure ConsecutiveValidHeartbeats
  ( RemoteAppId : in Itf.Int8;
    Value       : in Integer
  );

end Remote;
