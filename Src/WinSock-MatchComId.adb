
with CStrings;

separate( WinSock )

procedure MatchComId
( Start : in out Possible_Pairs_Count_Type;
  ComId : in Component_Ids_Type
) is

  Index  : Delivery_Table_Count_Type := Delivery_Table_Count_Type(Start)+1;

begin -- MatchComId

  for I in Index..Delivery_Table.Count loop

    if Delivery_Table.List(I).ComId = ComId then
      Start := Possible_Pairs_Count_Type(I);
      return;
    end if;
  end loop;
  Start := 0;

end MatchComId;
