unit DelphiLensUI.IPC.Client;

interface

uses
  DelphiLensUI.IPC.Intf;

function CreateIPClient: IDLUIIPCClient;

implementation

uses
  System.SysUtils, System.Classes,
  Vcl.Forms,
  Cromis.Comm.Custom, Cromis.Comm.IPC,
  DelphiLensUI.Error;

type
  TDLUIIPCClient = class(TInterfacedObject, IDLUIIPCClient)
  strict private
    FIPCClient: TIPCClient;
  strict protected
    function  CheckAnswer(var error: integer; var errMsg: string): boolean;
    function  CheckIfConnected(var error: integer; var errMsg: string): boolean;
    function  GetIsConnected: boolean;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Activate(monitorNum, projectID: integer; const fileName: string; line, column:
      integer; const tabNames: string; var navigateToFile: string; var navigateToLine,
      navigateToColumn: integer; var error: integer; var errMsg: string);
    procedure CloseProject(projectID: integer; var error: integer; var errMsg: string);
    procedure Connect(timeout_ms: integer; var serverFound, connected: boolean);
    procedure Disconnect;
    procedure FileModified(projectID: integer; const fileName: string; var error: integer;
      var errMsg: string);
    procedure OpenProject(const projectName: string; var projectID: integer;
      var error: integer; var errMsg: string);
    procedure ProjectModified(projectID: integer; var error: integer; var errMsg: string);
    procedure RescanProject(projectID: integer; var error: integer; var errMsg: string);
    procedure SetProjectConfig(projectID: integer; const platformName, conditionalDefines,
      searchPath: string; var error: integer; var errMsg: string);
    property IsConnected: boolean read GetIsConnected;
  end; { TDLUIIPCServer }

{ exports }

function CreateIPClient: IDLUIIPCClient;
begin
  Result := TDLUIIPCClient.Create;
end; { CreateIPClient }

{ TDLUIIPCClient }

constructor TDLUIIPCClient.Create;
begin
  inherited Create;
  FIPCClient := TIPCClient.Create;
  FIPCClient.ServerName := CDLUIIPCServerName;
end; { TDLUIIPCClient.Create }

destructor TDLUIIPCClient.Destroy;
begin
  Disconnect;
  FreeAndNil(FIPCClient);
  inherited;
end; { TDLUIIPCClient.Destroy }

procedure TDLUIIPCClient.Activate(monitorNum, projectID: integer; const fileName: string;
  line, column: integer; const tabNames: string; var navigateToFile: string;
  var navigateToLine, navigateToColumn: integer; var error: integer; var errMsg: string);
var
  request : IMessageData;
  response: IMessageData;
begin
  if not CheckIfConnected(error, errMsg) then
    Exit;

  request := AcquireMessageData;
  request.ID := CCmdActivate;
  request.Data.WriteInteger(CParamMonitorNum, monitorNum);
  request.Data.WriteInteger(CParamProjectID, projectID);
  request.Data.WriteString(CParamFileName, fileName);
  request.Data.WriteInteger(CParamLine, line);
  request.Data.WriteInteger(CParamColumn, column);
  request.Data.WriteString(CParamTabNames, tabNames);

  response := FIPCClient.ExecuteConnectedRequest(request);

  if not CheckAnswer(error, errMsg) then
    Exit;

  navigateToFile := response.Data.ReadString(CParamNavToFile);
  navigateToLine := response.Data.ReadInteger(CParamNavToLine);
  navigateToColumn := response.Data.ReadInteger(CParamNavToColumn);
  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.Activate }

function TDLUIIPCClient.CheckAnswer(var error: integer; var errMsg: string): boolean;
begin
  Result := FIPCClient.AnswerValid;
  if Result then begin
    error := 0;
    errMsg := '';
  end
  else begin
    error := FIPCClient.LastError;
    errMsg := FIPCClient.ErrorDesc;
  end;
end; { TDLUIIPCClient.CheckAnswer }

function TDLUIIPCClient.CheckIfConnected(var error: integer; var errMsg: string): boolean;
begin
  Result := IsConnected;
  if Result then begin
    error := 0;
    errMsg := '';
  end
  else begin
    error := ERR_NOT_CONNECTED;
    errMsg := 'Not connected to IPC server';
  end;
end; { TDLUIIPCClient.CheckIfConnected }

procedure TDLUIIPCClient.CloseProject(projectID: integer; var error: integer;
  var errMsg: string);
var
  request : IMessageData;
  response: IMessageData;
begin
  projectID := 0;
  if not CheckIfConnected(error, errMsg) then
    Exit;

  request := AcquireMessageData;
  request.ID := CCmdCloseProject;
  request.Data.WriteInteger(CParamProjectID, projectID);

  response := FIPCClient.ExecuteConnectedRequest(request);

  if not CheckAnswer(error, errMsg) then
    Exit;

  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.CloseProject }

procedure TDLUIIPCClient.Connect(timeout_ms: integer; var serverFound, connected: boolean);
begin
  FIPCClient.ConnectClient(timeout_ms);
  serverFound := FIPCClient.HasServer;
  connected := FIPCClient.IsConnected;
end; { TDLUIIPCClient.Connect }

procedure TDLUIIPCClient.Disconnect;
begin
  if IsConnected then
    FIPCClient.DisconnectClient;
end; { TDLUIIPCClient.Disconnect }

procedure TDLUIIPCClient.FileModified(projectID: integer; const fileName: string;
  var error: integer; var errMsg: string);
var
  request : IMessageData;
  response: IMessageData;
begin
  if not CheckIfConnected(error, errMsg) then
    Exit;

  request := AcquireMessageData;
  request.ID := CCmdFileModified;
  request.Data.WriteInteger(CParamProjectID, projectID);
  request.Data.WriteString(CParamFileName, fileName);

  response := FIPCClient.ExecuteConnectedRequest(request);

  if not CheckAnswer(error, errMsg) then
    Exit;

  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.FileModified }

function TDLUIIPCClient.GetIsConnected: boolean;
begin
  Result := assigned(FIPCClient) and FIPCClient.IsConnected;
end; { TDLUIIPCClient.GetIsConnected }

procedure TDLUIIPCClient.OpenProject(const projectName: string; var projectID: integer;
  var error: integer; var errMsg: string);
var
  request : IMessageData;
  response: IMessageData;
begin
  projectID := 0;
  if not CheckIfConnected(error, errMsg) then
    Exit;

  request := AcquireMessageData;
  request.ID := CCmdOpenProject;
  request.Data.WriteString(CParamProjectName, projectName);

  response := FIPCClient.ExecuteConnectedRequest(request);

  if not CheckAnswer(error, errMsg) then
    Exit;

  projectID := response.Data.ReadInteger(CParamProjectID);
  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.OpenProject }

procedure TDLUIIPCClient.ProjectModified(projectID: integer; var error: integer;
  var errMsg: string);
var
  request : IMessageData;
  response: IMessageData;
begin
  if not CheckIfConnected(error, errMsg) then
    Exit;

  request := AcquireMessageData;
  request.ID := CCmdProjectModified;
  request.Data.WriteInteger(CParamProjectID, projectID);

  response := FIPCClient.ExecuteConnectedRequest(request);

  if not CheckAnswer(error, errMsg) then
    Exit;

  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.ProjectModified }

procedure TDLUIIPCClient.RescanProject(projectID: integer; var error: integer;
  var errMsg: string);
var
  request : IMessageData;
  response: IMessageData;
begin
  if not CheckIfConnected(error, errMsg) then
    Exit;

  request := AcquireMessageData;
  request.ID := CCmdRescanProject;
  request.Data.WriteInteger(CParamProjectID, projectID);

  response := FIPCClient.ExecuteConnectedRequest(request);

  if not CheckAnswer(error, errMsg) then
    Exit;

  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.RescanProject }

procedure TDLUIIPCClient.SetProjectConfig(projectID: integer; const platformName,
  conditionalDefines, searchPath: string; var error: integer; var errMsg: string);
var
  request : IMessageData;
  response: IMessageData;
begin
  if not CheckIfConnected(error, errMsg) then
    Exit;

  request := AcquireMessageData;
  request.ID := CCmdSetProjectConfig;
  request.Data.WriteInteger(CParamProjectID, projectID);
  request.Data.WriteString(CParamPlatformName, platformName);
  request.Data.WriteString(CParamConditionals, conditionalDefines);
  request.Data.WriteString(CParamSearchPath, searchPath);

  response := FIPCClient.ExecuteConnectedRequest(request);

  if not CheckAnswer(error, errMsg) then
    Exit;

  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.SetProjectConfig }

end.
