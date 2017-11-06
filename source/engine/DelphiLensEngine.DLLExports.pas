unit DelphiLensEngine.DLLExports;

interface

const
  NO_ERROR              = 0;
  ERR_EXCEPTION         = 1;
  ERR_PROJECT_NOT_FOUND = 2;

procedure DLEInitialize;
procedure DLEFinalize;

/// After DLEOpenProject caller should next call DLESetProjectConfig followed by DLERescanProject.

function  DLEOpenProject(const projectName: PChar; var projectID: integer): integer; stdcall;
function  DLESetProjectConfig(projectID: integer; platform,
            searchPath, libraryPath: PChar): integer; stdcall;
function  DLERescanProject(projectID: integer): integer; stdcall;

function  DLEProjectModified(projectID: integer): integer; stdcall;
function  DLEFileModified(projectID: integer; const fileName: PChar): integer; stdcall;

function  DLECloseProject(projectID: integer): integer; stdcall;



function  DLEGetLastError(projectID: integer; var errorMsg: PChar): integer; stdcall;

implementation

uses
  Winapi.Windows,
  System.SysUtils, System.Generics.Collections,
  OtlSync, OtlCommon,
  DelphiLensEngine.Worker;

type
  TErrorInfo = TPair<integer,string>;

var
  GDLEngineWorkers: TObjectDictionary<integer, TDelphiLensEngineProject>;
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

function GetProject(projectID: integer; var project: TDelphiLensEngineProject): boolean;
begin
  GDLWorkerLock.Acquire;
  try
    Result := GDLEngineWorkers.TryGetValue(projectID, project);
  finally GDLWorkerLock.Release; end;
end; { GetProject }

function DLEOpenProject(const projectName: PChar; var projectID: integer): integer;
var
  project: TDelphiLensEngineProject;
begin
  Result := ClearError(projectID);
  try
    projectID := GDLEngineID.Increment;
    project := TDelphiLensEngineProject.Create(string(projectName));
    GDLWorkerLock.Acquire;
    try
      GDLEngineWorkers.Add(projectID, project);
    finally GDLWorkerLock.Release; end;
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLEOpenProject }

function DLECloseProject(projectID: integer): integer;
var
  project: TDelphiLensEngineProject;
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
end; { DLECloseProject }

function DLEProjectModified(projectID: integer): integer;
var
  project: TDelphiLensEngineProject;
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
end; { DLEProjectModified }

function DLEFileModified(projectID: integer; const fileName: PChar): integer;
var
  project: TDelphiLensEngineProject;
begin
  Result := ClearError(projectID);
  try
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else
      project.FileModified(string(fileName));
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLEFileModified }

function DLERescanProject(projectID: integer): integer;
var
  project: TDelphiLensEngineProject;
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
end; { DLERescanPRoject }

function DLESetProjectConfig(projectID: integer; platform, searchPath, libraryPath: PChar): integer;
var
  project: TDelphiLensEngineProject;
begin
  Result := ClearError(projectID);
  try
    if not GetProject(projectID, project) then
      Result := SetError(projectID, ERR_PROJECT_NOT_FOUND, 'Project %d is not open', [projectID])
    else
      project.SetConfig(TDLEProjectConfig.Create(string(platform), string(searchPath), string(libraryPath)));
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLESetProjectConfig }

procedure DLEInitialize;
begin
  GDLEngineID.Value := 0;
  GDLEngineWorkers := TObjectDictionary<integer, TDelphiLensEngineProject>.Create([doOwnsValues]);
  GDLEngineErrors := TDictionary<integer, TErrorInfo>.Create;
  GDLWorkerLock.Initialize;
  GDLErrorLock.Initialize;
end; { DLEInitialize }

procedure DLEFinalize;
begin
  FreeAndNil(GDLEngineWorkers);
  FreeAndNil(GDLEngineErrors);
end; { DLEFinalize }

function DLEGetLastError(projectID: integer; var errorMsg: PChar): integer; stdcall;
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
end; { DLEGetLastError }

end.
