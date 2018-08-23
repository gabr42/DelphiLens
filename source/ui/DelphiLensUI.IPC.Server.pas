unit DelphiLensUI.IPC.Server;

interface

uses
  DelphiLensUI.IPC.Intf;

function CreateIPCServer: IDLUIIPCServer;

implementation

uses
  GpConsole,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Forms,
  Winapi.Windows,
  Cromis.Comm.Custom, Cromis.Comm.IPC;

type
  TDLUIIPCServer = class(TInterfacedObject, IDLUIIPCServer)
  strict private type
    TIPCCommand = procedure (const request, response: IMessageData) of object;
  var
    FIPCCommands              : TDictionary<string, TIPCCommand>;
    FIPCServer                : TIPCServer;
    FOnClientConnected        : TProc;
    FOnClientDisconnected     : TProc;
    FOnError                  : TProc<string>;
    FOnExecuteActivate        : TDLUIIPCServerExecuteActivateEvent;
    FOnExecuteCloseProject    : TDLUIIPCServerExecuteCloseProjectEvent;
    FOnExecuteFileModified    : TDLUIIPCServerExecuteFileModifiedEvent;
    FOnExecuteOpenProject     : TDLUIIPCServerExecuteOpenProjectEvent;
    FOnExecuteProjectModified : TDLUIIPCServerExecuteProjectModifiedEvent;
    FOnExecuteRescanProject   : TDLUIIPCServerExecuteRescanProjectEvent;
    FOnExecuteSetProjectConfig: TDLUIIPCServerExecuteSetProjectConfigEvent;
    FStarting                 : boolean;
    FStartupError             : string;
  strict protected
    procedure CreateIPCServer;
    procedure ExecuteActivate(const request, response: IMessageData);
    procedure ExecuteCloseProject(const request, response: IMessageData);
    procedure ExecuteFileModified(const request, response: IMessageData);
    procedure ExecuteOpenProject(const request, response: IMessageData);
    procedure ExecuteProjectModified(const request, response: IMessageData);
    procedure ExecuteRescanProject(const request, response: IMessageData);
    procedure ExecuteSetProjectConfig(const request, response: IMessageData);
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
    procedure HandleClientConnect(const context: ICommContext);
    procedure HandleClientDisconnect(const context: ICommContext);
    procedure HandleExecuteRequest(const context: ICommContext; const request, response:
      IMessageData);
    procedure HandleServerError(const context: ICommContext; const error: TServerError);
    procedure SetOnClientConnected(const value: TProc);
    procedure SetOnClientDisconnected(const value: TProc);
    procedure SetOnError(const value: TProc<string>);
    procedure SetOnExecuteActivate(const value: TDLUIIPCServerExecuteActivateEvent);
    procedure SetOnExecuteCloseProject(const value: TDLUIIPCServerExecuteCloseProjectEvent);
    procedure SetOnExecuteFileModified(const value: TDLUIIPCServerExecuteFileModifiedEvent);
    procedure SetOnExecuteOpenProject(const value: TDLUIIPCServerExecuteOpenProjectEvent);
    procedure SetOnExecuteProjectModified(const value: TDLUIIPCServerExecuteProjectModifiedEvent);
    procedure SetOnExecuteRescanProject(const value: TDLUIIPCServerExecuteRescanProjectEvent);
    procedure SetOnExecuteSetProjectConfig(const value: TDLUIIPCServerExecuteSetProjectConfigEvent);
  public
    destructor Destroy; override;
    function  Start: string;
    procedure Stop;
    property OnClientConnected: TProc read GetOnClientConnected write SetOnClientConnected;
    property OnClientDisconnected: TProc read GetOnClientDisconnected write
      SetOnClientDisconnected;
    property OnError: TProc<string> read GetOnError write SetOnError;
  end; { TDLUIIPCServer }

{ exports }

function CreateIPCServer: IDLUIIPCServer;
begin
  Result := TDLUIIPCServer.Create;
end; { CreateIPCServer }

{ TDLUIIPCServer }

destructor TDLUIIPCServer.Destroy;
begin
  Stop;
  inherited;
end; { TDLUIIPCServer.Destroy }

procedure TDLUIIPCServer.CreateIPCServer;
begin
  FIPCCommands := TDictionary<string, TIPCCommand>.Create;
  FIPCCommands.Add(CCmdOpenProject, ExecuteOpenProject);
  FIPCCommands.Add(CCmdCloseProject, ExecuteCloseProject);
  FIPCCommands.Add(CCmdProjectModified, ExecuteProjectModified);
  FIPCCommands.Add(CCmdFileModified, ExecuteFileModified);
  FIPCCommands.Add(CCmdRescanProject, ExecuteRescanProject);
  FIPCCommands.Add(CCmdSetProjectConfig, ExecuteSetProjectConfig);
  FIPCCommands.Add(CCmdActivate, ExecuteActivate);

  FIPCServer := TIPCServer.Create;
  FIPCServer.ServerName := CDLUIIPCServerName;
  FIPCServer.OnServerError := HandleServerError;
  FIPCServer.OnClientConnect := HandleClientConnect;
  FIPCServer.OnClientDisconnect := HandleClientDisconnect;
//    property CommClientClass: TCommClientClass read FCommClientClass write FCommClientClass;
  FIPCServer.OnExecuteRequest := HandleExecuteRequest;
end; { TDLUIIPCServer.CreateIPCServer }

procedure TDLUIIPCServer.ExecuteActivate(const request, response: IMessageData);
var
  errMsg          : string;
  error           : integer;
  navigateToColumn: integer;
  navigateToFile  : string;
  navigateToLine  : integer;
begin
  error := NO_ERROR;
  errMsg := '';
  FOnExecuteActivate(
    request.Data.ReadInteger(CParamMonitorNum),
    request.Data.ReadInteger(CParamProjectID),
    request.Data.ReadString(CParamFileName),
    request.Data.ReadInteger(CParamLine),
    request.Data.ReadInteger(CParamColumn),
    request.Data.ReadString(CParamTabNames),
    navigateToFile, navigateToLine, navigateToColumn, error, errMsg);
  response.Data.WriteString(CParamNavToFile, navigateToFile);
  response.Data.WriteInteger(CParamNavToLine, navigateToLine);
  response.Data.WriteInteger(CParamNavToColumn, navigateToColumn);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteActivate }

procedure TDLUIIPCServer.ExecuteCloseProject(const request, response: IMessageData);
var
  errMsg: string;
  error : integer;
begin
  error := NO_ERROR;
  errMsg := '';
  FOnExecuteCloseProject(request.Data.ReadInteger(CParamProjectID), error, errMsg);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteCloseProject }

procedure TDLUIIPCServer.ExecuteFileModified(const request, response: IMessageData);
var
  errMsg: string;
  error : integer;
begin
  error := NO_ERROR;
  errMsg := '';
  FOnExecuteFileModified(
    request.Data.ReadInteger(CParamProjectID),
    request.Data.ReadString(CParamFileName), error, errMsg);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteFileModified }

procedure TDLUIIPCServer.ExecuteOpenProject(const request, response: IMessageData);
var
  errMsg   : string;
  error    : integer;
  projectID: integer;
begin
  error := NO_ERROR;
  errMsg := '';
  FOnExecuteOpenProject(request.Data.ReadString(CParamProjectName), projectID, error, errMsg);
  response.Data.WriteInteger(CParamProjectID, projectID);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteOpenProject }

procedure TDLUIIPCServer.ExecuteProjectModified(const request, response: IMessageData);
var
  errMsg: string;
  error : integer;
begin
  error := NO_ERROR;
  errMsg := '';
  FOnExecuteProjectModified(request.Data.ReadInteger(CParamProjectID), error, errMsg);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteProjectModified }

procedure TDLUIIPCServer.ExecuteRescanProject(const request, response: IMessageData);
var
  errMsg: string;
  error : integer;
begin
  error := NO_ERROR;
  errMsg := '';
  FOnExecuteRescanProject(request.Data.ReadInteger(CParamProjectID), error, errMsg);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteRescanProject }

procedure TDLUIIPCServer.ExecuteSetProjectConfig(const request, response: IMessageData);
var
  errMsg: string;
  error : integer;
begin
  error := NO_ERROR;
  errMsg := '';
  FOnExecuteSetProjectConfig(
    request.Data.ReadInteger(CParamProjectID),
    request.Data.ReadString(CParamPlatformName),
    request.Data.ReadString(CParamConditionals),
    request.Data.ReadString(CParamSearchPath),
    error, errMsg);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteSetProjectConfi g }

function TDLUIIPCServer.GetOnClientConnected: TProc;
begin
  Result := FOnClientConnected;
end; { TDLUIIPCServer.GetOnClientConnected }

function TDLUIIPCServer.GetOnClientDisconnected: TProc;
begin
  Result := FOnClientDisconnected;
end; { TDLUIIPCServer.GetOnClientDisconnected }

function TDLUIIPCServer.GetOnError: TProc<string>;
begin
  Result := FOnError;
end; { TDLUIIPCServer.GetOnError }

function TDLUIIPCServer.GetOnExecuteActivate: TDLUIIPCServerExecuteActivateEvent;
begin
  Result := FOnExecuteActivate;
end; { TDLUIIPCServer.GetOnExecuteActivate }

function TDLUIIPCServer.GetOnExecuteCloseProject: TDLUIIPCServerExecuteCloseProjectEvent;
begin
  Result := FOnExecuteCloseProject;
end; { TDLUIIPCServer.GetOnExecuteCloseProject }

function TDLUIIPCServer.GetOnExecuteFileModified: TDLUIIPCServerExecuteFileModifiedEvent;
begin
  Result := FOnExecuteFileModified;
end; { TDLUIIPCServer.GetOnExecuteFileModified }

function TDLUIIPCServer.GetOnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent;
begin
  Result := FOnExecuteOpenProject;
end; { TDLUIIPCServer.GetOnExecuteOpenProject }

function TDLUIIPCServer.GetOnExecuteProjectModified:
  TDLUIIPCServerExecuteProjectModifiedEvent;
begin
  Result := FOnExecuteProjectModified;
end; { TDLUIIPCServer.GetOnExecuteProjectModified }

function TDLUIIPCServer.GetOnExecuteRescanProject:
  TDLUIIPCServerExecuteRescanProjectEvent;
begin
  Result := FOnExecuteRescanProject;
end; { TDLUIIPCServer.GetOnExecuteRescanProject }

function TDLUIIPCServer.GetOnExecuteSetProjectConfig:
  TDLUIIPCServerExecuteSetProjectConfigEvent;
begin
  Result := FOnExecuteSetProjectConfig;
end; { TDLUIIPCServer.GetOnExecuteSetProjectConfig }

procedure TDLUIIPCServer.HandleClientConnect(const context: ICommContext);
begin
  if assigned(OnClientConnected) then
    OnClientConnected();
end; { TDLUIIPCServer.HandleClientConnect }

procedure TDLUIIPCServer.HandleClientDisconnect(const context: ICommContext);
begin
  if assigned(OnClientDisconnected) then
    OnClientDisconnected();
end; { TDLUIIPCServer.HandleClientDisconnect }

procedure TDLUIIPCServer.HandleExecuteRequest(const context: ICommContext; const request,
  response: IMessageData);
var
  command: TIPCCommand;
begin
  Console.Writeln(['SERVER execute request ', request.ID]);
  if FIPCCommands.TryGetValue(request.ID, command) then
    command(request, response);
end; { TDLUIIPCServer.HandleExecuteRequest }

procedure TDLUIIPCServer.HandleServerError(const context: ICommContext;
  const error: TServerError);
var
  errMsg: string;
begin
  Console.Writeln(['SERVER error ', error.Code]);

  if error.Code = ERROR_BROKEN_PIPE then // disconnected client
    Exit;

  errMsg := '[' + error.Code.ToString + '] ' + error.Desc;
  if FStarting then begin
    FStartupError := errMsg;
    FStarting := false;
  end
  else if assigned(OnError) then
    TThread.Queue(nil,
      procedure
      begin
        if assigned(OnError) then
          OnError(errMsg);
      end);
end; { TDLUIIPCServer.HandleServerError }

procedure TDLUIIPCServer.SetOnClientConnected(const value: TProc);
begin
  FOnClientConnected := value;
end; { TDLUIIPCServer.SetOnClientConnected }

procedure TDLUIIPCServer.SetOnClientDisconnected(const value: TProc);
begin
  FOnClientDisconnected := value;
end; { TDLUIIPCServer.SetOnClientDisconnected }

procedure TDLUIIPCServer.SetOnError(const value: TProc<string>);
begin
  FOnError := value;
end; { TDLUIIPCServer.GetOnError }

procedure TDLUIIPCServer.SetOnExecuteActivate(const value:
  TDLUIIPCServerExecuteActivateEvent);
begin
  FOnExecuteActivate := value;
end; { TDLUIIPCServer.SetOnExecuteActivate }

procedure TDLUIIPCServer.SetOnExecuteCloseProject(const value:
  TDLUIIPCServerExecuteCloseProjectEvent);
begin
  FOnExecuteCloseProject := value;
end; { TDLUIIPCServer.SetOnExecuteCloseProject }

procedure TDLUIIPCServer.SetOnExecuteFileModified(const value:
  TDLUIIPCServerExecuteFileModifiedEvent);
begin
  FOnExecuteFileModified := value;
end; { TDLUIIPCServer.SetOnExecuteFileModified }

procedure TDLUIIPCServer.SetOnExecuteOpenProject(const value:
  TDLUIIPCServerExecuteOpenProjectEvent);
begin
  FOnExecuteOpenProject := value;
end; { TDLUIIPCServer.SetOnExecuteOpenProject }

procedure TDLUIIPCServer.SetOnExecuteProjectModified(const value:
  TDLUIIPCServerExecuteProjectModifiedEvent);
begin
  FOnExecuteProjectModified := value;
end; { TDLUIIPCServer.SetOnExecuteProjectModified }

procedure TDLUIIPCServer.SetOnExecuteRescanProject(const value:
  TDLUIIPCServerExecuteRescanProjectEvent);
begin
  FOnExecuteRescanProject := value;
end; { TDLUIIPCServer.SetOnExecuteRescanProject }

procedure TDLUIIPCServer.SetOnExecuteSetProjectConfig(const value:
  TDLUIIPCServerExecuteSetProjectConfigEvent);
begin
  FOnExecuteSetProjectConfig := value;
end; { TDLUIIPCServer.SetOnExecuteSetProjectConfig }

function TDLUIIPCServer.Start: string;
begin
  Stop;
  CreateIPCServer;
  FStarting := true;
  if FIPCServer.Start then begin
    FStarting := false;
    Exit('');
  end;

  while FStarting do
    Application.ProcessMessages;

  Result := FStartupError;
  Stop;
end; { TDLUIIPCServer.Start }

procedure TDLUIIPCServer.Stop;
begin
  if assigned(FIPCServer) then begin
    FIPCServer.Stop;
    FreeAndNil(FIPCServer);
  end;
  FreeAndNil(FIPCCommands);
end; { TDLUIIPCServer.Stop }

end.
