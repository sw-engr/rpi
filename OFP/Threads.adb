
with Component;
with ExecItf;
with PeriodicTimer;
with System;
with Text_IO;
with Topic;
with Unchecked_Conversion;
--with Receive; --<<< while trying out instantiation here >>>
--with Transmit; --<<< while trying out instantiation here >>>

package body Threads is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  type ThreadPriorityType
  is ( Lowest,
       BelowNormal,
       Normal,
       AboveNormal,
       Highest
     );
  for ThreadPriorityType use
    ( Lowest      => 6,
      BelowNormal => 7,
      Normal      => 8,
      AboveNormal => 9,
      Highest     => 10
    );

  type ThreadDataType
  is record
    Name           : String(1..11);--Itf.V_Medium_String_Type;
    ThreadInstance : ExecItf.HANDLE; -- C# Thread threadInstance;
    Priority       : ThreadPriorityType;
  end record;

  type ThreadDataArrayType
  is array (1..Component.MaxComponents) of ThreadDataType;

  -- Component thread list
  type ComponentThreadType
  is record
    Count : Integer; -- Number of component threads.  Note: This should
                     -- end up equal to the number of components.
    List  : ThreadDataArrayType; -- List of component threads
  end record;

  -- Thread pool of component threads
  ThreadTable : ComponentThreadType;

  -- To allow ComponentThread to idle until all component threads have started
  AllThreadsStarted : Boolean := False;

  SchedulerThread
  -- Handle returned by Create_Thread for the Scheduler thread
  : ExecItf.HANDLE;

  function to_Entry_Addr is new Unchecked_Conversion
                                ( Source => Topic.CallbackType,
                                  Target => System.Address );
  function to_Void_Ptr is new Unchecked_Conversion
                              ( Source => System.Address,
                                Target => ExecItf.Void_Ptr );

  -- Convert component thread priority to that of Windows
  function ConvertThreadPriority
  ( Kind     : in Component.ComponentKind;
    Priority : in ComponentThreadPriority
  ) return ThreadPriorityType is
    use type Component.ComponentKind;
  begin -- Only for user component threads.
    if Kind = Component.USER then
      -- No component thread is allowed to have a priority above Normal.
      if Priority = LOWER then
        return BelowNormal;
      elsif Priority = LOWEST then
        return Lowest;
      else
        return Normal;
      end if;
    else
      -- Framework threads are allowed to have their specified priority.
      if Priority = HIGHEST then
        return Highest;
      elsif Priority = HIGH then
        return AboveNormal;
      elsif Priority = LOWER then
        return BelowNormal;
      elsif Priority = LOWEST then
        return Lowest;
      end if;
      return Normal;
    end if;
  end ConvertThreadPriority;

  -- Convert Windows priority to an integer
  function Priority_to_Int
  ( Priority : in ThreadPriorityType
  ) return Integer is
  begin -- Priority_to_Int
    case Priority is
      when Lowest      => return 6;
      when BelowNormal => return 7;
      when Normal      => return 8;
      when AboveNormal => return 9;
      when Highest     => return 10;
      when others      => return 8;
    end case;
  end Priority_to_Int;

  -- The common component thread code.  This code runs in the thread
  -- of the invoking component thread.  The input parameter is its
  -- location in the component table.
  -- Note: There are multiple "copies" of this function running; one
  --       for each component as called by that component's ComThread.
  --       Therefore, the data (such as stopWatch) is on the stack in
  --       a different location for each such thread.
  procedure ComponentThread
  ( Location : in Integer
  ) is

    CycleInterval : Integer;
    DelayInterval : Integer;
    Callback      : Topic.CallbackType; --; --MainEntry;
--    ExecuteTimer  : PeriodicTimer;
    Period        : Integer;
--    Queue         : Disburse.QueueName; --<<< fix >>>
--    Watch : StopWatch;

    use type Topic.CallbackType;

    function to_Int is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Integer );

  begin -- ComponentThread

    CycleInterval := Component.ComponentTable.List(Location).Period;
    if CycleInterval < 1 then -- no period supplied
      CycleInterval := 500; -- msec
    end if;
    DelayInterval := CycleInterval; -- initial delay
--    Queue := Component.ComponentTable.List(Location).Queue;

    -- Wait until all component threads have been started
    while AllThreadsStarted = False loop
      Delay(Duration(DelayInterval/100)); -- using Periods in seconds
    end loop;

    -- Create a Timer to signal the periodic components to resume
    -- when the timeout has been reached.
    Text_IO.Put("Threads ComponentThread "); --{0}", location);
    Int_IO.Put(Integer(Location));
    Text_IO.Put(" ");
    Text_IO.Put_Line(
      Component.ComponentTable.List(Location).Name.Data(1..Component.ComponentTable.List(Location).Name.Count));

    Callback := Component.ComponentTable.List(Location).fMain;
    if Callback /= null then -- component with periodic entry point
declare
function toInt is new Unchecked_Conversion (Source => Topic.CallbackType,
                                            Target => Integer );
begin
Text_IO.Put("Thread callback for ");
int_IO.put(integer(location));
text_io.put(" ");
int_IO.put(toInt(Callback));
text_io.put_line(" ");
end;

      -- Enter the component's callback to await a resume event from Timer or
      -- from receive of a message.
 --     Callback( TopicId => Topic.Empty );

      -- Create instance of Timer for periodic components
      if Component.ComponentTable.List(Location).Period > 0 then

        -- Instantiate PeriodicTimer for this component
        declare
          package ExecuteTimer is new PeriodicTimer( Index => Location );
--        ExecuteTimer := 0; --new PeriodicTimer(location);
function toInt is new Unchecked_Conversion (Source => System.Address,
                                            Target => Integer );
        begin
          Period := Component.ComponentTable.List(Location).Period;
          Text_IO.Put("StartTimer ");
          Int_IO.Put(to_Int(Component.ComponentTable.List(Location).WaitEvent));
          Text_IO.Put(" ");
          Int_IO.Put(toInt(ExecuteTimer.StartTimer'address));
          Text_IO.Put(" ");
          Int_IO.Put(toInt(ExecuteTimer'address));
                Text_IO.Put_Line(" ");

          Text_IO.Put_Line(" ");
          ExecuteTimer.StartTimer
          ( DueTime  => Period,
            Period   => Period, -- milliseconds
            Priority => 8, -- Normal
            Wait     => Component.ComponentTable.List(Location).WaitEvent );
        end;
      end if;
--      declare
--        use type Component.ComponentKind;
--        function toInt is new Unchecked_Conversion ( Source => System.Address,
--                                                     Target => Integer );
--      begin
--        if Component.ComponentTable.List(Location).Kind = Component.RECEIVE then
--          declare
--            package ReceivePkg is new
--              Receive(1,1); -- Index=1,RemoteAppId=1
--          begin
--            Text_IO.Put("Threads Receive ");
--            Text_IO.Put(" ");
--            Int_IO.Put(toInt(ReceivePkg.ReceiveThread'address));
--            Text_IO.Put(" ");
--            ReceivePkg.ReceiveThread( False );
--          end;
--        end if;
--      end;
      -- Enter the component's callback to await a resume event from Timer or
      -- from receive of a message.
--  declare
--        use type Component.ComponentKind;
--  begin
--    if Component.ComponentTable.List(Location).Kind /= Component.TRANSMIT then
      Callback( False );
--    else
--      declare
--        package TransmitPkg is new
--           Transmit(1,1); -- Index=1,RemoteAppId=1
--           function toInt is new Unchecked_Conversion ( Source => System.Address,
--                                                        Target => Integer );
--      begin
--        Text_IO.Put("Threads Transmit ");
--        Text_IO.Put(" ");
--        Int_IO.Put(toInt(TransmitPkg.Main'address));
--        Text_IO.Put(" ");
--        TransmitPkg.Main( False );
--      end;
--    end if;
--  end;

    end if;

    Delay(Duration(DelayInterval/100)); -- using Periods in seconds

  end ComponentThread;

  -- Component thread factory -- one thread for each possible component.
  -- Only those for the components in the Component componentTable will
  -- be run.
  procedure ComThread1 is
  begin
    ComponentThread(1);
  end ComThread1;
  procedure ComThread2 is
  begin
    ComponentThread(2);
  end ComThread2;
  procedure ComThread3 is
  begin
    ComponentThread(3);
  end ComThread3;
  procedure ComThread4 is
  begin
    ComponentThread(4);
  end ComThread4;
  procedure ComThread5 is
  begin
    ComponentThread(5);
  end ComThread5;
  procedure ComThread6 is
  begin
    ComponentThread(6);
  end ComThread6;
  procedure ComThread7 is
  begin
    ComponentThread(7);
  end ComThread7;
  procedure ComThread8 is
  begin
    ComponentThread(8);
  end ComThread8;
  procedure ComThread9 is
  begin
    ComponentThread(9);
  end ComThread9;
  procedure ComThread10 is
  begin
    ComponentThread(10);
  end ComThread10;
  procedure ComThread11 is
  begin
    ComponentThread(11);
  end ComThread11;
  procedure ComThread12 is
  begin
    ComponentThread(12);
  end ComThread12;
  procedure ComThread13 is
  begin
    ComponentThread(13);
  end ComThread13;
  procedure ComThread14 is
  begin
    ComponentThread(14);
  end ComThread14;

  -- The TimingScheduler thread
  procedure TimingScheduler is -- thread to manage component threads

    I    : Integer;
    Kind : Component.ComponentKind;
    ReqPriority    : ComponentThreadPriority;
    ThreadPriority : ThreadPriorityType;

  begin -- TimingScheduler

    -- Create the component thread pool/factory; one thread for each
    -- component.  -->>>>Nothing to do this >>>Wait until all are created before starting the threads.
    if ThreadTable.Count > 0 then
      I := 1;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread1 "; --( Count => 10,
                                   -- Data  => "ComThread1          " );
      ThreadTable.List(I).Priority := ThreadPriority;
--      if Kind = Component.RECEIVE then
--        ReceiveIndex := ReceiveIndex + 1;
----        ThreadTable.List(I).ThreadInstance := Remote.ReceiveThread(ReceiveIndex);
--      else
  ----      ThreadTable.List(I).ThreadInstance := ComThread1'Access;
                                              --ComponentThreadAccessType
                                              --(ComThread1'Address); --new Thread(ComThread1);
--        ThreadTable.List(I).ThreadInstance := to_Access(ComThread1'Address); --new Thread(ComThread1);
          -- <<< what for new Thread? >>>
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
--        ( Start      => to_Entry_Addr(Component.ComponentTable.List(I).fMain),
        ( Start      => ComThread1'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 1 then
      I := 2;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread2 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
--        ( Start      => to_Entry_Addr(Component.ComponentTable.List(I).fMain),
        ( Start      => ComThread2'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 2 then
      I := 3;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread3 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread3'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 3 then
      I := 4;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread4 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread4'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 4 then
      I := 5;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread5 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread5'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 5 then
      I := 6;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread6 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread6'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 6 then
      I := 7;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread7 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread7'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 7 then
      I := 8;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread8 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread8'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 8 then
      I := 9;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread9 ";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread9'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 9 then
      I := 10;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread10";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread10'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 10 then
      I := 11;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread11";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread11'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 11 then
      I := 12;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread12";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread12'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 12 then
      I := 13;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread13";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread13'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;
    if ThreadTable.Count > 13 then
      I := 14;
      Kind := Component.ComponentTable.List(I).Kind;
      ReqPriority := Component.ComponentTable.List(I).Priority;
      ThreadPriority := ConvertThreadPriority(Kind, ReqPriority);
      ThreadTable.List(I).Name := "ComThread14";
      ThreadTable.List(I).Priority := ThreadPriority;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread14'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadPriority) );
    end if;

    AllThreadsStarted := True; -- since started as created

    while True loop -- forever
      Delay 10.0;
    end loop;
  end TimingScheduler;

  procedure Create is

--  SchedulerPriority : ThreadPriorityType;

  begin -- Create

    ThreadTable.Count := Component.ComponentTable.Count;

    SchedulerThread := ExecItf.Create_Thread
                       ( Start      => TimingScheduler'address,
                         Parameters => to_Void_Ptr(System.Null_Address),
                         Stack_Size => 0,
                         Priority   => Priority_to_Int(Normal) ); --AboveNormal) );
--<<< this going to set the priority or need to use a ExecItf function? >>>

  end Create;

end Threads;
