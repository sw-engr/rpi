
with Itf;

package ReceiveInterface is

  -- Install the ReceiveInterface framework package to treat Receive messages
  function Install
  return Itf.ParticipantKeyType;

  -- Write a message to the DisburseQueue from multiple Receive threads
  function DisburseWrite
  ( Message : in Itf.BytesType
  ) return Boolean;

end ReceiveInterface;
