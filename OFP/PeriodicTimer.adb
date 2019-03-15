
with ExecItf;
--with Numeric_Conversion; -- only for the test
with System;
with Text_IO;            -- only for the test
with Unchecked_Conversion;

package body PeriodicTimer is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  -- Handles of a particular timer
  TimerThread : ExecItf.HANDLE;
  TimerHandle : ExecItf.HANDLE;
  WaitHandle  : ExecItf.HANDLE;

  procedure TimerProcedure is

    InfiniteValue : Integer := -1;
    Result : Boolean;

--    Timer_Min
    -- System time minutes as ASCII
--    : Numeric_Conversion.String_Type;
--    Timer_Sec
    -- System time seconds as ASCII
--    : Numeric_Conversion.String_Type;
--    Timer_MS : Numeric_Conversion.String_Type;
    System_Time
    -- System time
    : ExecItf.System_Time_Type;

    Rtrn : ExecItf.WaitReturnType;

    function toInt is new Unchecked_Conversion( Source => ExecItf.HANDLE,
                                                Target => Integer );

    use type System.Address;

  begin -- TimerProcedure

    if Index = 1 then
      Text_IO.Put_Line("in TimerProcedure for 1");
    elsif Index = 2 then
      Text_IO.Put_Line("in TimerProcedure for 2");
    elsif Index = 3 then
      Text_IO.Put_Line("in TimerProcedure for 3");
    elsif Index = 4 then
      Text_IO.Put_Line("in TimerProcedure for 4");
    elsif Index = 5 then
      Text_IO.Put_Line("in TimerProcedure for 5");
    elsif Index = 6 then
      Text_IO.Put_Line("in TimerProcedure for 6");
    elsif Index = 7 then
      Text_IO.Put_Line("in TimerProcedure for 7");
    elsif Index = 8 then
      Text_IO.Put_Line("in TimerProcedure for 8");
    elsif Index = 9 then
      Text_IO.Put_Line("in TimerProcedure for 9");
    else
      Text_IO.Put_Line("in TimerProcedure for unknown");
    end if;

    while (true) loop
      Rtrn := ExecItf.WaitForSingleObject(TimerHandle,InfiniteValue);

      System_Time := ExecItf.SystemTime;
--      Timer_Sec := Numeric_Conversion.Integer_to_Ascii
--                   ( Number => Integer(System_Time.Second),
--                     Count  => 2 );
--      if Index = 1 then
----        Text_IO.Put("WaitForSingleObject 1 after return ");
----        Text_IO.Put(Timer_Min.Value(1..Timer_Min.Length));
----        Text_IO.Put(" ");
----        Text_IO.Put(Timer_Sec.Value(1..Timer_Sec.Length));
----        Text_IO.Put(" ");
----        Text_IO.Put_Line(Timer_MS.Value(1..Timer_MS.Length));
--        Text_IO.Put("T1 ");
--        Text_IO.Put_Line(Timer_Sec.Value(1..Timer_Sec.Length));
--      elsif Index = 2 then
----        Text_IO.Put("WaitForSingleObject 2 after return ");
----        Text_IO.Put(Timer_Min.Value(1..Timer_Min.Length));
----        Text_IO.Put(" ");
----        Text_IO.Put(Timer_Sec.Value(1..Timer_Sec.Length));
----        Text_IO.Put(" ");
----        Text_IO.Put_Line(Timer_MS.Value(1..Timer_MS.Length));
--        Text_IO.Put("T2 ");
--        Text_IO.Put_Line(Timer_Sec.Value(1..Timer_Sec.Length));
--      else
--        Text_IO.Put("T3 ");
--        Text_IO.Put_Line(Timer_Sec.Value(1..Timer_Sec.Length));
--      end if;
      if WaitHandle /= System.Null_Address then
        Text_IO.Put("TimerProcedure Set_Event ");
        Int_IO.Put(toInt(WaitHandle));
        Text_IO.Put_Line(" ");
        Result := ExecItf.Set_Event( Event => WaitHandle );
      end if;
    end loop;

  end TimerProcedure;

  procedure StartTimer
  ( DueTime  : in Integer;
    Period   : in Integer;
    Priority : in Integer;
    Wait     : in ExecItf.HANDLE
  ) is

    Rtrn : Boolean;

    function to_Void_Ptr is new Unchecked_Conversion
                                ( Source => System.Address,
                                  Target => ExecItf.Void_Ptr );
    begin -- StartTimer

    WaitHandle := Wait;

    TimerThread := ExecItf.Create_Thread
                   ( Start      => TimerProcedure'Address,
                     Parameters => to_Void_Ptr(System.Null_Address),
                     Stack_Size => 0,
                     Priority   => Priority );
    TimerHandle := ExecItf.CreateWaitableTimer( ManualReset => False );

    Rtrn := ExecItf.SetWaitableTimer
            ( Timer   => TimerHandle,
              DueTime => DueTime,
              Period  => Period,
              Resume  => False );

--    TimerProcedure;

  end StartTimer;

end PeriodicTimer;
