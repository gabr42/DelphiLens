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
  GpConsole,
  Vcl.Dialogs,
  Winapi.Windows,
  System.SysUtils, System.Generics.Collections, System.Math,
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
  GDLStringLock  : TOmniCS;
  GDLStringTable : TDictionary<integer, string>;
  GDLIPCClient   : IDLUIIPCClient;

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

function CheckClient(projectID: integer; var error: integer): boolean;
begin
  Result := assigned(GDLIPCClient) and GDLIPCClient.IsConnected;
  if Result then
    error := ClearError(projectID)
  else
    error := SetError(projectID, ERR_NOT_CONNECTED, 'Not connected to DelphiLensUI.exe');
end; { CheckClient }

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
  if not CheckClient(projectID, Result) then
    Exit;

  Result := ClearError(projectID);
  try
  Console.Writeln('>OpenProject');
    GDLIPCClient.OpenProject(projectName, projectID, error, errMsg);
  Console.Writeln(['<OpenProject ', projectID]);
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
  if projectID = 0 then
    Exit;

  if not CheckClient(projectID, Result) then
    Exit;

  Result := ClearError(projectID);
  try
    GDLIPCClient.CloseProject(projectID, error, errMsg);
    GDLStringLock.Acquire;
    try
      GDLStringTable.Remove(projectID);
    finally GDLStringLock.Release; end;
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUICloseProject }

function DLUIProjectModified(projectID: integer): integer;
var
  errMsg: string;
  error : integer;
begin
  if not CheckClient(projectID, Result) then
    Exit;

  Result := ClearError(projectID);
  try
    GDLIPCClient.ProjectModified(projectID, error, errMsg);
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIProjectModified }

function DLUIFileModified(projectID: integer; fileName: PChar): integer;
var
  errMsg: string;
  error : integer;
begin
  if not CheckClient(projectID, Result) then
    Exit;

  Result := ClearError(projectID);
  try
    GDLIPCClient.FileModified(projectID, fileName, error, errMsg);
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIFileModified }

function DLUIRescanProject(projectID: integer): integer;
var
  errMsg: string;
  error : integer;
begin
  if not CheckClient(projectID, Result) then
    Exit;

  Result := ClearError(projectID);
  try
    GDLIPCClient.RescanProject(projectID, error, errMsg);
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIRescanPRoject }

function DLUISetProjectConfig(projectID: integer; platformName, conditionalDefines,
  searchPath: PChar): integer;
var
  errMsg: string;
  error : integer;
begin
  if not CheckClient(projectID, Result) then
    Exit;

  Result := ClearError(projectID);
  try
    GDLIPCClient.SetProjectConfig(projectID, platformName, conditionalDefines, searchPath,
      error, errMsg);
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUISetProjectConfig }

function DLUIActivate(monitorNum, projectID: integer; fileName: PChar; line, column: integer;
  tabNames: PChar; var navigateToFile: PChar; var navigateToLine,
  navigateToColumn: integer): integer;
var
  errMsg   : string;
  error    : integer;
  navToFile: string;
begin
  if not CheckClient(projectID, Result) then
    Exit;

  Result := ClearError(projectID);
  try
  Console.Writeln(['>Activate ', projectID]);
    GDLIPCClient.Activate(monitorNum, projectID, fileName, line, column, tabNames,
      navToFile, navigateToLine, navigateToColumn, error, errMsg);
  Console.Writeln('<Activate');
    if navToFile = '' then
      navigateToFile := nil
    else begin
      GDLStringLock.Acquire;
      try
        GDLStringTable.AddOrSetValue(projectID, navToFile);
        navigateToFile := PChar(GDLStringTable[projectID]); // must be alive only until next call for the same project ID
      finally GDLStringLock.Release; end;
    end;
    Result := SetError(projectID, error, errMsg);
  except
    on E: Exception do
      Result := SetError(projectID, ERR_EXCEPTION, E.Message);
  end;
end; { DLUIActivate }

procedure DLUIInitialize;
var
  conn   : boolean;
  hasSrv : boolean;
  time_ms: int64;
begin
  GDLEngineErrors := TDictionary<integer, TErrorInfo>.Create;
  GDLErrorLock.Initialize;
  GDLStringTable := TDictionary<integer, string>.Create;
  GDLStringLock.Initialize;

  GDLIPCClient := CreateIPClient;
  GDLIPCClient.Connect(5000, hasSrv, conn);
  if not hasSrv then begin
    if DSiExecute('DelphiLensUI.exe') = cardinal(MaxInt) then
      ShowMessage('Failed to execute DelphiLensUI.exe');
    time_ms := DSiTimeGetTime64;
    while not (conn or DSiHasElapsed64(time_ms, 5000)) do
      GDLIPCClient.Connect(Max(0, 5000 - DSiElapsedTime64(time_ms)), hasSrv, conn);
  end;

  // show this, somehow
  if not hasSrv then
    Console.Writeln('Failed to start DelphiLensUI.exe')
  else if not conn then
    Console.Writeln('Failed to connect to DelphiLensUI.exe')
  else
    Console.Writeln('Connected to server');
end; { DLUIInitialize }

procedure DLUIFinalize;
begin
  Console.Writeln('Finalize');
  if assigned(GDLIPCClient) then begin
    Console.Writeln('Disconnecting from server');
    GDLIPCClient.Disconnect;
    GDLIPCClient := nil;
  end;
  FreeAndNil(GDLEngineErrors);
  FreeAndNil(GDLStringTable);
end; { DLUIFinalize }

procedure DLUISetLogHook(const hook:  TDLLogger);
begin
  GLogHook := hook;
end; { DLUISetLogHook }

end.
