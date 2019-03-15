
with Itf;
with NamedPipe;
with System;

package Receive2 is

  -- Install the instance of the Receive framework package for Index
  function Install
  ( IndexIn  : in Integer;
    RemoteId : in Itf.Int8
  ) return Itf.ParticipantKeyType;

--  procedure Initialize
  function Initialize
  ( PipeOpen       : in Itf.ReceiveOpenCallbackType;
    ReceiveMessage : in Itf.ReceiveCallbackType
  ) return System.Address;

  procedure ReceiveThread -- callback
  ( Topic : in Boolean := False
  );

end Receive2;
