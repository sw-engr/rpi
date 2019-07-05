
package Socket.Server is

-- child package of Socket

  function Request
  -- Request a Client component pairing
  ( FromName     : in String;
    FromId       : in ComponentIdsType;
    ToName       : in String;
    ToId         : in ComponentIdsType;
    RecvCallback : in ReceiveCallbackType
  ) return Boolean;

end Socket.Server;
