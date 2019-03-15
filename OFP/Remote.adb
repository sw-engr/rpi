
with Component;
with Configuration;
with CStrings;
with Delivery;
with Disburse;
with Format;
with Heartbeat;
with Library;
with NamedPipe;
with NamedPipeNames;
with Receive1;
with Receive2;
with Receive3;
with ReceiveInterface;
with System;
with Text_IO;
with Threads;
with Topic;
with Transmit1;
with Transmit2;
with Transmit3;
with Unchecked_Conversion;

package body Remote is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  type RemoteConnectionsDataType
  is record
    ReceiveComponentKey  : Itf.ParticipantKeyType; -- Key of particular Receive
    TransmitComponentKey : Itf.ParticipantKeyType; -- Key of particular Transmit
    RemoteAppId          : Itf.Int8; -- remote application
    RegisterSent         : Boolean; -- true if REGISTER message sent to remote app
    RegisterCompleted    : Boolean; -- true if REGISTER message acknowledged
  end record;

  type RemoteConnectionsArrayType
  is array (1..Configuration.MaxApplications-1) of RemoteConnectionsDataType;

  type RemoteConnectionsTableType
  is record
    Count : Integer; -- Number of declared connection possibilities
    List  : RemoteConnectionsArrayType;
  end record;

  RemoteConnections : RemoteConnectionsTableType;

  type ConnectionsDataType
  is record
    PipeConnected    : Boolean; -- client pipe connected to server pipe
    Connected        : Boolean; -- true if connected with remote app via heartbeats
    ConsecutiveValid : Integer; -- consecutive valid heartbeats
  end record;

  type ConnectionsDataArrayType
  is array(1..Configuration.MaxApplications) of ConnectionsDataType;

  -- This array has one unused (that is, extra) position.  This is because
  -- references to it use the remote app id as the index and the position
  -- that corresponds to the local app won't be used.
  -- The booleans and integers of this array are referenced from/by other
  -- packages with this Remote package only being a "central" location.
  Connections : ConnectionsDataArrayType;

  type ReceivedMessageConnectionType
  --| Method and Connection of received message
  is record
    Remote : Itf.Int8;
    -- Remote connection of received message; i.e., such as 2 for pipe of
    -- "App 2 to 1" for NamedPipe method receive of application 1 from
    -- application 2
    Length : Integer;
    -- Length of received message
  end record;

  type TransmitMessageType
  --| Remote App to which to transmit
  is record
    Remote_Id : Itf.ApplicationIdType;
    -- Remote application id if known
  end record;

  type TransmitMessageQueueElementType
  -- Data to be unqueued for a message to be transmitted
  is record
    Format  : TransmitMessageType;
    -- Possible app id of remote app
    Message : Itf.GenericMessageType;
    -- Message to be transmitted
  end record;

  ReceiveMessages : Itf.V_Short_String_Type
                  := ( Count => 15,
                       Data  => "ReceiveMessages     " );

  ReceiveIndex : Integer := 0;
  ReceiveInterfaceKey : Itf.ParticipantKeyType := (0,0,0);


  procedure Initialize is
  begin -- Initialize

    RemoteConnections.Count := 0;
    ReceiveIndex := 0;

    for I in 1..Configuration.ConfigurationTable.Count loop
      Connections(I).Connected := False;
      Connections(I).PipeConnected := False;
      Connections(I).ConsecutiveValid := 0;
    end loop;

    Format.Initialize;

  end Initialize;

  procedure Launch is

    Index  : Integer := 0; -- Index into NamedPipeNames
    RIndex : Integer := 0; -- Index into RemoteConnections table and the
                           -- selector of the Receive/Transmit package pair

    Match : Boolean;

    use type Itf.Int8;

  begin -- Launch

    NamedPipeNames.Initialize;

    if Configuration.ConfigurationTable.Count > 1 then
      -- Remote applications exist in the configuration.
      -- Instantiate a Receive and a Transmit framework
      -- component instance for each remote application.
      -- Note1: Ada can instantiate a generic package whereas C# can 
      -- instantiate an instance of a class.  However, after trying
      -- the instantiated generic packages, they didn't seem to work.
      -- Therefore, a warehouse of Receive and Transmit packages were 
      -- created and are selected in turn for each remote application 
      -- of the configuration.  These allow a different thread to be 
      -- created for each of the packages.
      -- Note2: However, for NamedPipe an array of Pairs for local and remote
      -- applications was created to keep track of data for each possible
      -- connection assuming a maximum of 4 applications in the configuration.
      -- NamedPipe is invoked from the particular Receive and Transmit packages
      -- so runs in the thread of the invoking package.
      for I in 1..Configuration.ConfigurationTable.Count loop
        Match := False;
        if Configuration.ConfigurationTable.List(I).App.Id /=
           Itf.ApplicationId.Id -- other app than this one
        then
          -- Instantiate instance of NamedPipe to communicate
          -- with this remote application.
          if Itf.ApplicationId.Id = 1 and then -- assuming just 3 possible
             Configuration.ConfigurationTable.List(I).App.Id = 2
          then
            Match := True;
            Index  := 1; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          elsif Itf.ApplicationId.Id = 2 and then -- use the reverse
                Configuration.ConfigurationTable.List(I).App.Id = 1
          then
            Match := True;
            Index  := 2; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          end if; -- compare if first pair of app possibilities
          if Itf.ApplicationId.Id = 1 and then -- assuming just apps 1, 2, 3 and 4
             Configuration.ConfigurationTable.List(I).App.Id = 3
          then
            Match := True;
            Index  := 3; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          elsif Itf.ApplicationId.Id = 3 and then -- use the reverse
                Configuration.ConfigurationTable.List(I).App.Id = 1
          then
            Match := True;
            Index  := 4; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          end if; 
          if Itf.ApplicationId.Id = 1 and then -- 3rd pair
             Configuration.ConfigurationTable.List(I).App.Id = 4
          then
            Match := True;
            Index  := 5; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          elsif Itf.ApplicationId.Id = 4 and then -- use the reverse
                Configuration.ConfigurationTable.List(I).App.Id = 1
          then
            Match := True;
            Index  := 6; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          end if; 
          if Itf.ApplicationId.Id = 2 and then -- 4th pair
             Configuration.ConfigurationTable.List(I).App.Id = 3
          then
            Match := True;
            Index  := 7; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          elsif Itf.ApplicationId.Id = 3 and then -- use the reverse
                Configuration.ConfigurationTable.List(I).App.Id = 2
          then
            Match := True;
            Index  := 8; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          end if; 
          if Itf.ApplicationId.Id = 2 and then -- 5th pair
             Configuration.ConfigurationTable.List(I).App.Id = 4
          then
            Match := True;
            Index  := 9; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          elsif Itf.ApplicationId.Id = 4 and then -- use the reverse
                Configuration.ConfigurationTable.List(I).App.Id = 2
          then
            Match := True;
            Index  := 10; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          end if; 
          if Itf.ApplicationId.Id = 3 and then -- 6th pair
             Configuration.ConfigurationTable.List(I).App.Id = 4
          then
            Match := True;
            Index  := 11; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          elsif Itf.ApplicationId.Id = 4 and then -- use the reverse
                Configuration.ConfigurationTable.List(I).App.Id = 3
          then
            Match := True;
            Index  := 12; -- index into NamedPipeNames array
            RIndex := RIndex + 1;
          end if; 

          if Match then
            -- Save the Remote App Identifier from the configuration
            RemoteConnections.List(RIndex).RemoteAppId :=
              Configuration.ConfigurationTable.List(I).App.Id;
            -- Initialize for the connection
            RemoteConnections.List(RIndex).RegisterSent := False;
            RemoteConnections.List(RIndex).RegisterCompleted := False;

            -- Install the Receive and Transmit components from the warehouse
            if RIndex = 1 then  
              RemoteConnections.List(RIndex).ReceiveComponentKey :=
                Receive1.Install
                ( RIndex,
                  RemoteConnections.List(RIndex).RemoteAppId );
              RemoteConnections.List(RIndex).TransmitComponentKey :=
                Transmit1.Install
                ( RIndex,
                  RemoteConnections.List(RIndex).RemoteAppId );

              -- Instantiate the NamedPipe package for the remote app and supply
              -- the callbacks to the associated Receive and Transmit packages.
              declare
                OpenReceivePipe : Itf.ReceiveOpenCallbackType;
                ReceiveMessage  : Itf.ReceiveCallbackType;
                TransmitMessage : Itf.TransmitCallbackType;
                Callback        : System.Address;
              begin
                NamedPipe.Index := Index;
                NamedPipe.RemoteId := RemoteConnections.List(RIndex).RemoteAppId;
                NamedPipe.ReceiveKey := 
                  RemoteConnections.List(RIndex).ReceiveComponentKey;
                NamedPipe.TransmitKey := 
                  RemoteConnections.List(RIndex).TransmitComponentKey;
                NamedPipe.Initialize( 1, 
                                      Itf.ApplicationId.Id,
                                      OpenReceivePipe,
                                      ReceiveMessage,
                                      TransmitMessage );
                Callback := Receive1.Initialize( OpenReceivePipe, 
                                                 ReceiveMessage );

                Transmit1.Initialize( TransmitMessage );
              end;
            elsif RIndex = 2 then 
              RemoteConnections.List(RIndex).ReceiveComponentKey :=
                Receive2.Install
                ( RIndex,
                  RemoteConnections.List(RIndex).RemoteAppId );
              RemoteConnections.List(RIndex).TransmitComponentKey :=
                Transmit2.Install
                ( RIndex,
                  RemoteConnections.List(RIndex).RemoteAppId );

              -- Instantiate NamedPipe package for the remote app and supply
              -- the callbacks to the associated Receive and Transmit packages.
              declare
                OpenReceivePipe : Itf.ReceiveOpenCallbackType;
                ReceiveMessage  : Itf.ReceiveCallbackType;
                TransmitMessage : Itf.TransmitCallbackType;
                Callback        : System.Address;
              begin
                NamedPipe.Index := Index;
                NamedPipe.RemoteId := RemoteConnections.List(RIndex).RemoteAppId;
                NamedPipe.ReceiveKey := 
                  RemoteConnections.List(RIndex).ReceiveComponentKey;
                NamedPipe.TransmitKey := 
                  RemoteConnections.List(RIndex).TransmitComponentKey;
                NamedPipe.Initialize( 2, 
                                      Itf.ApplicationId.Id,
                                      OpenReceivePipe,
                                      ReceiveMessage,
                                      TransmitMessage );
                Callback := Receive2.Initialize( OpenReceivePipe,
                                                 ReceiveMessage );
                  
                Transmit2.Initialize( TransmitMessage );
              end;
            else -- can't be more than 3
              RemoteConnections.List(RIndex).ReceiveComponentKey :=
                Receive3.Install
                ( RIndex,
                  RemoteConnections.List(RIndex).RemoteAppId );
              RemoteConnections.List(RIndex).TransmitComponentKey :=
                Transmit3.Install
                ( RIndex,
                  RemoteConnections.List(RIndex).RemoteAppId );

              -- Instantiate NamedPipe package for the remote app and supply
              -- the callbacks to the associated Receive and Transmit packages.
              declare
                OpenReceivePipe : Itf.ReceiveOpenCallbackType;
                ReceiveMessage  : Itf.ReceiveCallbackType;
                TransmitMessage : Itf.TransmitCallbackType;
                Callback        : System.Address;
              begin
                NamedPipe.Index := Index;
                NamedPipe.RemoteId := RemoteConnections.List(RIndex).RemoteAppId;
                NamedPipe.ReceiveKey := 
                  RemoteConnections.List(RIndex).ReceiveComponentKey;
                NamedPipe.TransmitKey := 
                  RemoteConnections.List(RIndex).TransmitComponentKey;
                NamedPipe.Initialize( 3,
                                      Itf.ApplicationId.Id,
                                      OpenReceivePipe,
                                      ReceiveMessage,
                                      TransmitMessage );
                Callback := Receive3.Initialize( OpenReceivePipe, 
                                                 ReceiveMessage );
                  
                Transmit3.Initialize( TransmitMessage );
              end;
            end if;
          end if;
            
          -- Increment count of remote connections.
          RemoteConnections.Count := RemoteConnections.Count + 1;
 
        end if; -- local application different from remote application
      end loop;

    end if; -- more than one application in configuration

    -- Invoke the Install procedure of the ReceiveInterface component.  
    -- It will instantiate its queue that is visible to the various Receive 
    -- "components" via a callback.  The Install will Register itself with 
    -- the Component package.
    ReceiveInterfaceKey := ReceiveInterface.Install;

    -- Also Register the Heartbeat component to send periodic Heartbeat messages
    -- to the Transmit components for each of the Remote applications.  Delivery
    -- will forward the message to each of the registered Transmit components.
    Heartbeat.Install;
    
  end Launch;

  -- Return whether remote app is connected
  function RemoteConnected
  ( RemoteAppId : in Itf.Int8
  ) return Boolean is

    use type Itf.Int8;

  begin -- RemoteConnected

    for I in 1..RemoteConnections.Count loop
      if RemoteConnections.List(I).RemoteAppId = RemoteAppId then
        return Connections(I).Connected;
      end if;
    end loop;
    return False; -- no match

  end RemoteConnected;

  -- Record that whether or not connected to Remote App
  procedure SetConnected
  ( RemoteAppId : in Itf.Int8;
    Set         : in Boolean
  ) is

    use type Itf.Int8;

  begin -- SetConnected

    for I in 1..RemoteConnections.Count loop
      if RemoteConnections.List(I).RemoteAppId = RemoteAppId then
        Connections(I).Connected := Set;
        if not Set then
          Connections(I).ConsecutiveValid := 0;
          Connections(I).PipeConnected := False;
        end if;
        return;
      end if;
    end loop;

  end SetConnected;

  -- Return whether remote app has acknowledged Register Request.
  function RegisterAcknowledged
  ( RemoteAppId : in Itf.Int8
  ) return Boolean is

    use type Itf.Int8;

  begin -- RegisterAcknowledged

    for I in 1..RemoteConnections.Count loop
      if RemoteConnections.List(I).RemoteAppId = RemoteAppId then
        return RemoteConnections.List(I).RegisterCompleted;
      end if;
    end loop;
    return false;

  end RegisterAcknowledged;

  -- Return consecutive valid heartbeats
  function ConsecutiveValidHeartbeats
  ( RemoteAppId : in Itf.Int8
  ) return Integer is

    use type Itf.Int8;

  begin -- ConsecutiveValidHeartbeats

    for I in 1..Configuration.ConfigurationTable.Count loop
      if RemoteConnections.List(I).RemoteAppId = RemoteAppId then
        return Connections(I).ConsecutiveValid;
      end if;
    end loop;
    return 0;

  end ConsecutiveValidHeartbeats;

  -- Update consecutive valid heartbeats
  procedure ConsecutiveValidHeartbeats
  ( RemoteAppId : in Itf.Int8;
    Value       : in Integer
  ) is

    use type Itf.Int8;

  begin -- ConsecutiveValidHeartbeats

    for I in 1..Configuration.ConfigurationTable.Count loop
      if RemoteConnections.List(I).RemoteAppId = RemoteAppId then
        Connections(I).ConsecutiveValid := Value;
        return;
      end if;
    end loop;

  end ConsecutiveValidHeartbeats;

  -- Record that remote app acknowledged the Register Request.
  procedure SetRegisterAcknowledged
  ( RemoteAppId : in Itf.Int8;
    Set         : in Boolean
  ) is

    use type Itf.Int8;

  begin -- SetRegisterAcknowledged

    for I in 1..RemoteConnections.Count loop
      if RemoteConnections.List(I).RemoteAppId = RemoteAppId then
        RemoteConnections.List(I).RegisterCompleted := Set;
        return;
      end if;
    end loop;

  end SetRegisterAcknowledged;

end Remote;
