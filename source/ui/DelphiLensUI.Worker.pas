unit DelphiLensUI.Worker;

interface

uses
  System.SysUtils,
  OtlSync, OtlComm, OtlTaskControl,
  DelphiLens.Intf,
  DelphiLensUI.UIXStorage,
  DelphiLensUI.UIXEngine.Intf;

type
  TDLUIProjectConfig = record
    PlatformName      : string;
    ConditionalDefines: string;
    SearchPath        : string;
    constructor Create(const APlatform, AConditionalDefines, ASearchPath: string);
  end; { TDLUIProjectConfig }

  TDLUINavigationInfo = record
  private
    FileNameStr: string;
  public
    FileName  : PChar;
    Line      : integer;
    Column    : integer;
    constructor Create(const location: TDLUIXLocation);
  end; { TDLUINavigationInfo }
  PDLUINavigationInfo = ^TDLUINavigationInfo;

  TDelphiLensUIProject = class
  strict private
    FCurrentRescanID: integer;
    FCurrentResultID: integer;
    FNavigationInfo : TDLUINavigationInfo;
    FProjectID      : integer;
    FProjectName    : string;
    FScanLock       : IOmniCriticalSection;
    FScanResult     : IDLScanResult;
    FUIXStorage     : IDLUIXStorage;
    FWorker         : IOmniTaskControl;
  protected
    procedure LogToIDE(const msg: string);
    procedure ReportException(const funcName, excClass, excMessage: string);
    procedure ScanComplete_Asy(const result: IDLScanResult; scanID: integer);
  public
    constructor Create(const projectName: string; projectID: integer);
    destructor  Destroy; override;
    procedure Activate(monitorNum: integer; const fileName: string;
      line, column: integer; const tabNames: string; var navigate: boolean);
    procedure FileModified(const fileName: string);
    function  GetNavigationInfo: PDLUINavigationInfo; inline;
    procedure ProjectModified;
    procedure Rescan;
    procedure SetConfig(const config: TDLUIProjectConfig);
    property ProjectID: integer read FProjectID;
  end; { TDelphiLensUIProject }

var
  GLogHook: procedure (projectID: integer; const msg: PChar); stdcall; //TDLLogger;

implementation

uses
  Winapi.Windows,
  System.UITypes, System.Classes,
  Vcl.Forms,
  Spring,
  DSiWin32,
  GpConsole,
  OtlCommon, OtlTask,
  DelphiLens,
  DelphiLensUI.Main, DelphiLensUI.WorkerContext;

type
  TDelphiLensUIWorker = class(TOmniWorker)
  strict private const
    CTimerRescan         = 1;
    CTimerRescanDelay_ms = 3000;
  var
    FDelphiLens: IDelphiLens;
    FOwner     : TDelphiLensUIProject;
    FScanLock  : IOmniCriticalSection;
    FScanID    : TOmniAlignedInt32;
  strict protected
    procedure LogToIDE(const msg: string);
    procedure ReportException(const funcName: string; E: Exception);
    procedure ScheduleRescan;
  protected
    function  Initialize: boolean; override;
    procedure InternalRescan;
  public
    procedure Open(const projectName: TOmniValue);
    procedure Close;
    procedure ProjectModified(var scanID: integer);
    procedure FileModified(const fileName: string; var scanID: integer);
    procedure Rescan(var scanID: integer);
    procedure SetConfig(const configInfo: TOmniValue);
    procedure TimerRescan;
  end; { TDelphiLensUIWorker }

{ TDLUIProjectConfig }

constructor TDLUIProjectConfig.Create(const APlatform, AConditionalDefines,
  ASearchPath: string);
begin
  PlatformName := APlatform;
  ConditionalDefines := AConditionalDefines;
  SearchPath := ASearchPath;
end; { TDLUIProjectConfig.Create }

{ TDelphiLensUIProject }

constructor TDelphiLensUIProject.Create(const projectName: string; projectID: integer);
begin
  inherited Create;
  FProjectName := projectName;
  FProjectID := projectID;
  FScanLock := CreateOmniCriticalSection;
  FWorker := CreateTask(TDelphiLensUIWorker.Create(), 'DelphiLens engine for ' + projectName)
               .SetParameter('owner', Self)
               .SetParameter('lock', FScanLock)
               .Unobserved
               .Run;
  FWorker.Invoke(@TDelphiLensUIWorker.Open, projectName);
  FUIXStorage := CreateUIXStorage;
end; { TDelphiLensUIProject.Create }

destructor TDelphiLensUIProject.Destroy;
begin
  if assigned(FWorker) then
    FWorker.Invoke(@TDelphiLensUIWorker.Close);
  FWorker.Terminate;
  FWorker := nil;
  inherited;
end; { TDelphiLensUIProject.Destroy }

procedure TDelphiLensUIProject.Activate(monitorNum: integer; const fileName: string;
  line, column: integer; const tabNames: string; var navigate: boolean);
var
  context  : IDLUIWorkerContext;
  lastLog  : Tuple<integer,integer>;
  oldCursor: TCursor;
  timer    : TStopwatch;
  unitName : string;
begin
  unitName := ExtractFileName(fileName);
  if DSiFileExtensionIs(unitName, ['.pas', '.dpr', '.dpk']) then
    unitName := ChangeFileExt(unitName, '');

  oldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;

  lastLog := Tuple.Create(integer(0),integer(0));
  timer := TStopwatch.StartNew;
  repeat
    FScanLock.Acquire;
    try
      //TODO: Show nicer "Please wait" window with TActivityIndicator
      Screen.Cursor := oldCursor;

      if FCurrentResultID = FCurrentRescanID then begin
LogToIDE(Format('Current result: %d, current rescan: %d', [FCurrentResultID, FCurrentRescanID]));
        if not assigned(FScanResult) then
          raise Exception.Create('TDelphiLensUIProject.Activate: FScanResult = nil');

        context := CreateWorkerContext(FUIXStorage, FProjectName, FScanResult,
          TDLUIXLocation.Create(fileName, unitName, line, column),
          tabNames.Split([#13]), monitorNum);
        DLUIShowUI(context);
        break; //repeat
      end
      else if (FCurrentRescanID <> lastLog.Value1) or (FCurrentResultID <> lastLog.Value2) then begin
        LogToIDE(Format('Waiting for parser. Rescan ID = %d, Result ID = %d',
                        [FCurrentRescanID, FCurrentResultID]));
        lastLog := Tuple.Create(FCurrentRescanID, FCurrentResultID);
      end;
    finally
      FScanLock.Release;
    end;
    if timer.Elapsed.TotalSeconds > 30 then begin
      LogToIDE('30 second timeout reached ... aborting activation');
      break;
    end;
    Sleep(100);
  until false;

  navigate := assigned(context) and context.Target.HasValue;
  if navigate then
    FNavigationInfo := TDLUINavigationInfo.Create(context.Target);
end; { TDelphiLensUIProject.Activate }

procedure TDelphiLensUIProject.FileModified(const fileName: string);
var
  waiter: IOmniWaitablevalue;
begin
  waiter := CreateWaitableValue;
  FWorker.Invoke(
    procedure (const task: IOmniTask)
    var
      scanID: integer;
    begin
      (task.Implementor as TDelphiLensUIWorker).FileModified(fileName, scanID);
      waiter.Signal(scanID);
    end);
  waiter.WaitFor;
  FCurrentRescanID := waiter.Value;
LogToIDE(Format('File modified, rescan ID = %d', [FCurrentRescanID]));
end; { TDelphiLensUIProject.FileModified }

function TDelphiLensUIProject.GetNavigationInfo: PDLUINavigationInfo;
begin
  Result := @FNavigationInfo;
end; { TDelphiLensUIProject.GetNavigationInfo }

procedure TDelphiLensUIProject.LogToIDE(const msg: string);
begin
try
  if assigned(GLogHook) then
    GLogHook(FProjectID, PChar(msg));
except
  on E: Exception do
    Console.Writeln(['[main] *** ', E.ClassName, ': ', E.Message]);
end;
end; { TDelphiLensUIProject.LogToIDE }

procedure TDelphiLensUIProject.ProjectModified;
var
  waiter: IOmniWaitableValue;
begin
  waiter := CreateWaitableValue;
  FWorker.Invoke(
    procedure (const task: IOmniTask)
    var
      scanID: integer;
    begin
      (task.Implementor as TDelphiLensUIWorker).ProjectModified(scanID);
      waiter.Signal(scanID);
    end);
  waiter.WaitFor;
  FCurrentRescanID := waiter.Value;
LogToIDE(Format('Project modified, rescan ID = %d', [FCurrentRescanID]));
end; { TDelphiLensUIProject.ProjectModified }

procedure TDelphiLensUIProject.ReportException(const funcName, excClass, excMessage: string);
begin
  raise Exception.CreateFmt('Exception in worker method %s. [%s] %s', [funcName, excClass, excMessage]);
end; { TDelphiLensUIProject.ReportException }

procedure TDelphiLensUIProject.Rescan;
var
  waiter: IOmniWaitableValue;
begin
LogToIDE('Rescan');
  waiter := CreateWaitableValue;
  FWorker.Invoke(
    procedure (const task: IOmniTask)
    var
      scanID: integer;
    begin
      (task.Implementor as TDelphiLensUIWorker).Rescan(scanID);
      waiter.Signal(scanID);
    end);
  waiter.WaitFor;
  FCurrentRescanID := waiter.Value;
LogToIDE(Format('Rescan, rescan ID = %d', [FCurrentRescanID]));
end; { TDelphiLensUIProject.Rescan }

procedure TDelphiLensUIProject.ScanComplete_Asy(const result: IDLScanResult; scanID: integer);
begin
LogToIDE('ScanComplete_Asy');
  FScanLock.Acquire;
  try
    FScanResult := result;
    FCurrentResultID := scanID;
LogToIDE(Format('ScanComplete, result ID = %d', [scanID]));
  finally FScanLock.Release; end;
end; { TDelphiLensUIProject.ScanComplete_Asy }

procedure TDelphiLensUIProject.SetConfig(const config: TDLUIProjectConfig);
begin
  FWorker.Invoke(@TDelphiLensUIWorker.SetConfig, TOmniValue.FromRecord<TDLUIProjectConfig>(config));
  Rescan;
end; { TDelphiLensUIProject.SetConfig }

{ TDelphiLensUIWorker }

procedure TDelphiLensUIWorker.Close;
begin
  try
    FDelphiLens := nil;
  except
    on E:Exception do
      ReportException('Close', E);
  end;
end; { TDelphiLensUIWorker.Close }

procedure TDelphiLensUIWorker.FileModified(const fileName: string; var scanID: integer);
begin
  try
    scanID := FScanID.Increment;
    ScheduleRescan;
  except
    on E:Exception do
      ReportException('FileModified', E);
  end;
end; { TDelphiLensUIWorker.FileModified }

function TDelphiLensUIWorker.Initialize: boolean;
begin
  LogToIDE('Worker initializing');
  Result := inherited Initialize;
  if Result then begin
    FOwner := Task.Param['owner'];
    FScanLock := Task.Param['lock'].AsInterface as IOmniCriticalSection;
    FScanID.Value := 0;
    LogToIDE(Format('Worker initialized, scan ID = %d', [FScanID.Value]));
  end;
end; { TDelphiLensUIWorker.Initialize }

procedure TDelphiLensUIWorker.InternalRescan;
var
  scanIDCpy : integer;
  scanResult: IDLScanResult;
begin
  Task.ClearTimer(CTimerRescan);

  FScanLock.Acquire;
  try
    scanResult := FDelphiLens.Rescan;
    scanIDCpy := FScanID.Value;
  finally FScanLock.Release; end;

LogToIDE('Scan complete');
  FOwner.ScanComplete_Asy(scanResult, scanIDCpy);
end; { TDelphiLensUIWorker.InternalRescan }

procedure TDelphiLensUIWorker.LogToIDE(const msg: string);
begin
Console.Writeln(['[worker]', msg]);
try
  TThread.Queue(nil,
//  Task.Invoke(
    procedure
    begin
      if assigned(FOwner) then
        FOwner.LogToIDE(msg);
    end);
except
  on E: Exception do
    Console.Writeln(['[worker] *** ', E.ClassName, ': ', E.Message]);
end;
end; { TDelphiLensUIWorker.LogToIDE }

procedure TDelphiLensUIWorker.Open(const projectName: TOmniValue);
begin
  try
LogToIDE(Format('Worker open %s', [projectName.AsString]));
    FDelphiLens := CreateDelphiLens(projectName);
  except
    on E:Exception do
      ReportException('Open', E);
  end;
end; { TDelphiLensUIWorker.Open }

procedure TDelphiLensUIWorker.ProjectModified(var scanID: integer);
begin
  try
    scanID := FScanID.Increment;
    ScheduleRescan;
  except
    on E:Exception do
      ReportException('ProjectModified', E);
  end;
end; { TDelphiLensUIWorker.ProjectModified }

procedure TDelphiLensUIWorker.ReportException(const funcName: string; E: Exception);
var
  eClass  : string;
  eMessage: string;
begin
  eClass := E.ClassName;
  eMessage := E.Message;
  Task.Invoke(
    procedure
    begin
      FOwner.ReportException(funcName, eClass, eMessage);
    end);
end; { TDelphiLensUIWorker.ReportException }

procedure TDelphiLensUIWorker.Rescan(var scanID: integer);
begin
  try
    scanID := FScanID.Increment;
LogToIDE(Format('Rescan %d', [scanID]));
    if not assigned(FDelphiLens) then
      Exit;

    InternalRescan;
  except
    on E:Exception do
      ReportException('Rescan', E);
  end;
end; { TDelphiLensUIWorker.Rescan }

procedure TDelphiLensUIWorker.ScheduleRescan;
begin
  try
LogToIDE('ScheduleRescan');
    if assigned(FDelphiLens) then
      Task.SetTimer(CTimerRescan, CTimerRescanDelay_ms, @TDelphiLensUIWorker.TimerRescan);
  except
    on E:Exception do
      ReportException('ScheduleRescan', E);
  end;
end; { TDelphiLensUIWorker.ScheduleRescan }

procedure TDelphiLensUIWorker.SetConfig(const configInfo: TOmniValue);
var
  config: TDLUIProjectConfig;
begin
  try
    if assigned(FDelphiLens) then begin
      config := configInfo.ToRecord<TDLUIProjectConfig>;
      { TODO : Implement: SetProjectConfig }
  //    FDelphiLens.Platform := config.PlatformName;
      FDelphiLens.ConditionalDefines := config.ConditionalDefines;
      FDelphiLens.SearchPath := config.SearchPath;
    end;
  except
    on E:Exception do
      ReportException('SetConfig', E);
  end;
end; { TDelphiLensUIWorker.SetConfig }

procedure TDelphiLensUIWorker.TimerRescan;
begin
  InternalRescan;
end; { TDelphiLensUIWorker.TimerRecan }

{ TDLUINavigationInfo }

constructor TDLUINavigationInfo.Create(const location: TDLUIXLocation);
begin
  FileNameStr := location.FileName;
  UniqueString(FileNameStr);
  FileName := PChar(FileNameStr);
  Line := location.Line;
  Column := location.Column;
end; { TDLUINavigationInfo.Create }

initialization
  GLogHook := nil;
end.
