unit DelphiLens.OTAUtils;

interface

uses
  ToolsAPI,
  System.SysUtils,
  System.Classes;

function GetActivePlatform(const project: IOTAProject): string;
function GetConditionalDefines(const project: IOTAProject): string;
function GetLibraryPath(const PlatformName: string; MapEnvVariables: boolean): string;
function GetProjectConfigurations(const project: IOTAProject): IOTAProjectOptionsConfigurations; overload; inline;
function GetProjectConfigurations(const project: IOTAProject; var configs: IOTAProjectOptionsConfigurations): boolean; overload; inline;
function GetSearchPath(const project: IOTAProject; MapEnvVariables: boolean): string;

function ReplaceEnvVariables(const s: string): string;

function ActivateTab(const fileName: string): boolean;

type
  TLogClass = (lcError, lcActiveProject, lcActivation);

procedure LogMessage(const s: string);
procedure Log(logClass: TLogClass; const s: string); overload;
procedure Log(logClass: TLogClass; const s: string; const params: array of const); overload;
procedure Log(logClass: TLogClass; const method: string; E: Exception); overload;

implementation

uses
  Winapi.Windows,
  System.Win.Registry,
  System.StrUtils,
  DCCStrs,
  DSiWin32,
  UtilityFunctions;

type
  TLogClasses = set of TLogClass;
  PLogClasses = ^TLogClasses;

var
  GLogClasses: TLogClasses;

function GetProjectConfigurations(const project: IOTAProject;
  var configs: IOTAProjectOptionsConfigurations): boolean;    //inline
begin
  configs := GetProjectConfigurations(project);
  Result := assigned(configs);
end;

function GetActivePlatform(const project: IOTAProject): string;
var
  configs: IOTAProjectOptionsConfigurations;
begin
  Result := '';
  if assigned(project) and GetProjectConfigurations(project, configs) then
    Result := configs.ActivePlatformName;
end;

function GetConditionalDefines(const project: IOTAProject): string;
var
  configs: IOTAProjectOptionsConfigurations;
begin
  Result := '';
  if assigned(project) and GetProjectConfigurations(project, configs) then
    Result := configs.ActiveConfiguration.Value[sDefine];
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

function ActivateTab(const fileName: string): boolean;
var
  actSvc    : IOTAActionServices;
  editBuffer: IOTAEditBuffer;
  editIter  : IOTAEditBufferIterator;
  editSvc   : IOTAEditorServices;
  i         : integer;
begin
  Result := false;

  editSvc := (BorlandIDEServices as IOTAEditorServices);
  if assigned(editSvc) and editSvc.GetEditBufferIterator(editIter) then begin
    for i := 0 to editIter.Count - 1 do begin
      editBuffer := editIter.EditBuffers[i];
      if (editBuffer.GetSubViewCount > 0)
         and SameText(fileName, editBuffer.GetSubViewIdentifier(0))
      then begin
        editIter.EditBuffers[i].Show;
        Result := true;
        break; //for i
      end;
    end;
  end;

  if not Result then begin
    actSvc := (BorlandIDEServices as IOTAActionServices);
    Result := assigned(actSvc) and actSvc.OpenFile(fileName);
  end;

  if Result and (editSvc.TopBuffer.GetSubViewCount > 0) then
    editSvc.TopBuffer.SwitchToView(0);
end; { ActivateTag }

procedure LogMessage(const s: string);
begin
  OutputMessage(s, 'DelphiLens');
end;

procedure Log(logClass: TLogClass; const s: string);
begin
  if logClass in GLogClasses then
    LogMessage(s);
end;

procedure Log(logClass: TLogClass; const s: string; const params: array of const);
begin
  Log(logClass, Format(s, params));
end;

procedure Log(logClass: TLogClass; const method: string; E: Exception);
begin
  Log(logClass, Format('%s in %s, %s', [E.ClassName, method, E.Message]));
end;

var
  logLevel: string;
  logLevelInt: integer;

initialization
  GLogClasses := [lcError];
  logLevel := GetEnvironmentVariable('DL_LOGGING');
  if not TryStrToInt(logLevel, logLevelInt) then begin
    LogMessage('Invalid DL_LOGGING setting: ' + logLevel + '. Expecting a number.');
  end
  else if (logLevelInt < 0) or (logLevelInt > 255) then
    LogMessage('Invalid DL_LOGGING setting: ' + logLevel + '. Number must be between 0 and 255.')
  else begin
    GLogClasses := PLogClasses(@logLevelInt)^;
    LogMessage(Format('Logging level set to %d', [logLevelInt]));
  end;
end.
