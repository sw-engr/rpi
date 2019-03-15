
with Itf;

package Transmit1 is

  -- Install the instance of the Transmit framework package for Index
  function Install
  ( IndexIn  : in Integer;
    RemoteId : in Itf.Int8
  ) return Itf.ParticipantKeyType;

  procedure Initialize
  ( TransmitMessage : in Itf.TransmitCallbackType
  );

  procedure Main -- callback
  ( Topic : in Boolean := False
  );

end Transmit1;
