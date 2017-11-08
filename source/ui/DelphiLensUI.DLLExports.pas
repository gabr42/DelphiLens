unit DelphiLensUI.DLLExports;

interface

uses
  DelphiLensUI.Error;

procedure DLUIInitialize;
procedure DLUIFinalize;

/// After DLUIOpenProject caller should next call DLUISetProjectConfig followed by DLUIRescanProject.

function  DLUIOpenProject(const projectName: PChar; var projectID: integer): integer; stdcall;
function  DLUISetProjectConfig(projectID: integer; platformName,
            conditionalDefines, searchPath: PChar): integer; stdcall;
function  DLUIRescanProject(projectID: integer): integer; stdcall;

function  DLUIProjectModified(projectID: integer): integer; stdcall;
function  DLUIFileModified(projectID: integer; fileName: PChar): integer; stdcall;

function  DLUICloseProject(projectID: integer): integer; stdcall;

function  DLUIGetLastError(projectID: integer; var errorMsg: PChar): integer; stdcall;

function  DLUIActivate(projectID: integer; fileName: PChar; line, column: integer): integer; stdcall;

implementation

uses
  Winapi.Windows,
  System.SysUtils, System.Generics.Collections,
  OtlSync, OtlCommon,
  DelphiLensUI.Worker;

type
  TErrorInfo = TPair<integer,string>;

var
  GDLEngineWorkers: TObjectDictionary<integer, TDelphiLensUIProject>;
  GDLEngineErrors : TDictionary<integer, TErrorInfo>;
  GDLEngineID     : TOmniAlignedInt32;
  GDLWorkerLock   : TOmniCS;
  GDLErrorLock    : TOmniCS;

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
  Result := SetError(projectiD, NO_ERROR, '');
end; { ClearError }

function GetProject(projectID: integer; var project: TDelphiLensUIProject): boolean;
begin
  GDLWorkerLock.Acquire;
  try
    Result := GDLEngineWorkers.TryGetValue(projectID, project);
  finally GDLWorkerLock.Release; end;
end; { GetProject }

function DLUIGetLastError(projectID: integer; var errorMsg: PChar): integer; stdcall;
var
  errorInfo: TErrorInfo;
begin
  GDLErrorLock.Acquire;
  try
    if not GDLEngineErrors.TryGetValue(projectID, errorInfo) then
      Result := NO_ERROR
    else begin
      errorMsg := PChar(errorInfo.Value);
      Result := errorInfo.Key;
    end;
  finally GDLErrorLock.Release; end;
end; { DLUIGetLastError }

function DLUIOpenProject(const projectName: PChar; var projectID: integer): integer;
var
  project: TDelphiLensUIProject;
begin
  Result := ClearError(projectID);
  try
    projectID := GDLEngineID.Increment;
    project := TDelphiLensUIProject.Create(projectName);
    GDLWorkerLock.Acquire;
    try
      GDLEngineWorkers.Add(projectID, project);
    finally GDLWorkerLock.Release; end;
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIOpenProject }

function DLUICloseProject(projectID: integer): integer;
var
  project: TDelphiLensUIProject;
begin
  Result := ClearError(projectID);
  try
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else begin
      GDLWorkerLock.Acquire;
      try
        GDLEngineWorkers.Remove(projectID);
      finally GDLWorkerLock.Release; end;
    end;
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
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else
      project.ProjectModified;
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
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else
      project.FileModified(fileName);
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
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else
      project.Rescan;
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
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else
      project.SetConfig(TDLUIProjectConfig.Create(platformName, conditionalDefines, searchPath));
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUISetProjectConfig }

function DLUIActivate(projectID: integer; fileName: PChar; line, column: integer): integer;
var
  project: TDelphiLensUIProject;
begin
  Result := ClearError(projectID);
  try
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else
      project.Activate(fileName, line, column);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIActivate }

procedure DLUIInitialize;
begin
  GDLEngineID.Value := 0;
  GDLEngineWorkers := TObjectDictionary<integer, TDelphiLensUIProject>.Create([doOwnsValues]);
  GDLEngineErrors := TDictionary<integer, TErrorInfo>.Create;
  GDLWorkerLock.Initialize;
  GDLErrorLock.Initialize;
end; { DLUIInitialize }

procedure DLUIFinalize;
begin
  FreeAndNil(GDLEngineWorkers);
  FreeAndNil(GDLEngineErrors);
end; { DLUIFinalize }

end.
