
with Ada.Finalization;
with Ada.Task_Identification;
with GNAT.OS_Lib;
with GNAT.Sockets.Linker_Options; -- needed to link via GNAT to its libwsock32.a library
with Interfaces.C;
with Interfaces.C.Pointers;
with Itf;
with System;
with Unchecked_Conversion;

package ExecItf is

  ------------------------------------------------------------------------------
  --| Notes:                                                                   |
  --|   Miscellaneous types, constants, and functions.                         |
  ------------------------------------------------------------------------------

  type Op_Sys_Type
  --| Possible operating system (i.e., executive) choices
  is ( Unknown,
       Windows,
       Linux );

  Op_Sys
  --| Operating system supported by this version of the executive
  : Op_Sys_Type := Unknown;

  procedure Set_Op_Sys;
  --| Set Operating System Running Under

  subtype Config_File_Name_Type is String(1..60);

  type Config_File_Name_Var_Type
  is record
    Count : Integer;
    Value : Config_File_Name_Type;
  end record;

  function Config_File_Name
  return Config_File_Name_Var_Type;
  --| Return path name of configuration file

  procedure Exit_to_OS
  ( Status : Integer := 0
  );
  -- Exit to OS with Status

  function GetLastError
  return Integer;
  -- Return current last error number

  type BOOL is new Interfaces.C.Int;             -- same as Win32 BOOL
  subtype CHAR    is Interfaces.C.Char;          -- Win32
  type    PCHAR   is access all CHAR;            -- Win32
  subtype LPSTR   is PCHAR;                      -- Win32
  subtype DWORD   is Interfaces.C.Unsigned_Long; -- same as Win32 DLONG
  subtype ULONG   is Interfaces.C.Unsigned_Long; -- same as Win32 DLONG
  type    PULONG  is access all ULONG;           -- Win32
  subtype PDWORD  is PULONG;                     -- Win32
  subtype LPDWORD is PDWORD;                     -- Win32

--  procedure Log_Error;
  -- Log the current last error number

  subtype Computer_Name_Type
  is Integer range 1..200;

  function GetComputerName
  ( Name   : in System.Address;
    --| Location of buffer into which to store the name
    Length : in Computer_Name_Type
    --| Number of characters, including trailing NUL, that can be stored
  ) return Integer; -- 0 if no error
  --| Return the computer / host name on which application is running

  function GetComputerNameA                      -- winbase.h:6576
  ( Buffer : LPSTR;
    Size   : LPDWORD
  ) return BOOL;
  pragma Import( Stdcall, GetComputerNameA, "GetComputerNameA" ); -- winbase.h:6576
  -- GetComputerName and GetComputerNameA are the same function

  type Integer_Pair_Type
  is array( 1..2 ) of Integer;

  function Unsigned_Long_to_Int
  ( Source : in Interfaces.C.Unsigned_Long
  ) return Integer_Pair_Type;

  ------------------------------------------------------------------------------
  --| Notes:                                                                   |
  --|   File types, constants, and functions.                                  |
  ------------------------------------------------------------------------------

  type File_Handle is private;
  --|  Corresponds to the file handle values used in the C routines

  type Mode_Type
  is ( Binary, Text );
  for Mode_Type'Size use Integer'Size;
  for Mode_Type use ( Binary => 0, Text => 1 );
  -- Used in all the Open and Create calls to specify if the file is to be
  -- opened in binary mode or text mode. In systems like Unix, this has no
  -- effect, but in systems capable of text mode translation, the use of
  -- Text as the mode parameter causes the system to do CR/LF translation
  -- and also to recognize the DOS end of file character on input. The use
  -- of Text where appropriate allows programs to take a portable Unix view
  -- of DOS-format files and process them appropriately.

  Invalid_File_Handle
  --|  File descriptor returned when error in opening/creating file;
  : constant File_Handle;

  function Close_File
  ( Handle : File_Handle
  ) return Boolean;
  -- Close file referenced by Handle. Return False if the underlying service
  -- failed. Reasons for failure include: disk full, disk quotas exceeded
  -- and invalid file handle (the file may have been closed twice).

  subtype PVOID  is System.Address;              -- same as Win32
  subtype HANDLE is PVOID;                       -- winnt.h:144

  function CloseHandle                           -- winbase.h:2171
  ( Object : HANDLE
  ) return BOOL;

  function Create_File
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle;
  -- Creates new file with given name for writing, returning file descriptor
  -- for subsequent use in Write calls. The file handle is returned as
  -- Invalid_Handle if the file cannot be successfully created.

  function Create_New_File
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle;
  -- Create new file with given name for writing, returning file descriptor
  -- for subsequent use in Write calls. This differs from Create_File in
  -- that it fails if the file already exists. File handle returned is
  -- Invalid_Handle if the file exists or cannot be created.

  Seek_Cur : constant := 1; -- seek from current position
  Seek_End : constant := 2; -- seek from end of file
  Seek_Set : constant := 0; -- seek from start of file
  --  Used to indicate origin for Seek call

  procedure Seek
  ( Handle : File_Handle; --FD     : File_Descriptor;
    Offset : Long_Integer;
    Origin : Integer
  );
  --  Sets the current file pointer to the indicated offset value, relative
  --  to the current position (origin = SEEK_CUR), end of file (origin =
  --  SEEK_END), or start of file (origin = SEEK_SET).
  pragma Import( C, Seek, "__gnat_lseek" );

  function Open_Read
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle;
  -- Open file Name for reading, returning file handle.  File handle is
  -- returned as Invalid_Handle if file cannot be opened.

  function Open_Read_Write
  ( Name : String;
    Mode : Mode_Type := Text
  ) return File_Handle;
  -- Open file Name for both reading and writing, returning file handle.
  -- File handle returned as Invalid_Handle if file cannot be opened.

  type OVERLAPPED;                               -- winbase.h:179
  type LPOVERLAPPED is access all OVERLAPPED;    -- winbase.h:185
  subtype LPVOID  is PVOID;                      -- windef.h

  function ReadFile                              -- winbase.h:2095
  ( File                : HANDLE;
    Buffer              : LPVOID;
    NumberOfBytesToRead : DWORD;
    NumberOfBytesRead   : LPDWORD;
    Overlapped          : LPOVERLAPPED
  ) return BOOL;

  function Read_File
  ( File : File_Handle;
    Addr : System.Address;
    Num  : Integer
  ) return Integer;
  -- Read Num bytes to address Addr from file referenced by File.
  -- Returned value is count of bytes actually read, which can be
  -- less than Num at EOF.

  function Write_File
  --| Write Text to File and return number of bytes written.  Strip internal
  --| NULs if True.
  ( File       : in File_Handle;
    Text       : in String;
    Strip_NULs : in Boolean := False
  ) return Integer;

  function Write_File
  --| Write Len bytes at Addr to File and return number of bytes written.
  ( File : File_Handle;
    Addr : System.Address;
    Len  : Integer
  ) return Integer;

  ------------------------------------------------------------------------------
  --| Notes:                                                                   |
  --|   Time types, constants, and functions.                                  |
  ------------------------------------------------------------------------------

  -- The following types are duplicates of those in GNAT s-os_lib.ads.

  subtype OS_Time is GNAT.OS_Lib.OS_Time; --private;
  --  The OS's notion of time is represented by the private type OS_Time.
  --  This is the type returned by the File_Time_Stamp functions to obtain
  --  the time stamp of a specified file. Functions and a procedure (modeled
  --  after the similar subprograms in package Calendar) are provided for
  --  extracting information from a value of this type. Although these are
  --  called GM, the intention is not that they provide GMT times in all
  --  cases but rather the actual (time-zone independent) time stamp of the
  --  file (of course in Unix systems, this *is* in GMT form).
  subtype SystemTimeType is OS_Time;

  Invalid_Time : constant OS_Time := GNAT.OS_Lib.Invalid_Time;
  --  A special unique value used to flag an invalid time stamp value

  subtype Year_Type     is Integer range 1900 .. 2099;
  subtype Month_Type    is Integer range    1 ..   12;
  subtype Day_Type      is Integer range    1 ..   31;
  subtype Hour_Type     is Integer range    0 ..   23;
  subtype Minute_Type   is Integer range    0 ..   59;
  subtype Second_Type   is Integer range    0 ..   59;
  subtype Millisec_Type is Integer range    0 ..  999;
  --  Declarations similar to those in Calendar, breaking down the time

  function Current_Time
  return OS_Time;
  --  Return the system clock value as OS_Time

  type Split_Time_Type
  --| Structure with the Data and Time.
  --| Notes: Not part of GNAT but similar to C tm type.
  --|        Also, like SYSTEMTIME of System.Win32 except each field was of
  --|        type WORD where WORD is declared as Interfaces.C.unsigned_short
  --|        where type unsigned_short is mod 2 ** short'Size; and short is
  --|        type short is new Short_Integer;
  is record
    Year     : Year_Type;
    Month    : Month_Type;
    Day      : Day_Type;
    Hour     : Hour_Type;
    Minute   : Minute_Type;
    Second   : Second_Type;
    Millisec : Millisec_Type;
  end record;
  subtype System_Time_Type is Split_Time_Type;

  function System_Time
  ( Time : OS_Time
    --| System clock value
  ) return System_Time_Type;
  --| Return system clock value as a record.
  --| Notes: This time contains no adjustment for local time.

  type FILETIME;                                 -- winbase.h:204
  type SYSTEMTIME1;                              -- same as Win32.WinBase SYSTEMTIME
  type PFILETIME is access all FILETIME;         -- winbase.h:207
  subtype LPFILETIME is PFILETIME;               -- winbase.h:207
  type PSYSTEMTIME is access all SYSTEMTIME1;    -- winbase.h:222
  subtype LPSYSTEMTIME is PSYSTEMTIME;           -- winbase.h:222

  procedure GetSystemTime                        -- winbase.h:2613
  ( SystemTime : LPSYSTEMTIME );
  pragma Import( Stdcall, GetSystemTime, "GetSystemTime" ); -- winbase.h:2613

  function SystemTime
  return System_Time_Type;
  --| Return system clock value as a record.
  --| Notes: This time contains no adjustment for local time.

  procedure GM_Split
  ( Date     : OS_Time;
    Year     : out Year_Type;
    Month    : out Month_Type;
    Day      : out Day_Type;
    Hour     : out Hour_Type;
    Minute   : out Minute_Type;
    Second   : out Second_Type;
    Millisec : out Millisec_Type
  );
  --  Analogous to the Split routine in Ada.Calendar, takes an OS_Time and
  --  provides a representation of it as a set of component parts, to be
  --  interpreted as a date point in UTC.

  function File_Time_Stamp
  ( Name : String
  ) return OS_Time;
  --  Given the name of a file or directory, Name, obtains and returns the
  --  time stamp. This function can be used for an unopened file. Returns
  --  Invalid_Time is Name doesn't correspond to an existing file.

  function File_Time_Stamp
  ( Handle : File_Handle
  ) return OS_Time;
  --  Get time stamp of file from file Handle and returns Invalid_Time if
  --  Handle doesn't correspond to an existing file.

  ------------------------------------------------------------------------------
  --| Notes:                                                                   |
  --|   Process types, constants, and functions.                               |
  ------------------------------------------------------------------------------

  type PId_t is private;

  Invalid_PId : constant PId_t;

  function GetPId return PId_t;
  -- This function gets system identifier of the current process / application.
  pragma Import (C, GetPId, "getpid");

  function Execute_Program
  ( Name : in String
    --| Program name to be executed
  ) return PId_t;
  --| Spawn a new Process and Execute the Command
  -- ++
  --| Overview:
  --|   Comments are from GNAT:
  --|     This is a non blocking call. The Process_Id of the spawned process
  --|     is returned. Parameters are to be used as in Spawn. If Invalid_Pid
  --|     is returned the program could not be spawned.
  --|
  --|     Spawning processes from tasking programs is not recommended. See
  --|     "NOTE: Spawn in tasking programs" below.
  -- --

  function GetProcessShutdownParameters
  ( Level : in LPDWORD;
    Flags : in LPDWord
  ) return BOOL;

  function Is_Running
  ( Path : String
    --| Full path of executable
  ) return Boolean;
  --| Return True if executable is currently running
  -- ++
  --| Overview:
  --|   Determine if the executable named by the Path is currently running.
  --
  --| Notes:
  --|   o It is expected that Path will be the full path including the
  --|     trailing ".exe" of the executable.
  --|   o The function iterates through the /proc directory to obtain the
  --|     process identifiers of the running processes and, for each one
  --|     for which ReadLink returns a value for an executable path, it
  --|     compares that value with the supplied Path.  If it matches, True
  --|     is returned.
  -- --

  ------------------------------------------------------------------------------
  --| Notes:                                                                   |
  --|   Event types, constants, and functions.                                 |
  ------------------------------------------------------------------------------

  procedure Create_Event
  ( Name : in String;
    -- Event name
    Id   : in out Integer;
    --| Event id on input, 0 upon output for failur
    Addr : in System.Address
    --| Address of handle
  );

  function Reset_Event                            -- winbase.h:1878
  ( Event : HANDLE
  ) return Boolean;

  function Set_Event                              -- winbase.h:1871
  ( Event : HANDLE
  ) return Boolean;

  ------------------------------------------------------------------------------
  --| Notes:                                                                   |
  --|   Thread types, constants, and functions.                                |
  ------------------------------------------------------------------------------

  -- The following types are duplicates of those in GNAT g-thread.ads and
  -- those needed to interface directly with Linux C functions.

  type Void_Ptr is access all Integer;

  type Thread_Handle_Type is private;

  type Thread_Id_Type is new Interfaces.C.unsigned_long;

  Null_Thread_Id
  : constant Thread_Id_Type := 0;

  Null_Thread_Handle
  --| Null thread handle value
  : constant Thread_Handle_Type;

  PTHREAD_RWLOCK_SIZE --  pthread_rwlock_t
  -- as taken from /usr/lib/gcc/i686-redhat-linux/4.7.0/adainclude/s-oscons.ads
  -- of Fedora install on removal drive
  : constant := 32;

  PTHREAD_ATTR_SIZE --  pthread_attr_t
  -- as taken from /usr/lib/gcc/i686-redhat-linux/4.7.0/adainclude/s-oscons.ads
  -- of Fedora install on removal drive
  : constant := 36;

  PTHREAD_RWLOCKATTR_SIZE --  pthread_rwlockattr_t
  -- as taken from /usr/lib/gcc/i686-redhat-linux/4.7.0/adainclude/s-oscons.ads
  -- of Fedora install on removal drive
  : constant := 8;

  subtype char_array
  -- as taken from /usr/lib/gcc/i686-redhat-linux/4.7.0/adainclude/s-osinte.ads
  -- of Fedora install on removal drive
  is Interfaces.C.char_array;

  type WSA_CHAR_Array is array(Natural range <>) of aliased CHAR;

  type pthread_attr_t
  -- as taken from /usr/lib/gcc/i686-redhat-linux/4.7.0/adainclude/s-osinte.ads
  -- of Fedora install on removal drive
  --    type pthread_attr_t
  is record
    Data : char_array(1 .. PTHREAD_ATTR_SIZE);
  end record;
  pragma Convention (C, pthread_attr_t);
  for pthread_attr_t'Alignment use Interfaces.C.unsigned_long'Alignment;

  type pthread_rwlock_t is record
  -- as taken from /usr/lib/gcc/i686-redhat-linux/4.7.0/adainclude/s-osinte.ads
  -- of Fedora install on removal drive
    Data : char_array(1 .. PTHREAD_RWLOCK_SIZE);
  end record;
  pragma Convention (C, pthread_rwlock_t);
  for pthread_rwlock_t'Alignment use Interfaces.C.unsigned_long'Alignment;

  type pthread_rwlockattr_t is record
  -- as taken from /usr/lib/gcc/i686-redhat-linux/4.7.0/adainclude/s-osinte.ads
  -- of Fedora install on removal drive
    Data : char_array(1 .. PTHREAD_RWLOCKATTR_SIZE);
  end record;
  pragma Convention (C, pthread_rwlockattr_t);
  for pthread_rwlockattr_t'Alignment use Interfaces.C.unsigned_long'Alignment;

  subtype Thread_RWLock_Type is pthread_rwlock_t;
  subtype Thread_RWLock_Attr_Type is pthread_rwlockattr_t;

  subtype Thread_Address_Type
  --| System address of a thread
  is System.Address;

  Null_Thread_Address
  --| Null system address for thread
  : constant Thread_Address_Type;

  procedure Create_Thread
  ( Start           : System.Address;     -- pointer to start address of thread
    Parameter       : System.Address;     -- pointer to parameters
    Stack_Size      : Natural;            -- stack size in bytes
    Thread_Priority : Integer;            -- priority for thread
    Thread_Handle   : out Thread_Handle_Type
  );
  -- Creates a thread with the given (Size) stack size in bytes, and
  -- the given (Prio) priority. The task will execute a call to the
  -- procedure whose address is given by Code. This procedure has
  -- the prototype
  --
  --   void thread_code (void *id, void *parm);
  --
  -- where id is the id of the created task, and parm is the parameter
  -- passed to Create_Thread. The called procedure is the body of the
  -- code for the task, the task will be automatically terminated when
  -- the procedure returns.
  --
  -- This function returns the Ada Id of the created task that can then be
  -- used as a parameter to the procedures below.
  --
  -- C declaration:
  --
  -- extern void *__gnat_create_thread
  --   (void (*code)(void *, void *), void *parm, int size, int prio);
  --|
  --| Notes:
  --|   This Create_Thread using GNAT.Threads.  The Thread_Handle that is
  --|   returned is different from that of the C pthread_create Create_Thread
  --|   below.  It needs the use of Get_Thread to retrun the Thread_Handle
  --|   to a Linux Thread_Id.  Also, when the thread starts the pointer that
  --|   is supposed to be the address of the parameters passed to the thread
  --|   has a different value than that supplied to Create_Thread.

  function Create_Thread
  ( Start      : in System.Address;  -- pointer
    Parameters : in Void_Ptr;        -- pointer
    Stack_Size : in Natural;         -- int
    Priority   : in Integer          -- int
  ) return HANDLE;
  --| Create Thread
  -- ++
  --| Overview:
  --|   This function creates a thread with the given stack size in bytes, and
  --|   the given Priority.  The task will execute a call to the procedure whose
  --|   address is given by Start and may pass the Parmeters at the address.
  --|   The thread handle is at the returned address.
  -- --

--  procedure Create_Thread_Linux
--  ( Stack_Size    : in Integer;
    --| Stack size to use
--    Start         : in System.Address;
    --| Pointer to start address for thread
--    Thread_Number : in  Integer;
    --| Application-defined thread number
--    Thread_Id     : out Integer;
    --| Identifier returned by pthread_create
--    Success       : out Boolean
    --| Whether create was successful
--  );
  --| Create Thread
  -- ++
  --| Overview:
  --|   Create thread and return its id at the location specified and True if
  --|   created successfully.
  -- --

  procedure Get_Thread -- get thread identifier from handle
  ( Thread_Handle : in HANDLE;
    Thread_Id     : out PId_t );
  -- This procedure is used to retrieve the thread id of a given task.
  -- The value Thread_Handle is the value that was passed to the thread
  -- code procedure at activation time.
  -- Thread_Id is obtained by this procedure.

  procedure Get_Thread
  ( Thread_Handle : in Thread_Handle_Type;
    --| GNAT thread id
    Thread_Id     : out Thread_Id_Type
    --| Linux thread id
  );
  -- Convert GNAT thread identifier to that of Linux.

  function To_Task_Id
  ( Thread_Handle : in Thread_Handle_Type
  ) return Ada.Task_Identification.Task_Id;
   --  Ada interface only.
  -- Given a low level Id, as returned by Create_Thread, return a Task_Id,
  -- so that operations in Ada.Task_Identification can be used.

  procedure Destroy_Thread
  ( Thread_Handle : Thread_Handle_Type
  );
  -- This procedure may be used to prematurely abort the created thread.
  -- The Thread_Handle is the value that was returned by thread create.
  -- Notes:
  --   There are two sets of procedures/functions.  One using the GNAT
  --   thread identifier that I refer to as the Thread Handle and one
  --   using the Linux C functions that I refer to as the Thread Id.
  --   Matching routines need to be used that use either the handle or
  --   the identifier and not the wrong one for the routine.

  function GetCurrentThreadId
  return Thread_Id_Type;
  -- This function gets the system identifier of the currently running thread.

  function GetCurrentThread                      -- winbase.h:1623
  return HANDLE;

  type Thread_RWLock_Ptr_Type
  is access Thread_RWLock_Type;

  type Thread_RWLock_Attr_Ptr_Type
  is access Thread_RWLock_Attr_Type;

--  function Thread_Lock_Init
--  ( Lock : Thread_RWLock_Ptr_Type;
--    Attr : Thread_RWLock_Attr_Ptr_Type
--  ) return Interfaces.C.int;
  -- Initalize thread read/write lock semaphore

  function Thread_Lock_Destroy
  ( Lock : Thread_RWLock_Ptr_Type
  ) return Interfaces.C.int;
  -- Destroy thread read/write lock semaphore
  pragma Import( C, Thread_Lock_Destroy, "pthread_rwlock_destroy" );

--  function Thread_Lock
--  ( Lock : Thread_RWLock_Ptr_Type
--  ) return Interfaces.C.int;
  -- Lock the thread read/write lock semaphore

  function Thread_Unlock
  ( Lock : Thread_RWLock_Ptr_Type
  ) return Interfaces.C.int;
  -- Unlock the thread read/write lock semaphore

  ------------------------------------------------------------------------------
  -- Named pipes

  type mode_t is new Integer;

  subtype Pipe_Handle is File_Handle; --private;

  Invalid_Pipe_Handle
  --|  File descriptor returned when error in opening/creating file;
  : constant Pipe_Handle;

  subtype Pipe_Name_Type
  --| Pipe name
  is String(1..79);

  type Named_Pipe_Name_Type
  --| Name to use for the pipe
  is record
    Count : Integer;
    --| Number of characters in name
    Path  : Pipe_Name_Type;
    --| Path including pipe name
  end record;

  type Open_Mode_Type is new Integer;
  -- see Win32Ada/win32/src/crt/win32-crt-fcntl.ads and
  -- /4.5.4/gcc-include/s-oscons.h of gnat of Linux
  O_RDONLY  : constant Open_Mode_Type := 16#0#;
  O_WRONLY  : constant Open_Mode_Type := 16#1#;
  O_RDWR    : constant Open_Mode_Type := 16#2#;
  -- The above three modes can't be or-ed together.
  O_APPEND  : constant Open_Mode_Type := 16#8#;
  O_CREAT   : constant Open_Mode_Type := 16#100#;
--O_NOCTTY  : constant Open_Mode_Type := 256;  -- 16#100#
  O_NDELAY  : constant Open_Mode_Type := 2048; -- 16#800#

--  function MkFifo
--  ( Path : System.Address;
--    Mode : Mode_t
--  ) return Integer;

  function Open
  ( Path : System.Address;
    Mode : Open_Mode_Type
  ) return Pipe_Handle;
  pragma Import( C, Open, "open" );

  function Unlink
  ( Path : System.Address
  ) return Integer;
  pragma Import( C, Unlink, "unlink" );


  subtype PSTR   is PCHAR;                       -- winnt.h
  type    PCCH   is access constant CHAR;        -- winnt.h
  subtype LPCSTR is PCCH;                        -- Win32
  subtype LPCTSTR is PCCH;
  subtype PCSTR  is PCCH;                        -- Win32

  subtype SHORT  is Interfaces.C.Short;          -- winnt.h
  subtype USHORT is Interfaces.C.Unsigned_Short; -- same as Win32
  subtype WORD   is USHORT;                      -- same as Win32

  type    VOID    is null record;                -- same as Win32
  subtype PCVOID  is PVOID;
  subtype LPCVOID is PCVOID;                     -- Win32
  type    PVOID_Array                            -- rpcproxy.h
          is array( Natural range <> ) of aliased PVOID;

  subtype INT    is Interfaces.C.Int;            -- Win32
  subtype UINT   is Interfaces.C.Unsigned;       -- Win32
  type SOCKET is new UINT;                       -- winsock.h:45

  subtype LONG  is Interfaces.C.Long;            -- Win32
  type    PLONG is access all LONG;

  type BY_HANDLE_FILE_INFORMATION;               -- winbase.h:2030
  type LPBY_HANDLE_FILE_INFORMATION              -- winbase.h:2041
  is access all BY_HANDLE_FILE_INFORMATION;


  function to_LPSYSTEMTIME -- convert address to pointer
  is new Unchecked_Conversion( Source => System.Address,
                               Target => LPSystemTime );


  type SECURITY_ATTRIBUTES;                      -- winbase.h:187
  type PSECURITY_ATTRIBUTES is access all SECURITY_ATTRIBUTES; -- winbase.h:191
  subtype LPSECURITY_ATTRIBUTES is PSECURITY_ATTRIBUTES;

  type PHANDLE is access all HANDLE;             -- winnt.h:145

  type LIST_ENTRY;                               -- winnt.h:446
  type PLIST_ENTRY is access all LIST_ENTRY;     -- winnt.h:449

  type RTL_CRITICAL_SECTION;                     -- winnt.h:3953
  type PRTL_CRITICAL_SECTION is access all       -- winnt.h:3977
       RTL_CRITICAL_SECTION;
  type PCRITICAL_SECTION is access all RTL_CRITICAL_SECTION;
  subtype LPCRITICAL_SECTION is PCRITICAL_SECTION; -- winbase.h:231
  type RTL_CRITICAL_SECTION_DEBUG;               -- winnt.h:3950
  type PRTL_CRITICAL_SECTION_DEBUG is access all -- winnt.h:3959
       RTL_CRITICAL_SECTION_DEBUG;

  type SOCKADDR;                                 -- winsock.h:473
  type PSOCKADDR is access all SOCKADDR;         -- winsock.h:830

  type WSADATA;                                  -- winsock.h:328
  type LPWSADATA is access all WSADATA;          -- winsock.h:338

--  type TIMERAPCROUTINE;
--  type PTIMERAPCROUTINE is access all TIMERAPCROUTINE;
  subtype PTIMERAPCROUTINE is PVOID; -- what needed for this?
  type LARGE_INTEGER
  is record
    LowPart  : Itf.Nat32; -- DWORD for LowPart
    HighPart : Itf.Int32; -- LONG for HighPart
  end record;
  for LARGE_INTEGER
  use record
    LowPart  at 0 range 0..31;
    HighPart at 4 range 0..31;
  end record;

  ------------------------------------------------------------------------------
  --| Notes:  Constants

  ERROR_ALREADY_EXISTS  : constant := 183;        -- winerror.h:1370
  ERROR_IO_PENDING      : constant := 997;        -- winerror.h:1874

  FILE_SHARE_READ       : constant := 16#1#;      -- winnt.h:1848
  FILE_ATTRIBUTE_NORMAL : constant := 16#80#;     -- winnt.h:1855

  GENERIC_READ  : constant := 16#80000000#;       -- winnt.h:1967
  GENERIC_WRITE : constant := 16#40000000#;       -- winnt.h:1968

  FILE_FLAG_NO_BUFFERING  : constant := 16#20000000#;
  FILE_FLAG_WRITE_THROUGH : constant := 16#80000000#;

  STATUS_WAIT_0  : constant DWORD  := 16#0#;      -- winnt.h:702
  STATUS_TIMEOUT : constant DWORD  := 16#102#;    -- winnt.h:705

--  WAIT_FAILED   : constant DWORD := 16#ffffffff#; -- winbase.h:66
--  WAIT_OBJECT_0 : DWORD renames STATUS_WAIT_0;    -- winbase.h:67
--  WAIT_TIMEOUT  : DWORD renames STATUS_TIMEOUT;   -- winbase.h:72
  PIPE_ACCESS_DUPLEX       : constant := 16#3#;   -- winbase.h:133

  CREATE_SUSPENDED              : constant := 16#4#;    -- winbase.h:538

  NORMAL_PRIORITY_CLASS         : constant := 16#20#;   -- winbase.h:544
  IDLE_PRIORITY_CLASS           : constant := 16#40#;   -- winbase.h:545
  HIGH_PRIORITY_CLASS           : constant := 16#80#;   -- winbase.h:546
  REALTIME_PRIORITY_CLASS       : constant := 16#100#;  -- winbase.h:547
  BELOW_NORMAL_PRIORITY_CLASS   : constant := 16#4000#; -- newer windbase.h
  ABOVE_NORMAL_PRIORITY_CLASS   : constant := 16#8000#; -- newer windbase.h
  THREAD_PRIORITY_LOWEST        : constant := -2;       -- winbase.h:557
  THREAD_PRIORITY_BELOW_NORMAL  : constant := -1;       -- winbase.h:558
  THREAD_PRIORITY_NORMAL        : constant := 0;        -- winbase.h:559
  THREAD_PRIORITY_HIGHEST       : constant := 2;        -- winbase.h:560
  THREAD_PRIORITY_ABOVE_NORMAL  : constant := 1;        -- winbase.h:561
  THREAD_PRIORITY_ERROR_RETURN  : constant := 16#7fffffff#;
  THREAD_PRIORITY_TIME_CRITICAL : constant := 15;       -- winbase.h:564
  THREAD_PRIORITY_IDLE          : constant := -15;      -- winbase.h:565

  FILE_END      : constant := 2;                  -- winbase.h:62

  CREATE_ALWAYS : constant := 2;                  -- winbase.h:117
  OPEN_EXISTING : constant := 3;                  -- winbase.h:118
  OPEN_ALWAYS   : constant := 4;
  PIPE_WAIT                : constant := 16#0#;   -- winbase.h:146
  PIPE_READMODE_BYTE       : constant := 16#0#;
  PIPE_READMODE_MESSAGE    : constant := 16#2#;   -- winbase.h:149
  PIPE_TYPE_BYTE           : constant := 16#0#;
  PIPE_TYPE_MESSAGE        : constant := 16#4#;   -- winbase.h:151
  PIPE_UNLIMITED_INSTANCES : constant := 255;     -- winbase.h:157
  NMPWAIT_USE_DEFAULT_WAIT : constant := 16#0#;
  FILE_FLAG_OVERLAPPED     : constant := 16#40000000#;
  PIPE_TIMEOUT             : constant := 5000;


  function To_Handle is new Unchecked_Conversion
                            ( Source => Integer,
                              Target => HANDLE );
  INVALID_HANDLE_VALUE                            -- winbase.h:57
  : constant HANDLE := To_Handle(-1);

  IPPROTO_TCP        : constant := 6;             -- winsock.h:202
  WSADESCRIPTION_LEN : constant := 256;           -- winsock.h:325
  WSASYS_STATUS_LEN  : constant := 128;           -- winsock.h:326
  SOCK_STREAM        : constant := 1;             -- winsock.h:377
  AF_INET            : constant := 2;             -- winsock.h:448
  PF_INET            : constant := 2;             -- winsock.h:492
  INVALID_SOCKET     : constant := UINT'Last;

  -- Possible WinSock shutdown "how" possibilities 
  SD_RECEIVE : constant Itf.Int32 := 0;
  SD_SEND    : constant Itf.Int32 := 1;
  SD_BOTH    : constant Itf.Int32 := 2;

  -- Waitable Timer DesiredAccess possibilities
  TIMER_ALL_ACCESS   : constant := 16#1F0003#;
  TIMER_MODIFY_STATE : constant := 16#0002#;
  SYNCHRONIZE        : constant := 16#00100000#;

  ------------------------------------------------------------------------------
  -- Timers
  ------------------------------------------------------------------------------
  type Time_Interval_Type
  --OLD  64-bit signed integer with 1 nanoseconds LSB
  --NEW  32-bit signed integer with 1 millisecond LSB --@
  is new Itf.Interface_Integer; --Interface_Long_Integer;
  for Time_Interval_Type'Alignment use 8;

  Infinite_Time
  -- Time Interval to indicate no timeout or no periodic time interval
  -- for a thread
  : constant Time_Interval_Type := -1;

  -- Create an Event
  function CreateEvent
  ( ManualReset  : Boolean;
    InitialState : Boolean;
    Name         : System.Address
  ) return HANDLE; -- Handle of the event object

  -- Create a wait timer
  -- Security attributes and whether timer is inheritable.
  -- ManualReset indicates whether timer is a manual-reset notification timer
  -- or a synchronization timer.
  -- The name is limited to MAX_PATH characters and cannot contain '\'.
--  function CreateWaitableTimer
--  ( SecurityAttributes : LPSECURITY_ATTRIBUTES; -- pointer to security attributes
--    ManualReset        : BOOL; -- TRUE if manual reset timer; otherwise synchronization
--    TimerName          : LPCSTR -- pointer to null-terminated string name
--  ) return HANDLE; -- Handle of the timer object or NULL if a failure
--  pragma Import( Stdcall, CreateWaitableTimer, "CreateWaitableTimerA" ); -- winbase.h 1405
  function CreateWaitableTimer
  ( ManualReset : Boolean
  ) return HANDLE; -- handle of timer object or NULL if a failure

  -- Open an existing timer.
  -- DesiredAccess can be TIMER_ALL_ACCESS, TIMER_MODIFY_STATE, or SYNCHRONIZE.
  function OpenWaitableTimer
  ( DesiredAccess : DWORD; -- requested access to the timer object
    InheritHandle : BOOL;  -- whether the returned handle is inheritable.
    TimerName     : LPCSTR --LPCTSTR -- points to null-terminated string naming the timer
  ) return HANDLE; -- Handle of the timer object or NULL if a failure
  pragma Import( Stdcall, OpenWaitableTimer, "OpenWaitableTimerA" ); -- winbase.h 1960

  -- Activates the specified "waitable" timer. When the due time arrives,
  -- the timer is signaled and the thread that set the timer calls the
  -- optional completion routine.
  -- Period is in 100 nanosecond intervals; i.e., .1 milliseconds.  Negative
  -- values indicate relative time.
  -- A periodic timer automatically reactivates each time the the Period
  -- elapses until the timer is canceled or reset via SetWaitableTimer.
  -- The CompletionRoutine is optional.
  -- Resume is whether to restore a system in suspended power conservation mode.
--  function SetWaitableTimer
--  ( Timer                  : HANDLE; -- handle of timer object
--    DueTime                : LARGE_INTEGER; -- when timer will become signaled
--    Period                 : LONG; -- periodic timer interval in milliseconds
--    CompletionRoutine      : PTIMERAPCROUTINE; -- pointer to completion routine
--    ArgToCompletionRoutine : LPVOID; -- data passed to the completion routine
--    Resume                 : BOOL -- flag for resume state
--  ) return BOOL; -- non-zero if successful
--  pragma Import( Stdcall, SetWaitableTimer, "SetWaitableTimer" ); -- winbase.h:2132
  function SetWaitableTimer
  ( Timer   : HANDLE;  -- handle of timer object
    DueTime : Integer; -- when timer will become signaled
    Period  : Integer; -- periodic timer interval in milliseconds
    Resume  : Boolean  -- flag for resume state
  ) return Boolean; -- whether successful

--  function WaitForSingleObject
--  ( WaitHandle   : HANDLE;
--    Milliseconds : DWORD
--  ) return DWORD;
  type WaitReturnType
    is ( WAIT_ABANDONED, -- for mutex object not released by owning thread
         WAIT_SIGNALED,  -- state of object is signaled
         WAIT_TIMEOUT,   -- timeout interval elapsed without object being signaled
         WAIT_FAILED,    -- function has failed, call GetLastError
         Unknown_Failure -- failure couldn't be determined
       );

  function WaitForSingleObject
  ( WaitHandle   : HANDLE;
    Milliseconds : Integer -- -1 for Infinite
  ) return WaitReturnType;

--  function WaitForSingleObject                   -- winbase.h:1908
--  ( ObjectHandle : HANDLE;
--    Milliseconds : DWORD
--  ) return DWORD;

  function WaitForSingleObjectEx
  ( WaitHandle   : HANDLE;
    Milliseconds : DWORD;
    Alertable    : BOOL
  ) return DWORD;

  ------------------------------------------------------------------------------
  --| Notes: Unchecked Conversion functions

  ------------------------------------------------------------------------------
  --| Notes: Ada functions to access C functions

  type LPTHREAD_START_ROUTINE is access function
  return DWORD;
  pragma Convention( Stdcall, LPTHREAD_START_ROUTINE ); -- winbase.h:227

  type PHANDLER_ROUTINE is access function              -- same as Win32.Wincon
  ( CtrlType : DWORD
  ) return BOOL;
  pragma Convention( Stdcall, PHANDLER_ROUTINE );

  function to_PHandler -- convert one access type to the other
  is new Unchecked_Conversion( Source => System.Address,
                               Target => PHandler_Routine );

  function Bind                                  -- winsock.h:705
  --| Bind WinSock server socket
  ( S       : SOCKET;
    Addr    : PSOCKADDR; --ac_SOCKADDR_t;
    Namelen : INT
  ) return INT;
  pragma Import( Stdcall, bind, "bind" );        -- winsock.h:705

  function C_Accept                              -- winsock.h:702
  --| Accept WinSock connection
  ( S       : SOCKET;
    Addr    : access SOCKADDR;
    Addrlen : access INT
  ) return SOCKET;
  pragma Import( Stdcall, c_accept, "accept" );  -- winsock.h:702

  function Shutdown
  -- Shutdown receive or send operations on a socket
  ( S   : SOCKET;
    How : INT
  ) return INT;
  pragma Import( Stdcall, shutdown, "shutdown" ); -- winsock.h:321

  function CloseSocket                           -- winsock.h:707
  --| Close WinSock Socket
  ( s : SOCKET
  ) return INT;
  pragma Import( Stdcall, closesocket, "closesocket" ); -- winsock.h:707

  function CreateFile                            -- winbase.h:4745
  ( FileName            : LPCSTR;
    DesiredAccess       : DWORD;
    ShareMode           : DWORD;
    SecurityAttributes  : LPSECURITY_ATTRIBUTES;
    CreationDisposition : DWORD;
    FlagsAndAttributes  : DWORD;
    TemplateFile        : HANDLE
  ) return HANDLE;

  function CreateMailslot                        -- winbase.h:2877
  ( Name               : LPCSTR;
    MaxMessageSize     : DWORD;
    ReadTimeout        : DWORD;
    SecurityAttributes : LPSECURITY_ATTRIBUTES
  ) return HANDLE;
  pragma Import( Stdcall, CreateMailslot, "CreateMailslotA" ); -- winbase.h:2877
  -- CreateMailslot and CreateMailslotA are the same function

  function CreateThread                          -- winbase.h:1598
  ( ThreadAttributes : LPSECURITY_ATTRIBUTES;
    StackSize        : DWORD;
    StartAddress     : LPTHREAD_START_ROUTINE;
    Parameter        : LPVOID;
    CreationFlags    : DWORD;
    ThreadId         : LPDWORD
  ) return HANDLE;
  pragma Import( Stdcall, CreateThread, "CreateThread" ); -- winbase.h:1598

  function Connect                               -- winsock.h:709
  --| Connect to WinSock Socket
  ( s       : SOCKET;
    Name    : PSOCKADDR;
    Namelen : INT
  ) return INT;
  pragma Import( Stdcall, connect, "connect" );  -- winsock.h:709

  function ConnectNamedPipe                      -- winbase.h:2816
  ( NamedPipe  : HANDLE;
    Overlapped : LPOVERLAPPED
  ) return BOOL;

  function CreateNamedPipe                       -- winbase.h:4987
  ( Name               : LPCSTR;
    OpenMode           : DWORD;
    PipeMode           : DWORD;
    MaxInstances       : DWORD;
    OutBufferSize      : DWORD;
    InBufferSize       : DWORD;
    DefaultTimeOut     : DWORD;
    SecurityAttributes : LPSECURITY_ATTRIBUTES
  ) return HANDLE;

  function DisconnectNamedPipe                   -- winbase.h:2824
  ( NamedPipe : HANDLE
  ) return BOOL;

  procedure EnterCriticalSection                 -- winbase.h:1850
  ( CriticalSection : LPCRITICAL_SECTION );

  procedure ExitProcess                          -- winbase.h:1500
  ( ExitCode : UINT );

  MaxArguments: constant := 50;                  -- stdarg.ads
  -- "&" and Concat functions raise Constraint_Error if more than
  -- MaxArguments integer paramters are catenated.
  -- If you change this, change it in var.c also.

  type ArgList is private;                       -- stdarg.ads

  -- An empty arglist, to be used in constructors:
  function Empty return ArgList;                 -- stdarg.ads


  subtype C_Param is Interfaces.C.Long;          -- stdarg.ads

  type Param_Access is private;                  -- stdarg-impl.ads

  function Address_of_First_Arg (Args: ArgList) return Param_Access;

  function FormatMessage                         -- winbase.h:2767
  ( Flags      : DWORD;
    Source     : LPCVOID;
    MessageId  : DWORD;
    LanguageId : DWORD;
    Buffer     : LPSTR;
    Size       : DWORD;
    Arguments  : ArgList := Empty
  ) return DWORD;


  function GetCurrentProcess                     -- winbase.h:1486
  return HANDLE;

  function GetCurrentProcessId                   -- winbase.h:1493
  return DWORD;

  function GetExitCodeProcess                    -- winbase.h:1515
  ( Process  : HANDLE;
    ExitCode : LPDWORD
  ) return BOOL;

  function GetExitCodeThread                     -- winbase.h:1686
  ( Thread   : HANDLE;
    ExitCode : LPDWORD
  ) return BOOL;

  function GetFileInformationByHandle            -- winbase.h:2046
  ( File            : HANDLE;
    FileInformation : LPBY_HANDLE_FILE_INFORMATION
  ) return BOOL;
  pragma Import( Stdcall, GetFileInformationByHandle, -- winbase.h:2046
                         "GetFileInformationByHandle" );

  function GetHostname                           -- winsock.h:763
  --| Get hostname for WinSock
  ( Name    : PSTR;
    Namelen : INT
  ) return INT;
  pragma Import( Stdcall, gethostname, "gethostname" ); -- winsock.h:763

  procedure GetLocalTime                         -- winbase.h:2627
  ( SystemTime : LPSYSTEMTIME
  );


  function GetPriorityClass                      -- winbase.h:6260
  ( Process : HANDLE
  ) return DWORD;

  function GetThreadPriority                     -- winbase.h:1653
  ( Thread : HANDLE
  ) return INT;

  function htons                                 -- winsock.h:724
  ( Hostshort : USHORT
  ) return USHORT;
  pragma Import( Stdcall, htons, "htons" );      -- winsock.h:724

  function inet_addr                             -- winsock.h:726
  ( Cp : PCSTR
  ) return ULONG;
  pragma Import( Stdcall, inet_addr, "inet_addr" );   -- winsock.h:726

  procedure InitializeCriticalSection                 -- winbase.h:1843
  ( CriticalSection : LPCRITICAL_SECTION );

  procedure LeaveCriticalSection                 -- winbase.h:1857
  ( CriticalSection : LPCRITICAL_SECTION );

  function Listen                                -- winsock.h:730
  --| Mark the WinSock socket so it will listen for incoming connections
  ( S       : SOCKET;
    Backlog : INT
  ) return INT;
  pragma Import( Stdcall, listen, "listen" );    -- winsock.h:730


  function Recv                                  -- winsock.h:736
  --| Receive from WinSock socket
  ( S     : SOCKET;
    Buf   : PSTR;
    Len   : INT;
    Flags : INT
  ) return INT;
  pragma Import( Stdcall, recv, "recv" );        -- winsock.h:736

  function ResumeThread                          -- winbase.h:1805
  ( Thread : HANDLE
  ) return DWORD;
  pragma Import( Stdcall, ResumeThread, "ResumeThread" ); -- winbase.h:1805

  function Send                                  -- winsock.h:744
  --| Transmit via WinSock socket
  ( S     : SOCKET;
    Buf   : PCSTR;
    Len   : INT;
    Flags : INT
  ) return INT;
  pragma Import( Stdcall, send, "send" );        -- winsock.h:744

  function SetConsoleCtrlHandler                 -- same as Win32.Wincon
  ( HandlerRoutine : PHANDLER_ROUTINE;
    Add            : BOOL
  ) return BOOL;

  function SetFilePointer                        -- winbase.h:2134
  ( File               : HANDLE;
    DistanceToMove     : LONG;
    DistanceToMoveHigh : PLONG;
    MoveMethod         : DWORD
  ) return DWORD;
  pragma Import( Stdcall, SetFilePointer, "SetFilePointer" ); -- winbase.h:2134

  function SetPriorityClass                      -- winbase.h:6252
  ( Process       : HANDLE;
    PriorityClass : DWORD
  ) return BOOL;

  function SetThreadPriority                     -- winbase.h:1645
  ( Thread   : HANDLE;
    Priority : INT
  ) return Boolean; --BOOL;

  function Socket_Func                           -- winsock.h:754
  ( Af       : INT;
    C_Type   : INT;
    Protocol : INT
  ) return SOCKET;
  pragma Import( Stdcall, socket_func, "socket" ); -- winsock.h:754

  function SystemTimeToFileTime                  -- winbase.h:2685
  ( SystemTime : PSYSTEMTIME;
    FileTime   : LPFILETIME
  ) return BOOL;
  pragma Import( Stdcall, SystemTimeToFileTime, "SystemTimeToFileTime"); -- winbase.h:2685

  function TerminateThread                       -- winbase.h:1678
  ( Thread   : HANDLE;
    ExitCode : DWORD
  ) return BOOL;

  function WriteFile                             -- winbase.h:2084
  ( File                 : HANDLE;
    Buffer               : LPCVOID;
    NumberOfBytesToWrite : DWORD;
    NumberOfBytesWritten : LPDWORD;
    Overlapped           : LPOVERLAPPED
  ) return BOOL;

  function WSACleanup return INT;                   -- winsock.h:778
  pragma Import( Stdcall, WSACleanup, "WSACleanup" ); -- winsock.h:778

  function WSAGetLastError return INT;           -- winsock.h:782
  pragma Import( Stdcall, WSAGetLastError, "WSAGetLastError" ); -- winsock.h:782

  function WSAStartup                            -- winsock.h:776
  ( VersionRequired : WORD;
    WSAData         : LPWSADATA
  ) return INT;
  pragma Import( Stdcall, WSAStartup, "WSAStartup" ); -- winsock.h:776

  ------------------------------------------------------------------------------
  --| Notes: Structures

  type FILETIME                                  -- winbase.h:204
  is record
    LowDateTime  : DWORD;
    HighDateTime : DWORD;
  end record;

  type BY_HANDLE_FILE_INFORMATION                -- winbase.h:2030
  is record
    FileAttributes     : DWORD;
    CreationTime       : FILETIME;
    LastAccessTime     : FILETIME;
    LastWriteTime      : FILETIME;
    VolumeSerialNumber : DWORD;
    FileSizeHigh       : DWORD;
    FileSizeLow        : DWORD;
    NumberOfLinks      : DWORD;
    FileIndexHigh      : DWORD;
    FileIndexLow       : DWORD;
  end record;

  type LIST_ENTRY                                -- winnt.h:446
  is record
    Flink: PLIST_ENTRY;
    Blink: PLIST_ENTRY;
  end record;

  type OVERLAPPED                                -- winbase.h:179
  is record
    Internal     : DWORD;
    InternalHigh : DWORD;
    Offset       : DWORD;
    OffsetHigh   : DWORD;
    Event        : HANDLE;
  end record;

  type RTL_CRITICAL_SECTION                      -- winnt.h:3953
  is record
    DebugInfo     : PRTL_CRITICAL_SECTION_DEBUG;
    LockCount     : LONG;
    RecursionCount: LONG;
    OwningThread  : HANDLE;
    LockSemaphore : HANDLE;
    Reserved      : DWORD;
  end record;

  type RTL_CRITICAL_SECTION_DEBUG                -- winnt.h:3950
  is record
    C_Type               : WORD;
    CreatorBackTraceIndex: WORD;
    CriticalSection      : PRTL_CRITICAL_SECTION;
    ProcessLocksList     : LIST_ENTRY;
    EntryCount           : DWORD;
    ContentionCount      : DWORD;
    Depth                : DWORD;
    OwnerBackTrace       : PVOID_Array(0..4);
  end record;

  type SECURITY_ATTRIBUTES                       -- winbase.h:187
  is record
    Length             : DWORD;
    SecurityDescriptor : LPVOID;
    InheritHandle      : BOOL;
  end record;

  type SOCKADDR                                  -- winsock.h:473
  is record
    Family : USHORT;
    Data   : WSA_CHAR_Array(0..13);
  end record;

  type SYSTEMTIME1                               -- same as Winbase SYSTEMTIME
  is record
    Year        : WORD;
    Month       : WORD;
    DayOfWeek   : WORD;
    Day         : WORD;
    Hour        : WORD;
    Minute      : WORD;
    Second      : WORD;
    Milliseconds: WORD;
  end record;

  type WSADATA                                   -- winsock.h:328
  is record
    Version      : WORD;
    HighVersion  : WORD;
    Description  : WSA_CHAR_Array(0..WSADESCRIPTION_LEN);
    SystemStatus : WSA_CHAR_Array(0..WSASYS_STATUS_LEN);
    MaxSockets   : USHORT;
    MaxUdpDg     : USHORT;
    VendorInfo   : PSTR;
  end record;

  procedure Display_Last_WSA_Error;

private

  type File_Handle is new Integer;

  function to_File_Handle -- convert integer to file handle
  is new Unchecked_Conversion( Source => Integer,
                               Target => File_Handle );

  Invalid_File_Handle : constant File_Handle := to_File_Handle(-1);

  Invalid_Pipe_Handle : constant Pipe_Handle := Invalid_File_Handle;

  -- The following type is similar to that in s-osinte.ads of GNAT rts native
  -- for a system thread id
  type Thread_Handle_Type is new Interfaces.C.unsigned_long;

  Null_Thread_Handle
  : constant Thread_Handle_Type
  := 0;

  type PId_t is new Integer;

  Invalid_PId : constant PId_t := -1;

  Null_Thread_Address
  --| Null system address for thread
  : constant Thread_Address_Type := Thread_Address_Type(System.Null_Address);

  type ArgVector is array(Integer range <>) of aliased C_Param; -- stdarg.ads

  type ArgBlock is record                     -- stdarg.ads
    Vector      : ArgVector(1..MaxArguments) := (others => 0);
    RefCount    : Natural := 1;
    CurrentArgs : Natural := 0;
    FirstHole   : Natural := 0;
  end record;

  AS: constant := MaxArguments*C_Param'Size; -- stdarg.ads
  NS: constant := Natural'Size;              -- stdarg.ads

  -- On HP target this record must be aligned at mod 8, like a double.
  -- Maybe on Alpha too, not sure.
  -- On other targets the 8 could be changed to 4.
  -- For i386/NT 4 is the size to use
  for ArgBlock use record at mod 4;         -- stdarg.ads
    Vector      at 0        range 0..AS-1;
    RefCount    at AS       range 0..NS-1;
    CurrentArgs at AS+NS    range 0..NS-1;
    FirstHole   at AS+NS+NS range 0..NS-1;
  end record;

  type ArgBlockP is access ArgBlock;       -- stdarg.ads

  type ArgList is                          -- stdarg.ads
    new Ada.Finalization.Controlled with
    record
      Contents: ArgBlockP;
  end record;

  package Arith is new Interfaces.C.Pointers( -- stdarg-impl.ads
                         Integer, C_Param, ArgVector, 0);

  type Param_Access is new Arith.Pointer;     -- stdarg-impl.ads

  pragma Convention( C, BY_HANDLE_FILE_INFORMATION ); -- winbase.h:2030
  pragma Convention( C, FILETIME );                   -- winbase.h:204
  pragma Convention( C, LIST_ENTRY );                 -- winnt.h:446
  pragma Convention( C, OVERLAPPED );                 -- winbase.h:179
  pragma Convention( C, SECURITY_ATTRIBUTES );        -- winbase.h:187
  pragma Convention( C, RTL_CRITICAL_SECTION );       -- winnt.h:3953
  pragma Convention( C, RTL_CRITICAL_SECTION_DEBUG ); -- winnt.h:3950
  pragma Convention( C, SOCKADDR );                   -- winsock.h:473
  pragma Convention( C, SYSTEMTIME1 );                -- winbase.h:213
  pragma Convention( C, WSADATA );                    -- winsock.h:328

end ExecItf;

