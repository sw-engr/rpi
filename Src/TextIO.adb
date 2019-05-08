
with Itf;
with Text_IO;

package body TextIO is

  function toString
  ( Int : in Natural
  ) return Itf.V_String_Type is

    Start
    -- Index of first non-zero digit
    : Integer;

    Temp1
    -- Temporary string
    : Itf.V_String_Type
    := ( Count => 0,
         Data  => ( others => '0' ) );
    Temp2
    -- Return string
    : Itf.V_String_Type
    := ( Count => 0,
         Data  => ( others => ' ' ) );

    Work
    -- Working integer
    : Integer := Int;

  begin -- toString

    for I in reverse 1..12 loop

      Temp1.Data(I) := Character'Val( Character'Pos( '0' ) + ( Work mod 10 ) );
      Temp1.Count := Temp1.Count + 1;

      Work := Work / 10;
      exit when Work = 0;

    end loop;

    if Work /= 0 then
      Text_IO.Put_Line("ERROR: Conversion Error in TextIO toString");
    end if;

    -- Remove leading 0s
    Start := 12;
    for I in 1..11 loop
      if Temp1.Data(I) /= '0' then
        Start := I;
        exit;
      end if;
      Temp1.Data(I) := ' ';
    end loop;

    -- Move digits to the beginning and into the string to be returned
    Temp2.Count := 0;
    for I in Start..12 loop
      Temp2.Count := Temp2.Count + 1;
      Temp2.Data(Temp2.Count) := Temp1.Data(I);
    end loop;

    return Temp2;

  end toString;

  function Concat -- leaving separating space
  ( S1 : String;
    I2 : Integer
  ) return Itf.V_80_String_Type is

    Temp1 : Itf.V_80_String_Type;
    Temp2 : Itf.V_String_Type;

  begin -- Concat

    Temp1.Data := ( others => ' ' );

    Temp2 := toString(abs(I2));
    Temp1.Count := S1'Length;
    Temp1.Data(1..S1'Length) := S1;
    -- Insert separating space after input string
    Temp1.Count := Temp1.Count + 1;
    Temp1.Data(Temp1.Count) := ' ';
    -- Concatenate string of converted integer
    Temp1.Data(Temp1.Count+1..Temp1.Count+Temp2.Count) :=
      Temp2.Data(1..Temp2.Count);
    Temp1.Count := Temp1.Count+Temp2.Count;

    return Temp1;

  end Concat;

  function Concat
  ( S1 : String;
    S2 : String
  ) return Itf.V_80_String_Type is

    Count : Integer;

    Temp1 : Itf.V_80_String_Type;

  begin -- Concat

    Temp1.Count := S1'Length;
    Temp1.Data(1..Temp1.Count) := S1;
    Temp1.Count := Temp1.Count + 1;
    Temp1.Data(Temp1.Count) := ' '; -- Insert separating space
    Count := Temp1.Count + S2'Length;
    Temp1.Data(Temp1.Count+1..Count) := S2;
    Temp1.Count := Count;

    return Temp1;

  end Concat;

  procedure Put_Line
  ( Text : in Itf.V_80_String_Type
  ) is
  begin -- Put_Line
    Text_IO.Put_Line(Text.Data(1..Text.Count));
  end Put_Line;

end TextIO;
