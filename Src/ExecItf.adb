
with Ada.Directories;
with CStrings;
with GNAT.OS_Lib;
with GNAT.Sockets.Thin;
with GNAT.Threads;
with Interfaces.C;
with Interfaces.C.Strings;
with Itf;
with Text_IO; --<<<temporary>>>

package body ExecItf is

  package Int_IO is new Text_IO.Integer_IO( Integer );

  Length
  -- Length of current directory/folder path
  : Integer := 0;
  Current_Directory : String(1..240);

  FALSEint : constant := 0;                          -- windef.h
  TRUEint  : constant := 1;                          -- windef.h

  Linux_Config_File_Name
  : constant Config_File_Name_Var_Type
  := ( Count => 46,
       Value => "/home/clayton/Source/EP/Apps-Configuration.dat              " );

  Windows_Config_File_Name
  : constant Config_File_Name_Var_Type
  := ( Count => 35,                   -- Windows
       Value => "C:\Source\EP\Apps-Configuration.dat                         " );

  function Config_File_Name
  return Config_File_Name_Var_Type is

  begin -- Config_File_Name

    if Op_Sys = Linux then
      return Linux_Config_File_Name;
    else
      return Windows_Config_File_Name;
    end if;

  end Config_File_Name;

  procedure Set_Op_Sys is

  begin -- Set_Op_Sys

    -- Logic_Step:
    --   Obtain current folder name.

    Length := Ada.Directories.Current_Directory'Length;

    declare

      Current_Dir
      -- Path name sized to that to be returned
      : String(1..Length);

    begin

      Current_Dir := Ada.Directories.Current_Directory;
      Current_Directory := ( others => ' ' );
      Current_Directory(1..Length) := Current_Dir;

      -- Logic_Step:
      --   Determine operating system that running under from the name.

      if Length > 2 and then
         ( Current_Dir(1..2) = "C:" or else Current_Dir(1..2) = "c:" )
      then
        Op_Sys := ExecItf.Windows;
      elsif Length > 6 and then
            ( Current_Dir(1..6) = "/home/" or else Current_Dir(1..6) = "\home\" )
      then
        Op_Sys := ExecItf.Linux;
      end if;

    end;

  end Set_Op_Sys;

  function GetHostName
  ( Name   : in System.Address;
    Length : in Interfaces.C.int
  ) return Interfaces.C.int;
  -- Return host name
  pragma Import(C, GetHostName, "gethostname");

  function GetComputerName
  ( Name   : in System.Address;
    Length : in Computer_Name_Type
  ) return Integer is

    ErrorCode : Interfaces.C.int;

    HostName : String(1..Computer_Name_Type'last);
    for HostName use at Name;

    Result : Integer;

  begin -- GetComputerName

    if Op_Sys = Linux then
      ErrorCode := GetHostName( Name   => Name,
                                Length => Interfaces.C.int(Length) );
    else
      ErrorCode := GNAT.Sockets.Thin.C_Gethostname( Name    => Name,
                                                    NameLen => Interfaces.C.int(Length) );
    end if;
    Result := Integer(ErrorCode);

    if Result = 0 then -- no error
      Result := Computer_Name_Type'last;
      for I in 1..Computer_Name_Type'last loop
        if HostName(I) = ASCII.NUL then -- trailing NUL found
          Result := I-1; -- return length of name
          exit; -- loop
        end if;
      end loop;
    end if;

    return Result; -- return -1 for error or # of chars in name

  end GetComputerName;

  procedure Exit_to_OS
  ( Status : Integer := 0
  ) is
  begin -- Exit_to_OS
    GNAT.OS_Lib.OS_Exit( Status );
  end Exit_to_OS;


  function Errno return Integer;
  -- Return the task-safe last error number
  pragma Import (C, Errno, "__get_errno");

  function GetLastErrorWindows return DWORD;            -- winbase.h:1703
  pragma Import( Stdcall, GetLastErrorWindows, "GetLastError" ); -- winbase.h:1703

--  function WSAGetLastError return INT;
--  pragma Import( Stdcall, WSAGetLastError, "WSAGetLastError" ); -- winsock.h:318

  function GetLastError
  return Integer is

    LastError : DWORD;

  begin -- GetLastError

    if Op_Sys = Linux then
      return Errno;
    else
      LastError := GetLastErrorWindows;
      return Integer(LastError);
    end if;

  end GetLastError;

  procedure Set_Errno
  ( Errno : Integer );
  -- Set last error number
  pragma Import (C, Set_Errno, "__set_errno");

  type String255 is new String(1..255);
  type StrPtr is access String255;
  -- error messages are no longer than 255 characters

  function StrError
  ( Error_Number : Integer
  ) return StrPtr;
  pragma Import( C, StrError, "strerror" );


  -- **********************************************************
  -- This package describes the differences in machine
  -- architectures that need to be known by Stdarg.
  --
  -- I386 is Intel 386/486/Pentium PC's
  -- Sparc is Sun-4 Sparcstation and Sparcserver
  -- HP is Hewlett-Packard HP-9000 series 700 and 800
  -- Mips is machines based on the MIPS chip, such as SGI
  -- PowerPC is Apple-IBM-Motorola Power PC, and IBM RS/6000
  -- Alpha is the Digital Equipment Corporation chip.
  --
  -- To build these packages for a different architecture,
  -- change the constant This_Arch to one of the allowed values
  -- and recompile.
  -- **********************************************************
  type Arch is (I386, Sparc, HP, Mips, Alpha, PowerPC); -- stdarg-machine.ads

  This_Arch: constant Arch := I386;                     -- stdarg-machine.ads

  type Stack_Growth_Direction                           -- stdarg-machine.ads
  is ( Up,             -- toward address 0
       Down );         -- toward high numbered addresses

  type Which_Arg is (Ellipsis, VA_List);  -- Stdarg-impl.adb

  type Arch_Description_Rec
  is record
    Int_Param_Alignment,
    Float_Param_Alignment : Positive;
    Stack_Growth          : Stack_Growth_Direction;
  end record;

  SU : constant := System.Storage_Unit;

  Arch_Description
  : constant array (Arch) of Arch_Description_Rec
  := (  I386 => (
	    Int_Param_Alignment   => C_Param'Size/SU,
	    Float_Param_Alignment => C_Param'Size/SU,
	    Stack_Growth          => Up )
	, Sparc => (
	    Int_Param_Alignment   => C_Param'Size/SU,
	    Float_Param_Alignment => C_Param'Size/SU,
	    Stack_Growth          => Up )
	, HP => (
	    Int_Param_Alignment   => C_Param'Size/SU,
	    Float_Param_Alignment => Interfaces.C.Double'Size/SU,
	    Stack_Growth          => Down )
	, Mips => (
	    Int_Param_Alignment   => C_Param'Size/SU,
	    Float_Param_Alignment => Interfaces.C.Double'Size/SU,
	    Stack_Growth          => Up )
	, Alpha => (
	    Int_Param_Alignment   => C_Param'Size/SU,
	    Float_Param_Alignment => Interfaces.C.Double'Size/SU,
	    Stack_Growth          => Up )
	, PowerPC => (
	    Int_Param_Alignment   => C_Param'Size/SU,
	    Float_Param_Alignment => C_Param'Size/SU,
	    Stack_Growth          => Up )
     );

  Desc                 : Arch_Description_Rec renames    -- stdarg-machine.ads
			   Arch_Description(This_Arch);
  Int_Param_Alignment  : Positive renames Desc.Int_Param_Alignment;
  Float_Param_Alignment: Positive renames Desc.Float_Param_Alignment;
  Stack_Growth         : Stack_Growth_Direction renames Desc.Stack_Growth;
  Param_Size           : constant Positive := C_Param'Size/SU;

  function Address_of_Arg                 -- Stdarg-impl.adb
  ( Args  : ArgList;
    Which : Which_Arg
  ) return Param_Access is
  begin
    if Args.Contents.CurrentArgs = 0 then
      return null; -- might not be an error
    end if;

    if This_Arch = Alpha then
      return Args.Contents.Vector(7)'access;
    elsif Stack_Growth = Up then
      return Args.Contents.Vector(1)'access;
    elsif Which = Ellipsis then
      return Args.Contents.Vector(MaxArguments-Args.Contents.CurrentArgs+1)'access;
    else
      declare
	use Arith;
	P : Pointer := Args.Contents.Vector(MaxArguments)'access;
      begin
        return Param_Access(P+1);
      end;
   end if;
  end Address_of_Arg;

  function Address_of_First_Arg
  ( Args : ArgList
  ) return Param_Access is
  begin
    return Address_of_Arg(Args, Ellipsis);
  end Address_of_First_Arg;

  function Empty return ArgList is
    Res: ArgList;
  begin
    Res.Contents := new ArgBlock;
    return Res;
  end Empty;

  function FormatMessage -- only for Windows
  ( Flags      : DWORD;
    Source     : LPCVOID;
    MessageId  : DWORD;
    LanguageId : DWORD;
    Buffer     : LPSTR;
    Size       : DWORD;
    Arguments  : ArgList := Empty
  ) return DWORD is

    function Doit    -- can't use with Linux
    ( dwFlags      : DWORD;
      lpSource     : LPCVOID;
      dwMessageId  : DWORD;
      dwLanguageId : DWORD;
      lpBuffer     : LPSTR;
      nSize        : DWORD;
      Arguments    : access Param_Access
    ) return DWORD;
    pragma Import( Stdcall, Doit, "FormatMessageA" );


    Param_Addr
    : aliased Param_Access
    := Address_of_First_Arg(Arguments);

  begin

    return Doit( Flags, Source, MessageId, LanguageId,
                 Buffer, Size, Param_Addr'access );    -- strange

  end FormatMessage;

  -- not for Linux
  function SetConsoleCtrlHandlerWindows            -- same as Win32.Wincon
  ( HandlerRoutine : PHANDLER_ROUTINE;
    Add            : BOOL
  ) return BOOL;
  pragma Import( Stdcall, SetConsoleCtrlHandlerWindows, "SetConsoleCtrlHandler" ); -- wincon.h:571

  function SetConsoleCtrlHandler                 -- same as Win32.Wincon
  ( HandlerRoutine : PHANDLER_ROUTINE;
    Add            : BOOL
  ) return BOOL is
  begin
    return SetConsoleCtrlHandlerWindows( HandlerRoutine => HandlerRoutine,
                                         Add            => Add );
  end SetConsoleCtrlHandler;

  -- not for Linux
  procedure InitializeCriticalSectionWindows                 -- winbase.h:1843
  ( CriticalSection : LPCRITICAL_SECTION
  );
  pragma Import( Stdcall, InitializeCriticalSectionWindows,  -- winbase.h:1843
                         "InitializeCriticalSection");

  procedure InitializeCriticalSection                 -- winbase.h:1843
  ( CriticalSection : LPCRITICAL_SECTION
  ) is
  begin -- InitializeCriticalSection
    InitializeCriticalSectionWindows( CriticalSection => CriticalSection );
  end InitializeCriticalSection;

  -- not for Linux
  procedure LeaveCriticalSectionWindows                 -- winbase.h:1857
  ( CriticalSection : LPCRITICAL_SECTION
  );
  pragma Import( Stdcall, LeaveCriticalSectionWindows,  -- winbase.h:1857
                          "LeaveCriticalSection" );

  procedure LeaveCriticalSection                 -- winbase.h:1857
  ( CriticalSection : LPCRITICAL_SECTION
  ) is
  begin -- LeaveCriticalSection
    LeaveCriticalSectionWindows( CriticalSection => CriticalSection );
  end LeaveCriticalSection;

  ------------------------------------------------------------------------------
  -- Directories

  type Dir_Entity_Struct_Type
  -- Linux note:
  --  The only fields in the dirent structure that are mandated by POSIX.1 are:
  --  o d_name[], of unspecified size, with at most NAME_MAX characters
  --              preceding the terminating null byte; and
  --  o (as an XSI extension) d_ino.
  --  The other fields are unstandardized, and not present on all systems.
  is record
    D_INo    : Itf.Longword; -- File system i-node number
    -- The file serial number, which distinguishes this file from all other
    -- files on the same device.
    D_Off    : Itf.Longword; -- i.e., of type off_t
    -- File offset, measured in bytes from the beginning of a file or device.
    -- off_t is normally defined as a signed, 32-bit integer. In the
    -- programming environment which enables large files, off_t is defined
    -- to be a signed, 64-bit integer.
    D_Reclen : Itf.Word;
    D_Type   : Itf.Byte;
    D_Name   : String(1..256); -- null terminated
  end record;

  type Dir_Entity_Ptr_Type is access Dir_Entity_Struct_Type;

  function OpenDir
  ( File_Name : String
    -- Name of directory; null terminated
  ) return System.Address;
  -- Pointer to opened directory
  pragma Import (C, OpenDir, "__gnat_opendir");

  function ReadDir
  ( Directory : System.Address
    -- Pointer to opened directory
  ) return Dir_Entity_Ptr_Type;
  -- Return pointer to directory entity
  pragma Import( C, ReadDir, "readdir" );

  function ReadLink
  ( Proc   : System.Address;
    -- Pointer to null terminated string
    Buffer : System.Address;
    -- Pointer to buffer for path
    Length : Integer
    -- Length of buffer
  ) return Integer;
  -- Return number of characters output to Buffer
--  pragma Import( C, ReadLink, "readlink" );
-- needed for Linux
  function ReadLink
  ( Proc   : System.Address;
    -- Pointer to null terminated string
    Buffer : System.Address;
    -- Pointer to buffer for path
    Length : Integer
    -- Length of buffer
  ) return Integer is
  begin -- ReadLink
    return -1;
  end ReadLink;
--above to compile for Windows

  ------------------------------------------------------------------------------
  -- Files

  function File_Descriptor_to_Handle
  is new Unchecked_Conversion( Source => GNAT.OS_Lib.File_Descriptor,
                               Target => File_Handle );

  function Handle_to_File_Descriptor
  is new Unchecked_Conversion( Source => File_Handle,
                               Target => GNAT.OS_Lib.File_Descriptor );

  function to_Mode is new Unchecked_Conversion( Source => Mode_Type,
                                                Target => GNAT.OS_Lib.Mode );

  function Close_File
  ( Handle : File_Handle
  ) return Boolean is

    Status : Boolean;

  begin -- Close_File

    GNAT.OS_Lib.Close( FD     => Handle_to_File_Descriptor(Handle),
                       Status => Status );
    return Status;

  end Close_File;

  function Create_File
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle is
  -- Creates new file with given name for writing, returning the file
  -- descriptor for subsequent use in Write calls. The file descriptor
  -- returned is Invalid_File_Handle if file cannot be successfully created

    FileDesc : GNAT.OS_Lib.File_Descriptor;

    function File_Descriptor_to_Handle
    is new Unchecked_Conversion( Source => GNAT.OS_Lib.File_Descriptor,
                                 Target => File_Handle );

    function to_Mode is new Unchecked_Conversion( Source => Mode_Type,
                                                  Target => GNAT.OS_Lib.Mode );

  begin -- Create_File

    FileDesc := GNAT.OS_Lib.Create_File( Name  => Name'address,
                                         FMode => to_Mode(Mode) );
    return File_Descriptor_to_Handle( FileDesc );

  end Create_File;

  function Create_New_File
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle is
  -- Create new file with given name for writing, returning file descriptor
  -- for subsequent use in Write calls. This differs from Create_File in
  -- that it fails if the file already exists. File descriptor returned is
  -- Invalid_FD if the file exists or cannot be created.

    FileDesc : GNAT.OS_Lib.File_Descriptor;

  begin -- Create_New_File

    FileDesc := GNAT.OS_Lib.Create_New_File( Name  => Name,
                                             FMode => to_Mode(Mode) );
    return File_Descriptor_to_Handle( FileDesc );

  end Create_New_File;

  function Open_Read
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle is

    FileDesc : GNAT.OS_Lib.File_Descriptor;

    function File_Descriptor_to_Handle
    is new Unchecked_Conversion( Source => GNAT.OS_Lib.File_Descriptor,
                                 Target => File_Handle );

    function to_Mode is new Unchecked_Conversion( Source => Mode_Type,
                                                  Target => GNAT.OS_Lib.Mode );

 --   New_Handle : File_Handle;

 --   function Int_to_Address is new Unchecked_Conversion
    -- To convert an integer to an address
 --   ( Source => Integer,
 --     Target => System.Address );

 --   function to_LPCSTR is new Unchecked_Conversion -- convert address to pointer
 --   ( Source => System.Address,
 --     Target => LPCSTR );

  begin -- Open_Read

--    New_Handle := CreateFile
--                  ( FileName            => to_LPCSTR(Name'address),
--                    DesiredAccess       => Exec_Itf.Generic_Read,
--                    ShareMode           => Exec_Itf.FILE_SHARE_READ,
--                    SecurityAttributes  => null,
--                    CreationDisposition => Exec_Itf.Open_Existing,
--                    FlagsAndAttributes  => Exec_Itf.FILE_ATTRIBUTE_NORMAL,
--                    TemplateFile        => Int_to_Address(0) );

--    New_Handle := Create_File( Name => Name,
--                               Mode => Mode );
--    return New_Handle;

    FileDesc := GNAT.OS_Lib.Open_Read( Name  => Name'address,
                                       FMode => to_Mode(Mode) );
    return File_Descriptor_to_Handle( FileDesc );

  end Open_Read;

  function Open_Read_Write
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle is
  --  Open file Name for both reading and writing, returning file
  --  descriptor. File descriptor returned is Invalid_FD if file cannot be
  --  opened.

    Handle : GNAT.OS_Lib.File_Descriptor;

  begin -- Open_Read_Write

    Handle := GNAT.OS_Lib.Open_Read_Write( Name  => Name,
                                           FMode => to_Mode(Mode) );
    return File_Descriptor_to_Handle( Handle );

  end Open_Read_Write;

  function Read_File
  ( File : File_Handle;
    Addr : System.Address;
    Num  : Integer
  ) return Integer is

--    Bytes_Read : LPDWORD;
--    Result     : BOOL;
    Bytes_Read : Integer := 0;

--    function to_Int
--    is new Unchecked_Conversion( Source => Exec_Itf.LPDWORD,
--                                 Target => Integer );

--    function to_LPCVOID -- convert address to Exec_Itf pointer
--    is new Unchecked_Conversion( Source => System.Address,
--                                 Target => Exec_Itf.LPCVOID );

--    function to_DWORD -- convert integer to DWORD
--    is new Unchecked_Conversion( Source => Integer,
--                                 Target => Exec_Itf.DWORD );

--    function to_LPDWORD -- convert address to pointer
--    is new Unchecked_Conversion( Source => System.Address,
--                                 Target => Exec_Itf.LPDWORD );

  begin -- Read_File

--    Result := ReadFile
--              ( File                => File_Handle,
--                Buffer              => to_LPCVOID(Addr),
--                NumberOfBytesToRead => to_DWORD(Num),
--                NumberOfBytesRead   => to_LPDWORD(Bytes_Read'address),
--                Overlapped          => null ); -- not overlapped I/O
--    return to_Int(Bytes_Read);

    Bytes_Read := GNAT.OS_Lib.Read( FD => Handle_to_File_Descriptor(File),
                                    A  => Addr, --Bytes'address,
                                    N  => Num );
    return Bytes_Read;


    --            ( File                => Mailslot.Server.Handle,         -- handle of mailslot
   --              Buffer              => to_LPCVOID(Message_In'address), -- buffer to receive data
   --              NumberOfBytesToRead => Mailslot.Max_Message_Size,      -- size of the buffer
   --              NumberOfBytesRead   => to_LPDWORD(Bytes_Read'address),
   --              Overlapped          => null ); -- not overlapped I/O

  exception
    when others =>
      return 0;

  end Read_File;

  function Write_File
  -- Write Text to File and return number of bytes written.  Strip internal
  -- NULs if True.
  ( File       : in File_Handle;
    Text       : in String;
    Strip_NULs : in Boolean := False
  ) return Integer is

    Index  : Integer := 0;
    Length : Integer;

    Result : Integer;

    Text_Out : String(1..Text'length+1);

  begin -- Write_File

    Length := Text'length;

    Text_Out(1..Length) := Text;
    Text_Out(Length+1)  := ASCII.NUL;

    -- Avoid the output of nulls embedded in the text.
    if Strip_NULs then
      for I in 1..Length loop
        if Text_Out(I) /= ASCII.NUL then
          Index := Index + 1;
          Text_Out(Index) := Text_Out(I);
        end if;
      end loop;
      Length := Index;
      Text_Out(Length+1) := ASCII.NUL;
    end if;

    Result := GNAT.OS_Lib.Write( FD => Handle_to_File_Descriptor(File),
                                 A  => Text_Out'address,
                                 N  => Length );
    return Result;

  end Write_File;

  function Write_File
  -- Write Len bytes at Addr to File and return number of bytes written.
  ( File : File_Handle;
    Addr : System.Address;
    Len  : Integer
  ) return Integer is

    Result : Integer;

  begin -- Write_File

    Result := GNAT.OS_Lib.Write( FD => Handle_to_File_Descriptor(File),
                                 A  => Addr, --Bytes_Out'address,
                                 N  => Len );
    return Result;

  end Write_File;

  ------------------------------------------------------------------------------
  -- Pipes

--  function MkFifo_Linux
--  ( Path : System.Address;
--    Mode : Mode_t
--  ) return Integer;
--  pragma Import( C, MkFifo_Linux, "mkfifo" );
-- above for Linux
--  function MkFifo_Linux
--  ( Path : System.Address;
--    Mode : Mode_t
--  ) return Integer is
--  begin
--    return -1;
--  end;
--<<< above to compile for Windows >>>

--  function MkFifo
--  ( Path : System.Address;
--    Mode : Mode_t
--  ) return Integer is
--  begin -- MkFifo
  --  if Op_Sys = Linux then
  --    return MkFifo_Linux( Path => Path,
  --                         Mode => Mode );
  --  else
--      return -1;
  --  end if;
 -- end MkFifo;

  function CloseHandleWindows                     -- winbase.h:2171
  ( Object : HANDLE
  ) return BOOL;
--<<< not for Linux >>>
  pragma Import( Stdcall, CloseHandleWindows, "CloseHandle" ); -- winbase.h:2171

  function CloseHandle                           -- winbase.h:2171
  ( Object : HANDLE
  ) return BOOL is
  begin -- CloseHandle
--    if Op_Sys = Linux then
--      return FALSEint;
--    else
      return CloseHandleWindows( Object => Object );
--    end if;
  end CloseHandle;

  function CreateFileWindows                            -- winbase.h:4745
  ( FileName            : LPCSTR;
    DesiredAccess       : DWORD;
    ShareMode           : DWORD;
    SecurityAttributes  : LPSECURITY_ATTRIBUTES;
    CreationDisposition : DWORD;
    FlagsAndAttributes  : DWORD;
    TemplateFile        : HANDLE
  ) return HANDLE;
  pragma Import( Stdcall, CreateFileWindows, "CreateFileA" ); -- winbase.h:4745
  -- CreateFile and CreateFileA are the same function
--<<< not for Linux >>>

  function CreateFile                            -- winbase.h:4745
  ( FileName            : LPCSTR;
    DesiredAccess       : DWORD;
    ShareMode           : DWORD;
    SecurityAttributes  : LPSECURITY_ATTRIBUTES;
    CreationDisposition : DWORD;
    FlagsAndAttributes  : DWORD;
    TemplateFile        : HANDLE
  ) return HANDLE is
  begin -- CreateFile
--    if Op_Sys = Linux then
--      return System.Null_Address;
--    else
      return CreateFileWindows( FileName            => FileName,
                                DesiredAccess       => DesiredAccess,
                                ShareMode           => ShareMode,
                                SecurityAttributes  => SecurityAttributes,
                                CreationDisposition => CreationDisposition,
                                FlagsAndAttributes  => FlagsAndAttributes,
                                TemplateFile        => TemplateFile );
--    end if;
  end CreateFile;

  function ConnectNamedPipeWindows                      -- winbase.h:2816
  ( NamedPipe  : HANDLE;
    Overlapped : LPOVERLAPPED
  ) return BOOL;
  pragma Import( Stdcall, ConnectNamedPipeWindows, "ConnectNamedPipe" ); -- winbase.h:2816
-- above for Windows
--  function ConnectNamedPipeWindows                      -- winbase.h:2816
--  ( NamedPipe  : HANDLE;
--    Overlapped : LPOVERLAPPED
--  ) return BOOL is
--  begin
--    return FALSEint;
--  end;
--<<< not for Linux >>>

  function ConnectNamedPipe
  ( NamedPipe  : HANDLE;
    Overlapped : LPOVERLAPPED
  ) return BOOL is
  begin -- ConnectNamedPipe
--    if Op_Sys = Linux then
--      return FALSEint;
--    else
      return ConnectNamedPipeWindows( NamedPipe  => NamedPipe,
                                      Overlapped => Overlapped );
--    end if;
  end ConnectNamedPipe;

  function CreateNamedPipeWindows                       -- winbase.h:4987
  ( Name               : LPCSTR;
    OpenMode           : DWORD;
    PipeMode           : DWORD;
    MaxInstances       : DWORD;
    OutBufferSize      : DWORD;
    InBufferSize       : DWORD;
    DefaultTimeOut     : DWORD;
    SecurityAttributes : LPSECURITY_ATTRIBUTES
  ) return HANDLE;
  pragma Import( Stdcall, CreateNamedPipeWindows, "CreateNamedPipeA" ); -- winbase.h:4987
  -- CreateNamedPipe and CreateNamedPipeA are the same function
--<<< not for Linux >>>
--  function CreateNamedPipeWindows                       -- winbase.h:4987
--  ( Name               : LPCSTR;
--    OpenMode           : DWORD;
--    PipeMode           : DWORD;
--    MaxInstances       : DWORD;
--    OutBufferSize      : DWORD;
--    InBufferSize       : DWORD;
--    DefaultTimeOut     : DWORD;
--    SecurityAttributes : LPSECURITY_ATTRIBUTES
--  ) return HANDLE is
--  begin
--    return System.Null_Address;
--  end;

  function CreateNamedPipe
  ( Name               : LPCSTR;
    OpenMode           : DWORD;
    PipeMode           : DWORD;
    MaxInstances       : DWORD;
    OutBufferSize      : DWORD;
    InBufferSize       : DWORD;
    DefaultTimeOut     : DWORD;
    SecurityAttributes : LPSECURITY_ATTRIBUTES
  ) return HANDLE is
  begin -- CreateNamedPipe
--    if Op_Sys = Linux then
--      return System.Null_Address;
--    else
      return CreateNamedPipeWindows
             ( Name               => Name,
               OpenMode           => OpenMode,
               PipeMode           => PipeMode,
               MaxInstances       => MaxInstances,
               OutBufferSize      => OutBufferSize,
               InBufferSize       => InBufferSize,
               DefaultTimeOut     => DefaultTimeOut,
               SecurityAttributes => SecurityAttributes );
--    end if;
  end CreateNamedPipe;

  function DisconnectNamedPipeWindows                   -- winbase.h:2824
  ( NamedPipe : HANDLE
  ) return BOOL;
--<<< not for Linux >>>
  pragma Import( Stdcall, DisconnectNamedPipeWindows, "DisconnectNamedPipe" ); -- winbase.h:2824

  function DisconnectNamedPipe                   -- winbase.h:2824
  ( NamedPipe : HANDLE
  ) return BOOL is
  begin -- DisconnectNamedPipe
--    if Op_Sys = Linux then
--      return FALSEint;
--    else
      return DisconnectNamedPipeWindows( NamedPipe => NamedPipe );
--    end if;
  end DisconnectNamedPipe;

  function ReadFileWindows                              -- winbase.h:2095
  ( File                : HANDLE;
    Buffer              : LPVOID;
    NumberOfBytesToRead : DWORD;
    NumberOfBytesRead   : LPDWORD;
    Overlapped          : LPOVERLAPPED
  ) return BOOL;
--<<< not for Linux >>>
  pragma Import( Stdcall, ReadFileWindows, "ReadFile"); -- winbase.h:2095

  function ReadFile                              -- winbase.h:2095
  ( File                : HANDLE;
    Buffer              : LPVOID;
    NumberOfBytesToRead : DWORD;
    NumberOfBytesRead   : LPDWORD;
    Overlapped          : LPOVERLAPPED
  ) return BOOL is
  begin -- ReadFile
--    if Op_Sys = Linux then
--      return FALSEint;
--    else
      return ReadFileWindows( File => File,
                             Buffer => Buffer,
                             NumberOfBytesToRead => NumberOfBytesToRead,
                             NumberOfBytesRead   => NumberOfBytesRead,
                             Overlapped          => Overlapped );
--    end if;
  end ReadFile;

  function WriteFileWindows                             -- winbase.h:2084
  ( File                 : HANDLE;
    Buffer               : LPCVOID;
    NumberOfBytesToWrite : DWORD;
    NumberOfBytesWritten : LPDWORD;
    Overlapped           : LPOVERLAPPED
  ) return BOOL;
--<<< not for Linux >>>
  pragma Import( Stdcall, WriteFileWindows, "WriteFile" ); -- winbase.h:2084

  function WriteFile                             -- winbase.h:2084
  ( File                 : HANDLE;
    Buffer               : LPCVOID;
    NumberOfBytesToWrite : DWORD;
    NumberOfBytesWritten : LPDWORD;
    Overlapped           : LPOVERLAPPED
  ) return BOOL is
  begin -- WriteFile
--    if Op_Sys = Linux then
--      return FALSEint;
--    else
      return WriteFileWindows( File                 => File,
                               Buffer               => Buffer,
                               NumberOfBytesToWrite => NumberOfBytesToWrite,
                               NumberOfBytesWritten => NumberOfBytesWritten,
                               Overlapped           => Overlapped );
--    end if;
  end WriteFile;

  ------------------------------------------------------------------------------
  -- Events

  function CreateEventWindows                       -- winbase.h:3457
  ( EventAttributes : LPSECURITY_ATTRIBUTES;
    ManualReset     : BOOL;
    InitialState    : BOOL;
    Name            : LPCSTR
  ) return HANDLE;
  pragma Import( Stdcall, CreateEventWindows, "CreateEventA" ); -- winbase.h:3457
-->>> above not for Linux
--  ) return HANDLE is
--  begin
--    return System.Null_Address;
--  end;
--<<< to compile for Linux >>>

  function CreateEvent
  ( ManualReset  : Boolean;
    InitialState : Boolean;
    Name         : System.Address
  ) return HANDLE is
    InitialS : BOOL;
    ManualR  : BOOL;
    function to_Ptr1 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => ExecItf.LPSECURITY_ATTRIBUTES );
    function to_Ptr2 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => ExecItf.LPCSTR );
  begin -- CreateEvent
    if ManualReset then
      ManualR := 1;
    else
      ManualR := 0;
    end if;
    if InitialState then
      InitialS := 1;
    else
      InitialS := 0;
    end if;
    return CreateEventWindows
           ( EventAttributes => null, --to_Ptr1(System.Null_Address),
             ManualReset     => ManualR,
             InitialState    => InitialS,
             Name            => to_Ptr2(Name) );
--to_Ptr2(System.Null_Address) );
  end CreateEvent;

--  function Pipe    -->> Linux
--  ( Handle : System.Address --File_Handle
--  ) return Integer;
----pragma Import( C, Pipe, "pipe" );
----needed for Linux
--  function Pipe
--  ( Handle : System.Address --File_Handle
--  ) return Integer is
--  begin -- Pipe
--    return -1;
--  end Pipe;
-- only to compile in Windows

--  function Thread_Lock_Init_Linux --> Linux
--  ( Lock : Thread_RWLock_Ptr_Type;
--    Attr : Thread_RWLock_Attr_Ptr_Type
--  ) return Interfaces.C.int;
----  pragma Import( C, Thread_Lock_Init_Linux, "pthread_rwlock_init" ); -- needed for Linux
--<<< not for Windows >>>
--  function Thread_Lock_Init_Linux --> to compile for Windows
--  ( Lock : Thread_RWLock_Ptr_Type;
--    Attr : Thread_RWLock_Attr_Ptr_Type
--  ) return Interfaces.C.int is
--  begin -- Thread_Lock_Init_Linux
--    return Interfaces.C.int(-1);
--  end Thread_Lock_Init_Linux;

--  function Thread_Lock_Linux --> Linux
--  ( Lock : Thread_RWLock_Ptr_Type
--  ) return Interfaces.C.int;
  -- Lock the thread read/write lock semaphore
----  pragma Import( C, Thread_Lock_Linux, "pthread_rwlock_wrlock" );
--<<< not for Windows >>>
--  function Thread_Lock_Linux --> to compile for Windows
--  ( Lock : Thread_RWLock_Ptr_Type
--  ) return Interfaces.C.int is
--  begin -- Thread_Lock_Linux
--    return Interfaces.C.int(-1);
--  end Thread_Lock_Linux;

--needed for Linux
--  function Thread_Lock_Init --> Linux
--  ( Lock : Thread_RWLock_Ptr_Type;
--    Attr : Thread_RWLock_Attr_Ptr_Type
--  ) return Interfaces.C.int is
--  begin
--    if Op_Sys = Linux then
----      return Thread_Lock_Init_Linux( Lock => Lock,
----                                     Attr => Attr );
--return Interfaces.C.int(-1);
--    else -- Windows
--      return Interfaces.C.int(-1);
--    end if;
--  end Thread_Lock_Init;

--needed for Linux
--  function Thread_Lock --> Linux
--  ( Lock : Thread_RWLock_Ptr_Type
--  ) return Interfaces.C.int is
--  begin
--    if Op_Sys = Linux then
      --      return Thread_Lock_Linux( Lock => Lock );
--      return Interfaces.C.int(-1);
--    else -- Windows
--      return Interfaces.C.int(-1);
--    end if;
--  end Thread_Lock;

--  function Thread_Unlock_Linux
--  ( Lock : Thread_RWLock_Ptr_Type
--  ) return Interfaces.C.int;
  -- Unlock the thread read/write lock semaphore
----  pragma Import( C, Thread_Unlock_Linux, "pthread_rwlock_unlock" );
---- above needed for Linux
--  function Thread_Unlock_Linux
--  ( Lock : Thread_RWLock_Ptr_Type
--  ) return Interfaces.C.int is
--  begin
--    return Interfaces.C.int(-1);
--  end Thread_Unlock_Linux;
-- above to compile in Windows

  function Thread_Unlock
  ( Lock : Thread_RWLock_Ptr_Type
  ) return Interfaces.C.int is
  begin
--    if Op_Sys = Linux then
--      return Thread_Unlock_Linux( Lock => Lock );
--    else -- Windows
      return Interfaces.C.int(-1);
--    end if;
  end Thread_Unlock;

  procedure Create_Event
  ( Name : in String; --Thread_Event_Name_Type; --LPCSTR;  --<<< change to string
    Id   : in out Integer;  --<<< change to string
    Addr : in System.Address --HANDLE
  ) is

  begin -- Create_Event

--    if Exec_Itf.Op_Sys = Exec_Itf.Linux then

--      declare
--        Result : Integer := -1;
--      begin
--        Result := Pipe( Addr );
--        if Result < 0 then
--  --      Events.Count := Events.Count - 1;
--          Id     := 0;
--  --      Handle := System.Null_Address; -- remains address at which windows handle would be put
--  --      Status   := Invalid_Param;
      --else
      --  Id leave unchanged
      --  Handle leave unchanged
  --      Status   := No_Error;
--        end if;
--      end;

--    else

      declare
        Result : HANDLE := System.Null_Address;
        for Result use at Addr;
        function to_Ptr is new Unchecked_Conversion( Source => System.Address,
                                                    Target => LPCSTR );
        use type System.Address;
      begin
        Result := CreateEventWindows
                  ( EventAttributes => null,
                    ManualReset     => TRUEint,
                    InitialState    => FALSEint,
                    Name            => to_Ptr(Name'address) );
         if Result = System.Null_Address then
          Id := 0;
        end if;
      end;

--    end if;

  end Create_Event;

  function ResetEventWindows                  -- winbase.h:1878
  ( Event : HANDLE
  ) return BOOL;
  pragma Import( Stdcall, ResetEventWindows, "ResetEvent" ); -- winbase.h:1878
--<<< not for Linux >>>

  function Reset_Event
  ( Event : HANDLE
  ) return Boolean is

    Result : BOOL := FALSEint;

  begin -- Reset_Event

--    if Op_Sys = Linux then
--      return False; -- no such function
--    else
      Result := ResetEventWindows( Event => Event );
      return Result /= FALSEint;
--    end if;

  end Reset_Event;

  function SetEvent                              -- winbase.h:1871
  ( Event : HANDLE
  ) return BOOL;
  pragma Import( Stdcall, SetEvent, "SetEvent" ); -- winbase.h:1871
--<<< not for Linux >>>

  function CreateWaitableTimer
  ( SecurityAttributes : LPSECURITY_ATTRIBUTES; -- pointer to security attributes
    ManualReset        : BOOL; -- TRUE if manual reset timer; otherwise synchronization
    TimerName          : LPCSTR -- pointer to null-terminated string name
  ) return HANDLE; -- Handle of the timer object or NULL if a failure
  pragma Import( Stdcall, CreateWaitableTimer, "CreateWaitableTimerA" ); -- winbase.h 1405

  function CreateWaitableTimer
  ( ManualReset : Boolean
  ) return HANDLE is
    ManualR : BOOL;
    function to_Ptr1 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => ExecItf.LPSECURITY_ATTRIBUTES );
    function to_Ptr2 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => ExecItf.LPCSTR );
  begin -- CreateWaitableTimer
    if ManualReset then
      ManualR := 1;
    else
      ManualR := 0;
    end if;
    return CreateWaitableTimer
           ( SecurityAttributes => to_Ptr1(System.Null_Address),
             ManualReset        => ManualR,
             TimerName          => to_Ptr2(System.Null_Address) );
  end CreateWaitableTimer;

--  function SetWaitableTimer
--  ( Timer                  : HANDLE; -- handle of timer object
--    DueTime                : LARGE_INTEGER; -- when timer will become signaled
--    Period                 : LONG; -- periodic timer interval in milliseconds
--    CompletionRoutine      : PTIMERAPCROUTINE; -- pointer to completion routine
--    ArgToCompletionRoutine : LPVOID; -- data passed to the completion routine
--    Resume                 : BOOL -- flag for resume state
--  ) return BOOL is -- non-zero if successful
--  begin -- SetWaitableTimer
--  end SetWaitableTimer;
  function SetWaitableTimer
  ( Timer                  : HANDLE; -- handle of timer object
    DueTime                : LARGE_INTEGER; -- when timer will become signaled
    Period                 : LONG; -- periodic timer interval in milliseconds
    CompletionRoutine      : PTIMERAPCROUTINE; -- pointer to completion routine
    ArgToCompletionRoutine : LPVOID; -- data passed to the completion routine
    Resume                 : BOOL -- flag for resume state
  ) return BOOL; -- non-zero if successful
  pragma Import( Stdcall, SetWaitableTimer, "SetWaitableTimer" ); -- winbase.h:2132

  function SetWaitableTimer
  ( Timer   : HANDLE;  -- handle of timer object
    DueTime : Integer; -- when timer will become signaled
    Period  : Integer; -- periodic timer interval in milliseconds
    Resume  : Boolean  -- flag for resume state
  ) return Boolean is  -- whether successful
    DT : LARGE_INTEGER;
    R  : BOOL;
    Rtrn : ExecItf.BOOL;
    function to_Ptr3 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => ExecItf.PTIMERAPCROUTINE );
    function to_Ptr4 is new Unchecked_Conversion
                            ( Source => System.Address,
                              Target => ExecItf.LPVOID );
  begin -- SetWaitableTimer
    if Resume then
      R := 1;
    else
      R := 0;
    end if;
    DT.HighPart := 0;
    DT.LowPart := Itf.Nat32(DueTime);
    Rtrn := SetWaitableTimer
            ( Timer                  => Timer,
              DueTime                => DT,
              Period                 => Interfaces.C.Long(Period),
              CompletionRoutine      => to_Ptr3(System.Null_Address),
              ArgToCompletionRoutine => to_Ptr4(System.Null_Address),
             Resume                 => R );
    if Rtrn = 0 then
      return False;
    else
      return True;
    end if;
  end SetWaitableTimer;

  function WaitForSingleObjectWindows                   -- winbase.h:1908
  ( ObjectHandle : HANDLE;
    Milliseconds : DWORD
  ) return DWORD;
--<<< not for Linux >>>
  pragma Import( Stdcall, WaitForSingleObjectWindows, "WaitForSingleObject" ); -- winbase.h:1908

--  function WaitForSingleObject                   -- winbase.h:1908
--  ( WaitHandle   : HANDLE;
--    Milliseconds : DWORD
--  ) return DWORD is
--  begin -- WaitForSingleObject
----    if Op_Sys = Linux then
----      return 0;
----    else
--      return WaitForSingleObjectWindows( ObjectHandle => WaitHandle,
--                                         Milliseconds => Milliseconds );
----    end if;
--  end WaitForSingleObject;
--  function WaitForSingleObject
--  ( WaitHandle   : HANDLE;
--    Milliseconds : DWORD
--  ) return DWORD;
  function WaitForSingleObject
  ( WaitHandle   : HANDLE;
    Milliseconds : Integer
  ) return WaitReturnType is
    Result : DWORD;
    MSec : DWORD;
    for MSec use at Milliseconds'Address;
  begin -- WaitForSingleObject
    Result := WaitForSingleObjectWindows( ObjectHandle => WaitHandle,
                                          Milliseconds => MSec );
    case Result is
      when 0 =>
        return WAIT_SIGNALED;
      when 16#00000080# =>
        return WAIT_ABANDONED;
      when 16#00000102# =>
        return WAIT_TIMEOUT;
      when 16#FFFFFFFF# =>
        return WAIT_FAILED;
      when others =>
        return Unknown_Failure;
    end case;
  end WaitForSingleObject;

  function WaitForSingleObjectEx
  ( WaitHandle   : HANDLE;
    Milliseconds : DWORD;
    Alertable    : BOOL
  ) return DWORD is
  begin -- WaitForSingleObjectEx
    return 0; -- not implemented
  end WaitForSingleObjectEx;

  procedure EnterCriticalSectionWindows                 -- winbase.h:1850
  ( CriticalSection : LPCRITICAL_SECTION );
--<<< not for Linux >>>
  pragma Import( Stdcall, EnterCriticalSectionWindows, "EnterCriticalSection" ); -- winbase.h:1850

  procedure EnterCriticalSection                 -- winbase.h:1850
  ( CriticalSection : LPCRITICAL_SECTION ) is
  begin -- EnterCriticalSection
--    if Op_Sys = Linux then
--    else
      EnterCriticalSectionWindows( CriticalSection => CriticalSection );
--    end if;
  end EnterCriticalSection;

  function Set_Event
  ( Event : HANDLE
  ) return Boolean is

  begin -- Set_Event

    if Op_Sys = Linux then
      declare
        Message
        -- One byte "message" to write to pipe
        : constant String(1..1) := ( others => 'e' );
        Written
        -- Number of bytes written
          : Integer := 0;
        function to_FH is new Unchecked_Conversion( Source => HANDLE,
                                                    Target => File_Handle );
      begin
          Written := Write_File               -- use write pipe
                     ( to_FH(Event), --(Send)),
                       Message(1..1) );
          return Written = 1;
      end;
    else
      declare
        Result : BOOL := TRUEint;
      begin
        Result := SetEvent( Event => Event );
--<<< can't use with Linux >>>
        return Result /= FALSEint;
      end;
    end if;

  end Set_Event;

--  function Wait_Event
--  ( Event_Id : in Event_Id_Type;
--    Time_Out : in Time_Interval_Type := Infinite_Time
--  ) return Boolean is

--  begin -- Wait_Event

--  end Wait_Event;

  ------------------------------------------------------------------------------
  -- Processes

  function Execute_Program
  ( Name : in String
    -- Program name to be executed
 --   Args : in ArgV_Type --GNAT.OS_Lib.Argument_List
    -- Argument list to be used
  ) return PId_t is
  -- ++
  -- Notes:
  --   GNAT s-os_lib.ads for the Spawn procedure has the following:
  --  This procedure spawns a program with a given list of arguments. The
  --  first parameter of is the name of the executable. The second parameter
  --  contains the arguments to be passed to this program. Success is False
  --  if the named program could not be spawned or its execution completed
  --  unsuccessfully. Note that the caller will be blocked until the
  --  execution of the spawned program is complete. For maximum portability,
  --  use a full path name for the Program_Name argument. On some systems
  --  (notably Unix systems) a simple file name may also work (if the
  --  executable can be located in the path).
  --
  --  Spawning processes from tasking programs is not recommended. See
  --  "NOTE: Spawn in tasking programs" below.
  --
  --  Note: Arguments in Args that contain spaces and/or quotes such as
  --  "--GCC=gcc -v" or "--GCC=""gcc -v""" are not portable across all
  --  operating systems, and would not have the desired effect if they were
  --  passed directly to the operating system. To avoid this problem, Spawn
  --  makes an internal call to Normalize_Arguments, which ensures that such
  --  arguments are modified in a manner that ensures that the desired effect
  --  is obtained on all operating systems. The caller may call
  --  Normalize_Arguments explicitly before the call (e.g. to print out the
  --  exact form of arguments passed to the operating system). In this case
  --  the guarantee a second call to Normalize_Arguments has no effect
  --  ensures that the internal call will not affect the result. Note that
  --  the implicit call to Normalize_Arguments may free and reallocate some
  --  of the individual arguments.
  --
  --  This function will always set Success to False under VxWorks and other
  --  similar operating systems which have no notion of the concept of
  --  dynamically executable file. Otherwise Success is set True if the exit
  --  status of the spawned process is zero.
  --
  --   Argument_List is a subtype of String_List.  String_List is in
  --   s-string.ads as
  --     type String_List is array (Positive range <>) of String_Access;
  --   where String_Access is
  --     type String_Access is access all String;
  -- --

    Arg  : GNAT.OS_Lib.Argument_List(1..1) := ( others => null );
    Arg1 : GNAT.OS_Lib.String_Access := new String(1..10);
    Id   : GNAT.OS_Lib.Process_Id;

    use type System.Address;

 --   function to_Access is new Unchecked_Conversion
 --                             ( Source => System.Address,
 --                               Target => GNAT.OS_Lib.String_Access );
 --   function to_Int is new Unchecked_Conversion
 --                          ( Source => System.Address,
 --                            Target => Integer );
    function to_PId is new Unchecked_Conversion
                           ( Source => GNAT.OS_Lib.Process_Id,
                             Target => PId_t );

  begin -- Execute_Program

    Arg1.all := ( others => ' ' ); -- empty argument
    Arg(1) := Arg1;
--    for I in 1..ArgV_Type'last loop
    --if Args(I) /= System.Null_Address then
--        Arg(I) := to_Access(Args(I));
    --else
    --  Arg(I) := ASCII.NUL;
--      exit when Args(I) = System.Null_Address;
--declare
--gx : string(1..50);
--J : integer;
--begin
--J := 1;
--while Args(I)
--      for K in N_Args'Range loop
--         N_Args (K) := new String'(Args (K).all);
--      end loop;

--end;
--    end loop;
-->>> could check that string pointed to by Arg is null terminated

    Id := GNAT.OS_Lib.Non_Blocking_Spawn( Program_Name => Name,
                                          Args         => Arg );
    return to_PId(Id);

  end Execute_Program;

  procedure ExitProcessWindows                          -- winbase.h:1500
  ( ExitCode : UINT );
--<<< not for Linux >>>
  pragma Import( Stdcall, ExitProcessWindows, "ExitProcess" ); -- winbase.h:1500

  procedure ExitProcess                          -- winbase.h:1500
  ( ExitCode : UINT
  ) is
  begin -- ExitProcess
--    if Op_Sys = Linux then
--      null;
--    else
      ExitProcessWindows( ExitCode => ExitCode );
--    end if;
  end ExitProcess;

  function GetExitCodeProcessWindows                    -- winbase.h:1515
  ( Process  : HANDLE;
    ExitCode : LPDWORD
  ) return BOOL;
--<<< not for Linux >>>
  pragma Import( Stdcall, GetExitCodeProcessWindows, "GetExitCodeProcess" ); -- winbase.h:1515

  function GetExitCodeProcess                    -- winbase.h:1515
  ( Process  : HANDLE;
    ExitCode : LPDWORD
  ) return BOOL is
  begin -- GetExitCodeProcess
--    if Op_Sys = Linux then
--      return Falseint;
--    else
      return GetExitCodeProcessWindows( Process  => Process,
                                        ExitCode => ExitCode );
--    end if;
  end GetExitCodeProcess;

  function GetExitCodeThreadWindows                     -- winbase.h:1686
  ( Thread   : HANDLE;
    ExitCode : LPDWORD
  ) return BOOL;
--<<< not for Linux >>>
  pragma Import( Stdcall, GetExitCodeThreadWindows, "GetExitCodeThread" ); -- winbase.h:1686

  function GetExitCodeThread                     -- winbase.h:1686
  ( Thread   : HANDLE;
    ExitCode : LPDWORD
  ) return BOOL is
  begin -- GetExitCodeThread
--    if Op_Sys = Linux then
--      return Falseint;
--    else
      return GetExitCodeThreadWindows( Thread   => Thread,
                                       ExitCode => ExitCode );
--    end if;
  end GetExitCodeThread;

  function GetCurrentProcessWindows                     -- winbase.h:1486
  return HANDLE;
  pragma Import( Stdcall, GetCurrentProcessWindows, "GetCurrentProcess" ); -- winbase.h:1486
--<<< not for Linux >>>

  function GetCurrentProcess                     -- winbase.h:1486
  return HANDLE is
  begin -- GetCurrentProcess
--    if Op_Sys = Linux then
--      return System.Null_Address;
--    else
      return GetCurrentProcessWindows;
--    end if;
  end GetCurrentProcess;

  function GetCurrentProcessIdWindows                   -- winbase.h:1493
  return DWORD;
  pragma Import( Stdcall, GetCurrentProcessIdWindows, "GetCurrentProcessId" ); -- winbase.h:1493
--<<< not for Linux >>>
--  function GetCurrentProcessIdWindows                   -- winbase.h:1493
--  return DWORD is
--    use type DWORD;
--  begin
--    return -1;
--  end;

  function GetCurrentProcessId                   -- winbase.h:1493
  return DWORD is
    use type DWORD;
  begin -- GetCurrentProcessId
--    if Op_Sys = Linux then
--      return -1;
--    else
      return GetCurrentProcessIdWindows;
--    end if;
  end GetCurrentProcessId;

  function GetProcessShutdownParametersWindows
  ( Level : in LPDWORD;
    Flags : in LPDWord
  ) return Bool;
--<<< not for Linux >>>
  pragma Import( Stdcall, GetProcessShutdownParametersWindows, -- winbase.h:3748
                         "GetProcessShutdownParameters" );

  function GetProcessShutdownParameters
  ( Level : in LPDWORD;
    Flags : in LPDWord
  ) return Bool is
  begin -- GetProcessShutdownParameters
--   if Op_Sys = Linux then
--      return Falseint;
--    else
      return GetProcessShutdownParametersWindows( Level => Level,
                                                  Flags => Flags );
--    end if;
  end GetProcessShutdownParameters;

--  function Is_Running  -- for Linux
--  ( Path : String
    -- Full path of executable
--  ) return Boolean is

--    Dir_Entity
    -- Pointer to process directory entity
--    : Dir_Entity_Ptr_Type := null;

--    Dir_Proc
    -- Pointer to process directory
--    : System.Address := System.Null_Address;

--    Lookup_Name
    -- Process id for /proc lookup
--    : String(1..50);

--    Name_Len
    -- Number of characters in name
--    : Integer;

--    Proc_Directory
    -- Null-terminated name of directory containing running processes
--    : String(1..10) := ( others => ASCII.NUL );

--    Running_Process
    -- Path of running process
--    : String(1..256);

--    use type String_Tools.Comparison_Type;
--    use type System.Address;

--  begin -- Is_Running

    -- Logic_Step:
    --   Open the /proc directory.

--    Proc_Directory(1..6) := "/proc/"; -- nul terminated
--    Dir_Proc := OpenDir( File_Name => Proc_Directory );
--    if Dir_Proc = System.Null_Address then
--      return False;
--    end if;

    -- Logic_Step:
    --   Search through the processes looking for the one with the
    --   specified path and executable name.

--    loop

      -- Read next item
--      Dir_Entity := ReadDir(Dir_Proc);
--      exit when Dir_Entity = null;

      -- Form lookup name
--      Name_Len := 0;
--      for I in 1..Dir_Entity.d_name'length loop
--        exit when Dir_Entity.d_name(I) = ASCII.NUL; -- trailing NUL
--        Name_Len := I; -- set length of name to last non-NUL character
--      end loop;
--      if Name_Len > 0 then
--        Lookup_Name(1..6) := "/proc/";
--        Lookup_Name(7..6+Name_Len) := Dir_Entity.d_name(1..Name_Len);
--        Lookup_Name(7+Name_Len..10+Name_Len) := "/exe";
--        Lookup_Name(11+Name_Len) := ASCII.NUL; -- trailing NUL
----declare
----name_len1 : Integer := Name_Len;
----begin

        -- Get path
--        Name_Len := ReadLink( Lookup_Name'address,
--                              Running_Process'address,
--                              Running_Process'length );

----Dir_Entity.d_name(1..Name_Len1));
----end;
        -- Compare path of running executable with that input
--        if Name_Len = Path'length and then
--           String_Tools.Blind_Compare
--           ( Left  => Running_Process(1..Name_Len),
--             Right => Path ) = String_Tools.Equal
--        then
--          return True; -- process is running
--        end if;
--      end if; -- Name_Len > 0

--    end loop;

--    return False; -- Path not found in running processes

--  end Is_Running;


--  function App_Running
--  ( Application : in Interfaces.C.Strings.Chars_Ptr
--  ) return Interfaces.C.char;
--  pragma Import(C, App_Running, "appRunningC");
--<<< not for Linux >>>

  function Is_Running_Linux
  ( Path : String
    -- Full path of executable
  ) return Boolean is

    Dir_Entity
    -- Pointer to process directory entity
    : Dir_Entity_Ptr_Type := null;

    Dir_Proc
    -- Pointer to process directory
    : System.Address := System.Null_Address;

    Lookup_Name
    -- Process id for /proc lookup
    : String(1..50);

    Name_Len
    -- Number of characters in name
    : Integer;

    Proc_Directory
    -- Null-terminated name of directory containing running processes
    : String(1..10) := ( others => ASCII.NUL );

    Running_Process
    -- Path of running process
    : String(1..256);

 --   use type String_Tools.Comparison_Type;
    use type System.Address;

  begin -- Is_Running_Linux

    -- Logic_Step:
    --   Open the /proc directory.

    Proc_Directory(1..6) := "/proc/"; -- nul terminated
    Dir_Proc := OpenDir( File_Name => Proc_Directory );
    if Dir_Proc = System.Null_Address then
      return False;
    end if;

    -- Logic_Step:
    --   Search through the processes looking for the one with the
    --   specified path and executable name.

    loop

      -- Read next item
      Dir_Entity := ReadDir(Dir_Proc);
      exit when Dir_Entity = null;

      -- Form lookup name
      Name_Len := 0;
      for I in 1..Dir_Entity.d_name'length loop
        exit when Dir_Entity.d_name(I) = ASCII.NUL; -- trailing NUL
        Name_Len := I; -- set length of name to last non-NUL character
      end loop;
      if Name_Len > 0 then
        Lookup_Name(1..6) := "/proc/";
        Lookup_Name(7..6+Name_Len) := Dir_Entity.d_name(1..Name_Len);
        Lookup_Name(7+Name_Len..10+Name_Len) := "/exe";
        Lookup_Name(11+Name_Len) := ASCII.NUL; -- trailing NUL
--declare
--name_len1 : Integer := Name_Len;
--begin

        -- Get path
        Name_Len := ReadLink( Lookup_Name'address,
                              Running_Process'address,
                              Running_Process'length );

--Dir_Entity.d_name(1..Name_Len1));
--end;
-- Compare path of running executable with that input
        declare
          Match : Integer;
          CPath : String(1..Path'length+1);
          CRunning : String(1..Name_Len+1);
        begin
        if Name_Len = Path'length then --and then
 --          String_Tools.Blind_Compare
 --          ( Left  => Running_Process(1..Name_Len),
 --            Right => Path ) = String_Tools.Equal
          CPath(1..Path'length) := Path;
          CPath(Path'length+1) := ASCII.NUL;
          CRunning := Running_Process(1..Name_Len);
          CRunning(Name_Len+1) := ASCII.NUL;
          Match := CStrings.Compare(CPath'Address,CRunning'Address,True);
          if Match = 0 then
     --   then
            return True; -- process is running
          end if;
        end if;
        end;
      end if; -- Name_Len > 0

    end loop;

    return False; -- Path not found in running processes

  end Is_Running_Linux;

  function Is_Running_Windows
  ( Path : String
  ) return Boolean is

    function to_Byte is new Unchecked_Conversion
                            ( Source => Interfaces.C.char,
                              Target => Itf.Byte ); --Machine.Unsigned_Byte );
    function to_Char is new Unchecked_Conversion
                            ( Source => Itf.Byte, --Machine.Unsigned_Byte,
                              Target => Interfaces.C.char );

    Result
    : Interfaces.C.char := to_Char(16#0#);

    use type Itf.Byte; --Machine.Unsigned_Byte;

    function to_Ptr is new Unchecked_Conversion
                           ( Source => System.Address,
                             Target => Interfaces.C.Strings.Chars_Ptr );

  begin -- Is_Running_Windows

--    Result := App_Running( Application => to_Ptr(Path'address) );
-- <<< not for Linux >>>

--    return to_Byte(Result) = 16#01#;
    return True; --<<< everything is Windows for this >>>
-- <<< why "appRunningC" not found? My own EP routine? >>>

  end Is_Running_Windows;

  function Is_Running
  ( Path : String
  ) return Boolean is

  begin -- Is_Running

    if Op_Sys = Linux then
      return Is_Running_Linux( Path => Path );
    else
      return Is_Running_Windows( Path => Path );
    end if;

  end Is_Running;

  function GetPriorityClassWindows                      -- winbase.h:6260
  ( Process : HANDLE
  ) return DWORD;
--<<<< not for Linux >>>>
  pragma Import( Stdcall, GetPriorityClassWindows,      -- winbase.h:6260
                         "GetPriorityClass");

  function GetPriorityClass                      -- winbase.h:6260
  ( Process : HANDLE
  ) return DWORD is
  begin -- GetPriorityClass
--    if Op_Sys = Linux then
--      return 0;
--    else
      return GetPriorityClassWindows( Process => Process );
--    end if;
  end GetPriorityClass;

  function SetPriorityClassWindows                      -- winbase.h:6252
  ( Process       : HANDLE;
    PriorityClass : DWORD
  ) return BOOL;
--<<< can't be used for Linux >>>
  pragma Import( Stdcall, SetPriorityClassWindows, "SetPriorityClass" ); -- winbase.h:6252

  function SetPriorityClass                      -- winbase.h:6252
  ( Process       : HANDLE;
    PriorityClass : DWORD
  ) return BOOL is
  begin -- SetPriorityClass
--    if Op_Sys = Linux then
--      return FALSEint;
--    else
      return SetPriorityClassWindows( Process       => Process,
                                      PriorityClass => PriorityClass );
--    end if;
  end SetPriorityClass;

  ------------------------------------------------------------------------------
  -- Threads

  type PThread_t is new Interfaces.C.Unsigned_Long; -- unsigned long int --Machine.Unsigned_Longword;
--<<<< need to be pointer?? >>>

  function Unsigned_Long_to_Int
  ( Source : in Interfaces.C.Unsigned_Long
  ) return Integer_Pair_Type is

    type Pair_Type
    is record
      Two : Itf.Word; --Machine.Unsigned_Word; -- to order for correct endian
      One : Itf.Word; --Machine.Unsigned_Word;
    end record;

    Temp1 : Pair_Type;
    for Temp1 use at Source'address;

    Temp2 : Integer_Pair_Type;

  begin -- Unsigned_Long_to_Int

    Temp2(1) := Integer(Temp1.One);
    Temp2(2) := Integer(Temp1.Two);

    return Temp2;

  end Unsigned_Long_to_Int;

--  function PThread_Attr_Init -- for Linux
--  ( Attributes : access PThread_Attr_t
--  ) return Interfaces.C.int;
  -- Return attribute structure with default attribute values
----  pragma Import(C, PThread_Attr_Init, "pthread_attr_init");
---- above needed for Linux
---- below to compile for Windows
--  function PThread_Attr_Init -- to compile for Windows
--  ( Attributes : access PThread_Attr_t
--  ) return Interfaces.C.int is
--  begin
--    return Interfaces.C.int(-1);
 -- end;

  function PThread_Attr_SetStacksize
  ( Attributes : access PThread_Attr_t;
    Stack_Size : Natural
  ) return Interfaces.C.int;
  -- Set stack size into thread attributes
--  pragma Import(C, PThread_Attr_SetStacksize, "pthread_attr_setstacksize");
-- above needed for Linux
-- below to compile for Windows
  function PThread_Attr_SetStacksize
  ( Attributes : access PThread_Attr_t;
    Stack_Size : Natural
  ) return Interfaces.C.int is
  begin
    return Interfaces.C.int(-1);
  end;

--  function PThread_Create
--  ( Thread_Id  : in System.Address; -- location for thread id
--    Attributes : in System.Address; -- location of thread attributes to use
--    Start      : in System.Address; -- pointer to start address for thread
--    Arg        : in System.Address  -- location of arguments for Start
--  ) return Interfaces.C.int;
  -- Create a thread and return its identifier at Thread_Id.  The return
  -- value is whether the create was successful (0) or an error number of
  --  EAGAIN Insufficient resources to create another thread, or a
  --         system-imposed limit on the number of threads was encountered.
  --         The latter case may occur in two ways: the RLIMIT_NPROC soft
  --         resource limit (set via setrlimit(2)), which limits the number
  --         of process for a real user ID, was reached; or the kernel's
  --         system-wide limit on the number of threads,
  --         /proc/sys/kernel/threads-max, was reached.
  --  EINVAL Invalid settings in attr.
  --  EPERM  No permission to set the scheduling policy and parameters
  --         specified in attr.
  --
  -- Notes:
  --   This Create_Thread uses the C pthread_create.  It returns the thread
  --   id that the other C functions use.  It also results in the Arg
  --   address being the same when the thread starts as that supplied to
  --   Create.
--> Need to find out the format of Attributes to know how to pass stack size, etc.
--> pthread_attr_t
-->          /* Initialize thread creation attributes */
-->           s = pthread_attr_init(&attr);
-->           if (s != 0)
-->               handle_error_en(s, "pthread_attr_init");
-->           if (stack_size > 0) {
-->               s = pthread_attr_setstacksize(&attr, stack_size);
-->               if (s != 0)
-->                   handle_error_en(s, "pthread_attr_setstacksize");
-->           }
--  pragma Import(C, PThread_Create, "pthread_create");
-- needed for Linux
--  function PThread_Create
--  ( Thread_Id  : in System.Address; -- location for thread id
--    Attributes : in System.Address; -- location of thread attributes to use
--    Start      : in System.Address; -- pointer to start address for thread
--    Arg        : in System.Address  -- location of arguments for Start
--  ) return Interfaces.C.int is
--  begin -- PThread_Create
--    return Interfaces.C.int(-1);
--  end PThread_Create;
-- needed to compile for Windows

-- for Linux
--  procedure Create_Thread_Linux
--  (-- Attributes : in PThread_Attr_t;
--    Stack_Size    : in Integer;
--    Start         : in System.Address;
----    Parameters : in System.Address;
----    Thread_Id  : in System.Address
--    Thread_Number : in  Integer;
--    Thread_Id     : out Integer;
--    Success       : out Boolean
--  ) is --return Boolean is

--    Attributes
--    : PThread_Attr_t;

--    type Attributes_Ptr_Type is access PThread_Attr_t;
--    function to_Attr_Ptr is new Unchecked_Conversion
--                                ( Source => System.Address,
--                                  Target => Attributes_Ptr_Type );
--    Attributes_Ptr : Attributes_Ptr_Type := to_Attr_Ptr(Attributes'address);

--    Result
--    : Interfaces.C.int;

--    StackSize
--    : Integer := Stack_Size;

--    type Dummy_Type is array(1..10) of Integer;

--    type Thread_Info_Type
--    is record
--      Thread_Id : PThread_t;      -- Identifier returned by pthread_create
--      Argv      : System.Address; -- pointer to command-line argument
--      Spare     : Dummy_Type;     -- be sure reserve enough space
--    end record;

--    Thread_Info
--    : Thread_Info_Type;
--    pragma Volatile(Thread_Info);

--    use type Interfaces.C.int;

--  begin -- Create_Thread_Linux

--    Result := PThread_Attr_Init( Attributes => Attributes_Ptr );
--    if StackSize <= 0 then
--      StackSize := 16384;
--    end if;
--    Result := PThread_Attr_SetStacksize( Attributes_Ptr,
--                                         StackSize );
--    Exec_Itf.Log_Error;

 ----   Result := Thread_Create
 ----             ( Thread_Id  => Thread_Id,    -- location for thread id
 ----               Attributes => Attributes'address, -- location of thread attributes to use
 ----               Start      => Start,        -- pointer to start address
 ----               Arg        => Parameters ); -- parameters
    -- Notes:
    --   Parameters needs to be of the form
    --    Parameters.thread_num where thread number starts at 1 and increases for each thread
    --    Parameters.argv_string = argv[optind + tnum] where tnum is one less than thread_num

 ----   Thread_Info.Thread_Id  := 0;
 ----   Thread_Info.Thread_Num := Thread_Number;
--    Thread_Info.Thread_Id  := PThread_t(Thread_Number);
--    Thread_Info.Argv       := System.Null_Address;
--    Result := PThread_Create
--              ( Thread_Id  => Thread_Number'address, --Thread_Info.Thread_Id'address,  -- &tinfo[tnum].thread_id, &attr,
--                Attributes => Attributes'address,
--                Start      => Start,     -- &thread_start, &tinfo[tnum]);
--                Arg        => Thread_Info'address ); --Parameters );
----declare
----  CTId1 : Integer_Pair_Type;
----  CTId2 : Integer_Pair_Type;
----begin
------CTId1 := unsigned_long_to_int(Interfaces.C.unsigned_long(thread_number));
----CTId2 := unsigned_long_to_int(Interfaces.C.unsigned_long(Thread_Info.Thread_Id));
----null;
----end;

--    if Result = 0 then
--      Thread_Id := Integer(Thread_Info.Thread_Id);
--      Success := True;
--    else
--      Thread_Id := -1;
--      Success := False;
--    end if;

    -- Logic_Step:
    --   Return true if thread created.

----    return Result = 0;

--  end Create_Thread_Linux;

-- for Linux
--  function Create_Thread
--  (-- Attributes : in PThread_Attr_t;
--    Stack_Size : in Integer;
--    Start      : in System.Address;
--    Parameters : in System.Address;
--    Thread_Id  : in System.Address
--  ) return Boolean is

--    Attributes
--    : PThread_Attr_t;

--    type Attributes_Ptr_Type is access PThread_Attr_t;
--    function to_Attr_Ptr is new Unchecked_Conversion
--                                ( Source => System.Address,
--                                  Target => Attributes_Ptr_Type );
--    Attributes_Ptr : Attributes_Ptr_Type := to_Attr_Ptr(Attributes'address);

--    Result
--    : Interfaces.C.int;

--    use type Interfaces.C.int;

--  begin -- Create_Thread

--    Result := PThread_Attr_Init( Attributes => Attributes_Ptr );

--    if Stack_Size > 0 then
--      Result := PThread_Attr_SetStacksize( Attributes_Ptr,
--                                           Stack_Size );
--      Exec_Itf.Log_Error;
--    end if;

--    Result := Thread_Create
--              ( Thread_Id  => Thread_Id,    -- location for thread id
--                Attributes => Attributes'address, -- location of thread attributes to use
--                Start      => Start,        -- pointer to start address
--                Arg        => Parameters ); -- parameters

    -- Logic_Step:
    --   Return true if thread created.

--    return Result = 0;

--  end Create_Thread;
--<<< above not for Windows >>>

--  procedure Create_Thread
--  ( Start      : in System.Address;          -- pointer
--    Parameters : in Void_Ptr;                -- pointer
--    Stack_Size : in Natural;                 -- int
--    Priority   : in Integer;                 -- int
--    Handle     : out HANDLE;                 -- if running Windows
--    TId        : out Exec_Itf.Thread_Id_Type -- if running Linux
--  ) is -- return HANDLE is
  function Create_Thread
  ( Start      : in System.Address;          -- pointer
    Parameters : in Void_Ptr;                -- pointer
    Stack_Size : in Natural;                 -- int
    Priority   : in Integer                  -- int
  ) return HANDLE is

--    Thread_Id
    -- Address of the thread id as returned by GNAT
--    : System.Address;
--    Handle
--    : Thread_Handle;
--    for Handle use at Thread_Id;
--<<< what to do for this?  The value to be returned is located at the address>>>

  begin -- Create_Thread

--    if Op_Sys = Linux then

--      declare

--        Thread_Created
--        -- True if thread was created successfully
--        : Boolean;

--  --      TId
--  --      -- Thread identifier
--  --      : Exec_Itf.Thread_Id_Type; --Thread_Id_Type;
--  --      pragma Volatile( TId );

--      begin
--        Thread_Created := Exec_Itf.Create_Thread
--                          ( Stack_Size => Stack_Size,
--                            Start      => Start,
--                            Parameters => Parameters,
--                            Thread_Id  => TId'address );
--        if not Thread_Created then
--          TId := -1;
--        end if;
--        Handle := Null_Thread_Handle;
--      end;

--    else

--      TId := -1;
      return GNAT.Threads.Create_Thread
             ( Code => Start,
               Parm => GNAT.Threads.Void_Ptr(Parameters),
               Size => Stack_Size,
               Prio => Priority );
--HANDLE    return Handle;

--    end if;

  end Create_Thread;

  procedure Create_Thread
  ( Start           : System.Address;     -- pointer to start address of thread
    Parameter       : System.Address; --Void_Ptr;           -- pointer to parameters
    Stack_Size      : Natural;            -- stack size in bytes
    Thread_Priority : Integer;            -- priority for thread
    Thread_Handle   : out Thread_Handle_Type
  ) is
  -- Notes:
  --   This procedure does not return a Thread_Id that matches that of
  --   GetCurrentThreadId.

 --   type Thread_Id_Ptr_Type is access Thread_Id_Type;
 --   function to_Ptr is new Unchecked_Conversion
 --                          ( Source => System.Address,
 --                            Target => Thread_Id_Ptr_Type );

    Thread_Ident : System.Address;

 --   Thread_Id_Ptr : Thread_Id_Ptr_Type; --:= to_Ptr(Thread_Ident);

    function to_Id is new Unchecked_Conversion
                          ( Source => System.Address,
                            Target => Thread_Handle_Type );

 function to_Int is new Unchecked_Conversion
                        ( Source => System.Address,
                          Target => Integer );

 function to_Ptr is new Unchecked_Conversion
                        ( Source => System.Address,--Void_Ptr,
                          Target => GNAT.Threads.Void_Ptr );--Remote.Parameters_Ptr_Type );

 --function to_Int2 is new Unchecked_Conversion
 --                       ( Source => Thread_Id_Type,
 --                         Target => Integer );

  begin -- Create_Thread

    Thread_Ident := GNAT.Threads.Create_Thread
                    ( Code => Start,
                      Parm => to_Ptr(Parameter), --GNAT.Threads.Void_Ptr(Parameter),
                      Size => Stack_Size,
                      Prio => Thread_Priority );
    Thread_Handle := to_Id(Thread_Ident);
--   Thread_Id_Ptr := to_Ptr(Thread_Ident);
--   Thread_Id := Thread_Id_Ptr.all;

--to_Int(Thread_Ident'address));

  end Create_Thread;



  procedure Destroy_Thread
  ( Thread_Handle : Thread_Handle_Type
  ) is

    function to_Addr is new Unchecked_Conversion
                            ( Source => Thread_Handle_Type,
                              Target => System.Address );

  begin -- Destroy_Thread

    GNAT.Threads.Destroy_Thread( to_Addr(Thread_Handle) );

  end Destroy_Thread;

  function PThread_Self --GetCurrentThreadIdLinux
  return Thread_Id_Type; --pThread_t;
  -- This function gets the system identifier of the currently running thread.
--  pragma Import (C, PThread_Self, "pthread_self");
  --<<< above pragma necessary for Linux >>>
  function PThread_Self --<<< this is just to compile for Windows >>>
  return Thread_Id_Type is
  begin
    return 0;
  end PThread_Self;

--<< Windows version >>
  function GetCurrentThreadIdWindows             -- winbase.h:1630
  return DWORD;
  pragma Import( Stdcall, GetCurrentThreadIdWindows, "GetCurrentThreadId" );   -- winbase.h:1630
--<<< not for Linux >>>

  function GetCurrentThreadId
  return Thread_Id_Type is

    use type Interfaces.C.unsigned_long;
    Thread_Id : DWORD := -1;
    T_Id : Thread_Id_Type;

  begin -- GetCurrentThreadId

--    if Op_Sys = Linux then
-- --     return PThread_Self; --GetCurrentThreadIdLinux;
--      T_Id := PThread_Self;
--declare
--  CTId : Integer_Pair_Type;
--begin
--CTId := unsigned_long_to_int(Interfaces.C.unsigned_long(T_Id));
--end;
--      return T_Id;
--    else
      Thread_Id := GetCurrentThreadIdWindows;
      return Thread_Id_Type(Thread_Id);
--    end if;

  end GetCurrentThreadId;

  function GetCurrentThreadWindows                      -- winbase.h:1623
  return HANDLE;
  pragma Import( Stdcall, GetCurrentThreadWindows, "GetCurrentThread" ); -- winbase.h:1623
--<<< only for Windows >>>

  function GetCurrentThread                      -- winbase.h:1623
  return HANDLE is
  begin -- GetCurrentThread
--    if Op_Sys = Linux then
--      return System.Null_Address;
--    else
      return GetCurrentThreadWindows;
--    end if;
  end GetCurrentThread;

  procedure Get_Thread -- get thread identifier from handle
  ( Thread_Handle : in HANDLE;
    Thread_Id     : out PId_t
  ) is
--                             : System.Address;

    Id_Addr : System.Address;-- := System.Null_Address;
    pragma Volatile(Id_Addr);
    Id : PId_t;
    for Id use at Id_Addr;
    pragma Volatile(Id);

--function to_int is new unchecked_conversion( Source => System.Address, Target => Integer );
function to_int is new unchecked_conversion( Source => PId_t, Target => Integer );
 --   function to_PId is new unchecked_conversion( Source => System.Address, Target => PId_t );
    function TH_to_Int is new Unchecked_Conversion
                            ( Source => Handle,
                              Target => Integer );

  begin -- Get_Thread

    GNAT.Threads.Get_Thread( Id     => Thread_Handle,
                             Thread => Id_Addr );
-->>> what's in Id?  What's at the address it points to?
    Thread_Id := Id; --to_PId(Id); --<<< FIX >>>

  end Get_Thread;

  procedure Get_Thread
  ( Thread_Handle : in Thread_Handle_Type;
    Thread_Id     : out Thread_Id_Type
  ) is

--  Ident : Thread_Id_Type;

    function TH_to_Addr is new Unchecked_Conversion
                            ( Source => Thread_Handle_Type,
                              Target => System.Address );
    function TH_to_Int is new Unchecked_Conversion
                            ( Source => Thread_Handle_Type,
                              Target => Integer );
    function TId_to_Int is new Unchecked_Conversion
                            ( Source => Thread_Id_Type,
                              Target => Integer );
 --   function to_Addr is new Unchecked_Conversion
 --                           ( Source => Thread_Id_Type,
 --                             Target => System.Address );
  begin

    GNAT.Threads.Get_Thread( Id     => TH_To_Addr(Thread_Handle), --'address,
                             Thread => Thread_Id'address ); --to_Addr(Ident)

  end Get_Thread;

  function GetThreadPriorityWindows                     -- winbase.h:1653
  ( Thread : HANDLE
  ) return INT;
--<<< not for Linux >>>
  pragma Import( Stdcall, GetThreadPriorityWindows, "GetThreadPriority" ); -- winbase.h:1653

  function GetThreadPriority                     -- winbase.h:1653
  ( Thread : HANDLE
  ) return INT is
  begin -- GetThreadPriority
--    if Op_Sys = Linux then
--      return 0;
--    else
      return GetThreadPriorityWindows( Thread => Thread );
--    end if;
  end GetThreadPriority;

  function SetThreadPriorityWindows                     -- winbase.h:1645
  ( Thread   : HANDLE;
    Priority : INT
  ) return BOOL;
  pragma Import( Stdcall, SetThreadPriorityWindows, "SetThreadPriority" ); -- winbase.h:1645
--<<< not for Linux >>>

  function SetThreadPriority
  ( Thread   : HANDLE;
    Priority : INT
  ) return Boolean is

    Result : BOOL := FALSEint;

  begin -- SetThreadPriority

--    if Op_Sys = Windows then
      Result := SetThreadPriorityWindows( Thread   => Thread,
                                          Priority => Priority );
--<<< can't use with Linux >>>
      return Result /= FALSEint;
--    else
--      return False; -- not for Linux
--    end if;

  end SetThreadPriority;

  function TerminateThreadWindows                       -- winbase.h:1678
  ( Thread   : HANDLE;
    ExitCode : DWORD
  ) return BOOL;
  pragma Import( Stdcall, TerminateThreadWindows, "TerminateThread" ); -- winbase.h:1678
--<<< not for Linux >>>

  function TerminateThread                       -- winbase.h:1678
  ( Thread   : HANDLE;
    ExitCode : DWORD
  ) return BOOL is
  begin -- TerminateThread
--    if Op_Sys = Linux then
--      return FALSEint;
--    else
      return TerminateThreadWindows( Thread   => Thread,
                                     ExitCode => ExitCode );
--    end if;
  end TerminateThread;

  function To_Task_Id
  ( Thread_Handle : in Thread_Handle_Type
  ) return Ada.Task_Identification.Task_Id is
  begin -- To_Task_Id

    return GNAT.Threads.To_Task_Id( Thread_Handle'address );

  end To_Task_Id;

  ------------------------------------------------------------------------------
  -- Time

  function Current_Time
  return OS_Time is
  --  Return the system clock value as OS_Time
  begin -- Current_Time
    return GNAT.OS_Lib.Current_Time;
  end Current_Time;

  procedure GetLocalTimeWindows                         -- winbase.h:2627
  ( SystemTime : LPSYSTEMTIME
  );
--<<< not usable for Linux >>>
  pragma Import( Stdcall, GetLocalTimeWindows, "GetLocalTime" ); -- winbase.h:2627
  procedure GetLocalTime                         -- winbase.h:2627
  ( SystemTime : LPSYSTEMTIME
  ) is
  begin
--    if Op_Sys = Linux then
--      null;
--    else
      GetLocalTimeWindows( SystemTime => SystemTime );
--    end if;
  end;

  procedure GM_Split
  ( Date     : OS_Time;
    Year     : out Year_Type;
    Month    : out Month_Type;
    Day      : out Day_Type;
    Hour     : out Hour_Type;
    Minute   : out Minute_Type;
    Second   : out Second_Type;
    Millisec : out Millisec_Type
  ) is
  begin -- GM_Split
    GNAT.OS_Lib.GM_Split
    ( Date   => Date,
      Year   => Year,
      Month  => Month,
      Day    => Day,
      Hour   => Hour,
      Minute => Minute,
      Second => Second );
    Millisec := 0;
  end GM_Split;

  function System_Time
  ( Time : OS_Time
    -- System clock value
  ) return System_Time_Type is --Split_Time_Type is
  -- Return system clock value as a record.

    Year     : Year_Type;
    Month    : Month_Type;
    Day      : Day_Type;
    Hour     : Hour_Type;
    Minute   : Minute_Type;
    Second   : Second_Type;
    Millisec : Millisec_Type;

    Tm : System_Time_Type; --Split_Time_Type;

  begin -- System_Time

    GM_Split( Date     => Time,
              Year     => Year,
              Month    => Month,
              Day      => Day,
              Hour     => Hour,
              Minute   => Minute,
              Second   => Second,
              Millisec => Millisec );

    Tm := ( Year     => Year,
            Month    => Month,
            Day      => Day,
            Hour     => Hour,
            Minute   => Minute,
            Second   => Second,
            Millisec => Millisec );
    return Tm;

  end System_Time;

  function SystemTime
  return System_Time_Type is

    Time : OS_Time;

  begin -- SystemTime

    Time := Current_Time;
    return System_Time( Time );

  end SystemTime;

  function File_Time_Stamp
  ( Name : String
  ) return OS_Time is
  --  Given the name of a file or directory, Name, obtains and returns the
  --  time stamp. This function can be used for an unopened file. Returns
  --  Invalid_Time is Name doesn't correspond to an existing file.
  begin -- File_Time_Stamp
    return GNAT.OS_Lib.File_Time_Stamp( Name => Name );
  end File_Time_Stamp;

  function File_Time_Stamp
  ( Handle : File_Handle
  ) return OS_Time is
  begin -- File_Time_Stamp
    return GNAT.OS_Lib.File_Time_Stamp( Handle_to_File_Descriptor(Handle) );
  end File_Time_Stamp;

--  procedure Display_Last_WSA_Error is separate;
procedure Display_Last_WSA_Error is
-- Get last error and display it along with the system text for it.

  package Int_IO is new Text_IO.Integer_IO( Integer );

  Last_Error
  -- Error code returned by LastError
  : INT; --Integer;

    use type Interfaces.C.int;

begin -- Display_Last_WSA_Error

  Last_Error := WSAGetLastError; --GetLastError;

--  Text(1).Item := Console.Int;
--  Text(1).Value := ( Count => 5, Value => Integer(Last_Error) );
--  Text(2).Item := Console.Done;

  Text_IO.Put( "ERROR: WSALastError");
  Int_IO.Put( Integer(Last_Error) );
  Text_IO.Put_Line(" ");

  if Last_Error = 10053 then
    Text_IO.Put_Line("Check that Anti-Virus / Firewall not blocking application");
    raise Program_Error;
  end if;

  end Display_Last_WSA_Error;

end ExecItf;
