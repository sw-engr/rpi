
with Itf;

package CRC is

  function CRC16
  ( Count : in Itf.Word;
    Data  : in Itf.MessageType
  ) return Itf.Word;

end CRC;
