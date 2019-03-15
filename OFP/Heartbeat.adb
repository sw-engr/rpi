
with Component;
with Delivery;
with DisburseBytes;
with Itf;
with Library;
with System;
with Text_IO;
with Threads;
with Topic;
with Unchecked_Conversion;

package body Heartbeat is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  QueueName : Itf.V_Short_String_Type
            := ( Count => 9,
                 Data  => "Heartbeat           " );

  Key : Itf.ParticipantKeyType := Component.NullKey;
  -- Component's key returned from Register

  RequestTopic : Topic.TopicIdType;

  package DisburseQueue
  -- Instantiate disburse queue for the component
  is new DisburseBytes( QueueName => QueueName'Address,
                        Periodic  => True,
                        Universal => System.Null_Address,
                        Forward   => System.Null_Address );

  HeartbeatName : Itf.V_Medium_String_Type
  := ( Count => 9,
       Data  => "Heartbeat                                         " );

  Result : Component.RegisterResult;

  function to_Callback is new Unchecked_Conversion
                              ( Source => System.Address,
                                Target => Topic.CallbackType );

  procedure Main -- Threads callback
  ( T : in Boolean := False );

  -- Install the Heartbeat framework package to publish Heartbeat messages
  procedure Install is

    Status : Library.AddStatus;

    use type Component.ComponentStatus;
    use type Library.AddStatus;

  begin -- Install

    -- Note: Heartbeat has a queue to be signaled when its period has expired.
    --       The wait could be done directly instead.
    Result :=
      Component.Register
      ( Name       => HeartbeatName,
        Period     => 1500, -- once per 1.5 seconds
        Priority   => Threads.NORMAL, -- although this is a framework component
        Callback   => to_Callback(Main'Address),
        Queue      => DisburseQueue.Location,
        QueueWrite => System.Null_Address );
    if Result.Status = Component.VALID then
      DisburseQueue.ProvideWaitEvent( Event => Result.Event );
      Key := Result.Key;
      RequestTopic.Topic := Topic.HEARTBEAT;
      RequestTopic.Ext   := Topic.FRAMEWORK;
      Status := Library.RegisterTopic( RequestTopic, Result.Key,
                                       Delivery.PRODUCER,
                                       to_Callback(Main'Address) );
      if Status /= Library.SUCCESS then
        Text_IO.Put_Line( "ERROR: Register of Topic failed" );
      end if;
    end if;

  end Install;

  procedure Main -- callback
  ( T : in Boolean := False
  ) is

    Message : Itf.MessageType := Itf.NullMessage;

  begin -- Main

    Text_IO.Put_Line("in Heartbeat callback");

    loop -- forever

  text_IO.Put_Line("Heartbeat wait for event");
      DisburseQueue.EventWait; -- wait for event

      -- Publish Heartbeat message to all remote components.
      -- Note: The actual message will be created in the particular instance of
      --       the Transmit component since it can supply the RemoteAppId.
      Message.Header.Id.Topic := Topic.HEARTBEAT;
      Message.Header.Id.Ext   := Topic.FRAMEWORK;
      Delivery.Publish( 0, Message );

    end loop; -- forever

  end Main;

end Heartbeat;
