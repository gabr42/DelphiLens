unit DelphiLensUI.DLLExports;

interface

uses
  DelphiLensUI.Error;

type
  TDLLogger = procedure (projectID: integer; const msg: PChar); stdcall;

procedure DLUIInitialize;
procedure DLUIFinalize;

procedure DLUISetLogHook(const hook: TDLLogger); stdcall;

/// After DLUIOpenProject caller should next call DLUISetProjectConfig followed by DLUIRescanProject.

function  DLUIOpenProject(const projectName: PChar; var projectID: integer): integer; stdcall;
function  DLUISetProjectConfig(projectID: integer; platformName,
            conditionalDefines, searchPath: PChar): integer; stdcall;
function  DLUIRescanProject(projectID: integer): integer; stdcall;

function  DLUIProjectModified(projectID: integer): integer; stdcall;
function  DLUIFileModified(projectID: integer; fileName: PChar): integer; stdcall;

function  DLUICloseProject(projectID: integer): integer; stdcall;

function  DLUIGetLastError(projectID: integer; var errorMsg: PChar): integer; stdcall;

function  DLUIActivate(monitorNum, projectID: integer; fileName: PChar;
  line, column: integer; tabNames: PChar; var navigateToFile: PChar;
  var navigateToLine, navigateToColumn: integer): integer; stdcall;

implementation

uses
  Vcl.Dialogs,
  Winapi.Windows,
  System.SysUtils, System.Generics.Collections,
  DSiWin32,
  OtlSync, OtlCommon,
  DelphiLensUI.Worker,
  DelphiLensUI.IPC.Intf,
  DelphiLensUI.IPC.Client;

type
  TErrorInfo = TPair<integer, string>;

var
  GDLEngineErrors: TDictionary<integer, TErrorInfo>;
  GDLErrorLock   : TOmniCS;
  GDLIPCClient   : IDLUIIPCClient;

function CheckClient(var error: integer): boolean;
begin
  Result := assigned(GDLIPCClient) and GDLIPCClient.IsConnected;
  if Result then
    error := NO_ERROR
  else
    error := ERR_NOT_CONNECTED;
end; { CheckClient }

function SetError(projectID: integer; error: integer; const errorMsg: string): integer; overload;
begin
  GDLErrorLock.Acquire;
  try
    GDLEngineErrors.AddOrSetValue(projectID, TErrorInfo.Create(error, errorMsg));
  finally GDLErrorLock.Release; end;
  Result := error;
end; { SetError }

function SetError(projectID: integer; error: integer; const errorMsg: string;
  const params: array of const): integer; overload;
begin
  Result := SetError(projectID, error, Format(errorMsg, params));
end; { SetError }

function ClearError(projectID: integer): integer; inline;
begin
  Result := SetError(projectID, NO_ERROR, '');
end; { ClearError }

function DLUIGetLastError(projectID: integer; var errorMsg: PChar): integer;
var
  errorInfo: TErrorInfo;
begin
  try
    GDLErrorLock.Acquire;
    try
      if not GDLEngineErrors.TryGetValue(projectID, errorInfo) then
        Result := NO_ERROR
      else begin
        errorMsg := PChar(errorInfo.Value);
        Result := errorInfo.Key;
      end;
    finally GDLErrorLock.Release; end;
  except
    on E: Exception do begin
      // Throwing memory away, but this should not happen anyway
      errorMsg := StrNew(PChar('Exception in DLUIGetLastError: ' + E.Message + ' '));
      Result := ERR_INTERNAL_ERROR;
    end;
  end;
end; { DLUIGetLastError }

function DLUIOpenProject(const projectName: PChar; var projectID: integer): integer;
var
  errMsg: string;
  error : integer;
begin
  projectID := 0;
  if not CheckClient(Result) then
    Exit;

  Result := ClearError(projectID);
  try
    GDLIPCClient.OpenProject(projectName, projectID, error, errMsg);
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIOpenProject }

function DLUICloseProject(projectID: integer): integer;
var
  errMsg: string;
  error : integer;
begin
  projectID := 0;
  if not CheckClient(Result) then
    Exit;

  Result := ClearError(projectID);
  try
    GDLIPCClient.CloseProject(projectID, error, errMsg);
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUICloseProject }

function DLUIProjectModified(projectID: integer): integer;
var
  project: TDelphiLensUIProject;
begin
  Result := ClearError(projectID);
  try
//    if not GetProject(projectID, project) then
//      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
//    else
//      project.ProjectModified;
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIProjectModified }

function DLUIFileModified(projectID: integer; fileName: PChar): integer;
var
  project: TDelphiLensUIProject;
begin
  Result := ClearError(projectID);
  try
//    if not GetProject(projectID, project) then
//      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
//    else
//      project.FileModified(fileName);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIFileModified }

function DLUIRescanProject(projectID: integer): integer;
var
  project: TDelphiLensUIProject;
begin
  Result := ClearError(projectID);
  try
//    if not GetProject(projectID, project) then
//      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
//    else
//      project.Rescan;
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIRescanPRoject }

function DLUISetProjectConfig(projectID: integer; platformName, conditionalDefines,
  searchPath: PChar): integer;
var
  project: TDelphiLensUIProject;
begin
  Result := ClearError(projectID);
  try
//    if not GetProject(projectID, project) then
//      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
//    else
//      project.SetConfig(TDLUIProjectConfig.Create(platformName, conditionalDefines, searchPath));
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUISetProjectConfig }

function DLUIActivate(monitorNum, projectID: integer; fileName: PChar; line, column: integer;
  tabNames: PChar; var navigateToFile: PChar; var navigateToLine,
  navigateToColumn: integer): integer;
var
  project : TDelphiLensUIProject;
  navigate: boolean;
begin
  Result := ClearError(projectID);
  try
//    if not GetProject(projectID, project) then begin
//      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID]);
//    end
//    else begin
//      project.Activate(monitorNum, fileName, line, column, tabNames, navigate);
//      if not navigate then
//        navigateToFile := nil
//      else begin
//        navigateToFile := project.GetNavigationInfo.FileName;
//        navigateToLine := project.GetNavigationInfo.Line;
//        navigateToColumn := project.GetNavigationInfo.Column;
//      end;
//    end;
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message );
  end;
end; { DLUIActivate }

procedure DLUIInitialize;
var
  conn  : boolean;
  hasSrv: boolean;
begin
  GDLEngineErrors := TDictionary<integer, TErrorInfo>.Create;
  GDLErrorLock.Initialize;

  GDLIPCClient := CreateIPClient;
  GDLIPCClient.Connect(5000, hasSrv, conn);
  if not hasSrv then begin
    if DSiExecute('DelphiLensUI.exe') = MaxInt then
      ShowMessage('Failed to execute DelphiLensUI.exe');
    GDLIPCClient.Connect(5000, hasSrv, conn);
  end;
  if not hasSrv then
    ShowMessage('Failed to start DelphiLensUI.exe')
  else if not conn then
    ShowMessage('Failed to connect to DelphiLensUI.exe');
end; { DLUIInitialize }

procedure DLUIFinalize;
begin
  if assigned(GDLIPCClient) then begin
    GDLIPCClient.Disconnect;
    GDLIPCClient := nil;
  end;
  FreeAndNil(GDLEngineErrors);
end; { DLUIFinalize }

procedure DLUISetLogHook(const hook:  TDLLogger);
begin
  GLogHook := hook;
end; { DLUISetLogHook }

end.
