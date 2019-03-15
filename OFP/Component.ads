with Configuration;
with ExecItf;
with Itf;
with Topic;
with Threads;
with System;

package Component is

  MaxUserComponents
  -- Maximum allowed number of user (non-framework) components
  : constant Integer := 8;

  MaxComponents
  : constant Integer := 8 + (2 * (Configuration.MaxApplications - 1));

  NullKey : Itf.ParticipantKeyType;

  type ComponentStatus
  is ( NONE,
       VALID,
       DUPLICATE,
       INVALID,
       INCONSISTENT,
       INCOMPLETE
     );

  type ComponentKind
  is ( USER,
       FRAMEWORK,
       RECEIVE,   -- special framework component
       TRANSMIT   -- special framework component
     );

  type ComponentSpecial
  is ( NORMAL,
       RECEIVE,
       RECEIVEINTERFACE,
       TRANSMIT
     );

  type RegisterResult
  is record
    Status : ComponentStatus;
    Key    : Itf.ParticipantKeyType;
    Event  : ExecItf.HANDLE;
  end record;

  type DisburseWriteCallback
  -- Callback to execute the Write function of a participant component's
  -- Disburse queue
  is access function
  ( Message : in Itf.MessageType
    -- Message to be written to the queue
  ) return Boolean; -- indicates if Write was successful

  -- Component data from registration as well as run-time status
  type ComponentDataType
  is record
    Kind        : ComponentKind;
    -- Whether user component or a framework component
    Name        : Itf.V_Medium_String_Type;
    -- Component name
    Key         : Itf.ParticipantKeyType;
    -- Component key (application and component identifiers)
    RemoteAppId : Itf.Int8;
    -- Remote application for transmit
    Period      : Integer;
    -- Periodic interval in milliseconds; 0 if only message consumer
    Priority    : Threads.ComponentThreadPriority;
    -- Requested priority for component
    fMain       : Topic.CallbackType; --MainEntry;
    -- Main entry point of the component
    WaitEvent   : ExecItf.HANDLE;
    -- Wait Event associated component
    Queue       : System.Address; --Disburse.QueuePtrType;
 --Disburse.DisburseTablePtrType; --Itf.V_Medium_String_Type; --Disburse;
    -- Message queue of the component
    QueueWrite  : DisburseWriteCallback;
    -- Callback to Write to the component's queue
    Special     : ComponentSpecial;
    -- Special processing
--    Timer      : Threads.PeriodicTimer; --<<package within Threads package -- need ptr>>
--    Timer      : PeriodicTimer; --<<package within Threads package -- need ptr>>
    -- Thread timer of special components
--    WaitHandle : EventWaitHandle; --<<??>>
    -- Wait Handle to use to signal end of wait
  end record;

  type ComponentDataArrayType is array (1..MaxComponents) of ComponentDataType;

  -- List of components
  type ComponentTableType
  is record
    AllowComponentRegistration : Boolean;
    -- True indicates that components are allowed to register themselves
    Count                      : Integer;
    -- Number of registered components of the application
    List                       : ComponentDataArrayType;
    -- Registration supplied data concerning the component as well as
    -- run-time status data
  end record;

  -- Component table containing registration data as well as run-time status data
  -- Note: I would like to keep this table hidden from components but I don't
  --       know how to structure C# so that classes of a certain kind (that is,
  --       App, Component, Threads, etc) aren't directly visible to components
  --       such as ComPeriodic.
  -- Note: There must be one creation of a new table.  Only one instance.
  ComponentTable : ComponentTableType;

  -- true if Component class has been initialized
  ComponentInitialized : Boolean := False;

  -- Determine if two components are the same
  function CompareParticipants
  ( Left  : in Itf.ParticipantKeyType;
    Right : in Itf.ParticipantKeyType
  ) return Boolean;

--  function GetQueueWriteCallback
--  ( ComponentKey : in Itf.ParticipantKeyType
--  ) return DisburseWriteCallback;
  -- Forward Message to Callback of Component
  function DisburseWrite
  ( ComponentKey : in Itf.ParticipantKeyType;
    -- Component for message delivery
    Message      : in Itf.MessageType
    -- Message to be delivered
  ) return Boolean; -- true indicates successful write to queue

  -- Forward Message to instantiation of Transmit package to send to remote app
  function TransmitWrite
  ( RemoteAppId : in Itf.Int8;
    -- Transmit component to send Message
    Message     : in Itf.MessageType
    -- Message to be delivered
  ) return Boolean; -- true indicates successful write to queue
                                      
  procedure Initialize;

  -- Register User Component
  function Register
  ( Name       : in Itf.V_Medium_String_Type; -- name of component
    RemoteId   : in Itf.Int8 := 0;      -- remote id for transmit
    Period     : in Integer; -- # of millisec at which Main() function to cycle
    Priority   : in Threads.ComponentThreadPriority; -- Requested priority of thread
    Callback   : in Topic.CallbackType; -- Callback function of component
    Queue      : in System.Address;     -- message queue of component
    QueueWrite : in System.Address      -- queue Write function address
  ) return RegisterResult;

  -- Register Receive Component
  function RegisterReceive
  ( Name     : in Itf.V_Medium_String_Type; -- name of component
    Callback : in Topic.CallbackType        -- Callback function of component
  ) return RegisterResult;

  -- Register Transmit Component
  function RegisterTransmit
  ( Name       : in Itf.V_Medium_String_Type; -- name of component
    RemoteId   : in Itf.Int8;                 -- remote app to transmit to
    Callback   : in Topic.CallbackType;       -- Callback function of component
    Queue      : in System.Address;           -- message queue of component
    QueueWrite : in System.Address            -- queue Write function address
  ) return RegisterResult;

end Component;
