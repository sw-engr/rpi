with Component2;
with ExComponent;
with Text_IO;
with Threads;
with WinSock;

procedure App2 is

begin -- App2

  -- Initialize certain WinSock tables and input and parse the Delivery.dat file
  WinSock.Initialize;

  -- Install the components of App2
  Component2.Install;
  ExComponent.Install;

  -- Complete the WinSock tables and install the WinSock Recv and Xmit for each
  -- pair of components
  WinSock.Finalize;

  Text_IO.Put_Line("calling Threads Create");

  -- Create the threads for the thread table objects and enter the callbacks
  Threads.Create;

end App2;
