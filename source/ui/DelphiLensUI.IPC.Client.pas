unit DelphiLensUI.IPC.Client;

interface

uses
  DelphiLensUI.IPC.Intf;

function CreateIPClient: IDLUIIPCClient;

implementation

uses
  System.SysUtils, System.Classes,
  Vcl.Forms,
  Cromis.Comm.Custom, Cromis.Comm.IPC;

type
  TDLUIIPCClient = class(TInterfacedObject, IDLUIIPCClient)
  strict private
    FIPCClient: TIPCClient;
  strict protected
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Connect(timeout_ms: integer; var serverFound, connected: boolean);
  end; { TDLUIIPCServer }

{ exports }

{ TDLUIIPCClient }

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
  FreeAndNil(FIPCClient);
  inherited;
end; { TDLUIIPCClient.Destroy }

procedure TDLUIIPCClient.Connect(timeout_ms: integer; var serverFound, connected: boolean);
begin
  FIPCClient.ConnectClient(timeout_ms);
  serverFound := FIPCClient.HasServer;
  connected := FIPCClient.IsConnected;
end; { TDLUIIPCClient.Connect }

end.
