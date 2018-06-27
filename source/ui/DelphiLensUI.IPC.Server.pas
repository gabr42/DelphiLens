unit DelphiLensUI.IPC.Server;

interface

uses
  DelphiLensUI.IPC.Intf;

function CreateIPCServer: IDLUIIPCServer;

implementation

uses
  System.SysUtils, System.Classes,
  Vcl.Forms,
  Winapi.Windows,
  Cromis.Comm.Custom, Cromis.Comm.IPC;

type
  TDLUIIPCServer = class(TInterfacedObject, IDLUIIPCServer)
  strict private
    FIPCServer           : TIPCServer;
    FOnClientConnected   : TProc;
    FOnClientDisconnected: TProc;
    FOnError             : TProc<string>;
    FOnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent;
    FStarting            : boolean;
    FStartupError        : string;
  strict protected
    procedure CreateIPCServer;
    procedure ExecuteOpenProject(const request, response: IMessageData);
    function  GetOnClientConnected: TProc;
    function  GetOnClientDisconnected: TProc;
    function  GetOnError: TProc<string>;
    function  GetOnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent;
    procedure HandleClientConnect(const context: ICommContext);
    procedure HandleClientDisconnect(const context: ICommContext);
    procedure HandleExecuteRequest(const context: ICommContext; const request, response:
      IMessageData);
    procedure HandleServerError(const context: ICommContext; const error: TServerError);
    procedure SetOnClientConnected(const value: TProc);
    procedure SetOnClientDisconnected(const value: TProc);
    procedure SetOnError(const value: TProc<string>);
    procedure SetOnExecuteOpenProject(const value: TDLUIIPCServerExecuteOpenProjectEvent);
  public
    destructor Destroy; override;
    function  Start: string;
    procedure Stop;
    property OnClientConnected: TProc read GetOnClientConnected write SetOnClientConnected;
    property OnClientDisconnected: TProc read GetOnClientDisconnected write
      SetOnClientDisconnected;
    property OnError: TProc<string> read GetOnError write SetOnError;
    property OnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent read
      GetOnExecuteOpenProject write SetOnExecuteOpenProject;
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
  FIPCServer := TIPCServer.Create;
  FIPCServer.ServerName := CDLUIIPCServerName;
  FIPCServer.OnServerError := HandleServerError;
  FIPCServer.OnClientConnect := HandleClientConnect;
  FIPCServer.OnClientDisconnect := HandleClientDisconnect;
//    property CommClientClass: TCommClientClass read FCommClientClass write FCommClientClass;
  FIPCServer.OnExecuteRequest := HandleExecuteRequest;
end; { TDLUIIPCServer.CreateIPCServer }

procedure TDLUIIPCServer.ExecuteOpenProject(const request, response: IMessageData);
var
  errMsg   : string;
  error    : integer;
  projectID: integer;
begin
  error := NO_ERROR;
  errMsg := '';
  OnExecuteOpenProject(request.Data.ReadString(CParamProjectName), projectID, error, errMsg);
  response.Data.WriteInteger(CParamProjectID, projectID);
  response.Data.WriteInteger(CParamError, error);
  response.Data.WriteString(CParamErrMsg, errMsg);
end; { TDLUIIPCServer.ExecuteOpenProject }

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

function TDLUIIPCServer.GetOnExecuteOpenProject: TDLUIIPCServerExecuteOpenProjectEvent;
begin
  Result := FOnExecuteOpenProject;
end; { TDLUIIPCServer.GetOnExecuteOpenProject }

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
begin
  if request.ID = CCmdOpenClient then
    ExecuteOpenProject(request, response);
end; { TDLUIIPCServer.HandleExecuteRequest }

procedure TDLUIIPCServer.HandleServerError(const context: ICommContext;
  const error: TServerError);
var
  errMsg: string;
begin
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

procedure TDLUIIPCServer.SetOnExecuteOpenProject(const value:
  TDLUIIPCServerExecuteOpenProjectEvent);
begin
  FOnExecuteOpenProject := value;
end; { TDLUIIPCServer.SetOnExecuteOpenProject }

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
end; { TDLUIIPCServer.Stop }

end.
