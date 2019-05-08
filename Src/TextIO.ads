with Itf;

package TextIO is

  function Concat
  ( S1 : String;
    I2 : Integer
  ) return Itf.V_80_String_Type;

  function Concat
  ( S1 : String;
    S2 : String
  ) return Itf.V_80_String_Type;

  procedure Put_Line
  ( Text : in Itf.V_80_String_Type
  );

end TextIO;
