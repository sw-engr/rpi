
with Itf;
with System;
with TextIO;
with Text_IO;
with Threads;
with Unchecked_Conversion;
with WinSock;

package body ExComponent is

  ComponentWakeup
  -- Wakeup Event handle of the component
  : ExecItf.HANDLE;

  Message
  : String(1..19)
  := "ExComponent message";

  procedure Callback
  ( Id : in Integer
  );

  procedure ReceiveCallback
  ( Message : in String
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
              ( Name     => "ExComponent",
                Index    => 0, -- value doesn't matter
                Priority => Threads.NORMAL,
                Callback => to_Callback(Callback'Address)
              );
    if Result.Status = Threads.VALID then
      ComponentWakeup := Result.Event; -- make visible to WinSock via function

      -- Do the Windows sockets initialization and install its threads.
      WinSock.Install( ComponentId => 5,
                       Component   => "ExComponent",
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
  ( Message : in String
  ) is

   Temp : Itf.V_80_String_Type;

  begin -- ReceiveCallback

    Temp := TextIO.Concat( "ExComponent received a message:",
                           Message );
    TextIO.Put_Line(Temp);

  end ReceiveCallback;

  -- Forever loop as initiated by Threads
  procedure Callback
  ( Id : in Integer
  ) is

    Text : Itf.V_80_String_Type;

  begin -- Callback

    Text := TextIO.Concat( "in ExComponent callback", Id );
    TextIO.Put_Line( Text );

    loop -- forever
      Text_IO.Put_Line("ExComponent wait to transmit to 6");

      WinSock.Transmit( DeliverTo => 6,
                        Count     => 19,
                        Message   => Message'address );
      Delay(1.5);

    end loop;

  end Callback;

end ExComponent;
