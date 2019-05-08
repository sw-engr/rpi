
--with Topic;

package Itf is

  type Int8  is new Integer range  -2**7+1..2**7-1;
  for Int8'Size use 8; -- bits
  type Int16 is new Integer range -2**15+1..2**15-1;
  for Int16'Size use 16; -- bits
  subtype Int32 is Integer range -2**31+1..2**31-1;
  type Interface_Integer
  is range -(2 ** 31) .. (2 ** 31) - 1;

  type Nat8  is new Natural range 0..2**8-1;
  for Nat8'Size use 8;
  type Nat32 is new Natural;

  type Byte
  -- 8-bit byte
  is mod 2**8;
  for Byte'Size use 8;
  type Word
  -- 16-bit word
  is mod 2**16;
  for Word'Size use 16;
  type Longword
  -- 32-bit longword
  is range -(2**31) .. 2**31 - 1;
  for Longword'Size use 32;

  type ByteArray
  -- Unconstrained array of bytes
  is array (Integer range <>) of Byte;


  type ApplicationIdType is
  record
    Name : String(1..10);
    Id   : Int8;
  end record;

  type ApplicationNameType
  --| Character string identifying the hosted function application
  is new String(1..10);

  ApplicationId : Itf.ApplicationIdType; -- the local appId

  -- Possible methods of inter-application communications
  type CommMethodType
  is ( NONE,    -- Topic added to the library
       MS_PIPE, -- Topic already added for the component
       TCP_IP   -- Topic not added
     );

  type Component_Name_Type
  --| Name of component
  is new String(1..50);

  Configuration_App_Path_Max
  -- Maximum length of application path
  : constant Integer := 150;

  type V_String_Type
  is record
    Count : Integer;
    Data  : String(1..12);
  end record;

  type V_Short_String_Type
  is record
    Count : Integer;
    Data  : String(1..20);
  end record;

  type V_Medium_String_Type
  is record
    Count : Integer;
    Data  : String(1..50);
  end record;

  type V_80_String_Type
  is record
    Count : Integer;
    Data  : String(1..80);
  end record;

  type V_Long_String_Type
  is record
    Count : Integer;
    Data  : String(1..Configuration_App_Path_Max);
  end record;

  type Message_Size_Type
  -- Number of total message bytes in any protocol message
  is new Natural range 0..4096;

  subtype Message_Data_Count_Type
  -- Number of message data bytes in topic protocol message
  is Message_Size_Type
  range Message_Size_Type'first..4096;

  type Message_Buffer_Type
  -- Message buffer for remote messages
  is array( 1..Message_Data_Count_Type'last ) of Byte;

  Message_Size
  --| Maximum message size; Header and data
  : constant := 4096; -- bytes

  Message_Alignment
  -- Byte boundary at which to align message header and topic buffer
  : constant := 4;

--  type GenericMessageType is private;

  -- Identifier of component
  type ParticipantKeyType
  is record
    AppId : Int8; -- application identifier
    ComId : Int8; -- component identifier
    SubId : Int8; -- subcomponent identifier
  end record;

--  type HeaderType
--  is record
--    CRC  : Int16;              -- message CRC
--    Id   : Topic.TopicIdType;  -- topic of the message
--    From : ParticipantKeyType; -- publishing component
--    To   : ParticipantKeyType; -- consumer component
--    ReferenceNumber : Int32;   -- reference number of message
--    Size : Int16;              -- size of data portion of message
--  end record;
--  for HeaderType
--  use record
--    CRC    at  0 range 0..15;
--    Id     at  2 range 0..15;
--    From   at  4 range 0..23;
--    To     at  7 range 0..23;
--    ReferenceNumber at 10 range 0..31;
--    Size   at 14 range 0..15;
--  end record;

  HeaderSize
  : constant Int16 := 16;

  -- A message consists of the header data and the actual data of the message
--  type MessageType
--  is record
--    Header : HeaderType;
--    Data   : String(1..4080);
--  end record;

  MessageSize : constant Integer := 250;

  type MessageType
  is record
    Size : Integer;
    Data : String(1..MessageSize);
  end record;

  NullMessage
  : constant MessageType
  := ( Size => 0,
       Data => ( others => ' ' )
     );

  -- A message as received by NamedPipe to be queued to ReceiveInterface
  type BytesType
  is record
    Count : Integer; -- number of bytes in message
    Bytes : Itf.ByteArray(1..MessageSize);
  end record;

  -- Callback types of instantiation of NamedPipe
  type ReceiveOpenCallbackType
  -- Callback to open a receive pipe
  is access function
  ( RemoteAppId : in Int8
    -- Receive pipe to be opened
  ) return Boolean;
  type ReceiveCallbackType
  -- Callback to execute receive message to be transmitted
  is access procedure
  ( Pair    : in Int8;
    -- Pair index of receive pipe
    Message : out BytesType
    -- Received Message to be returned
  );
  type TransmitCallbackType
  -- Callback to queue message to be transmitted
  is access procedure
  ( Message : in BytesType
    -- Message to be transmitted
  );

  -- Declarations for Forward Table to be used by an instantiation of Disburse
--  type ForwardType
  -- Callback to forward message to component message callback
--  is access procedure
--            ( Message : in MessageType );

--  type DisburseDataType
--  is record
--    TopicId : Topic.TopicIdType;
--    Forward : ForwardType;
--  end record;

 -- type DisburseDataArrayType
 -- is array(1..10) of DisburseDataType;

  -- Table of topics to disburse to their callback
--  type DisburseTableType
--  is record
--    Count : Integer;
--    List  : DisburseDataArrayType;
--  end record;


--  NullMessage : MessageType;

--  procedure Initialize;

private

--  type GenericMessageType
  -- Message of any protocol
--  is array( 1..Message_Size ) of Byte;
--  for GenericMessageType'alignment use Message_Alignment;


end Itf;
