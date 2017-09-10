unit DelphiLens.OTAUtils;

interface

uses
  System.SysUtils,
  System.Classes;

function GetLibraryPath(const PlatformName: string; MapEnvVariables: boolean): string;
function ReplaceEnvVariables(const s: string): string;

procedure Log(const s: string); overload;
procedure Log(const s: string; const params: array of const); overload;
procedure Log(const method: string; E: Exception); overload;

implementation

uses
  Winapi.Windows,
  System.Win.Registry,
  System.StrUtils,
  ToolsAPI,
  DSiWin32,
  UtilityFunctions;

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

function ReplaceEnvVariables(const s: string): string;
var
  pPrev: Integer;
  pEnv: Integer;
  pEnd: Integer;
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
    envVar := DSiGetEnvironmentVariable(Copy(Result, pEnv + 2, pEnd - pEnv - 2));
    Delete(Result, pEnv, pEnd - pEnv + 1);
    Insert(Result, envVar, pEnv);
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
