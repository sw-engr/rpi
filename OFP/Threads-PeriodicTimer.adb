
separate( Threads )

package body PeriodicTimer is

  Location : Integer; -- index into componentTable
  Iterations : Integer := 0;
--        Stopwatch stopWatch = new Stopwatch();

  --      public PeriodicTimer(int index) // constructor
  --      {
  --          Console.WriteLine("PeriodicTimer {0}", index);
  --          location = index;

  --      } // end constructor
  procedure Initialize
  ( Index : Integer
  ) is
  begin -- Initialize
    Location := Index;
  end Initialize;

--        public void StartTimer(int dueTime, int period)
--        {
--            Timer periodicTimer = new Timer(new TimerCallback(TimerProcedure));
--            periodicTimer.Change(dueTime, period);
--            stopWatch.Start();
--        }

--        public void ResetInvokedTimer()
--        {
--            Console.WriteLine("ResetInvokedTimer entered");
--            StartTimer(0, 0);
--        } // end ResetInvokedTimer

--        private void TimerProcedure(object state)
--        {
--            // The state object is the Timer object.
--            Timer periodicTimer = (Timer)state;
--            stopWatch.Stop();
--            TimeSpan ts = stopWatch.Elapsed;
--            stopWatch.Start();
--            iterations++;
--            Console.WriteLine("TimerProcedure {0} {1} {2}",
--                Component.componentTable.list[location].name,
--                ts, iterations);

--            // Invoke component's Signal.
--            Component.componentTable.list[location].waitHandle.Set();

--        } // end TimerProcedure

end PeriodicTimer;
