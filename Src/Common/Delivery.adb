
with ExecItf;
with Socket;

package body Delivery is

  type FileType
  -- Delivery name and handle
  is record
    Name   : ExecItf.Config_File_Name_Type;
    -- Name of delivery data file for applications
    Handle : ExecItf.File_Handle;
    -- Handle of delivery data file after created
  end record;

  Delivery_File
  -- Name and Handle of Delivery.dat file
  : FileType;

  type DeliveryTableDataType
  is record
    ComId      : Socket.ComponentIdsType;
    -- Identifier of component of the table entry
    ComName    : Socket.ComponentNameType;
    -- Name of component of the table entry
    PCAddress  : BytesType;
    -- IP address of PC of the component
    ComRoute   : BytesType;
    -- IP address of the individual component
    PortServer : Integer;
    -- Identifier of the server/transmit port
    PortClient : Integer;
    -- Identifier of the client/receive port
    Partner    : LocationType;
    -- Index of the component with the opposite ports
  end record;

  type DeliveryTableDataArrayType
  is array (1..LocationType'Last) of DeliveryTableDataType;

  type DeliveryTableType
  -- Table of the contents of the Delivery.dat file
  is record
    Count : LocationType;
    -- Number of valid entries in the table
    Last  : LocationType;
    -- Last table location matched to ComponentId of component being Installed
    List  : DeliveryTableDataArrayType;
    -- Space for the maximum number of entries
  end record;

  DeliveryError
  -- Whether an error occurred in Install
  : Boolean := False;

  DeliveryTable
  -- Parsed contents of Delivery.dat file
  : DeliveryTableType;
  -- Lookup and return location of ComId with a Partner of OtherId

  function FindDeliveryFile
  return FileType;

  function Validate
  return Boolean;


  -- Read and parse Delivery.dat file to create DeliveryTable
  procedure Initialize is separate;

  function FindDeliveryFile
  return FileType is separate;

  function Validate
  return Boolean is separate;

  function Lookup
  ( ComId   : in Integer;
    OtherId : in Integer
  ) return LocationType is

    Location : LocationType := 0;
    Partner  : LocationType;

  begin -- Lookup

    for I in 1..DeliveryTable.Count loop
      if DeliveryTable.List(I).ComId = ComId then
        Partner := DeliveryTable.List(I).Partner;
        if DeliveryTable.List(Partner).ComId = OtherId then
          return I;
        end if;
      end if;
    end loop;

    return Location; -- that is, 0 for not matched

  end Lookup;

  -- Return Partner of component at table location
  function Partner
  ( Index : in LocationType
  ) return LocationType is

  begin -- Partner
  
    return DeliveryTable.List(Index).Partner;

  end Partner;

  function IP_Address
  ( Index : in LocationType 
  ) return BytesType is
  
  begin -- IP_Address
 
    return DeliveryTable.List(Index).PCAddress;

  end IP_Address;
    
  function Port
  ( Position : in PositionPortType;
    Index    : in LocationType
  ) return Natural is

  begin -- Port

    if Position = Mine then
      return DeliveryTable.List(Index).PortServer;
    else
      return DeliveryTable.List(Index).PortClient;
    end if;

  end Port;

end Delivery;
