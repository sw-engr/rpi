with CStrings;
with Component;
with Delivery;
with Disburse;
with ExecItf;
with Itf;
with Library;
with System;
with Text_IO;
with Threads;
with Topic;
with Unchecked_Conversion;

package body ComOFP is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  QueueOFP : Itf.V_Short_String_Type
             := ( Count => 7,
                  Data  => "QComOFP             " );

  ComponentKey : Itf.ParticipantKeyType := Component.NullKey;
  -- Component's key returned from Register

  KeyPushTopic    : Topic.TopicIdType;
  ChangePageTopic : Topic.TopicIdType;

  procedure AnyMessage
  ( Message : in Itf.MessageType );

  package DisburseQueue
  -- Instantiate disburse queue for component
  is new Disburse( QueueName => QueueOFP'Address,
                   Periodic  => False,
                   Universal => AnyMessage'Address,
                   Forward   => System.Null_Address );

  function DisburseWrite
  -- Callback to write message to the DisburseQueue
  ( Message : in Itf.MessageType
  ) return Boolean;

  procedure Main -- callback
  ( Topic : in Boolean := False
  );

  ComOFPName : Itf.V_Medium_String_Type
  := ( Count => 6,
       Data  => "ComOFP                                            " );

  Result : Component.RegisterResult;


  procedure Install is

    Status : Library.AddStatus;

    use type Component.ComponentStatus;
    use type Library.AddStatus;

    function to_Callback is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Topic.CallbackType );

  begin -- Install

    Result :=
      Component.Register
      ( Name       => ComOFPName,
        Period     => 0, -- not periodic
        Priority   => Threads.NORMAL, -- Requested priority of thread
        Callback   => to_Callback(Main'Address), -- Callback function of component
        Queue      => DisburseQueue.Location,
        QueueWrite => DisburseWrite'Address );
    if Result.Status = Component.VALID then
      DisburseQueue.ProvideWaitEvent( Event => Result.Event );
      ComponentKey := Result.Key;

      KeyPushTopic.Topic := Topic.OFP;
      KeyPushTopic.Ext := Topic.KEYPUSH;
      Status := Library.RegisterTopic( KeyPushTopic, Result.Key,
                                       Delivery.CONSUMER,
                                       to_Callback(Main'Address) );
      if Status /= Library.SUCCESS then
        Text_IO.Put_Line( "ERROR: Register of KEYPUSH Topic failed" );
      end if;

      ChangePageTopic.Topic := Topic.OFP;
      ChangePageTopic.Ext := Topic.CHANGEPAGE;
      Status := Library.RegisterTopic( ChangePageTopic, Result.Key,
                                       Delivery.PRODUCER,
                                       to_Callback(Main'Address) );
      if Status /= Library.SUCCESS then
        Text_IO.Put_Line( "ERROR: Register of CHANGEPAGE Topic failed" );
      end if;
    end if;

  end Install;

  -- Write to queue
  function DisburseWrite
  ( Message : in Itf.MessageType
  ) return Boolean is
  begin -- DisburseWrite
    return DisburseQueue.Write(Message => Message);
  end DisburseWrite;
  
  -- Forever loop as initiated by Threads
  procedure Main -- callback
  ( Topic : in Boolean := False
  ) is

    Success : Boolean;

    Timer_Sec
    -- System time seconds as ASCII
    : String(1..2);
    System_Time
    -- System time
    : ExecItf.System_Time_Type;

  begin -- Main

    Text_IO.Put_Line("in ComOFP callback");

    loop -- forever
      Text_IO.Put_Line("ComOFP wait for event");
 
      DisburseQueue.EventWait; -- wait for event

      Text_IO.Put_Line("ComOFP after end of wait");

      System_Time := ExecItf.SystemTime;
      CStrings.IntegerToString(System_Time.Second, 2, False, Timer_Sec, Success);
      Text_IO.Put("ComOFP ");
      Text_IO.Put_Line(Timer_Sec(1..2));

    end loop;

  end Main;

  -- Treat any message of the component that doesn't have its own procedure
  procedure AnyMessage
  ( Message : in Itf.MessageType
  ) is

    MessageOut : Itf.MessageType; 

    use type Topic.Extender_Type;
    use type Topic.Id_Type;

  begin -- AnyMessage

    Text_IO.Put("Entered ComOFP AnyMessage ");
    Int_IO.Put(Topic.Id_Type'pos(Message.Header.Id.Topic));
    Int_IO.Put(Topic.Extender_Type'pos(Message.Header.Id.Ext));
    Text_IO.Put_Line(" ");

    if Message.Header.Id.Topic = Topic.OFP and then
       Message.Header.Id.Ext   = Topic.KEYPUSH
    then

      -- Treat the message by selecting a new page and publishing the 
      -- OFP CHANGEPAGE back to App1 to change the displayed page on
      -- the pseudo CDU.
      
      Text_IO.Put_Line(Message.Data(1..3));
      
      MessageOut.Data := ( others => ASCII.NUL );
      
      if Message.Data(1..3) = "DIR" then
        MessageOut.Data(1..3) := "DIR";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..4) = "PROG" then
        MessageOut.Data(1..4) := "PROG";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..4) = "PERF" then
        MessageOut.Data(1..4) := "PERF";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..4) = "INIT" then
        MessageOut.Data(1..4) := "INIT";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..4) = "DATA" then
        MessageOut.Data(1..4) := "DATA";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..10) = "FLIGHTPLAN" then
        MessageOut.Data(1..10) := "FLIGHTPLAN";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..4) = "PREV" then
        MessageOut.Data(1..13) := "Previous Page";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..4) = "NEXT" then
        MessageOut.Data(1..9) := "Next Page";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..2) = "UP" then
        MessageOut.Data(1..11) := "Up Selected";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..4) = "DOWN" then
        MessageOut.Data(1..13) := "Down Selected";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKL1" then
        MessageOut.Data(1..13) := "LineSelect L1";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKL2" then
        MessageOut.Data(1..13) := "LineSelect L2";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKL3" then
        MessageOut.Data(1..13) := "LineSelect L3";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKL4" then
        MessageOut.Data(1..13) := "LineSelect L4";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKL5" then
        MessageOut.Data(1..13) := "LineSelect L5";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKL6" then
        MessageOut.Data(1..13) := "LineSelect L6";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKR1" then
        MessageOut.Data(1..13) := "LineSelect R1";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKR2" then
        MessageOut.Data(1..13) := "LineSelect R2";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKR3" then
        MessageOut.Data(1..13) := "LineSelect R3";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKR4" then
        MessageOut.Data(1..13) := "LineSelect R4";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKR5" then
        MessageOut.Data(1..13) := "LineSelect R5";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      elsif Message.Data(1..5) = "LSKR6" then
        MessageOut.Data(1..13) := "LineSelect R6";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      else
        Text_IO.Put_Line("ERROR: Invalid Key data");
        MessageOut.Data(1..16) := "Invalid Key data";
        Delivery.Publish(ChangePageTopic, ComponentKey, MessageOut.Data);
      end if;  
      
    else

      Text_IO.Put_Line("ERROR: Invalid topic received by ComOFP");

    end if;

    Text_IO.Put_Line("Exiting ComOFP AnyMessage");
    
  end AnyMessage;

end ComOFP;
