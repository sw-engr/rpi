
with System;

package CStrings is

  subtype CompareResultType is Integer range -1..+1;
  subtype IntegerSizeType is Natural range 0..64;
  subtype StringOffsetType is Integer;

--  type StringType is
  -- Provides size and location of a string / character array
--  record
 --   Length : Itf.Int16; --<< the size will be until nul terminator >>
    -- Number of characters in the string
--    Value  : System.Address;
    -- Location of the string / character array
--  end record;
  subtype StringType is System.Address;
  -- Provides location of a string / character array

  type SubStringType is
  record
    Length : Natural;
    -- Number of characters in the substring
    Value  : System.Address;
    -- Location of the string / character array
  end record;
--  type SubStringType is
  -- Provides ???? and a string
--  record
--    Callback : System.Address;
--    Data     : StringType;
--  end record;

  function AddToAddress
  ( Location : in System.Address;
    Amount   : in Integer
  ) return System.Address;

  procedure Append
  ( First  : in StringType;
    -- First string to append Second to
    Second : in StringType;
    -- String to append to First
    Result : in out SubStringType
    -- Available length upon input; concatenated string with length upon output
  );
  -- Append strings; C# +=

  function Compare
  ( Left       : in StringType; --SubstringType;
    -- First substring to be compared
    Right      : in StringType; --SubstringType;
    -- Other substring to be compared with first
    IgnoreCase : in Boolean
    -- True if case is to be considered
  ) return CompareResultType;
  -- Return whether Left is alpha sort before Right, equal, or after
  -- The compare can go until the trailing nul characters

  function IndexOf
  ( From : in StringType; --SubstringType;
    -- String to be searched
    Find : in StringType --SubstringType
    -- String to search for
  ) return StringOffsetType;
  -- Return location in From at which Find was located

  function IndexOf1
  ( From : in StringType;
    -- String to be searched
    Find : in Character
    -- Character to search for
  ) return StringOffsetType;
  -- Return location in From at which Find was located

  procedure IntegerToString
  ( From    : in Integer;
    -- Integer to convert to a string
    Size    : in IntegerSizeType;
    -- Number of characters into which the converted value must fit
    CTerm   : in Boolean := True;
    -- Whether to terminate Result string with ASCII.NUL
    Result  : out String;
    -- Converted value with trailing NUL
    Success : out Boolean
    -- Whether From fits in Size (plus 1 for the NUL)
  );
  -- Convert Integer to string that will fit in string of Size

  function Substring
  ( From  : in StringType; --SubstringType;
    -- String from which to extract a substring
    Start : in StringOffsetType;
    -- Start index into From
    Stop  : in StringOffsetType
    -- End index into From
  ) return String; --StringType; SubStringType
  -- Extract substring from From and return from Start to Stop - 1

  procedure TryParse
  ( From    : in StringType;
    -- String from which to extract a substring and convert
    Size    : in IntegerSizeType;
    -- Number of bits into which the converted value must fit
    Result  : out Integer;
    -- Converted value as normal sized integer
    Success : out Boolean
    -- Whether From string is numeric and fits in Size
  );
  -- Convert String to integer that will fit in one of Size

end CStrings;
