
with Text_IO;
with Unchecked_Conversion;

package body DisburseBytes is

  package Int_IO is new Text_IO.Integer_IO( Integer ); --debug

  QueueBytes : QueueBytesType; -- queue for byte array messages

  procedure Clear is
  begin -- Clear
    QueueBytes.Unread := False;
    QueueBytes.NextReadIndex := 1;
    QueueBytes.NextWriteIndex := 1;
  end Clear;

  -- This procedure is necessary since the instantiation of the queue has to be
  -- done before the wait event handle is known.
  procedure ProvideWaitEvent
  ( Event : in ExecItf.HANDLE
  ) is
  begin -- ProvideWaitEvent
    QueueBytes.WaitHandle := Event;
  end ProvideWaitEvent;

  -- This procedure waits for the wait event associated with the queue which is
  -- the event associated with the component.  The event is that of the thread
  -- of the component and so switches from the thread that delivered the message
  -- to that of the component.
  -- Note: ProvideWaitEvent must be called to provide the particular wait event
  --       before the component goes into its wait forever loop.
  procedure EventWait is

    WaitResult  : ExecItf.WaitReturnType;
    ResetResult : Boolean;

  begin -- EventWait

    Text_IO.Put_Line("Disburse Bytes in EventWait");

    -- Wait for the event to be signaled
    WaitResult  := ExecItf.WaitForSingleObject(QueueBytes.WaitHandle, -1);
    Text_IO.Put_Line("Disburse Bytes after Wait");
    -- Reset the wait handle
    ResetResult := ExecItf.Reset_Event(QueueBytes.WaitHandle);
    Text_IO.Put_Line("Disburse Bytes after Reset Event");

  end EventWait;

  function Read
  return Itf.BytesType is
    RtnNone : Boolean := False;
    SavedReadIndex : Integer;
    Bytes : Itf.BytesType;
  begin -- Read
    if QueueBytes.NextReadIndex = QueueBytes.NextWriteIndex then
      Text_IO.Put_Line("Disburse Bytes Queue empty");
      QueueBytes.Unread := False;
      RtnNone := True;
      Bytes.Count := 0;
      Bytes.Bytes(1) := 0;
      return Bytes;
    end if;

    SavedReadIndex := QueueBytes.NextReadIndex;
    if QueueBytes.NextReadIndex >= Size then
      QueueBytes.NextReadIndex := 1;
    else
      QueueBytes.NextReadIndex := QueueBytes.NextReadIndex + 1;
    end if;
    if QueueBytes.NextReadIndex = QueueBytes.NextWriteIndex then
      QueueBytes.Unread := False;
    else
      QueueBytes.Unread := True;
    end if;
    Bytes.Count := QueueBytes.List(SavedReadIndex).Count;
    Bytes.Bytes := QueueBytes.List(SavedReadIndex).Bytes;
    return Bytes;

  end Read;

  function Unread
  return Boolean is
  begin -- Unread
    return QueueBytes.Unread;
  end Unread;

  function Write
  ( Message : in Itf.BytesType
  ) return Boolean is

    Forwarded : Boolean := False;
    Rtn : Boolean := True;

    CurrentIndex : Integer := QueueBytes.NextWriteIndex;
    NextIndex    : Integer := CurrentIndex + 1;

    Result : Boolean;

    use type System.Address;

  begin -- Write

    -- Queue the message
    if NextIndex >= Size then
      NextIndex := 1;
    end if;
    if NextIndex = QueueBytes.NextReadIndex then -- queue overrun
      Text_IO.Put("ERROR: Disburse Bytes ");
      Text_IO.Put(QueueBytes.Name.Data(1..QueueBytes.Name.Count));
      Text_IO.Put_Line(" overrun");
      Rtn := False;
    end if;

    if Rtn then
      QueueBytes.List(CurrentIndex).Count := Message.Count;
      QueueBytes.List(CurrentIndex).Bytes := Message.Bytes;
      QueueBytes.NextWriteIndex := NextIndex;
      QueueBytes.Unread := True;
    end if;

    -- End the wait if queue not associated with a periodic component.
    -- The end of the wait will result in the thread of the component
    -- associated with the queue getting control switching from the
    -- thread that delivered the message.
    -- Note: Additional messages might be enqueued while the message just
    --       queued is being treated since it might be delivered by a higher
    --       priority thread that suspends the receiving component.
    if QueueBytes.WaitHandle /= System.Null_Address and then
       not Periodic
    then
      Result := ExecItf.Set_Event( Event => QueueBytes.WaitHandle );
 if Result then
      Text_IO.Put_Line("Disburse Bytes Set_Event True");
  else
      Text_IO.Put_Line("Disburse Bytes Set_Event False");
  end if;
    elsif not Periodic then
      Text_IO.Put("ERROR: No queue wait handle to signal end of wait ");
      Text_IO.Put_Line(QueueBytes.Name.Data(1..QueueBytes.Name.Count));
    end if;

    return Rtn;

  end Write;

begin -- instantiation procedure
  declare
    ComponentQueueName : Itf.V_Short_String_Type;
    for ComponentQueueName use at QueueName;
    function to_Int is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Integer );
  begin

    QueueBytes.Name.Count := ComponentQueueName.Count;
    QueueBytes.Name.Data  := ComponentQueueName.Data;
    QueueBytes.WaitHandle := System.Null_Address; -- until provided
    QueueBytes.Unread := False;
    QueueBytes.NextReadIndex := 1;
    QueueBytes.NextWriteIndex := 1;

    Location := QueueBytes'Address;
    Int_IO.Put(to_Int(Location));
    Text_IO.Put_Line(" ");

  end;

end DisburseBytes;
