
with Text_IO;
with Unchecked_Conversion;

package body WinSock is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  type Communication_Direction_Type
  is ( Receive,
       Transmit );

  type Possible_Pairs_Count_Type
  -- Range of possible component pairs that can inter-communicate
  is range 0..45;

  subtype Possible_Pairs_Index_Type
  is Possible_Pairs_Count_Type range 1..Possible_Pairs_Count_Type'Last;

  type Connection_Count_Type
  -- Number of allowed different connections that can be treated at one time
  is new Integer range 0..10;

  subtype Connection_Index_Type
  -- Index into Connection Data array
  is Connection_Count_Type range 1..Connection_Count_Type'last;

  WSAData
  -- Windows structure that contains the information on the configuration of
  -- the WinSock DLL, including the highest version available.  This structure
  -- is a record that contains
  --   wVersion      : Exec_Itf.WORD;
  --   wHighVersion  : Exec_Itf.WORD;
  --   szDescription : Exec_Itf.WSA_CHAR_Array(0..WSADESCRIPTION_LEN);
  --   szSystemStatus: Exec_Itf.WSA_CHAR_Array(0..WSASYS_STATUS_LEN);
  --   iMaxSockets   : Exec_Itf.USHORT;
  --   iMaxUdpDg     : Exec_Itf.USHORT;
  --   lpVendorInfo  : Exec_Itf.PSTR;
  : ExecItf.WSADATA;

  function to_LPWSADATA -- convert address to ExecItf.WinSock pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => ExecItf.LPWSADATA );

  lpWSAData
  -- Pointer to Windows WSADATA structure that contains the information on the
  -- configuration of the WinSock DLL, including the highest version available
  : constant ExecItf.LPWSADATA
  := to_LPWSADATA(WSAData'address);

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

  type Socket_Info_Type
  -- Socket handle and IP address with port of a particular component and
  -- its application to act as a WinSock server or client
  is record
    Socket : ExecItf.Socket;
    -- Handle to be supplied to accept function to obtain client socket when
    -- client application connect is accepted by this application acting as a
    -- WinSock server or handle to be supplied to connect function to obtain
    -- a connection to a remote server when this application is acting as a
    -- WinSock client
    Data : SockAddr_In;
    -- SA_family, port and IP address of the Server Socket
    Addr   : ExecItf.PSOCKADDR;
    -- Pointer to description of local address of Server Socket.  The SOCKADDR
    -- to which it points is a record that contains
    --   SA_family : u_short;
    --   SA_data   : ExecItf.WSA_CHAR_Array(0..13);
  end record;

  Null_Socket_Info
  : constant Socket_Info_Type
  := ( Socket => ExecItf.Invalid_Socket,
       Data   => ( SIn_Family => 0,
                   SIn_Port   => 0,
                   SIn_Addr   => 0,
                   SIn_Zero   => ( others => 0 ) ),
       Addr   => null );

  type Communication_Connection_Data_Type
  -- Data about server/client sockets that have requested a connection with a
  -- client or server.
  --
  -- In this peer-to-peer implementation, each application contains components
  -- and each component is both a server to other components and their client.
  -- As such each component of the pair can be connected to the other via a
  -- pair of Window socket ports. One connected as if a particular component is
  -- the WinSock server and the other as if it is the client.  
  --
  -- Along with the IP address each socket is identified via a port number; 
  -- one port for the server and one for the client.
  --
  -- Since the client, as the reader, has to wait for data from its server, the
  -- client connect attempt with its receive are implemented in its own thread;
  -- one thread for each component to connect as the client.
  --
  -- Likewise, the server portion of the application has to attempt to accept
  -- connections from each of the other applications.  Therefore, the accept
  -- request must be in a loop where the accept will return when a particular
  -- client connect request is accepted.  The accept returns the new socket 
  -- to be used and the IP address with the port.  Since one or more remote
  -- components may be in an application(s) that may not be running, the accept
  -- can block waiting for components to request to connect that aren't initially
  -- running.  Therefore, each server also has its own accept connection thread
  -- so the rest of the application can run while the accepts are taking place.
  --
  -- Note: The accept function returns a new socket that replaces that of the
  -- original bind and listen.
  --
  -- With both components of a communication pair acting as a server and a
  -- client of the other, each will attempt to connect to the other as a 
  -- client and each will attempt to accept the other's request to connect.
  -- Therefore, each shall have a socket it obtained for the client connect
  -- request and one that it obtained for the server bind and listen and 
  -- passed to its accept request (although the accept request can otherwise
  -- specify null).  For each accept a client socket will be returned to use
  -- in the communications.
  --
  -- Thus, the transmit to the other component will use the socket returned
  -- by the accept no matter what application it happens to be in.  The
  -- receive from the other application will use the socket returned by the 
  -- receive thread.
  is record
    Supported : Boolean;
    -- True if Apps Configuration indicates that both applications of the
    -- connection pair support WinSock communications
    Connected : Boolean;
    -- True if this application acting as a WinSock client has connected
    -- with its server
    Created   : Boolean;
    -- True if this application acting as a WinSock server has created
    -- the Socket
    Name      : Component_Name_Type; --Itf.Component_Name_Type;
    -- Name by which to register the Driver Receive or Transmit components
    Socket    : Socket_Info_Type;
    -- Socket handle and IP address to attempt to connect to remote application
  end record;


  Null_Communication_Connection_Data
  : constant Communication_Connection_Data_Type
  := ( Supported => False,
       Connected => False,
       Created   => False,
       Name      => ( others => ' ' ),
       Socket    => Null_Socket_Info );

  type Communication_Connection_Type
  -- Similar data for the WinSock client and server
  is record
    Receive  : Communication_Connection_Data_Type;
    Transmit : Communication_Connection_Data_Type;
  end record;

  type Communication_Connection_Link_Type
  is array( Connection_Index_Type )
  of Communication_Connection_Type;

  type Component_Id_Pair_Type
  -- Pair of application identifiers to identify applications that can communicate
  is array( 1..2 ) of Component_Ids_Type;

  type Delivery_Table_Count_Type
  -- Range of Delivery Table entries
  is new Integer range 0..16;

  type Delivery_Table_Positions_Type
  -- Locations of the matched pair in the Delivery_Table
  is array (1..2) of Delivery_Table_Count_Type;

  type Communication_Data_Type
  is record
    Available         : Boolean;
    -- True if remote application is available in the configuration
    Bound             : Boolean;
    -- True if the Bind for the Transmit socket has succeeded
    Pair              : Component_Id_Pair_Type;
    -- Identifiers of the application pair; always lower number first
    Local_Com         : Component_Ids_Type;
    -- Identifier of running component
    Remote_Com        : Component_Ids_Type;
    -- Identifier of other (i.e., remote) component of the pair
    Receive_Wait      : ExecItf.HANDLE;
    -- Wait event handle of receive thread
    Transmit_Wait     : ExecItf.HANDLE;
    -- Wait event handle of transmit thread
    Receive_Callback  : ReceiveCallbackType;
    -- Callback to component's procedure to receive messages
    DeliveryId        : Component_Ids_Type;
    -- Delivery_Table Component Identifier for transmit
    DeliveryPosition  : Delivery_Table_Positions_Type;
    -- Pair of indexes into Delivery_Table of the matched pair of components
  end record;

  Null_Data_Info
  : constant Communication_Data_Type
  := ( Available        => False,
       Bound            => False,
       Pair             => ( 0, 0 ),
       Local_Com        => 0,
       Remote_Com       => 0,
       Receive_Wait     => System.Null_Address,
       Transmit_Wait    => System.Null_Address,
       Receive_Callback => null,
       DeliveryId       => 0,
       DeliveryPosition => ( 0, 0 )
     );

  type Communication_Data_Array_Type
  is array( Connection_Index_Type ) of Communication_Data_Type;

  type Communication_Type
  -- Structure containing WinSock clients of the components of the configuration
  -- that receive messages from other components and servers that transmit to other
  -- components. That is, any of the components can be a server that send messages
  -- to other components as well as a client that receives messages.
  is record
    Count : Connection_Count_Type;
    -- Number of entries in the Data and Link arrays
    Data  : Communication_Data_Array_Type;
    -- Data to be used in conjunction with WinSock threads
    Link  : Communication_Connection_Link_Type;
    -- Data to be used by this application to receive from / transmit to the
    -- other components of this or other applications
  end record;

  Comm
  -- Information about threads and Microsoft Windows connections
  -- for each application
  : Communication_Type;
  pragma Volatile( Comm ); -- since accessed by multiple threads


  type Possible_Pairs_Type
  is array( Possible_Pairs_Index_Type ) of Component_Id_Pair_Type;

  Possible_Pairs
  --| Possible pairs of component ids in the Delivery.dat file
  : Possible_Pairs_Type;

  Possible_Pair_Indexes
  --| Possible pairs of applications with lower numbered indexes first
  : constant Possible_Pairs_Type
  := (  1 => ( 1, 2 ),
        2 => ( 1, 3 ),
        3 => ( 1, 4 ),
        4 => ( 1, 5 ),
        5 => ( 1, 6 ),
        6 => ( 1, 7 ),
        7 => ( 1, 8 ),
        8 => ( 1, 9 ),
        9 => ( 1, 10 ),
       10 => ( 2, 3 ),
       11 => ( 2, 4 ),
       12 => ( 2, 5 ),
       13 => ( 2, 6 ),
       14 => ( 2, 7 ),
       15 => ( 2, 8 ),
       16 => ( 2, 9 ),
       17 => ( 2, 10 ),
       18 => ( 3, 4 ),
       19 => ( 3, 5 ),
       20 => ( 3, 6 ),
       21 => ( 3, 7 ),
       22 => ( 3, 8 ),
       23 => ( 3, 9 ),
       24 => ( 3, 10 ),
       25 => ( 4, 5 ),
       26 => ( 4, 6 ),
       27 => ( 4, 7 ),
       28 => ( 4, 8 ),
       29 => ( 4, 9 ),
       30 => ( 4, 10 ),
       31 => ( 5, 6 ),
       32 => ( 5, 7 ),
       33 => ( 5, 8 ),
       34 => ( 5, 9 ),
       35 => ( 5, 10 ),
       36 => ( 6, 7 ),
       37 => ( 6, 8 ),
       38 => ( 6, 9 ),
       39 => ( 6, 10 ),
       40 => ( 7, 8 ),
       41 => ( 7, 9 ),
       42 => ( 7, 10 ),
       43 => ( 8, 9 ),
       44 => ( 8, 10 ),
       45 => ( 9, 10 )
     );

  type File_Type
  -- Delivery name and handle
  is record
    Name   : ExecItf.Config_File_Name_Type;
    -- Name of delivery data file for applications
    Handle : ExecItf.File_Handle;
    -- Handle of delivery data file after created
  end record;

  Delivery_File
  -- Name and Handle of Delivery.dat file
  : File_Type;

  type DeliveryBytesType
  is record
    Count : Integer; -- number of bytes in message
    Bytes : Itf.ByteArray(1..15);
  end record;

  type ComponentNameType
  is record
    Count : Integer; -- number of characters in name
    Value : String(1..20);
  end record;

  type Delivery_Table_Data_Type
  is record
    ComId      : Component_Ids_Type;
    -- Identifier of component of the table entry
    ComName    : ComponentNameType;
    -- Name of component of the table entry
    PCAddress  : DeliveryBytesType;
    -- IP address of PC of the component
    ComRoute   : DeliveryBytesType;
    -- IP address of the individual component
    PortServer : Integer;
    -- Identifier of the server/transmit port
    PortClient : Integer;
    -- Identifier of the client/receive port
    Partner    : Delivery_Table_Count_Type;
    -- Index of the component with the opposite ports
  end record;

  type Delivery_Table_Data_Array_Type
  is array (1..Delivery_Table_Count_Type'Last) of Delivery_Table_Data_Type;

  type Delivery_Table_Type
  -- Table of the contents of the Delivery.dat file
  is record
    Count : Delivery_Table_Count_Type;
    -- Number of valid entries in the table
    Last  : Delivery_Table_Count_Type;
    -- Last table location matched to ComponentId of component being Installed
    List  : Delivery_Table_Data_Array_Type;
    -- Space for the maximum number of entries
  end record;

  Delivery_Error
  -- Whether an error occurred in Install
  : Boolean := False;

  Delivery_Table
  -- Parsed contents of Delivery.dat file
  : Delivery_Table_Type;

  NameIndex
  -- Index of component in Delivery_Table
  : Integer := 0;

  function to_ac_SOCKADDR_t -- convert address to ExecItf.WinSock pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => ExecItf.PSOCKADDR );

  function FindDeliveryFile
  return File_Type;

  procedure MatchComId
  ( Start : in out Possible_Pairs_Count_Type;
    ComId : in Component_Ids_Type
  );

  function MatchName
  ( Start : in Possible_Pairs_Count_Type;
    Name  : in String
  ) return Possible_Pairs_Count_Type;

  -- Parse the Delivery.dat file to create the Delivery_Table
  procedure ParseDelivery;

  -- Lookup the component and check that the table entries cross reference
  procedure DeliveryLookup
  ( ComId   : in Component_Ids_Type;
    -- Current component's id
    Pair    : in Component_Id_Pair_Type;
    -- Pair of component ids to be looked up
    Matched : out Boolean;
    -- Whether the pair is in the Delivery table
    OtherId : out Component_Ids_Type;
    -- Other component id of the matched pair
    Indexes : out Delivery_Table_Positions_Type
    -- Locations of matched pair in the table
  );

  -- Validate the Delivery_Table; return True if not invalid
  function ValidateDelivery
  return Boolean;

  function to_Digit
  ( Number : in Integer
  ) return Character;

  package Recv is
  -- Receive message from a particular component

    procedure Install
    ( Id : in Connection_Count_Type
      -- Identifier of the component
    );

  end Recv;

  package Xmit is
  -- Transmit message to a particular component

    procedure Install
    ( Id : in Connection_Count_Type
      -- Identifier of the component
    );

  end Xmit;


  -- Separate declarations

  procedure Finalize is separate;

  function FindDeliveryFile
  return File_Type is separate;

  procedure Initialize is separate;

  procedure Install
  ( ComponentId  : in Component_Ids_Type;
    Component    : in String;
    RecvCallback : in ReceiveCallbackType
  ) is separate;

  procedure MatchComId
  ( Start : in out Possible_Pairs_Count_Type;
    ComId : in Component_Ids_Type
  ) is separate;

  function MatchName
  ( Start : in Possible_Pairs_Count_Type;
    Name  : in String
  ) return Possible_Pairs_Count_Type is separate;

  procedure ParseDelivery is separate;

  function ValidateDelivery
  return Boolean is separate;

  procedure DeliveryLookup
  ( ComId   : in Component_Ids_Type;
    Pair    : in Component_Id_Pair_Type;
    Matched : out Boolean;
    OtherId : out Component_Ids_Type;
    Indexes : out Delivery_Table_Positions_Type
  ) is separate;

  function to_Digit
  ( Number : in Integer
  ) return Character is
  -- Convert number from 1 thru 9 to a alpha digit.

  begin -- to_Digit

    case Number is
      when 1 => return '1';
      when 2 => return '2';
      when 3 => return '3';
      when 4 => return '4';
      when 5 => return '5';
      when 6 => return '6';
      when 7 => return '7';
      when 8 => return '8';
      when 9 => return '9';
      when others =>
        Text_IO.Put("ERROR: to_Digit for Number not 1 thru 0");
        Int_IO.Put(Number);
        Text_IO.Put_Line(" ");
--        raise Program_Error;
        return '0';
    end case;

  end to_Digit;

  procedure Transmit
  ( DeliverTo : in Component_Ids_Type;
    Count     : in Itf.Message_Size_Type;
    Message   : in System.Address
  ) is separate;

  package body Recv is separate;

  package body Xmit is separate;

end WinSock;
