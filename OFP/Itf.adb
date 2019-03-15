
package body Itf is

  procedure Initialize is
  
  begin -- Initialize
  
    NullMessage.Header.CRC := 0;
    NullMessage.Header.Id.Topic := Topic.NONE;
    NullMessage.Header.Id.Ext := Topic.FRAMEWORK;
    NullMessage.Header.From.AppId := 0;
    NullMessage.Header.From.ComId := 0;
    NullMessage.Header.From.SubId := 0;
    NullMessage.Header.To.AppId := 0;
    NullMessage.Header.To.ComId := 0;
    NullMessage.Header.To.SubId := 0;
    NullMessage.Header.ReferenceNumber := 0;
    NullMessage.Header.Size := 0;
    NullMessage.Data(1) := ASCII.NUL;
  
  end Initialize;

end Itf;