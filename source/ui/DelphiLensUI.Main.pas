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
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrInitialWaitTimer(Sender: TObject);
  strict private
    FDLEngineID     : integer;
    FDLEngineWorkers: TObjectDictionary<integer, TDelphiLensUIProject>;
    FDLWorkerLock   : TOmniCS;
    FIPCServer      : IDLUIIPCServer;
    FNumClients     : integer;
  strict protected
    procedure CreateIPCServer;
    procedure ExecuteActivate(monitorNum, projectID: integer; const fileName: string;
      line, column: integer; const tabNames: string; var navigateToFile: string;
      var navigateToLine, navigateToColumn: integer;
      var error: integer; var errMsg: string);
    procedure ExecuteCloseProject(projectID: integer; var error: integer; var errMsg: string);
    procedure ExecuteFileModified(projectID: integer; const fileName: string;
      var error: integer; var errMsg: string);
    procedure ExecuteOpenProject(const projectName: string; var projectID: integer;
      var error: integer; var errMsg: string);
    procedure ExecuteProjectModified(projectID: integer; var error: integer; var errMsg:
      string);
    procedure ExecuteRescanProject(projectID: integer; var error: integer; var errMsg: string);
    procedure ExecuteSetProjectConfig(projectID: integer; const platformName,
      conditionalDefines, searchPath: string; var error: integer; var errMsg: string);
    function  GetProject(projectID: integer; var project: TDelphiLensUIProject): boolean;
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
  FIPCServer.OnExecuteCloseProject := ExecuteCloseProject;
  FIPCServer.OnExecuteProjectModified := ExecuteProjectModified;
  FIPCServer.OnExecuteFileModified := ExecuteFileModified;
  FIPCServer.OnExecuteRescanProject := ExecuteRescanProject;
  FIPCServer.OnExecuteSetProjectConfig := ExecuteSetProjectConfig;
  FIPCServer.OnExecuteActivate := ExecuteActivate;
end; { TfrmMainHidden.CreateIPCServer }

procedure TfrmMainHidden.ExecuteActivate(monitorNum, projectID: integer;
  const fileName: string; line, column: integer; const tabNames: string;
  var navigateToFile: string; var navigateToLine, navigateToColumn: integer;
  var error: integer; var errMsg: string);
var
  navigate: boolean;
  project : TDelphiLensUIProject;
begin
  try
    if not GetProject(projectID, project) then begin
      error := ERR_PROJECT_NOT_FOUND;
      errMsg := Format('Project %d is not open', [projectID]);
    end
    else begin
      project.Activate(monitorNum, fileName, line, column, tabNames, navigate);
      if not navigate then
        navigateToFile := ''
      else begin
        navigateToFile := project.GetNavigationInfo.FileName;
        navigateToLine := project.GetNavigationInfo.Line;
        navigateToColumn := project.GetNavigationInfo.Column;
      end;
    end;
  except
    on E: Exception do begin
      error := ERR_EXCEPTION;
      errMsg := E.Message;
    end;
  end;
end; { TfrmMainHidden.ExecuteActivate }

procedure TfrmMainHidden.ExecuteCloseProject(projectID: integer; var error: integer;
  var errMsg: string);
var
  project: TDelphiLensUIProject;
begin
  try
    if not GetProject(projectID, project) then begin
      error := ERR_PROJECT_NOT_FOUND;
      errMsg := Format('Project %d is not open', [projectID]);
    end
    else begin
      FDLWorkerLock.Acquire;
      try
        FDLEngineWorkers.Remove(projectID);
      finally FDLWorkerLock.Release; end;
    end;
  except
    on E: Exception do begin
      error := ERR_EXCEPTION;
      errMsg := E.Message;
    end;
  end;
end; { TfrmMainHidden.ExecuteCloseProject }

procedure TfrmMainHidden.ExecuteFileModified(projectID: integer; const fileName: string;
  var error: integer; var errMsg: string);
var
  project: TDelphiLensUIProject;
begin
  try
    if not GetProject(projectID, project) then begin
      error := ERR_PROJECT_NOT_FOUND;
      errMsg := Format('Project %d is not open', [projectID]);
    end
    else
      project.FileModified(fileName);
  except
    on E: Exception do begin
      error := ERR_EXCEPTION;
      errMsg := E.Message;
    end;
  end;
end; { TfrmMainHidden.ExecuteFileModified }

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

procedure TfrmMainHidden.ExecuteProjectModified(projectID: integer; var error: integer;
  var errMsg: string);
var
  project: TDelphiLensUIProject;
begin
  try
    if not GetProject(projectID, project) then begin
      error := ERR_PROJECT_NOT_FOUND;
      errMsg := Format('Project %d is not open', [projectID]);
    end
    else
      project.ProjectModified;
  except
    on E: Exception do begin
      error := ERR_EXCEPTION;
      errMsg := E.Message;
    end;
  end;
end; { TfrmMainHidden.ExecuteProjectModified }

procedure TfrmMainHidden.ExecuteRescanProject(projectID: integer; var error: integer; var
  errMsg: string);
var
  project: TDelphiLensUIProject;
begin
  try
    if not GetProject(projectID, project) then begin
      error := ERR_PROJECT_NOT_FOUND;
      errMsg := Format('Project %d is not open', [projectID]);
    end
    else
      project.Rescan;
  except
    on E: Exception do begin
      error := ERR_EXCEPTION;
      errMsg := E.Message;
    end;
  end;
end; { TfrmMainHidden.ExecuteRescanProject }

procedure TfrmMainHidden.ExecuteSetProjectConfig(projectID: integer; const platformName,
  conditionalDefines, searchPath: string; var error: integer; var errMsg: string);
var
  project: TDelphiLensUIProject;
begin
  try
    if not GetProject(projectID, project) then begin
      error := ERR_PROJECT_NOT_FOUND;
      errMsg := Format('Project %d is not open', [projectID]);
    end
    else
      project.SetConfig(TDLUIProjectConfig.Create(platformName, conditionalDefines, searchPath));
  except
    on E: Exception do begin
      error := ERR_EXCEPTION;
      errMsg := E.Message;
    end;
  end;
end; { TfrmMainHidden.ExecuteSetProjectConfig }

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

function TfrmMainHidden.GetProject(projectID: integer; var project:
  TDelphiLensUIProject): boolean;
begin
  FDLWorkerLock.Acquire;
  try
    Result := FDLEngineWorkers.TryGetValue(projectID, project);
  finally FDLWorkerLock.Release; end;
end; { TfrmMainHidden.GetProject }

procedure TfrmMainHidden.tmrInitialWaitTimer(Sender: TObject);
begin
  Close;
end; { TfrmMainHidden.tmrInitialWaitTimer }

end.
