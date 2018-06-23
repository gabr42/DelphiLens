unit DelphiLensUI.IPC.Server;

interface

uses
  DelphiLensUI.IPC.Intf;

function CreateIPCServer: IDLUIIPCServer;

implementation

uses
  System.SysUtils, System.Classes,
  Vcl.Forms,
  Cromis.Comm.Custom, Cromis.Comm.IPC;

type
  TDLUIIPCServer = class(TInterfacedObject, IDLUIIPCServer)
  strict private
    FIPCServer   : TIPCServer;
    FStarting    : boolean;
    FStartupError: string;
  strict protected
    FOnError: TProc<string>;
    procedure CreateIPCServer;
    function  GetOnError: TProc<string>;
    procedure HandleExecuteRequest(const context: ICommContext; const request, response:
      IMessageData);
    procedure HandleServerError(const context: ICommContext; const error: TServerError);
    procedure SetOnError(const value: TProc<string>);
  public
    destructor Destroy; override;
    function  Start: string;
    procedure Stop;
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
  FIPCServer := TIPCServer.Create;
  FIPCServer.ServerName := CDLUIIPCServerName;
  FIPCServer.OnServerError := HandleServerError;
//    property OnClientConnect: TOnClientEvent read FOnClientConnect write FOnClientConnect;
//    property CommClientClass: TCommClientClass read FCommClientClass write FCommClientClass;
  FIPCServer.OnExecuteRequest := HandleExecuteRequest;
//    property OnClientDisconnect: TOnClientEvent read FOnClientDisconnect write FOnClientDisconnect;
end; { TDLUIIPCServer.CreateIPCServer }

function TDLUIIPCServer.GetOnError: TProc<string>;
begin
  Result := FOnError;
end; { TDLUIIPCServer.GetOnError }

procedure TDLUIIPCServer.HandleExecuteRequest(const context: ICommContext; const request,
  response: IMessageData);
begin
  // ...
end; { TDLUIIPCServer.HandleExecuteRequest }

procedure TDLUIIPCServer.HandleServerError(const context: ICommContext;
  const error: TServerError);
var
  errMsg: string;
begin
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

procedure TDLUIIPCServer.SetOnError(const value: TProc<string>);
begin
  FOnError := value;
end; { TDLUIIPCServer.GetOnError }

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
