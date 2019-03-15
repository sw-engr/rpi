
with Text_IO;
with Unchecked_Conversion;

package body Disburse is

  package Int_IO is new Text_IO.Integer_IO( Integer ); --debug

  ForwardPtr : DisburseTablePtrType;

  Queue : QueueType; -- queue for Topic messages

  procedure DisplayQName is
    ComponentQueueName : Itf.V_Short_String_Type;
    for ComponentQueueName use at QueueName;
  begin -- DisplayQName
    Text_IO.Put(ComponentQueueName.Data(1..ComponentQueueName.Count));
  end DisplayQName;

  procedure Clear is
  begin -- Clear
    Queue.Unread := False;
    Queue.NextReadIndex := 1;
    Queue.NextWriteIndex := 1;
  end Clear;

  -- This procedure is necessary since the instantiation of the queue has to be
  -- done before the wait event handle is known.
  procedure ProvideWaitEvent
  ( Event : in ExecItf.HANDLE
  ) is
    function to_int is new unchecked_conversion
      ( source => System.Address,
        target => Integer );
  begin -- ProvideWaitEvent
    Text_IO.Put("ProvideWaitEvent ");
    DisplayQName;
    Int_IO.Put(to_int(Event));
    Text_IO.Put_Line(" ");
    Queue.WaitHandle := Event;
  end ProvideWaitEvent;

  -- Note: Use of this procedure will Read all queue entries.  Provision must
  --       be made to notify the component to end its wait if there isn't an
  --       entry in the Forward Table for the topic so that the component can
  --       treat the topic.  However, the message will already have been dequeued.
  --       Need another Peek function to return the message while leaving it in
  --       the queue until have determined whether the topic is in the forward
  --       table.  The Peek only needs to return the topic of the message to
  --       allow this.  Peek has to avoid permanently modifying the Read pointer.
  procedure ForwardMessage is

    ForwardRef : Itf.ForwardType;
    Message    : Itf.MessageType;

    use type Itf.ForwardType;
    use type Topic.Id_Type;
    use type Topic.TopicIdType;
    use type Topic.Extender_Type;

  begin -- ForwardMessage

    -- Continue as long as messages in the queue
    while Unread loop
      ForwardRef := null;
      -- Read message from queue
      Message := Read;
      if Message.Header.Id = Itf.NullMessage.Header.Id then
        exit; -- loop; no more messages
      end if;

      -- Lookup callback associated with message topic
      if ForwardPtr /= null then
        for I in 1..ForwardPtr.Count loop

          if Message.Header.Id.Topic = ForwardPtr.List(I).TopicId.Topic
          and then
             Message.Header.Id.Ext = ForwardPtr.List(I).TopicId.Ext
          then
            ForwardRef := ForwardPtr.List(I).Forward;
            Exit; -- for loop for topic
          end if;
        end loop; -- for
      end if;

      -- Invoke the callback passing the received message
      if ForwardRef /= null then
        ForwardRef( Message => Message );
      else -- Invoke the universal callback of the component for the message
        Queue.Universal( Message => Message );
      end if;
    end loop; -- while Unread messages

  end ForwardMessage;

  -- This procedure waits for the wait event associated with the queue which is
  -- the event associated with the component.  The event is that of the thread
  -- of the component and so switches from the thread that delivered the message
  -- to that of the component.
  -- Note: ProvideWaitEvent must be called to provide the particular wait event
  --       before the component goes into its wait forever loop.
  procedure EventWait is

    WaitResult  : ExecItf.WaitReturnType;
    ResetResult : Boolean;

    function to_Int is new unchecked_conversion
      ( Source => System.Address,
        Target => Integer );

  begin -- EventWait

    -- Forward the message(s) of the queue to a particular message callback
    -- if specified for the topic or to the universal message callback when
    -- not in a forward message table.
    ForwardMessage;

    Text_IO.Put("after ForwardMessage ");
    DisplayQName;
    Int_IO.Put(to_int(Queue.WaitHandle));
    Text_IO.Put_Line(" ");

    -- Wait for the event to be signaled
    WaitResult  := ExecItf.WaitForSingleObject(Queue.WaitHandle, -1);
    -- Reset the wait handle
    ResetResult := ExecItf.Reset_Event(Queue.WaitHandle);

  end EventWait;

  function Read
  return Itf.MessageType is

    RtnNone        : Boolean := False;
    SavedReadIndex : Integer;

  begin -- Read

    if Queue.NextReadIndex = Queue.NextWriteIndex then
      Text_IO.Put_Line("Disburse queue empty");
      Queue.Unread := False;
      RtnNone := True;
      return Itf.NullMessage;
    end if;

    SavedReadIndex := Queue.NextReadIndex;
    if Queue.NextReadIndex >= Size then
      Queue.NextReadIndex := 1;
    else
      Queue.NextReadIndex := Queue.NextReadIndex + 1;
    end if;
    if Queue.NextReadIndex = Queue.NextWriteIndex then
      Queue.Unread := False;
    else
      Queue.Unread := True;
    end if;
    return Queue.List(SavedReadIndex).Message;

  end Read;

  function Unread
  return Boolean is
  begin -- Unread
    return Queue.Unread;
  end Unread;

  function Write
  ( Message   : in Itf.MessageType
  ) return Boolean is

    Forwarded : Boolean := False;
    Rtn : Boolean := True;

    CurrentIndex : Integer := Queue.NextWriteIndex;
    NextIndex    : Integer := CurrentIndex + 1;

    Result : Boolean;

    use type System.Address;

    function to_Int is new unchecked_conversion
      ( Source => System.Address,
        Target => Integer );

  begin -- Write

    -- Queue the message
    if NextIndex >= Size then
      NextIndex := 1;
    end if;
    if NextIndex = Queue.NextReadIndex then -- queue overrun
      Text_IO.Put("ERROR: Disburse ");
      Text_IO.Put(Queue.Name.Data(1..Queue.Name.Count));
      Text_IO.Put_Line(" overrun");
      Rtn := False;
    end if;

    if Rtn then
      Queue.List(CurrentIndex).Message := Message;
      Queue.NextWriteIndex := NextIndex;
      Queue.Unread := True;
    end if;

    Text_IO.Put("in Write ");
    DisplayQName;
    Int_IO.Put(to_int(Queue.WaitHandle));
    Text_IO.Put_Line(" ");

    -- End the wait if queue not associated with a periodic component.
    -- The end of the wait will result in the thread of the component
    -- associated with the queue getting control switching from the
    -- thread that delivered the message.
    -- Note: Additional messages might be enqueued while the message just
    --       queued is being treated since it might be delivered by a higher
    --       priority thread that suspends the receiving component.
    if Queue.WaitHandle /= System.Null_Address and then
       not Periodic
    then
      Result := ExecItf.Set_Event( Event => Queue.WaitHandle ); --WaitEvent );
    elsif not Periodic then
      Text_IO.Put("ERROR: No queue wait handle to signal end of wait ");
      Text_IO.Put_Line(Queue.Name.Data(1..Queue.Name.Count));
    end if;

    return Rtn;

  end Write;

begin -- instantiation procedure
  declare
    ComponentQueueName : Itf.V_Short_String_Type;
    for ComponentQueueName use at QueueName;
    function to_Ptr1 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => Itf.ForwardType );
    function to_Ptr2 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => DisburseTablePtrType );
    function to_Int is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Integer );
  begin

    Queue.Name.Count := ComponentQueueName.Count;
    Queue.Name.Data  := ComponentQueueName.Data;
    Queue.WaitHandle := System.Null_Address; -- until provided
    Queue.Universal  := to_Ptr1(Universal);
    Queue.Unread := False;
    Queue.NextReadIndex := 1;
    Queue.NextWriteIndex := 1;

    ForwardPtr := to_Ptr2(Forward);

    Location := Queue'Address;
    Int_IO.Put(to_Int(Location));
    Text_IO.Put_Line(" ");

  end;

end Disburse;
