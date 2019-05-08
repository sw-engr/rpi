
with CStrings;

separate( WinSock )

function MatchName
( Start : in Possible_Pairs_Count_Type;
  Name  : in String
) return Possible_Pairs_Count_Type is

  Index  : Delivery_Table_Count_Type := Delivery_Table_Count_Type(Start)+1;
  NameIn : String(1..Name'Length+1);

begin -- MatchName

  NameIn(1..Name'Length) := Name;
  NameIn(Name'Length+1) := ASCII.NUL;
  for I in Index..Delivery_Table.Count loop
    declare
      Count   : Integer := Delivery_Table.List(I).ComName.Count;
      NameCom : String(1..Delivery_Table.List(I).ComName.Count+1);
    begin
      NameCom(1..Delivery_Table.List(I).ComName.Count) :=
        Delivery_Table.List(I).ComName.Value(1..Count);
      NameCom(Count+1) := ASCII.NUL;
      if CStrings.Compare( NameIn'Address,
                           NameCom'Address,
                           False ) = 0
      then
        return Possible_Pairs_Count_Type(I);
      end if;
    end;
  end loop;
  return 0;

end MatchName;
