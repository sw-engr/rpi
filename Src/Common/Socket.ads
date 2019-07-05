with Delivery;
with ExecItf;
with Itf;
with System;
with Threads;
with Unchecked_Conversion;

package Socket is

  subtype ComponentIdsType
  -- Identifier of the hosted components.
  -- Notes:
  --   This allows for a configuration with a maximum of 63 components.
  is Integer range 0..63;

  type ComponentNameType
  -- Name of the hosted components
  is record
    Count : Integer; -- number of characters in name
    Value : String(1..20);
  end record;

  type ReceiveCallbackType
  -- Callback to return received message to its component
--  is access procedure( Message : in String );
  is access procedure( Message : in Itf.BytesType );

  function to_ac_SOCKADDR_t -- convert address to ExecItf.WinSock pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => ExecItf.PSOCKADDR );

  procedure WSARestart;

  package Data is

    -- SocketServer Listener Data

    type SockAddr_In
    is record
      SIn_Family : ExecItf.SHORT;   -- Internet protocol (16 bits)
      SIn_Port   : ExecItf.USHORT;  -- Address port (16 bits)
      SIn_Addr   : ExecItf.ULONG;   -- IP address (32 bits)
      SIn_Zero   : Itf.ByteArray(1..8);
    end record;
    for SockAddr_In
    use record
      SIn_Family at 0 range 0 .. 15;
      SIn_Port   at 2 range 0 .. 15;
      SIn_Addr   at 4 range 0 .. 31;
      SIn_Zero   at 8 range 0 .. 63;
    end record;
    for SockAddr_In'size use 16*8; -- bits

    type ListenerDataType
    is record
      ToId         : ComponentIdsType;  -- Name and Id of this component waiting to
      ToName       : ComponentNameType; --   receive the message & the callback
      RecvCallback : ReceiveCallbackType; -- to return the message
      FromName     : ComponentNameType; -- Name and Id of the component from
      FromId       : ComponentIdsType;  --  which message is to be received

      ThreadId     : Integer;           -- Id of Receive thread

      Data         : SockAddr_In;
      -- SA_family, port and IP address of the Server Socket
      Addr         : ExecItf.PSOCKADDR;
      -- Pointer to description of local address of Server Socket.
      -- The SOCKADDR to which it points is a record that contains
      --   SA_family : u_short;
      --   SA_data   : ExecItf.WSA_CHAR_Array(0..13);
      Listener :  ExecItf.Socket;
      -- Socket handle to be supplied to accept function, etc;
    end record;

    type ListenerListType
    is array (1..ComponentIdsType'Last) of ListenerDataType;
--<<< need to fix MaxComponents.  This needs to be the maximum number of components
--    whereas that of threads also includes the receive and transmit threads so
--    three times as many >>>

    type ListenerType
    is record
      Count : ComponentIdsType;
      List  : ListenerListType;
    end record;

    ListenerData
    : ListenerType;


    -- SocketClient Sender Data

    type SenderDataType
    is record
      FromName    : ComponentNameType;  -- Name and Id of the invoking component
      FromId      : ComponentIdsType;   --  from which message is to be sent
      ToId        : ComponentIdsType;   -- Name and Id of remote component
      ToName      : ComponentNameType;  --   to be sent the message

      ThreadId    : Integer;           -- Id of Transmit thread

      Data         : SockAddr_In;
      -- SA_family, port and IP address of the Client Socket
      Addr         : ExecItf.PSOCKADDR;
      -- Pointer to description of local address of Client Socket.
      -- The SOCKADDR to which it points is a record that contains
      --   SA_family : u_short;
      --   SA_data   : ExecItf.WSA_CHAR_Array(0..13);
      Sender      : ExecItf.Socket;
      -- Socket handle to be supplied to accept function, etc
    end record;

    type SenderListType
    is array (1..ComponentIdsType'Last) of SenderDataType;

    type SenderType
    is record
      Count : ComponentIdsType;
      List  : SenderListType;
    end record;

    SenderData
    : SenderType;

  end Data;

end Socket;
