
with Itf;

package Configuration is

  MaxApplications
  -- Maximum allowed number of allowed applications
  : constant Integer := 4;


  type Computer_Name_Length_Type
  -- Range of characters allowed for a computer name
  is range 0..20;

  type Computer_Name_Type
  -- Name of the computer running the application for the connection
  is record
    Length : Computer_Name_Length_Type;
    -- Number of characters in the name
    Name   : String(1..Integer(Computer_Name_Length_Type'last));
    -- NetBIOS name of the computer
  end record;

  type ConfigurationDataType
  is record
    App        : Itf.ApplicationIdType;  -- name and id
    CommMethod : Itf.CommMethodType;     -- communication method
    ComputerId : Computer_Name_Type;     -- expected computer identifier
    AppPath    : Itf.V_Long_String_Type; -- path to application executable
    Connected  : Boolean;                -- true if connected to the remote app
  end record;

  type ConfigurationDataArrayType
  is array (1..MaxApplications) of ConfigurationDataType;

  type ConfigurationTableType
  is record
    Count : Integer; -- Number of declared applications
    List  : ConfigurationDataArrayType;
  end record;

  ConfigurationTable
  --| Information about the hosted function applications of the configuration
  --| Notes:
  --|   The values in the table will be overridden by those of the
  --|   Apps-Configuration.dat file.  These are only SAMPLES.
  : ConfigurationTableType
  := ( Count => 1,
       List  => ( 1 => ( App        => ( Name => "App 1     ",
                                         Id   => 1 ),
                         CommMethod => Itf.NONE,
                         ComputerId => ( Length => 0,
                                         Name   => ( others => ' ' ) ),
                         AppPath    => ( Count => 0,
                                         Data  => ( others => ' ' ) ),
                         Connected  => False ),

                  others => ( App        => ( Name => ( others => ' ' ),
                                              Id   => 0 ),
                              CommMethod => Itf.NONE,
                              ComputerId => ( Length => 0,
                                              Name   => ( others => ' ' ) ),
                              AppPath    => ( Count => 0,
                                              Data  => ( others => ' ' ) ),
                              Connected  => False ) )
     );

  procedure Initialize;


end Configuration;

