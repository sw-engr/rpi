with ExecItf;
with Itf;

package Delivery is

  type LocationType
  -- Range of Delivery Table entry locations
  is new Integer range 0..16;

  type PositionPortType
  -- First or Second column of ports in Delivery.dat
  is ( Mine, Other );

  type BytesType
  is record
    Count : Integer; -- number of bytes in message
    Bytes : Itf.ByteArray(1..15);
  end record;

--  type SockAddr_In
--  is record
--    SIn_Family : ExecItf.SHORT;   -- Internet protocol (16 bits)
--    SIn_Port   : ExecItf.USHORT;  -- Address port (16 bits)
--    SIn_Addr   : ExecItf.ULONG;   -- IP address (32 bits)
--    SIn_Zero   : Itf.ByteArray(1..8);
--  end record;
--  for SockAddr_In
--  use record
--    SIn_Family at 0 range 0 .. 15;
--    SIn_Port   at 2 range 0 .. 15;
--    SIn_Addr   at 4 range 0 .. 31;
--    SIn_Zero   at 8 range 0 .. 63;
--  end record;
--  for SockAddr_In'size use 16*8; -- bits

  -- Read and parse Delivery.dat file to create DeliveryTable
  procedure Initialize;

  -- Lookup and return location of ComId with a Partner of OtherId
  function Lookup
  ( ComId   : in Integer;
    -- Identifier of invoking component
    OtherId : in Integer
    -- Identifier of other component of pair
  ) return LocationType;

  -- Return Partner of component at table location
  function Partner
  ( Index : in LocationType
  ) return LocationType;

  -- Return the IP Address at the table location
  function IP_Address
  ( Index : in LocationType
  ) return BytesType;

  -- Return the Port at the 1st/2nd position at the table location
  function Port
  ( Position : in PositionPortType;
    Index    : in LocationType
  ) return Natural;

end Delivery;
