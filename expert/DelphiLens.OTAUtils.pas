unit DelphiLens.OTAUtils;

interface

uses
  ToolsAPI,
  System.SysUtils,
  System.Classes;

function GetActivePlatform(const project: IOTAProject): string;
function GetLibraryPath(const PlatformName: string; MapEnvVariables: boolean): string;
function GetProjectConfigurations(const project: IOTAProject): IOTAProjectOptionsConfigurations; overload; inline;
function GetProjectConfigurations(const project: IOTAProject; var configs: IOTAProjectOptionsConfigurations): boolean; overload; inline;
function GetSearchPath(const project: IOTAProject; MapEnvVariables: boolean): string;

function ReplaceEnvVariables(const s: string): string;

procedure Log(const s: string); overload;
procedure Log(const s: string; const params: array of const); overload;
procedure Log(const method: string; E: Exception); overload;

implementation

uses
  Winapi.Windows,
  System.Win.Registry,
  System.StrUtils,
  DCCStrs,
  DSiWin32,
  UtilityFunctions;

function GetActivePlatform(const project: IOTAProject): string;
var
  config : IOTABuildConfiguration;
  configs: IOTAProjectOptionsConfigurations;
begin
  Result := '';
  if assigned(project) and GetProjectConfigurations(project, configs) then
    Result := configs.ActivePlatformName;
end;

// https://stackoverflow.com/q/38826629/4997
function GetLibraryPath(const PlatformName: string; MapEnvVariables: boolean): string;
var
  Svcs: IOTAServices;
  Options: IOTAEnvironmentOptions;
  ValueCompiler: string;
  RegRead: TRegistry;
begin
  Svcs := BorlandIDEServices as IOTAServices;
  if not Assigned(Svcs) then Exit;
  Options := Svcs.GetEnvironmentOptions;
  if not Assigned(Options) then Exit;

  ValueCompiler := Svcs.GetBaseRegistryKey;

  if PlatformName = '' then
    Result := Options.GetOptionValue('LibraryPath')
  else
  begin
    RegRead := TRegistry.Create;
    try
      RegRead.RootKey := HKEY_CURRENT_USER;
      RegRead.OpenKey(ValueCompiler + '\Library\' + PlatformName, False);
      Result := RegRead.GetDataAsString('Search Path');
    finally RegRead.Free; end;
  end;

  if MapEnvVariables then
    Result := ReplaceEnvVariables(Result);
end;

function GetProjectConfigurations(const project: IOTAProject): IOTAProjectOptionsConfigurations;
var
  configs: IOTAProjectOptionsConfigurations;
begin
  Result := nil;
  if assigned(project) and Supports(project.ProjectOptions, IOTAProjectOptionsConfigurations, configs) then
    Result := configs;
end;

function GetProjectConfigurations(const project: IOTAProject;
  var configs: IOTAProjectOptionsConfigurations): boolean;
begin
  configs := GetProjectConfigurations(project);
  Result := assigned(configs);
end;

function GetSearchPath(const project: IOTAProject; MapEnvVariables: boolean): string;
var
  configs: IOTAProjectOptionsConfigurations;
begin
  Result := '';
  if assigned(project) and GetProjectConfigurations(project, configs) then begin
    Result := configs.ActiveConfiguration.Value[sUnitSearchPath];
    if MapEnvVariables then
      Result := ReplaceEnvVariables(Result);
  end;
end;

function ReplaceEnvVariables(const s: string): string;
var
  pPrev: Integer;
  pEnv: Integer;
  pEnd: Integer;
  envName: String;
  envVar: String;
begin
  Result := s;
  pEnv := 1;
  repeat
    pEnv := PosEx('$(', Result, pEnv);
    if pEnv = 0 then
      break;
    pEnd := PosEx(')', Result, pEnv+2);
    if pEnd = 0 then
      break;
    envName := Copy(Result, pEnv + 2, pEnd - pEnv - 2);
    if SameText(envName, 'Platform') then
      envVar := GetActivePlatform(GetActiveProject)
    else
      envVar := DSiGetEnvironmentVariable(envName);
    Delete(Result, pEnv, pEnd - pEnv + 1);
    Insert(envVar, Result, pEnv);
  until false;
end;

procedure Log(const s: string);
begin
  OutputMessage(s, 'DelphiLens');
end;

procedure Log(const s: string; const params: array of const);
begin
  Log(Format(s, params));
end;

procedure Log(const method: string; E: Exception);
begin
  Log(Format('%s in %s, %s', [E.ClassName, method, E.Message]));
end;

end.
