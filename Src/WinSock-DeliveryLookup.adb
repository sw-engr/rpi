
separate( WinSock )

procedure DeliveryLookup
( ComId   : in Component_Ids_Type;
  Pair    : in Component_Id_Pair_Type;
  Matched : out Boolean;
  OtherId : out Component_Ids_Type;
  Indexes : out Delivery_Table_Positions_Type
) is

  OtherComponent : Component_Ids_Type := 0;

  Partner1 : Delivery_Table_Count_Type;
  Partner2 : Delivery_Table_Count_Type;
  
begin -- DeliveryLookup

  -- Determine if one component of the pair is the current component
  if Pair(1) = ComId then
    OtherComponent := Pair(2);
  elsif Pair(2) = ComId then
    OtherComponent := Pair(1);
  end if;
  -- return if Pair doesn't contain the component's identifier
  if OtherComponent = 0 then -- No match of ComId in pair
    Matched := False;
    OtherId := 0;
    Indexes := (0,0);
    return;
  end if;

  -- Determine if each component of the Pair cross references the other
  for I in Delivery_Table.Last+1..Delivery_Table.Count loop
    -- Does the Delivery Table location contain one of the pair?
    if Delivery_Table.List(I).ComId = ComId then
      Partner1 := Delivery_Table.List(I).Partner;
      if Partner1 > I then -- not already examined
        -- Find any matching partner
        for J in I+1..Delivery_Table.Count loop
          Partner2 := Delivery_Table.List(J).Partner;
          if Delivery_Table.List(Partner1).ComId = OtherComponent and then
             Delivery_Table.List(Partner1).Partner = Partner2
          then -- matched
            Matched := True;
            OtherId := OtherComponent;
            Indexes(1) := I;
            Indexes(2) := J;
            Delivery_Table.Last := I;
            return;
          end if;
        end loop;
      end if;
    elsif Delivery_Table.List(I).ComId = OtherComponent then
      Partner1 := Delivery_Table.List(I).Partner;
      if Partner1 > I then -- not already examined
        -- Find any matching partner
        for J in I+1..Delivery_Table.Count loop
          Partner2 := Delivery_Table.List(J).Partner;
          if Delivery_Table.List(Partner1).ComId = ComId and then
             Delivery_Table.List(Partner1).Partner = Partner2
          then -- matched
            Matched := True;
            OtherId := OtherComponent;
            Delivery_Table.Last := I;
            Indexes(1) := J;
            Indexes(2) := I;
            return;
          end if;
        end loop;
      end if;
    end if;
  end loop;

--    Delivery_Table.List(Delivery_Table_Count_Type(ComId)).Partner;
--  Partner2 := 
--    Delivery_Table.List(Delivery_Table_Count_Type(OtherComponent)).Partner;
--  if Partner1 /= Delivery_Table_Count_Type(OtherComponent) or else
--     Partner2 /= Delivery_Table_Count_Type(OtherId)
--  then 
  -- No match of component partners in pair
  Matched := False;
  OtherId := 0;
  Indexes := (0,0);
  return;
--  end if;
  
--  Delivery_Table.Last := I;

end DeliveryLookup;
