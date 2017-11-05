unit DelphiLensEngine.DLLExports;

interface

procedure DLEInitialize;
procedure DLEFinalize;

procedure DLEOpenProject(const projectName: PChar; var projectID: integer); stdcall;
procedure DLESetProjectConfig(projectID: integer; platform, searchPath, libraryPath: PChar); stdcall;
procedure DLECloseProject(projectID: integer); stdcall;

procedure DLEProjectModified(projectID: integer); stdcall;
procedure DLEFileModified(projectID: integer; const fileName: PChar); stdcall;

procedure DLERescanProject(projectID: integer); stdcall;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  OtlCommon,
  DelphiLensEngine.Worker;

var
  GDLEngineWorkers: TObjectDictionary<integer, TDelphiLensEngineProject>;
  GDLEngineID     : TOmniAlignedInt32;

procedure DLEOpenProject(const projectName: PChar; var projectID: integer);
var
  project: TDelphiLensEngineProject;
begin
  projectID := GDLEngineID.Increment;
  project := TDelphiLensEngineProject.Create(string(projectName));
  GDLEngineWorkers.Add(projectID, project);
end; { DLEOpenProject }

procedure DLECloseProject(projectID: integer);
var
  project: TDelphiLensEngineProject;
begin
  if not GDLEngineWorkers.TryGetValue(projectID, project) then
    // *** error handling
  else
    GDLEngineWorkers.Remove(projectID);
end; { DLECloseProject }

procedure DLEProjectModified(projectID: integer);
var
  project: TDelphiLensEngineProject;
begin
  if not GDLEngineWorkers.TryGetValue(projectID, project) then
    // *** error handling
  else
    project.ProjectModified;
end; { DLEProjectModified }

procedure DLEFileModified(projectID: integer; const fileName: PChar);
var
  project: TDelphiLensEngineProject;
begin
  if not GDLEngineWorkers.TryGetValue(projectID, project) then
    // *** error handling
  else
    project.FileModified(string(fileName));
end; { DLEFileModified }

procedure DLERescanProject(projectID: integer);
var
  project: TDelphiLensEngineProject;
begin
  if not GDLEngineWorkers.TryGetValue(projectID, project) then
    // *** error handling
  else
    project.Rescan;
end; { DLERescanPRoject }

procedure DLESetProjectConfig(projectID: integer; platform, searchPath, libraryPath:
  PChar);
var
  project: TDelphiLensEngineProject;
begin
  if not GDLEngineWorkers.TryGetValue(projectID, project) then
    // *** error handling
  else
    project.SetConfig(TDLEProjectConfig.Create(string(platform), string(searchPath), string(libraryPath)));
end; { DLESetProjectConfig }

procedure DLEInitialize;
begin
  GDLEngineID.Value := 0;
  GDLEngineWorkers := TObjectDictionary<integer, TDelphiLensEngineProject>.Create([doOwnsValues]);
end; { DLEInitialize }

procedure DLEFinalize;
begin
  FreeAndNil(GDLEngineWorkers);
end; { DLEFinalize }

end.
