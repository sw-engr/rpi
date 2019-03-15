
with CStrings;
with System;
with Text_IO;
with Unchecked_Conversion;

package body Component is

  package Int_IO is new Text_IO.Integer_IO( Integer );--debug

  Kind : ComponentKind := USER; -- can be overridden by Register of Receive, etc

  -- Find the index into the registered Application table of the currently
  -- running application and return it.
  function ApplicationIndex
  return Itf.Int8 is

    Index : Itf.Int8; -- Index of hosted function application in Application table

    use type Itf.Int8;

  begin -- ApplicationIndex

    -- Find index to be used for hosted function application processor
    Index := Itf.ApplicationId.Id;
    if Index = 0 then
      Text_IO.Put_Line("ERROR: Application Index doesn't exist");
    end if;
    return index;

  end ApplicationIndex;

  function CompareParticipants
  ( Left  : in Itf.ParticipantKeyType;
    Right : in Itf.ParticipantKeyType
  ) return Boolean is

    use type Itf.Int8;

  begin -- CompareParticipants

    -- Determine if two components are the same
    if ((Left.AppId = Right.AppId) and then
        (Left.ComId = Right.ComId) and then
        (Left.SubId = Right.SubId))
    then
      return True;
    else
      return False;
    end if;
  end CompareParticipants;

  function DisburseWrite
  ( ComponentKey : in Itf.ParticipantKeyType;
    Message      : in Itf.MessageType
  ) return Boolean is
  begin -- DisburseWrite

    for I in 1..ComponentTable.Count loop
      if CompareParticipants(ComponentTable.List(I).Key, ComponentKey) and then
         ComponentTable.List(I).QueueWrite /= null
      then
        return ComponentTable.List(I).QueueWrite(Message);
      end if;
    end loop;
    Text_IO.Put("Failed to find Component for ");
    Text_IO.Put_Line(Message.Data(1..2));
    return False; -- no component to which to write the message

  end DisburseWrite;

  -- Forward Message to instantiation of Transmit package to send to remote app
  function TransmitWrite
  ( RemoteAppId : in Itf.Int8;
    Message     : in Itf.MessageType
  ) return Boolean is

    Success : Boolean;

    use type Itf.Int8;

  begin -- TransmitWrite

    if RemoteAppId /= 0 then
      for I in 1..ComponentTable.Count loop
        if ComponentTable.List(I).RemoteAppId = RemoteAppId then
          return ComponentTable.List(I).QueueWrite(Message);
        end if;
      end loop;
      return False; -- no Transmit component to send message to remote app
    else -- forward to all Transmit components
      for I in 1..ComponentTable.Count loop
        if ComponentTable.List(I).Kind = TRANSMIT then
          Success := ComponentTable.List(I).QueueWrite(Message);
        end if;
      end loop;
      return True;
    end if;

  end TransmitWrite;

  procedure Initialize is
  begin -- Initialize
    NullKey.AppId := 0;
    NullKey.ComId := 0;
    NullKey.SubId := 0;

    ComponentTable.Count := 0;
    ComponentTable.AllowComponentRegistration := False;

  end Initialize;

  -- Look up the Name in the registered component and return the index of where
  -- the data has been stored.  Return zero if the Name is not in the list.
   function Lookup
   ( Name : in Itf.V_Medium_String_Type
   ) return Integer is

     App : Itf.Int8; -- Application id
     Idx : Integer;  -- Index of component in registry
     CompareName : String(1..Name.Count+1);

   begin -- Lookup

     App := ApplicationIndex;
     CompareName(1..Name.Count) := Name.Data(1..Name.Count);
     CompareName(Name.Count+1) := ASCII.NUL;

     Idx := 0;
     for I in 1..ComponentTable.Count loop
       declare
         TableName : String(1..ComponentTable.List(I).Name.Count+1);
       begin
         if Name.Count = ComponentTable.List(I).Name.Count then
           TableName(1..Name.Count) :=
             ComponentTable.List(I).Name.Data(1..Name.Count);
           TableName(Name.Count+1) := ASCII.NUL;
           if CStrings.Compare( Left       => CompareName'Address,
                                Right      => TableName'Address,
                                IgnoreCase => True ) = 0
           then
             Idx := I;
             exit; -- loop
           end if;
         end if;
       end;
     end loop;

    -- Return the index.
    return Idx;

  end Lookup;

  -- Increment the identifier of the component key and then return it with
  -- the application identifier as the next available component key.
  function NextComponentKey
  return Itf.ParticipantKeyType is

    App       : Itf.Int8; -- Index of current application
    ReturnApp : Itf.ParticipantKeyType;

  begin -- NextComponentKey

    App := ApplicationIndex;

    if ComponentTable.Count < MaxComponents then
      ComponentTable.Count := ComponentTable.Count + 1;
      ReturnApp.AppId := App;
      ReturnApp.ComId := Itf.Int8(ComponentTable.Count);
      ReturnApp.SubId := 0;
      return ReturnApp;
    else
      Text_IO.Put_Line("ERROR: More components than can be accommodated");
      return NullKey;
    end if;

  end NextComponentKey;

  function Register
  ( Name       : in Itf.V_Medium_String_Type; -- name of component
    RemoteId   : in Itf.Int8 := 0;  -- remote id for transmit
    Period     : in Integer; -- # of millisec at which Main() function to cycle
    Priority   : in Threads.ComponentThreadPriority; -- Requested priority of thread
    Callback   : in Topic.CallbackType; -- Callback() function of component
    Queue      : in System.Address; -- Disburse.QueuePtrType
    QueueWrite : in System.Address  -- message queue Write function of component
  ) return RegisterResult is

    App      : Itf.Int8; -- Index of current application
    CIndex   : Integer;  -- Index of component; 0 if not found
    Location : Integer;  -- Location of component in the registration table
    NewKey   : Itf.ParticipantKeyType; -- component key of new component
    Result : RegisterResult;

    function to_Write_Ptr is new Unchecked_Conversion
                                 ( Source => System.Address,
                                   Target => DisburseWriteCallback );

    use type Topic.CallbackType;

  begin -- Register

    Result.Status := NONE; -- unresolved
    Result.Key    := NullKey;
    Result.Event  := System.Null_Address;

    NewKey := NullKey;

    -- Find index to be used for application
    App := ApplicationIndex;

    -- Look up the component in the Component Table
    CIndex := Lookup(Name);

    -- Return if component has already been registered
    if CIndex > 0 then -- duplicate registration
      Result.Status := DUPLICATE;
      return Result;
    end if;

    -- Return if component is periodic but without a Main entry point.
    if Period > 0 then
      if Callback = null then
        Result.Status := INVALID;
        return Result;
      end if;
    end if;

    -- Add new component to component registration table.
    --
    --   First obtain the new table location and set the initial values.
    NewKey := NextComponentKey;

    Location := ComponentTable.Count;

    ComponentTable.List(Location).Kind := Kind;
    ComponentTable.List(Location).Name := Name;
    Kind := USER; -- clear Kind for next Register

    declare
      EventName : String(1..Name.Count+1);
      package Int_IO is new Text_IO.Integer_IO( Integer );
      function to_Int is new Unchecked_Conversion( Source => ExecItf.HANDLE,
                                                   Target => Integer );
    begin
      EventName(1..Name.Count) := Name.Data(1..Name.Count);
      EventName(Name.Count+1) := ASCII.NUL; -- terminating NUL
      Result.Event := ExecItf.CreateEvent( ManualReset  => True,
                                           InitialState => False,
                                           Name         => EventName'Address );
      Text_IO.Put("EventName ");
      Text_IO.Put(EventName);
      Text_IO.Put(" ");
      Int_IO.Put(to_Int(Result.Event));
      Text_IO.Put_Line(" ");
    end;
    ComponentTable.List(Location).Key := NewKey;
    ComponentTable.List(Location).RemoteAppId := RemoteId;
    ComponentTable.List(Location).Period := Period;
    ComponentTable.List(Location).Priority := Priority;
    ComponentTable.List(Location).fMain := Callback;
    ComponentTable.List(Location).WaitEvent := Result.Event;
    ComponentTable.List(Location).Queue := Queue;
    ComponentTable.List(Location).QueueWrite := to_Write_Ptr(QueueWrite);

    -- Return status and the assigned component key.
    Result.Status := VALID;
    Result.Key := NewKey;
    return Result;

  end Register;

  -- Register Receive Component
  function RegisterReceive
  ( Name     : in Itf.V_Medium_String_Type; -- name of component
    Callback : in Topic.CallbackType        -- Callback function of component
  ) return RegisterResult is
  begin -- RegisterReceive

    Kind := RECEIVE;

    return Register( Name       => Name,
                     Period     => 0,
                     Priority   => Threads.HIGH,
                     Callback   => Callback,
                     Queue      => System.Null_Address,
                     QueueWrite => System.Null_Address );
  end RegisterReceive;

  -- Register Transmit Component
  function RegisterTransmit
  ( Name       : in Itf.V_Medium_String_Type; -- name of component
    RemoteId   : in Itf.Int8;                 -- remote app to transmit to
    Callback   : in Topic.CallbackType;       -- Callback function of component
    Queue      : in System.Address;           -- message queue of component
    QueueWrite : in System.Address            -- queue Write function address
  ) return RegisterResult is

    use type Itf.Int8;

  begin -- RegisterTransmit

    if RemoteId = 0 then
      Kind := FRAMEWORK;
    else
      Kind := TRANSMIT;
    end if;
    return Register( Name       => Name,
                     RemoteId   => RemoteId,
                     Period     => 0,
                     Priority   => Threads.HIGH,
                     Callback   => Callback,
                     Queue      => Queue,
                     QueueWrite => QueueWrite );

  end RegisterTransmit;

end Component;
