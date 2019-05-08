
with System;
with Text_IO;
with Threads;
with Unchecked_Conversion;
with WinSock;

package body Component2 is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  ComponentWakeup
  -- Wakeup Event handle of the component
  : ExecItf.HANDLE;

  Message
  : String(1..18)
  := "Component2 message";

  MessageTo6
  : String(1..23)
  := "Component2 message to 6";

  procedure Callback
  ( Id : in Integer
  );

  procedure ReceiveCallback
  ( Message : in String --Itf.Message_Buffer_Type
  );

  procedure Install is

    Result : Threads.RegisterResult;

    use type Threads.InstallResult;

    function to_Callback is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Threads.CallbackType );
    function to_RecvCallback is new Unchecked_Conversion
                                    ( Source => System.Address,
                                      Target => WinSock.ReceiveCallbackType );

  begin -- Install

    -- Install the component into the Threads package.
    Result := Threads.Install
              ( Name     => "Component2",
                Index    => 0, -- value doesn't matter
                Priority => Threads.NORMAL,
                Callback => to_Callback(Callback'Address)
              );
    if Result.Status = Threads.VALID then
      ComponentWakeup := Result.Event; -- make visible to WinSock via function

      -- Do the Windows sockets initialization and install its threads.
      WinSock.Install( ComponentId => 2,
                       Component   => "Component2",
                       RecvCallback => to_RecvCallback(ReceiveCallback'Address)
                     );

    end if;

  end Install;

  -- Return component's wakeup event handle
  function WakeupEvent
  return ExecItf.HANDLE is
  begin -- WakeupEvent
    return ComponentWakeup;
  end WakeupEvent;

  -- Received message from WinSock Recv
  procedure ReceiveCallback
  ( Message : in String --Itf.Message_Buffer_Type
  ) is

  begin -- ReceiveCallback

    Text_IO.Put("Component2 received a message: ");
    declare
      Msg : String(1..Message'Length);
      for Msg use at Message'Address;
    begin
      Text_IO.Put_Line(Msg);
    end;

  end ReceiveCallback;

  -- Forever loop as initiated by Threads
  procedure Callback
  ( Id : in Integer
  ) is

 --   WaitResult  : ExecItf.WaitReturnType;
 --   ResetResult : Boolean;

  begin -- Callback

    Text_IO.Put("in Component2 callback");
    Int_IO.Put(Id);
    Text_IO.Put_Line(" ");

    loop -- forever
--      Text_IO.Put_Line("Component2 wait for event");

      Text_IO.Put_Line("Component2 to send to Component1");
      WinSock.Transmit( DeliverTo => 1,
                        Count     => 18,
                        Message   => Message'address );

      Text_IO.Put_Line("Component2 to send to RemoteComponent");
      WinSock.Transmit( DeliverTo => 6,
                        Count     => 23,
                        Message   => MessageTo6'address );
      Delay(2.0);

    end loop;

  end Callback;

end Component2;
