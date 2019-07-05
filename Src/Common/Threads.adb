with CStrings;
with ExecItf;
with System;
with Text_IO;
with Unchecked_Conversion;

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

--  MaxComponents
--  : constant Integer := 24;

  type ThreadDataType
  -- Data for ThreadTable
  is record
    Name           : String(1..25);
    Index          : Integer;
    Callback       : CallbackType;
    ThreadInstance : ExecItf.HANDLE;
    WaitEvent      : ExecItf.HANDLE;
    Priority       : ThreadPriorityType;
  end record;

  type ThreadDataArrayType
  is array (1..MaxComponents) of ThreadDataType;

  -- Component thread list
  type ComponentThreadType
  is record
    Count : Integer;             -- Number of component threads.
    List  : ThreadDataArrayType; -- List of component threads
  end record;

  -- Thread pool of component threads
  ThreadTable : ComponentThreadType;

  -- To allow ComponentThread to idle until all component threads have started
  AllThreadsStarted : Boolean := False;

  SchedulerThread
  -- Handle returned by ExecItf Create_Thread for the Scheduler thread
  : ExecItf.HANDLE;

  function to_Entry_Addr is new Unchecked_Conversion
                                ( Source => CallbackType,
                                  Target => System.Address );
  function to_Void_Ptr is new Unchecked_Conversion
                              ( Source => System.Address,
                                Target => ExecItf.Void_Ptr );

  -- Look up the Name in the registered component and return the index of where
  -- the data has been stored.  Return zero if the Name is not in the list.
  function Lookup
  ( Name : in String
  ) return Integer is

    Idx : Integer;  -- Index of component in ThreadTable
    CompareName : String(1..Name'Length+1);

  begin -- Lookup

    CompareName(1..Name'Length) := Name(Name'First..Name'Last);
    CompareName(Name'Last+1) := ASCII.NUL;

    Idx := 0;
    for I in 1..ThreadTable.Count loop
      declare
        TableName : String(1..ThreadTable.List(I).Name'Last+1);
      begin
        TableName(1..Name'Last) :=
        ThreadTable.List(I).Name(Name'First..Name'Last);
        TableName(Name'Last+1) := ASCII.NUL;
        if CStrings.Compare( Left       => CompareName'Address,
                             Right      => TableName'Address,
                             IgnoreCase => True ) = 0
        then
          Idx := I;
          exit; -- loop
        end if;
      end;
    end loop;

    -- Return the index.
    return Idx;

  end Lookup;

  -- Convert component thread priority to that of Windows
  function ConvertThreadPriority
  ( Priority : in ComponentThreadPriority
  ) return ThreadPriorityType is
  begin -- Only for user component threads.
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
  end ConvertThreadPriority;

  -- Return count of entries in Thread Table plus 1
  function TableCount
  return Integer is

  begin -- TableCount

    return ThreadTable.Count + 1;

  end TableCount;

  -- Add item to ThreadTable whether a component or a WinSock thread
  function Install
  ( Name     : in String;
    Index    : in Integer;
    Priority : in ComponentThreadPriority;
    Callback : in CallbackType
  ) return RegisterResult is

    CIndex   : Integer;  -- Index of item/component; 0 if not found
    Location : Integer;  -- Location of item/component in the table
    Result   : RegisterResult;

  begin -- Install

Text_IO.Put("Threads Install ");
Text_IO.Put(Name);
Text_IO.Put_Line(" ");
    Result.Status := NONE; -- unresolved

    -- Look up the item/component in the Table
    CIndex := Lookup(Name);
    -- Return if iten/component has already been registered
    if CIndex > 0 then -- duplicate registration
      Result.Status := DUPLICATE;
      return Result;
    end if;

    -- Return if item/component is without a Callback entry point.
    if Callback = null then
      Result.Status := INVALID;
      return Result;
    end if;

    Location := ThreadTable.Count + 1;
    ThreadTable.Count := Location;

    -- Store item/component data in the table
    ThreadTable.List(Location).Name(Name'First..Name'Last) :=
      Name(Name'First..Name'Last);
    ThreadTable.List(Location).Index    := Index;
    ThreadTable.List(Location).Callback := Callback;
    ThreadTable.List(Location).Priority := ConvertThreadPriority(Priority);
    Text_IO.Put("Thread item Name ");
    Text_IO.Put(Name(Name'First..Name'Last));
    Text_IO.Put_Line(" ");

    -- Obtain an event to associate with the item/component
    declare
      EventName : String(1..Name'Last+1);
      package Int_IO is new Text_IO.Integer_IO( Integer );
      function to_Int is new Unchecked_Conversion( Source => ExecItf.HANDLE,
                                                   Target => Integer );
    begin
      EventName(1..Name'Last) := Name(Name'First..Name'Last);
      EventName(Name'Last+1) := ASCII.NUL; -- terminating NUL
      ThreadTable.List(Location).WaitEvent :=
        ExecItf.CreateEvent
        ( ManualReset  => True,
          InitialState => False,
          Name         => EventName'Address );
      Result.Event := ThreadTable.List(Location).WaitEvent;
      Text_IO.Put("EventName ");
      Text_IO.Put(EventName);
      Text_IO.Put(" ");
      Int_IO.Put(to_Int(Result.Event));
      Text_IO.Put_Line(" ");
    end;

    -- Return status and the assigned event
    Result.Status := VALID;
    return Result;

  end Install;


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

  -- The common item/component thread code.  This code runs in the thread
  -- of the invoking thread.  The input parameter is its location in the
  -- thread table.
  -- Note: There are multiple "copies" of this function running; one
  --       for each thread as called by that item/component's ComThread.
  --       Therefore, the data (such as CycleInterval) is on the stack
  --       in a different location for each such thread.
  procedure ComponentThread
  ( Location : in Integer
  ) is

    CycleInterval : Integer;
    DelayInterval : Integer;
    Callback      : CallbackType;
    Index         : Integer;

    function to_Int is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Integer );

  begin -- ComponentThread

    CycleInterval := 500; -- msec
    DelayInterval := CycleInterval; -- initial delay

    -- Wait until all component threads have been started
    while AllThreadsStarted = False loop
      Delay(Duration(DelayInterval/100)); -- using Periods in seconds
    end loop;

    -- Obtain the thread name, callback, and index to associate with
    -- the item/component
--    Text_IO.Put("Threads ComponentThread ");
--    Int_IO.Put(Integer(Location));
--    Text_IO.Put(" ");
--    Text_IO.Put_Line(
--      ThreadTable.List(Location).Name(1..ThreadTable.List(Location).Name'Last));

    Callback := ThreadTable.List(Location).Callback;
    Index    := ThreadTable.List(Location).Index;
    if Callback /= null then -- component with periodic entry point
--declare
--function toInt is new Unchecked_Conversion (Source => CallbackType,
--                                            Target => Integer );
--begin
--Text_IO.Put("Thread callback for ");
--int_IO.put(integer(location));
--text_io.put(" ");
--int_io.put(Index);
--text_io.put(" ");
--int_IO.put(toInt(Callback));
--text_io.put_line(" ");
--end;

      -- Create instance of Timer for periodic components
--      if Component.ComponentTable.List(Location).Period > 0 then

        -- Instantiate PeriodicTimer for this component
--        declare
--          package ExecuteTimer is new PeriodicTimer( Index => Location );
----        ExecuteTimer := 0; --new PeriodicTimer(location);
--function toInt is new Unchecked_Conversion (Source => System.Address,
--                                            Target => Integer );
--        begin
--          Period := Component.ComponentTable.List(Location).Period;
--          Text_IO.Put("StartTimer ");
--          Int_IO.Put(to_Int(Component.ComponentTable.List(Location).WaitEvent));
--          Text_IO.Put(" ");
--          Int_IO.Put(toInt(ExecuteTimer.StartTimer'address));
--          Text_IO.Put(" ");
--          Int_IO.Put(toInt(ExecuteTimer'address));
--          Text_IO.Put_Line(" ");

--          Text_IO.Put_Line(" ");
--          ExecuteTimer.StartTimer
--          ( DueTime  => Period,
--            Period   => Period, -- milliseconds
--            Priority => 8, -- Normal
--            Wait     => ThreadTable.List(Location).WaitEvent );
--        end;
--      end if;
      -- Enter the component's callback to await a resume event from Timer or
      -- from receive of a message.
      Callback(Index);

    end if; -- Callback /= null

    Delay(Duration(DelayInterval/100)); -- using Periods in seconds

  end ComponentThread;

  -- Component thread factory -- one thread for each possible item/component.
  -- Only those for the items/components in the ThreadTable will be run.
  -- Notes:
  --   1) These procedures are provided for ExecItf Create_Thread to reference
  --      since invoking it will immediately start the referenced procedure.
  --      Each will then invoke the common ComponentThread procedure to await
  --      the creation of all the threads, perform any special treatment of
  --      periodic components, and then enter the component's callback where
  --      it will loop forever.
  --   2) More such procedures can be added if the this package has to be
  --      extended to treat applications with more components.
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
  procedure ComThread15 is
  begin
    ComponentThread(15);
  end ComThread15;
  procedure ComThread16 is
  begin
    ComponentThread(16);
  end ComThread16;
  procedure ComThread17 is
  begin
    ComponentThread(17);
  end ComThread17;
  procedure ComThread18 is
  begin
    ComponentThread(18);
  end ComThread18;
  procedure ComThread19 is
  begin
    ComponentThread(19);
  end ComThread19;
  procedure ComThread20 is
  begin
    ComponentThread(20);
  end ComThread20;
  procedure ComThread21 is
  begin
    ComponentThread(21);
  end ComThread21;
  procedure ComThread22 is
  begin
    ComponentThread(22);
  end ComThread22;
  procedure ComThread23 is
  begin
    ComponentThread(23);
  end ComThread23;
  procedure ComThread24 is
  begin
    ComponentThread(24);
  end ComThread24;

  -- The TimingScheduler thread
  procedure TimingScheduler is -- thread to manage component threads

    I : Integer;

  begin -- TimingScheduler

    -- Create the component thread pool/factory; one thread for each component.
    if ThreadTable.Count > 0 then
      I := 1;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread1'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 1 then
      I := 2;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread2'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 2 then
      I := 3;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread3'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 3 then
      I := 4;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread4'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 4 then
      I := 5;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread5'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 5 then
      I := 6;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread6'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );

    end if;
    if ThreadTable.Count > 6 then
      I := 7;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread7'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 7 then
      I := 8;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread8'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 8 then
      I := 9;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread9'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 9 then
      I := 10;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread10'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 10 then
      I := 11;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread11'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 11 then
      I := 12;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread12'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 12 then
      I := 13;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread13'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 13 then
      I := 14;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread14'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 14 then
      I := 15;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread15'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 15 then
      I := 16;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread16'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 16 then
      I := 17;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread17'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 17 then
      I := 18;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread18'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 18 then
      I := 19;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread19'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 19 then
      I := 20;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread20'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 20 then
      I := 21;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread21'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 21 then
      I := 22;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread22'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;
    if ThreadTable.Count > 22 then
      I := 23;
      ThreadTable.List(I).ThreadInstance :=
        ExecItf.Create_Thread
        ( Start      => ComThread23'Address,
          Parameters => to_Void_Ptr(System.Null_Address),
          Stack_Size => 0,
          Priority   => Priority_to_Int(ThreadTable.List(I).Priority) );
    end if;

    AllThreadsStarted := True; -- since all threads started as created

    -- Never return from invocation of Threads.Create
    while True loop -- forever
      Delay 10.0;
    end loop;
  end TimingScheduler;

  procedure Create is

  begin -- Create

    SchedulerThread := ExecItf.Create_Thread
                       ( Start      => TimingScheduler'address,
                         Parameters => to_Void_Ptr(System.Null_Address),
                         Stack_Size => 0,
                         Priority   => Priority_to_Int(Normal) );

  end Create;

end Threads;

