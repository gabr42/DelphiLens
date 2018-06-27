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
    procedure CloseProject(var projectID: integer; var error: integer; var errMsg: string);
    procedure Connect(timeout_ms: integer; var serverFound, connected: boolean);
    procedure Disconnect;
    procedure OpenProject(const projectName: string; var projectID: integer;
      var error: integer; var errMsg: string);
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

procedure TDLUIIPCClient.CloseProject(var projectID: integer; var error: integer; var
  errMsg: string);
var
  messageData: IMessageData;
  response   : IMessageData;
begin
  projectID := 0;
  if not CheckIfConnected(error, errMsg) then
    Exit;

  messageData := AcquireMessageData;
  messageData.ID := CCmdCloseProject;
  messageData.Data.WriteInteger(CParamProjectID, projectID);

  response := FIPCClient.ExecuteConnectedRequest(messageData);

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

function TDLUIIPCClient.GetIsConnected: boolean;
begin
  Result := assigned(FIPCClient) and FIPCClient.IsConnected;
end; { TDLUIIPCClient.GetIsConnected }

procedure TDLUIIPCClient.OpenProject(const projectName: string; var projectID: integer;
  var error: integer; var errMsg: string);
var
  messageData: IMessageData;
  response   : IMessageData;
begin
  projectID := 0;
  if not CheckIfConnected(error, errMsg) then
    Exit;

  messageData := AcquireMessageData;
  messageData.ID := CCmdOpenProject;
  messageData.Data.WriteString(CParamProjectName, projectName);

  response := FIPCClient.ExecuteConnectedRequest(messageData);

  if not CheckAnswer(error, errMsg) then
    Exit;

  projectID := response.Data.ReadInteger(CParamProjectID);
  error := response.Data.ReadInteger(CParamError);
  errMsg := response.Data.ReadString(CParamErrMsg);
end; { TDLUIIPCClient.OpenProject }

end.
