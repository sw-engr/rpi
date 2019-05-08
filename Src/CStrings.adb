
with Interfaces.C;
with System.Storage_Elements;
with Text_IO;

package body CStrings is

  package C renames Interfaces.C;

  Adjustment
  : constant := Character'Pos('a') - Character'Pos('A');

  function AddToAddress
  ( Location : in System.Address;
    Amount   : in Integer
  ) return System.Address is
    use System.Storage_Elements;
  begin -- AddToAddress
    return Location+System.Storage_Elements.Storage_Offset(Amount);
  end AddToAddress;

  procedure Append
  ( First  : in StringType;
    Second : in StringType;
    Result : in out SubStringType
  ) is

    Available : Integer := Result.Length;

    Last : Integer := 0;

    FirstAddr  : System.Address := First;
    SecondAddr : System.Address := Second;
    OutAddr    : System.Address := Result.Value;

  begin -- Append

    -- Copy First string to Result
    while (True) loop
      declare
        Location : System.Address := FirstAddr;
        OutLoc   : System.Address := OutAddr;
      begin
        declare
          FirstChar : Character;
          for FirstChar use at Location;
          OutChar : Character;
          for OutChar use at OutLoc;
        begin
          if FirstChar = ASCII.NUL then -- end of first string
            exit; -- loop; don't copy the trailing NUL
          else
            if Last < Available then
              Last := Last + 1;     -- copy character into
              OutChar := FirstChar; --  output string
            else
              Text_IO.Put_Line("First string too long for output");
              raise Constraint_Error;
            end if;
          end if;
        end;
        FirstAddr := AddToAddress(FirstAddr,1);
        OutAddr   := AddToAddress(OutAddr,1);
     end;
    end loop;

    -- Copy Second string to Result
    while (True) loop
      declare
        Location : System.Address := SecondAddr;
        OutLoc   : System.Address := OutAddr;
      begin
        declare
          SecondChar : Character;
          for SecondChar use at Location;
          OutChar : Character;
          for OutChar use at OutLoc; --Result.Value;
        begin
          if Last < Available then
            Last := Last + 1;      -- copy character to
            OutChar := SecondChar; --  output Result string
            if SecondChar = ASCII.NUL then -- end of second string
              Result.Length := Last; -- Set output Result Length
              exit; -- loop to return with new string
            end if;
          else
            Text_IO.Put_Line("Second string too long for output");
            raise Constraint_Error;
          end if;
        end;
        SecondAddr := AddToAddress(SecondAddr,1);
        OutAddr    := AddToAddress(OutAddr,1);
      end;
    end loop;

  end Append;

  function ToLower
  ( Char : in Character
  ) return Character is
  begin -- ToLower
    if Char in 'A'..'Z' then
      return Character'Val( Character'Pos(Char) + Adjustment );
    else
      return Char;
    end if;
  end ToLower;

  function Compare
  ( Left       : in StringType; --SubstringType;
    Right      : in StringType; --SubstringType;
    IgnoreCase : in Boolean
  ) return CompareResultType is

    Index : Integer := 0;

    LeftAddr  : System.Address := Left;
    RightAddr : System.Address := Right;

  begin -- Compare

    while (True) loop
      Index := Index + 1;
      declare
        LeftLoc  : System.Address := LeftAddr;
        RightLoc : System.Address := RightAddr;
      begin
        declare
          LeftChar : Character;
          for LeftChar use at LeftLoc;
          RightChar : Character;
          for RightChar use at RightLoc;
        begin
          if IgnoreCase then
            LeftChar  := ToLower(LeftChar);
            RightChar := ToLower(RightChar);
          end if;
          if LeftChar = ASCII.NUL and then RightChar = ASCII.NUL then
            return 0; -- match
          elsif LeftChar = ASCII.NUL then
            return 1; -- treating blank fill etc as mismatch
          elsif RightChar = ASCII.NUL then
            return -1; -- treating blank fill etc as mismatch
          elsif LeftChar < RightChar then
            return 1; -- right string greater
          elsif LeftChar > RightChar then
            return -1; -- left string greater
          end if;
        end;
        LeftAddr  := AddToAddress(LeftAddr,1);
        --LeftLoc + System.Storage_Elements.Storage_Offset(1);
        RightAddr := AddToAddress(RightAddr,1);-- + System.Storage_Elements.Storage_Offset(1);
      end;
    end loop;
    return -1;
  end Compare;

  function IndexOf
  ( From : in StringType; --SubstringType;
    Find : in StringType --SubstringType
  ) return StringOffsetType is

    Done  : Boolean;
    Index : Integer := 1;

    FromAddr : System.Address := From;
    FindAddr : System.Address := Find;

    TempFind : array(0..120) of Character; --C.char_array(1..120);

 --   use System.Storage_Elements;

  begin -- IndexOf

--change this to find size of Find by locating the trailing NUL
--then search thru From for a complete match of Find chars except for the
--trailing NUL

    -- Obtain array of characters to search for in From.  Limit the number
    -- of characters in Find.
    Done := False;
    declare
      Location : System.Address := FindAddr;
    begin
      declare
        FindChar : Character;
        for FindChar use at Location;
      begin
        if FindChar /= ASCII.NUL then
          TempFind(Index) := FindChar;
          Index := Index + 1;
        else
          Done := True;
        end if;
      end;
      if not Done and then Index < 120 then
        Location := AddToAddress(Location,1); -- + System.Storage_Elements.Storage_Offset(1); --Machine +.## what to increment address?
      end if;
    end;

-- what to do?  obtain the complete Find string as started above OR
-- look for first Find character in the From string and then check if
-- any following Find chars (i.e., next char not NUL).  If following
-- Find chars, check if the next Find char is matched to the next From
-- char (while checking that the next From char is not NUL).  If the
-- same continue.  If not, start over looking for the first Find char
-- from the current From char.
-- or easier to get the complete Find string (less trailing NUL) first
-- and then do a sliding loop thru the From string checking for a
-- complete match to the Find string.
-- This way can use String_Tools code for the match.  And if From string
-- is too short, its trailing NUL will cause a mismatch since Find string
-- will no longer have a trailing NUL.

 --   declare
 --     FromData : Character;
 --     for FromData use at TempFrom;
 --     FindData : Character;
return 0;
  end IndexOf;

  function IndexOf1
  ( From : in StringType;
    Find : in Character
  ) return StringOffsetType is

    Found : Boolean := False;
    Index : StringOffsetType := 1;

    FromAddr : System.Address := From;

--    use System.Storage_Elements;

  begin -- IndexOf1

    while (not Found) loop
      declare
        Location : System.Address := FromAddr;
      begin
        declare
          FromChar : Character;
          for FromChar use at Location;
        begin
          if FromChar = Find then
            Found := True;
            return Index;
          elsif FromChar = ASCII.NUL then -- at end of C string
            Found := True;
            return 0;
          end if;
        end;
      end;
      Index := Index + 1;
      FromAddr := AddToAddress(FromAddr,1); -- + System.Storage_Elements.Storage_Offset(1);
    end loop;

    return 0;

  end IndexOf1;

  procedure IntegerToString
  ( From    : in Integer;
    Size    : in IntegerSizeType;
    CTerm   : in Boolean := True;
    Result  : out String;
    Success : out Boolean
  ) is

    ResultData : String(1..Size+1); -- sufficient to contain the converted integer

    Index : Integer := 0; -- location at which to insert '-' sign
    Sign  : Character := ' ';

    TempFrom : Integer;
    -- From as positive

  begin -- IntegerToString

    if From < 0 then
      Sign := '-';
    end if;

    TempFrom := Abs(From);

    ResultData := ( others => '0' );
    for I in reverse 1..Size loop
      ResultData(I) := Character'Val( Character'Pos('0') + ( TempFrom mod 10) );
      TempFrom := TempFrom / 10;
      exit when TempFrom = 0;
    end loop;

    if TempFrom /= 0 then -- From cannot be converted into Size characters
      Success := False;
      Result := (others => ASCII.NUL);
      return;
    end if;

    Index := 0;
    for I in 1..Size-1 loop -- replace leading 0s with spaces
      exit when ResultData(I) /= '0';
      Index := I; -- index of last space
      ResultData(Index) := ' ';
    end loop;

    if Sign /= ' ' then -- negative sign
      if Index > 0 then -- available position for negative sign
        ResultData(Index) := Sign;
      else -- From cannot be converted into Size characters
        Success := False;
        Result := (others => ASCII.NUL);
        return;
      end if;
    end if;

    Success := True;
    if CTerm then
      ResultData(Size+1) := ASCII.NUL; -- append trailing NUL
      Result := ResultData;
    else
      Result := ResultData(1..Size);
    end if;

  end IntegerToString;

  function Substring
  ( From  : in StringType;
    Start : in StringOffsetType;
    Stop  : in StringOffsetType
  ) return String is --SubStringType is --StringType is

    -- Create C char_array at location of From
    Size : C.size_t := C.size_t(Stop-Start+2);
    FromData : C.char_array(1..Size);
    for FromData use at From;

    Index : Integer;

    -- Ada string to be returned
    Temp : String(1..Stop-Start+2) := ( others => ASCII.NUL );
--    TempAda : String(1..Stop-Start+2);
--    TempC : C.char_array(Stop-Start+2);

  begin -- Substring

    -- Copy substring characters from location at From to Ada string.
    Index := 0;
    for I in Start..Stop loop
      Index := Index + 1;
      Temp(Index) := Character(FromData(C.size_t(I)));
      if Temp(Index) = ASCII.NUL then -- quit early if trailing NUL found
        exit; -- loop
      end if;
    end loop;

    -- Insert trailing NUL if needed
    if Temp(Index) /= ASCII.NUL then
      Index := Index + 1;
      Temp(Index) := ASCII.NUL;
    end if;
  --  C.To_Ada(
  --return ( 0, System.Null_Address );

    -- Return NUL terminated Ada string.
    return Temp(1..Index); --( Index, Temp ); -- can't return Temp as address since on stack

  end Substring;

  procedure TryParse
  ( From    : in StringType;
    Size    : in IntegerSizeType;
    Result  : out Integer;
    Success : out Boolean
  ) is

    Digit : Integer;
    Sign  : Integer := 1;
    Start : Integer := 1;

    Number : Integer := 0;

    FromData : String(1..Size); --C.char_array(1..Size);
    for FromData use at From;

  begin -- TryParse

    Result := 0;
    Success := False;

    -- Check for leading spaces
    for I in 1..Size loop
      if FromData(I) /= ' ' then
        Start := I;
        exit;
      end if;
    end loop;

    -- Check for a leading non-space sign
    if FromData(Start) = '+' then
      Start := Start + 1; -- bypass sign
    elsif FromData(Start) = '-' then
      Start := Start + 1;
      Sign  := -1; -- to make number negative
    end if;

    -- Check if rest of From array contains numeric digits and convert
    for I in Start..Size loop
      if FromData(I) not in '0'..'9' then
        if I = Size and then FromData(I) = ASCII.NUL then
          null; -- ignore trailing NUL
        else
          return; -- with failure
        end if;
      else -- valid digit
        Digit := Character'Pos(FromData(I)) - Character'Pos('0');
        Number := Number * 10 + Digit;
      end if;
    end loop;

    Result := Sign*Number; -- take any leading sign into account
    Success := True;

  end TryParse;

end CStrings;
