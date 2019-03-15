
with App;
with App2;
with Itf;
with Threads;

procedure Main is

  AppId : Itf.ApplicationIdType;

begin -- Main

  -- Launch the general packages of this application
  AppId.Name := "App 2     ";
  AppId.Id   := 2;
  App.Launch(AppId);

  -- Install the components of this application
  App2.Install;

  -- Now, after all the components have been installed, create their threads
  Threads.Create;

end Main;
