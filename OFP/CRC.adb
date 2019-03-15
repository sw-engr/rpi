
with Interfaces;

package body CRC is

--  function Shift_Right
--  ( Value  : in Unsigned_Longword;
    --| Unsigned longword value
--    Amount : in Natural
    --| Shift bit count
--  ) return Unsigned_Longword;
  --| Shift Unsigned Longword Right
  -- ++
  --| Overview:
  --|   This function shifts an unsigned longword value right by the number of
  --|   bits specified, returning an unsigned longword.
  -- --
--  pragma Import( Intrinsic, Shift_Right );

--  function RightShift
--  ( Value  : Itf.Word;
--   Amount : in Natural
--  ) return Itf.Word is
--    Word : Itf.Longword;
--    type DoubleWord
--    is record
--      Low  : Itf.Word;
--      High : Itf.Word;
--    end record;
--    for DoubleWord
--    use record
--      Low  at 0 range 0..15;
--      High at 2 range 0..15;
--    end record;
--    Double : DoubleWord;
--    for Double.Low use at Value'address;
--    for Word use at Double'Address;
--  begin -- RightShift
--    Double.High := 0;
--    Shift_Right(Value => Word, Amount => Amount);
--    return Double.Low;
--  end RightShift;

  function RightShift
  ( Value  : Itf.Word;
   Amount : in Natural
  ) return Itf.Word is
  begin -- RightShift
    return Itf.Word( Interfaces.Shift_Right
                     ( Value  => Interfaces.Unsigned_16(Value),
                       Amount => Amount ) );
  end RightShift;

  function CRC16
  ( Count : in Itf.Word;
    Data  : in Itf.MessageType
  ) return Itf.Word is

    -- Notes:
    --   Taken from the internet as published by AnandTech.
    --   The byte array contains the first two bytes that are reserved
    --   for the CRC.  Therefore, these two bytes are ignored in the
    --   for loop below.
    -- As converted from C to Ada.

    CRC : Itf.Word;

    --need to convert MessageType to a byte array.
    type ByteArray is array(1..Count) of Itf.Byte;
    Bytes : ByteArray;
    for Bytes use at Data'Address;
--<<< is this going to be the address of the parameter or the address of the
--    message? >>>

    use type Itf.Word;

  begin -- CRC16

    CRC := 16#FFFF#;

    for J in 3..Count loop
--<<< problem here.  CRC is 16-bits and Bytes(J) is 8-bits.
--    what is the C# doing with it? >>>
      CRC := Itf.Word(CRC xor Itf.Word(Bytes(J)));
  --      crc = (ushort)(crc ^ bytes[j]);
      for I in 1..8 loop
        if (CRC and 16#0001#) = 1 then
          -- Shift CRC right by one bit
--          declare
--            Word : Itf.Longword;
--            type DoubleWord
--            is record
--              Low  : Itf.Word;
--              High : Itf.Word;
--              end record;
--            for DoubleWord
--            use record
--              Low  at 0 range 0..15;
--              High at 2 range 0..15;
--            end record;
--            Double : DoubleWord;
--            for Double.Low use at CRC'address;
--            for Word use at Double'Address;
--          begin
--            Double.High := 0;
--            Shift_Right(Value => Word, Amount => 1);
--          end;
          CRC := RightShift(CRC,1);
          CRC := CRC xor 16#8408#;
        else
          CRC := RightShift(CRC,1);
        end if;
      end loop;
    end loop;
    -- take the bit-wise complement
    declare
      type PackedBits is array (1..16) of Boolean;
      Pragma Pack (PackedBits);
      for PackedBits'Size use 16;
      Bits : PackedBits;
      for Bits use at CRC'Address;
    begin
      for I in 1..16 loop
        if Bits(I) then
          Bits(I) := False;
        else
          Bits(I) := True;
        end if;
      end loop;
    end;
    return CRC;

  end CRC16;

end CRC;
