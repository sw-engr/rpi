
with ExecItf;
with Itf;
with System;
with Topic;

generic

  -- The parameters to be supplied when instantiating an instance of the package
  QueueName : System.Address; -- address of name given to queue by component
  Periodic  : Boolean;        -- True if instantiating component is periodic
  Universal : System.Address; -- address of general message callback
  Forward   : System.Address; -- address of any forward message table

package Disburse is

  Location : System.Address;
  -- Location of the instance of the QueueType private table

  type QueueDataType is private;

  Size : constant Integer := 10;

  type QueueDataArrayType is private;

  type QueueType is private;

  type QueuePtrType is access QueueType;
  for QueuePtrType'storage_size use 0;

  type DisburseTablePtrType
  is access Itf.DisburseTableType;
  for DisburseTablePtrType'storage_size use 0;

  procedure Clear;
  -- Clear the queue

  procedure EventWait;
  -- Wait for the provided wait event and then treat any queued messages

  procedure ProvideWaitEvent
  ( Event : in ExecItf.HANDLE );
  -- Specify wait event to be used to signal component
  -- Note: The Wait Event Handle would be provide with the instantiation
  --       parameters except that the queue has to be provided to the
  --       Register of the component and the handle isn't known until
  --       the Register procedure returns.

  function Read
  return Itf.MessageType;
  -- Return message from queue or null message if queue is empty

  function Unread
  return Boolean;
  -- Return whether there are unread messages in the queue

  function Write
  ( Message : in Itf.MessageType
  ) return Boolean;
  -- Write message to the queue and return if successful

private

  type QueueDataType
  is record
    Message : Itf.MessageType;
  end record;

  type QueueDataArrayType
  is array (1..Size) of QueueDataType;

  type QueueType
  is record
    Name           : Itf.V_Short_String_Type; -- Name given to the queue by the component
    WaitHandle     : ExecItf.HANDLE;
    Universal      : Itf.ForwardType;
    Unread         : Boolean;
    NextReadIndex  : Integer;
    NextWriteIndex : Integer;
    List : QueueDataArrayType;
  end record;

end Disburse;
