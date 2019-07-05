
package Socket.Client is

  -- child package of Socket

  function Request
  -- Request a Client component pairing
  ( FromName : in String;
    FromId   : in ComponentIdsType;
    ToName   : in String;
    ToId     : in ComponentIdsType 
  ) return Boolean;

  function Transmit
  ( FromId  : in ComponentIdsType;
    ToId    : in ComponentIdsType;
    Message : in Itf.BytesType --String
  ) return Boolean;

end Socket.Client;
