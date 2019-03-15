
separate( Component )

package body Queues is

package Int_IO is new Text_IO.Integer_IO( Integer );----debug

  package Queue1 is
      procedure Install
      ( Instance : in Component.DisburseQueueInstanceType );
      procedure WaitEvent;
      function Write
      ( Message : Itf.MessageType
      ) return Boolean;
  end Queue1;

  package Queue2 is
      procedure Install
      ( Instance : in Component.DisburseQueueInstanceType );
      procedure WaitEvent;
      function Write
      ( Message : Itf.MessageType
      ) return Boolean;
  end Queue2;

    type QueueDataType
    is record
      Name     : Itf.V_Short_String_Type;
      -- Name of queue
      Location : System.Address;
      -- Location of the instance of the QueueType private table
      Key      : Itf.ParticipantKeyType;
      -- Component key associated with Disburse queue
    end record;

    type QueueArrayType
    is array(1..MaxComponents) of QueueDataType;

    type QueueTable
    is record
      Count : Integer;
      List  : QueueArrayType;
    end record;

    type QueuePtrType
    -- Access to queue package instance
    is access procedure( Index : in Integer --Apps.Configuration.Connection_Index_Type
                         -- Index Queue package
                       );

    FirstQueue : Boolean := True;

    Queue : QueueTable;

    type QueueProceduresTableType
    is record
      Install   : QueuePtrType;
      WaitEvent : QueuePtrType;
      Write     : QueuePtrType;
    end record;

--    Invoke
    -- Table of queue packages
--    : QueueProceduresTableType
--    := ( Install   => Install'access,
--         WaitEvent => WaitEvent'access,
--         Write     => Write'access );
-- this assumes using the index -- but the actual procedures are in separate
-- packages.  how to use this?

    function AddQueue
    ( Key      : in Itf.ParticipantKeyType;
      Data     : in QueueParameterType;
      Periodic : in Boolean
    ) return Integer is -- index of queue in table

      Instance : DisburseQueueInstanceType;

    begin -- AddQueue

      Instance := ( Name      => Data.Name'Address,
                    Periodic  => Periodic,
                    Universal => Data.Universal,
                    Forward   => Data.Forward );
      if FirstQueue then
        Queue.Count := 1;
        FirstQueue := False;
      else
        Queue.Count := Queue.Count + 1;
      end if;


--      declare
--        package DisburseQueue
        -- Instantiate disburse queue for component
--        is new Disburse( Instance => Instance );
                       --QueueName => Data.Name'Address, --Queue1'Address,
                       --Periodic  => Periodic,
                       --Universal => Data.AnyMessage,
                       --Forward   => Data.Forward ); --System.Null_Address )
--      begin
-->>>> need to do from the packages
        Queue.List(Queue.Count) := ( Name     => Data.Name,
                                     Location => System.Null_Address, --DisburseQueue.Location,
                                     Key      => Key );

      case Queue.Count is
        when 1 => Queue1.Install( Instance => Instance );
        when 2 => Queue1.Install( Instance => Instance );
        when others => null;
      end case;
      --<<< how to do this?  now have the Queue1 and Queue2 packages.  Have to do
--    the Install for the package corresponding to the count.  so need a case
--    statement.
--      end;
--    begin -- AddQueue

 --     package DisburseQueue
      -- Instantiate disburse queue for component
 --     is new Disburse( QueueName => Data.Name'Address, --Queue1'Address,
 --                      Periodic  => Periodic,
 --                      Universal => Data.AnyMessage,
 --                      Forward   => Data.Forward ); --System.Null_Address );
 --     if FirstQueue then
 --       Queue.Count := 1;
 --     else
 --       Queue.Count := Queue.Count + 1;
 --     end if;
--      Queue.List(Queue.Count) := ( Name     => Data.Name,
--                                   Location => DisburseQueue.Location );
      return Queue.Count;
    end AddQueue;

    procedure EventWait
    ( ComponentKey : in Itf.ParticipantKeyType;
      Name         : in Itf.V_Short_String_Type
    ) is

      Index : Integer := 0;
      use type Itf.ParticipantKeyType;

    begin -- EventWait

      -- Lookup queue package to use
      for I in 1..Queue.Count loop
        if CompareParticipants( ComponentKey, Queue.List(I).Key) then
          Index := I;
          exit; -- loop
        end if;
     end loop;
     if Index > 0 then
       case Index is
         when 1 => Queue1.WaitEvent;
         when 2 => Queue2.WaitEvent;
         when others => null;
       end case;
     end if;
  end EventWait;

    function Write
    ( ComponentKey : in Itf.ParticipantKeyType;
      Message      : in Itf.MessageType
    ) return Boolean is
      Index : Integer := 0;
      use type Itf.ParticipantKeyType;
    begin -- Write
      -- Lookup queue package to use
      for I in 1..Queue.Count loop
        if CompareParticipants( ComponentKey, Queue.List(I).Key) then
          Index := I;
          exit; -- loop
        end if;
      end loop;
      if Index > 0 then
        case Index is
          when 1 => return Queue1.Write( Message => Message );
          when 2 => return Queue2.Write( Message => Message );
          when others => return False;
        end case;
      else
        return False;
      end if;

    end Write;

    package body Queue1 is
      InstanceParams : Component.DisburseQueueInstanceType;

      package DisburseQueue1
      -- Instantiate disburse queue for component
      is new Disburse; --( Instance => InstanceParams );

      procedure Install
      ( Instance : in Component.DisburseQueueInstanceType
      ) is
 --       package DisburseQueue
        -- Instantiate disburse queue for component
 --       is new Disburse( Instance => Instance );
      begin --Install
        InstanceParams := Instance;
        DisburseQueue1.Initialize( InstanceParams );
      end Install;

    procedure WaitEvent is
      begin -- WaitEvent
        DisburseQueue1.EventWait;
      end WaitEvent;

    function Write
      ( Message : Itf.MessageType
      ) return Boolean is
      begin -- Write
        return DisburseQueue1.Write(Message);
      end Write;
    end Queue1;

    package body Queue2 is
      InstanceParams : Component.DisburseQueueInstanceType;

      package DisburseQueue2
      -- Instantiate disburse queue for component
      is new Disburse; --( Instance => InstanceParams );

      procedure Install
      ( Instance : in Component.DisburseQueueInstanceType
      ) is
 --       package DisburseQueue
 --       -- Instantiate disburse queue for component
 --       is new Disburse( Instance => Instance );
      begin --Install
        InstanceParams := Instance;
        DisburseQueue2.Initialize( InstanceParams );
      end Install;
      procedure WaitEvent is
      begin -- WaitEvent
        DisburseQueue2.EventWait;
      end WaitEvent;
      function Write
      ( Message : Itf.MessageType
      ) return Boolean is
      begin -- Write
        return DisburseQueue2.Write(Message);
      end Write;
    end Queue2;

  end Queues;
