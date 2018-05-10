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
    FProjectName    : string;
    FScanLock       : IOmniCriticalSection;
    FScanResult     : IDLScanResult;
    FUIXStorage     : IDLUIXStorage;
    FWorker         : IOmniTaskControl;
  protected
    procedure ReportException(const funcName, excClass, excMessage: string);
    procedure ScanComplete(const result: IDLScanResult; scanID: integer);
  public
    constructor Create(const projectName: string);
    destructor  Destroy; override;
    procedure Activate(monitorNum: integer; const fileName: string;
      line, column: integer; const tabNames: string; var navigate: boolean);
    procedure FileModified(const fileName: string);
    function  GetNavigationInfo: PDLUINavigationInfo; inline;
    procedure ProjectModified;
    procedure Rescan;
    procedure SetConfig(const config: TDLUIProjectConfig);
  end; { TDelphiLensUIProject }

var
  GLogHook: procedure (projectID: integer; const msg: PChar); stdcall; //TDLLogger;

implementation

uses
  System.UITypes,
  Vcl.Forms,
  Spring,
  DSiWin32,
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

constructor TDelphiLensUIProject.Create(const projectName: string);
begin
  inherited Create;
  FProjectName := projectName;
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
  oldCursor: TCursor;
  unitName : string;
begin
  unitName := ExtractFileName(fileName);
  if DSiFileExtensionIs(unitName, ['.pas', '.dpr', '.dpk']) then
    unitName := ChangeFileExt(unitName, '');

  oldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;

  repeat
    FScanLock.Acquire;
    try
      Application.ProcessMessages;
      //TODO: Show nicer "Please wait" window with TActivityIndicator
      Screen.Cursor := oldCursor;

      if not assigned(FScanResult) then
        raise Exception.Create('TDelphiLensUIProject.Activate: FScanResult = nil')
      else if FCurrentResultID = FCurrentRescanID then begin
        context := CreateWorkerContext(FUIXStorage, FProjectName, FScanResult,
          TDLUIXLocation.Create(fileName, unitName, line, column),
          tabNames.Split([#13]), monitorNum);
        DLUIShowUI(context);
        break; //repeat
      end
    finally
      FScanLock.Release;
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
end; { TDelphiLensUIProject.FileModified }

function TDelphiLensUIProject.GetNavigationInfo: PDLUINavigationInfo;
begin
  Result := @FNavigationInfo;
end; { TDelphiLensUIProject.GetNavigationInfo }

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
end; { TDelphiLensUIProject.ProjectModified }

procedure TDelphiLensUIProject.ReportException(const funcName, excClass, excMessage: string);
begin
  raise Exception.CreateFmt('Exception in worker method %s. [%s] %s', [funcName, excClass, excMessage]);
end;

procedure TDelphiLensUIProject.Rescan;
var
  waiter: IOmniWaitableValue;
begin
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
end; { TDelphiLensUIProject.Rescan }

procedure TDelphiLensUIProject.ScanComplete(const result: IDLScanResult; scanID: integer);
begin
  FScanResult := result;
  FCurrentResultID := scanID;
end; { TDelphiLensUIProject.ScanComplete }

procedure TDelphiLensUIProject.SetConfig(const config: TDLUIProjectConfig);
begin
  FWorker.Invoke(@TDelphiLensUIWorker.SetConfig, TOmniValue.FromRecord<TDLUIProjectConfig>(config))
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
  Result := inherited Initialize;
  if Result then begin
    FOwner := Task.Param['owner'];
    FScanLock := Task.Param['lock'].AsInterface as IOmniCriticalSection;
    FScanID.Value := 0;
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
  finally FScanLock.Release; end;

  scanIDCpy := FScanID.Value;
  Task.Invoke(
    procedure
    begin
      FOwner.ScanComplete(scanResult, scanIDCpy);
    end);
end; { TDelphiLensUIWorker.InternalRescan }

procedure TDelphiLensUIWorker.Open(const projectName: TOmniValue);
begin
  try
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
