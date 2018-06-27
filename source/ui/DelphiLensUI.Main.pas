unit DelphiLensUI.Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  OtlSync,
  DelphiLensUI.IPC.Intf,
  DelphiLensUI.Worker;

type
  TfrmMainHidden = class(TForm)
    tmrInitialWait: TTimer;
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure tmrInitialWaitTimer(Sender: TObject);
  strict private
    FIPCServer      : IDLUIIPCServer;
    FNumClients     : integer;
    FDLEngineID     : integer;
    FDLEngineWorkers: TObjectDictionary<integer, TDelphiLensUIProject>;
    FDLWorkerLock   : TOmniCS;
  strict protected
    procedure CreateIPCServer;
    procedure ExecuteOpenProject(const projectName: string; var projectID: integer;
      var error: integer; var errMsg: string);
  end; { TfrmMainHidden }

var
  frmMainHidden: TfrmMainHidden;

implementation

uses
  DelphiLensUI.Error,
  DelphiLensUI.IPC.Server;

{$R *.dfm}

procedure TfrmMainHidden.CreateIPCServer;
begin
  FIPCServer := DelphiLensUI.IPC.Server.CreateIPCServer;
  FIPCServer.OnClientConnected :=
    procedure
    begin
      Inc(FNumClients);
      tmrInitialWait.Enabled := false;
    end;
  FIPCServer.OnClientDisconnected :=
    procedure
    begin
      Dec(FNumClients);
      if FNumClients = 0 then
        TThread.ForceQueue(nil, procedure begin Close; end);
    end;
  FIPCServer.OnError :=
    procedure (msg: string)
    begin
      ShowMessage('IPC Server error: ' + msg);
    end;
  FIPCServer.OnExecuteOpenProject := ExecuteOpenProject;
end; { TfrmMainHidden.CreateIPCServer }

procedure TfrmMainHidden.ExecuteOpenProject(const projectName: string;
  var projectID: integer; var error: integer; var errMsg: string);
var
  project: TDelphiLensUIProject;
begin
  try
    Inc(FDLEngineID);
    projectID := FDLEngineID;
    project := TDelphiLensUIProject.Create(projectName, projectID);
    FDLWorkerLock.Acquire;
    try
      FDLEngineWorkers.Add(projectID, project);
    finally FDLWorkerLock.Release; end;
  except
    on E: Exception do begin
      error := ERR_EXCEPTION;
      errMsg := E.Message;
    end;
  end;
end; { TfrmMainHidden.ExecuteOpenProject }

procedure TfrmMainHidden.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if assigned(FIPCServer) then begin
    FIPCServer.Stop;
    FIPCServer := nil;
  end;
  CanClose := true;
end; { TfrmMainHidden.FormCloseQuery }

procedure TfrmMainHidden.FormCreate(Sender: TObject);
var
  err: string;
begin
  FDLEngineWorkers := TObjectDictionary<integer, TDelphiLensUIProject>.Create([doOwnsValues]);
  FDLWorkerLock.Initialize;

  CreateIPCServer;
  err := FIPCServer.Start;
  if err <> '' then begin
    ShowMessage('Failed to start IPC server!'#13#10#13#10 + err + #13#10#13#10'This application will now close.');
    Application.Terminate;
  end;
end; { TfrmMainHidden.FormCreate }

procedure TfrmMainHidden.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDLEngineWorkers);
end; { TfrmMainHidden.FormDestroy }

procedure TfrmMainHidden.tmrInitialWaitTimer(Sender: TObject);
begin
  Close;
end; { TfrmMainHidden.tmrInitialWaitTimer }

end.
