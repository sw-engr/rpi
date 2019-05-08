
with ExecItf;
with Itf;
with System;

package WinSock is

  subtype Component_Ids_Type
  -- Identifier of the hosted components.
  -- Notes:
  --   This allows for a configuration with a maximum of 63 components.
  is Integer range 0..63;

  subtype Component_Name_Type 
  is String(1..25);

  type ReceiveCallbackType
  -- Callback to return received message to its component
  is access procedure( Message : in String ); --Itf.Message_Buffer_Type );

  -- Do overall initialization of arrays
  procedure Initialize;

  -- Add to the tables for particular component
  procedure Install
  ( ComponentId  : in Component_Ids_Type;
    Component    : in String;
    RecvCallback : in ReceiveCallbackType
  );

  -- Finalize the Comm arrays and invoke the Recv and Xmit for each pair
  procedure Finalize;

  -- Send a message to its DeliverTo component
  procedure Transmit
  ( DeliverTo : in Component_Ids_Type;
    Count     : in Itf.Message_Size_Type;
    Message   : in System.Address
  );

end WinSock;
