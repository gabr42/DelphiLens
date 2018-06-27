unit DelphiLensUI.IPC.Intf;

interface

uses
  System.SysUtils;

const
  CDLUIIPCServerName = 'Gp\FDA8909F-3429-4824-A6C4-7196462F130C\DelphiLens\IPC\UI';

  CCmdOpenProject = 'OpenProject';
  CCmdCloseProject = 'CloseProject';

  CParamProjectName = 'ProjectName';
  CParamProjectID   = 'ProjectID';
  CParamError       = 'Error';
  CParamErrMsg      = 'ErrMsg';

type
  IDLUIIPCClient = interface ['{D9CAF801-6F7D-4A57-9A55-A4DEE10546B6}']
    function  GetIsConnected: boolean;
    //
    procedure Connect(timeout_ms: integer; var serverFound, connected: boolean);
    procedure Disconnect;
    procedure OpenProject(const projectName: string; var projectID: integer;
      var error: integer; var errMsg: string);
    procedure CloseProject(var projectID: integer;
      var error: integer; var errMsg: string);
    property IsConnected: boolean read GetIsConnected;
  end; { IDLUIIPCClient }

  TDLUIIPCServerExecuteOpenProjectEvent = reference to procedure(const projectName: string;
      var projectID: integer; var error: integer; var errMsg: string);
  TDLUIIPCServerExecuteCloseProjectEvent = reference to procedure(projectID : integer;
      var error: integer; var errMsg: string);

  IDLUIIPCServer = interface ['{492A8AD4-9656-43D4-80EE-E9BCD02B3B12}']
    function  GetOnClientConnected: TProc;
    function  GetOnClientDisconnected: TProc;
    function  GetOnError: TProc<string>;
    function  GetOnExecuteCloseProject: TDLUIIPCServerExecuteCloseProjectEvent;
    function  GetOnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent;
    procedure SetOnClientConnected(const Value: TProc);
    procedure SetOnClientDisconnected(const Value: TProc);
    procedure SetOnError(const Value: TProc<string>);
    procedure SetOnExecuteCloseProject(const value: TDLUIIPCServerExecuteCloseProjectEvent);
    procedure SetOnExecuteOpenProject(const value: TDLUIIPCServerExecuteOpenProjectEvent);
  //
    function  Start: string;
    procedure Stop;
    property OnClientConnected: TProc read GetOnClientConnected write SetOnClientConnected;
    property OnClientDisconnected: TProc read GetOnClientDisconnected write
      SetOnClientDisconnected;
    property OnError: TProc<string> read GetOnError write SetOnError;
    property OnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent read
      GetOnExecuteOpenProject write SetOnExecuteOpenProject;
    property OnExecuteCloseProject: TDLUIIPCServerExecuteCloseProjectEvent read
      GetOnExecuteCloseProject write SetOnExecuteCloseProject;
  end; { IDLUIIPCServer }

implementation

end.
