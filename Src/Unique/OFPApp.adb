with ComOFP;
with Delivery;
with Text_IO;
with Threads;

procedure OFPApp is

begin -- OFPApp

  -- Build the DeliveryTable from the Delivery.dat file
  Delivery.Initialize;

  -- Install the components of OFPApp
  ComOFP.Install;

  Text_IO.Put_Line("calling Threads Create");

  -- Create the threads for the thread table objects and enter the callbacks
  Threads.Create;

end OFPApp;
