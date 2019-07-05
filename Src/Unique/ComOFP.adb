
with Itf;
with Socket.Client;
with Socket.Server;
with System;
with Text_IO;
with Threads;
with Unchecked_Conversion;

package body ComOFP is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  ComponentWakeup
  -- Wakeup Event handle of the component
  : ExecItf.HANDLE;

  CurrentThread
  : ExecItf.HANDLE;

  SocketFromCDU : Boolean; -- keypush message
  SocketToCDU   : Boolean; -- response message

--  ResponseMessage
--  : Itf.BytesType;

  procedure Callback
  ( Id : in Integer
  );

  -- Receive Message from ComCDU
  procedure ReceiveCallback
  ( Message : in Itf.BytesType
  );

  -- Convert Message data to a string, create response, and transmit it
  procedure SendResponse
  ( Message : in Itf.BytesType
  );

  procedure Install is

    Result : Threads.RegisterResult;

    use type Threads.InstallResult;

    function to_Callback is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => Threads.CallbackType );
    function to_RecvCallback is new Unchecked_Conversion
                                    ( Source => System.Address,
                                      Target => Socket.ReceiveCallbackType );

  begin -- Install

    CurrentThread := ExecItf.GetCurrentThread;
    
    -- Install the component into the Threads package.
    Result := Threads.Install
              ( Name     => "ComOFP",
                Index    => 0, -- value doesn't matter
                Priority => Threads.NORMAL,
                Callback => to_Callback(Callback'Address)
              );

    if Result.Status = Threads.VALID then
      ComponentWakeup := Result.Event; -- make visible to ???

       -- Request the ability to send to ComCDU.
      SocketToCDU := Socket.Client.Request( "ComOFP",
                                            2,
                                            "ComCDU",
                                            1 );
      if not SocketToCDU then
        Text_IO.Put_Line(
                 "Socket.Client not valid for ComOFP, ComCDU pair" );
      end if;

      -- Request the ability to receive from ComCDU.
      SocketFromCDU := Socket.Server.Request
                       ( "ComOFP",
                         2,
                         "ComCDU",
                         1,
                         to_RecvCallback(ReceiveCallback'Address) );
      if not SocketFromCDU then
        Text_IO.Put_Line(
                 "Socket.Server not valid for ComOFP, ComCDU pair" );
      end if;

    end if;

  end Install;

  -- Return component's wakeup event handle
  function WakeupEvent
  return ExecItf.HANDLE is
  begin -- WakeupEvent
    return ComponentWakeup;
  end WakeupEvent;

  -- Received message from ComCDU
  procedure ReceiveCallback
  ( Message : in Itf.BytesType
  ) is

  begin -- ReceiveCallback

    Text_IO.Put("ComOFP received a message: ");
    declare
--      Msg : String(1..Message'Length);
--      for Msg use at Message'Address;
      use type Itf.Byte;
    begin
      Text_IO.Put_Line("Received Message");

      -- Check if connect message to receive from ComCDU
      if Message.Count = 3    and then
         Message.Bytes(1) = 3 and then
         Message.Bytes(2) = 3 and then
         Message.Bytes(3) = 0
      then -- "connect" message received.  Ignore it.
        Text_IO.Put_Line("Connect message received");
        return;
      end if;

      -- Check if valid message to receive from ComCDU
      if Message.Count < 4 or else     -- no room for text
         Message.Bytes(1) /= 1 or else -- Topic of OFP 
         Message.Bytes(2) /= 1         -- Topic of Keypush 
      then
        Text_IO.Put_Line("ERROR: Invalid message - can't be from ComCDU");
--        exit; -- has to be from elsewhere
--        accept Quit;
--        Terminate;
--        Abort;
--        declare
--          Result : ExecItf.BOOL;
--        begin
--          Result := ExecItf.TerminateThread
--                    ( Thread => CurrentThread,
--                      ExecCode
--        end;
        ExecItf.ExitThread( ExitCode => 1 );
      else
        -- Parse the message and transmit the response
        SendResponse(Message);
      end if;
    end;
--<< check topic and size .  Terminate app if not correct.  Else
--   convert data to string. Transmit response. >>>

  end ReceiveCallback;

  -- Forever loop as initiated by Threads
  procedure Callback
  ( Id : in Integer
  ) is

  begin -- Callback

    Text_IO.Put("in ComOFP callback");
    Int_IO.Put(Id);
    Text_IO.Put_Line(" ");

--    loop -- forever

-- have to wait until receive message.  So no need to do anything in callback. 
--      if SocketToCDU then
--        Text_IO.Put_Line("ComOFP to send to ComCDU");
--        if not Socket.Client.Transmit( 2, 1, -- from 2 to 1
--                                       Message )
--        then
--          Text_IO.Put_Line( "Message not sent to ComCDU" );
--        end if;
--      end if;

--      Delay(1.0);

--    end loop;

  end Callback;

  procedure SendResponse
  ( Message : in Itf.BytesType
  ) is

    Data : String(1..Integer(Message.Bytes(3))); -- third byte is size of text
    for Data use at Message.Bytes(4)'Address;

    Response   : Itf.BytesType;
    MessageOut : String(1..16);
    for MessageOut use at Response.Bytes(4)'Address;

    use type Itf.Byte;
 
  begin -- SendResponse
    
    Response.Bytes(1) := 1; -- OFP topic
    Response.Bytes(2) := 2; -- CHANGEPAGE topic
    Response.Bytes(3) := 0; -- erroneous input
    MessageOut := ( others => ASCII.NUL );

    if Message.Bytes(3) = 2 then
      if Data(1..2) = "UP" then
        Response.Bytes(3) := 11;
        MessageOut(1..11) := "Up Selected";
      end if;
    elsif Message.Bytes(3) = 3 then
      if Data(1..3) = "DIR" then
        Response.Bytes(3) := 3;
        MessageOut(1..3) := "DIR";
      end if;
    elsif Message.Bytes(3) = 4 then
      if Data(1..4) = "PROG" then
        Response.Bytes(3) := 4;
        MessageOut(1..4) := "PROG";
      elsif Data(1..4) = "PERF" then
        Response.Bytes(3) := 4;
        MessageOut(1..4) := "PERF";
      elsif Data(1..4) = "INIT" then
        Response.Bytes(3) := 4;
        MessageOut(1..4) := "INIT";
      elsif Data(1..4) = "DATA" then
        Response.Bytes(3) := 4;
        MessageOut(1..4) := "DATA";
      elsif Data(1..4) = "PREV" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "Previous Page";
      elsif Data(1..4) = "NEXT" then
        Response.Bytes(3) := 9;
        MessageOut(1..9) := "Next Page";
      elsif Data(1..4) = "DOWN" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "Down Selected";
      end if;
    elsif Message.Bytes(3) = 5 then
      if Data(1..5) = "LSKL1" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect L1";
      elsif Data(1..5) = "LSKL2" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect L2";
      elsif Data(1..5) = "LSKL3" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect L3";
      elsif Data(1..5) = "LSKL4" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect L4";
      elsif Data(1..5) = "LSKL5" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect L5";
      elsif Data(1..5) = "LSKL6" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect L6";
      elsif Data(1..5) = "LSKR1" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect R1";
      elsif Data(1..5) = "LSKR2" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect R2";
      elsif Data(1..5) = "LSKR3" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect R3";
      elsif Data(1..5) = "LSKR4" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect R4";
      elsif Data(1..5) = "LSKR5" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect R5";
      elsif Data(1..5) = "LSKR6" then
        Response.Bytes(3) := 13;
        MessageOut(1..13) := "LineSelect R6";
       end if;
    elsif Message.Bytes(3) = 10 then
      if Data(1..10) = "FLIGHTPLAN" then
        Response.Bytes(3) := 10;
        MessageOut(1..10) := "FLIGHTPLAN";
      end if;
    end if;
    if Response.Bytes(3) = 0 then
      Text_IO.Put_Line("ERROR: Invalid Key data");
      Response.Bytes(3) := 16;
      MessageOut(1..16) := "Invalid Key data";
    end if;         
    Response.Count := Integer(Response.Bytes(3)+3);

    if SocketToCDU then
      Text_IO.Put_Line("ComOFP to send to ComCDU");
      if not Socket.Client.Transmit( 2, 1, -- from 2 (ComOFP) to 1 (ComCDU)
                                     Response )
      then
        Text_IO.Put_Line( "Message not sent to ComCDU" );
      end if;
    end if;

  end SendResponse;

end ComOFP;
