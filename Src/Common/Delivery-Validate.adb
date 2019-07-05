
with Text_IO;

separate( Delivery )

function Validate
return Boolean is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  Count   : Integer := 0;
  Failure : Boolean := False;

  use type Socket.ComponentNameType;

begin -- Validate

  for I in 1..DeliveryTable.Count loop

    DeliveryTable.List(I).Partner := 0;

    -- Check that ComId is within range
    if DeliveryTable.List(I).ComId > 0 and then
      DeliveryTable.List(I).ComId <=
        Socket.ComponentIdsType(LocationType'Last)
    then
      null;
    else
      Text_IO.Put_Line("ERROR: Delivery.dat ComId is out-of-range");
    end if;
      
    -- Check that an entry with a duplicate ComId has the same ComName
    for J in I+1..DeliveryTable.Count loop
      if DeliveryTable.List(J).ComId = DeliveryTable.List(I).ComId then
        if DeliveryTable.List(J).ComName /= DeliveryTable.List(I).ComName then
          Text_IO.Put
            ("WARNING: ComponentName mismatch between Delivery.dat records at");
          Int_IO.Put(Integer(I));
          Text_IO.Put(" and");
          Int_IO.Put(Integer(J));
          Text_IO.Put_Line(" ");
        end if;
      end if;
    end loop;

    -- Check that IP addresses are in dot notation
    Count := DeliveryTable.List(I).PCAddress.Count;
    declare
      Dots  : Integer := 0;
      Previous : Integer := 1;
      AsString : String(1..Count);
      for AsString use at DeliveryTable.List(I).PCAddress.Bytes(1)'address;
    begin
      CheckDot:
      for S in Previous..Count loop
        if AsString(S) = '.' then -- dot found
          Dots := Dots + 1;
          for D in Previous..S-1 loop
            if AsString(D) not in '0'..'9' then
              Text_IO.Put(AsString);
              Text_IO.Put(" contains invalid dotted IP formatting at record");
              Int_IO.Put(Integer(I));
              Text_IO.Put_Line(" ");
              exit CheckDot; -- loop
            end if;
          end loop;
          Previous := S+1; 
          if Dots = 3 then
            for D in Previous..Count loop
              if AsString(D) not in '0'..'9' then
                Text_IO.Put(AsString);
                Text_IO.Put(" contains invalid dotted IP formatting at record");
                Int_IO.Put(Integer(I));
                Text_IO.Put_Line(" ");
                exit CheckDot; -- loop
              end if;
            end loop;
            exit CheckDot; -- finished with all the bytes
          end if;
        end if;
      end loop CheckDot;
    end;
-- check format and values of PCAddress

    -- Check PortServer and PortClient for some range of values
    if (DeliveryTable.List(I).PortServer < 8000 or else
        DeliveryTable.List(I).PortServer > 9999) or else
       (DeliveryTable.List(I).PortClient < 8000 or else
        DeliveryTable.List(I).PortClient > 9999)
    then
      Text_IO.Put_Line
        ("ERROR: Server or Client Port not within selected range of 8000-9999");
    end if;
    
-- check that another record doesn't have the same PortServer or the same PortClient
    -- Find component partner of this entry
    for J in 1..DeliveryTable.Count loop
      if I /= J then -- avoid current entry
        if DeliveryTable.List(I).PortServer =
           DeliveryTable.List(J).PortClient and then
           DeliveryTable.List(I).PortClient =
           DeliveryTable.List(J).PortServer
        then
          DeliveryTable.List(I).Partner := J;
          exit; -- inner loop; can't be more than one partner
        end if;
      end if;
    end loop;

  end loop; -- for I

-- check that there are no entries without a Partner?? or leave this? or just
-- issue a warning.

  -- Issue a warning if entry has no partner.
  for I in 1..DeliveryTable.Count loop
    if DeliveryTable.List(I).Partner = 0 then
      declare
        ComName : String(1..DeliveryTable.List(I).ComName.Count);
        for ComName use at DeliveryTable.List(I).ComName.Value'Address;
      begin
        Text_IO.Put("WARNING: Delivery.dat lacks a partner component for");
        Int_IO.Put(DeliveryTable.List(I).ComId);
        Text_IO.Put(" ");
        Text_IO.Put_Line(ComName);
      end;
    end if;
  end loop;

  return not Failure;

end Validate;
