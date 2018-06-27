unit DelphiLensUI.IPC.Intf;

interface

uses
  System.SysUtils;

const
  CDLUIIPCServerName = 'Gp\FDA8909F-3429-4824-A6C4-7196462F130C\DelphiLens\IPC\UI';

  CCmdActivate         = 'Activate';
  CCmdCloseProject     = 'CloseProject';
  CCmdFileModified     = 'FileModified';
  CCmdOpenProject      = 'OpenProject';
  CCmdProjectModified  = 'ProjectModified';
  CCmdRescanProject    = 'RescanProject';
  CCmdSetProjectConfig = 'SetProjectConfig';

  CParamColumn       = 'Column';
  CParamConditionals = 'ConditionalSymbols';
  CParamErrMsg       = 'ErrMsg';
  CParamError        = 'Error';
  CParamFileName     = 'FileName';
  CParamLine         = 'Line';
  CParamMonitorNum   = 'MonitorNum';
  CParamNavToColumn  = 'NavigateToColumn';
  CParamNavToFile    = 'NavigateToFile';
  CParamNavToLine    = 'NavigateToLine';
  CParamPlatformName = 'PlatformName';
  CParamProjectID    = 'ProjectID';
  CParamProjectName  = 'ProjectName';
  CParamSearchPath   = 'SearchPath';
  CParamTabNames     = 'TabNames';

type
  IDLUIIPCClient = interface ['{D9CAF801-6F7D-4A57-9A55-A4DEE10546B6}']
    function  GetIsConnected: boolean;
    //
    procedure Connect(timeout_ms: integer; var serverFound, connected: boolean);
    procedure Disconnect;
    procedure OpenProject(const projectName: string; var projectID: integer;
      var error: integer; var errMsg: string);
    procedure CloseProject(projectID: integer; var error: integer; var errMsg: string);
    procedure ProjectModified(projectID: integer; var error: integer; var errMsg: string);
    procedure FileModified(projectID: integer; const fileName: string;
      var error: integer; var errMsg: string);
    procedure RescanProject(projectID: integer; var error: integer; var errMsg: string);
    procedure SetProjectConfig(projectID: integer; const platformName, conditionalDefines,
      searchPath: string; var error: integer; var errMsg: string);
    procedure Activate(monitorNum, projectID: integer; const fileName: string;
      line, column: integer; const tabNames: string;
      var navigateToFile: string; var navigateToLine, navigateToColumn: integer;
      var error: integer; var errMsg: string);
    property IsConnected: boolean read GetIsConnected;
  end; { IDLUIIPCClient }

  TDLUIIPCServerExecuteOpenProjectEvent = reference to procedure(const projectName: string;
    var projectID: integer; var error: integer; var errMsg: string);
  TDLUIIPCServerExecuteCloseProjectEvent = reference to procedure(projectID : integer;
    var error: integer; var errMsg: string);
  TDLUIIPCServerExecuteProjectModifiedEvent = reference to procedure(projectID : integer;
    var error: integer; var errMsg: string);
  TDLUIIPCServerExecuteFileModifiedEvent = reference to procedure(projectID : integer;
    const fileName: string; var error: integer; var errMsg: string);
  TDLUIIPCServerExecuteRescanProjectEvent = reference to procedure(projectID : integer;
    var error: integer; var errMsg: string);
  TDLUIIPCServerExecuteSetProjectConfigEvent = reference to procedure(projectID : integer;
    const platformName, conditionalDefines, searchPath: string;
    var error: integer; var errMsg: string);
  TDLUIIPCServerExecuteActivateEvent = reference to procedure(
    monitorNum, projectID: integer; const fileName: string; line, column: integer;
    const tabNames: string; var navigateToFile: string;
    var navigateToLine, navigateToColumn: integer;
    var error: integer; var errMsg: string);

  IDLUIIPCServer = interface ['{492A8AD4-9656-43D4-80EE-E9BCD02B3B12}']
    function  GetOnClientConnected: TProc;
    function  GetOnClientDisconnected: TProc;
    function  GetOnError: TProc<string>;
    function  GetOnExecuteActivate: TDLUIIPCServerExecuteActivateEvent;
    function  GetOnExecuteCloseProject: TDLUIIPCServerExecuteCloseProjectEvent;
    function  GetOnExecuteFileModified: TDLUIIPCServerExecuteFileModifiedEvent;
    function  GetOnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent;
    function  GetOnExecuteProjectModified: TDLUIIPCServerExecuteProjectModifiedEvent;
    function  GetOnExecuteRescanProject: TDLUIIPCServerExecuteRescanProjectEvent;
    function  GetOnExecuteSetProjectConfig: TDLUIIPCServerExecuteSetProjectConfigEvent;
    procedure SetOnClientConnected(const Value: TProc);
    procedure SetOnClientDisconnected(const Value: TProc);
    procedure SetOnError(const value: TProc<string>);
    procedure SetOnExecuteActivate(const value: TDLUIIPCServerExecuteActivateEvent);
    procedure SetOnExecuteCloseProject(const value: TDLUIIPCServerExecuteCloseProjectEvent);
    procedure SetOnExecuteFileModified(const value: TDLUIIPCServerExecuteFileModifiedEvent);
    procedure SetOnExecuteOpenProject(const value: TDLUIIPCServerExecuteOpenProjectEvent);
    procedure SetOnExecuteProjectModified(const value: TDLUIIPCServerExecuteProjectModifiedEvent);
    procedure SetOnExecuteRescanProject(const value: TDLUIIPCServerExecuteRescanProjectEvent);
    procedure SetOnExecuteSetProjectConfig(const value: TDLUIIPCServerExecuteSetProjectConfigEvent);
  //
    function  Start: string;
    procedure Stop;
    property OnClientConnected: TProc read GetOnClientConnected write SetOnClientConnected;
    property OnClientDisconnected: TProc read GetOnClientDisconnected write
      SetOnClientDisconnected;
    property OnError: TProc<string> read GetOnError write SetOnError;
    property OnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent
      read GetOnExecuteOpenProject write SetOnExecuteOpenProject;
    property OnExecuteCloseProject: TDLUIIPCServerExecuteCloseProjectEvent
      read GetOnExecuteCloseProject write SetOnExecuteCloseProject;
    property OnExecuteProjectModified: TDLUIIPCServerExecuteProjectModifiedEvent
      read GetOnExecuteProjectModified write SetOnExecuteProjectModified;
    property OnExecuteFileModified: TDLUIIPCServerExecuteFileModifiedEvent
      read GetOnExecuteFileModified write SetOnExecuteFileModified;
    property OnExecuteRescanProject: TDLUIIPCServerExecuteRescanProjectEvent
      read GetOnExecuteRescanProject write SetOnExecuteRescanProject;
    property OnExecuteSetProjectConfig: TDLUIIPCServerExecuteSetProjectConfigEvent
      read GetOnExecuteSetProjectConfig write SetOnExecuteSetProjectConfig;
    property OnExecuteActivate: TDLUIIPCServerExecuteActivateEvent
      read GetOnExecuteActivate write SetOnExecuteActivate;
  end; { IDLUIIPCServer }

implementation

end.
