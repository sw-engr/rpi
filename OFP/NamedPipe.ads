
with Configuration;
with Itf;

package NamedPipe is

  -- Package to communicate between applications via Named Pipes.

  type PairType is new Integer range 1..Configuration.MaxApplications-1;

  Index       : Integer; -- NamedPipeNames index
  RemoteId    : Itf.Int8;
  ReceiveKey  : Itf.ParticipantKeyType;
  TransmitKey : Itf.ParticipantKeyType;

  procedure Initialize
  ( Pair        : in PairType;
    LocalId     : in Itf.Int8;
    OpenReceive : out Itf.ReceiveOpenCallbackType;
    Receive     : out Itf.ReceiveCallbackType;
    Transmit    : out Itf.TransmitCallbackType
   );

  function OpenReceivePipe
  ( Pair : in PairType
  ) return Boolean;

  function OpenTransmitPipe
  ( Pair : in PairType
  ) return Boolean;

  type PipeDirectionType
  is ( Receive,
       Transmit
     );

end NamedPipe;
