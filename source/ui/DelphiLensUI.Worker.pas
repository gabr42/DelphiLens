unit DelphiLensUI.Worker;

interface

uses
  OtlComm, OtlTaskControl,
  DelphiLens.Intf;

type
  TDLUIProjectConfig = record
    PlatformName      : string;
    ConditionalDefines: string;
    SearchPath        : string;
    constructor Create(const APlatform, AConditionalDefines, ASearchPath: string);
  end; { TDLUIProjectConfig }

  TDelphiLensUIProject = class
  strict private
    FScanResult: IDLScanResult;
    FWorker    : IOmniTaskControl;
  protected
    procedure ScanComplete(const result: IDLScanResult);
  public
    constructor Create(const projectName: string);
    destructor  Destroy; override;
    procedure Activate(const fileName: string; line, column: integer);
    procedure FileModified(const fileName: string);
    procedure ProjectModified;
    procedure Rescan;
    procedure SetConfig(const config: TDLUIProjectConfig);
  end; { TDelphiLensUIProject }

implementation

uses
  System.SysUtils,
  OtlCommon,
  DelphiLens,
  DelphiLensUI.Main;

type
  TDelphiLensUIWorker = class(TOmniWorker)
  strict private const
    CTimerRescan         = 1;
    CTimerRescanDelay_ms = 3000;
  var
    FDelphiLens: IDelphiLens;
    FOwner     : TDelphiLensUIProject;
  strict protected
    procedure ScheduleRescan;
  protected
    function Initialize: boolean; override;
  public
    procedure Open(const projectName: TOmniValue);
    procedure Close;
    procedure ProjectModified;
    procedure FileModified(const fileModified: TOmniValue);
    procedure Rescan;
    procedure SetConfig(const configInfo: TOmniValue);
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
  FWorker := CreateTask(TDelphiLensUIWorker.Create(), 'DelphiLens engine for ' + projectName)
               .SetParameter('owner', Self)
               .Unobserved
               .Run;
  FWorker.Invoke(@TDelphiLensUIWorker.Open, projectName);
end; { TDelphiLensUIProject.Create }

destructor TDelphiLensUIProject.Destroy;
begin
  if assigned(FWorker) then
    FWorker.Invoke(@TDelphiLensUIWorker.Close);
  FWorker.Terminate;
  FWorker := nil;
  inherited;
end; { TDelphiLensUIProject.Destroy }

procedure TDelphiLensUIProject.Activate(const fileName: string; line, column: integer);
begin
  //TODO: Needs a way to wait for the latest rescan to be processed. Requests must send command ID and ScanCompleted must return this command ID.
  DLUIShowUI(FScanResult, fileName, line, column);
end; { TDelphiLensUIProject.Activate }

procedure TDelphiLensUIProject.FileModified(const fileName: string);
begin
  FWorker.Invoke(@TDelphiLensUIWorker.FileModified, fileName);
end; { TDelphiLensUIProject.FileModified }

procedure TDelphiLensUIProject.ProjectModified;
begin
  FWorker.Invoke(@TDelphiLensUIWorker.ProjectModified);
end; { TDelphiLensUIProject.ProjectModified }

procedure TDelphiLensUIProject.Rescan;
begin
  FWorker.Invoke(@TDelphiLensUIWorker.Rescan);
end; { TDelphiLensUIProject.Rescan }

procedure TDelphiLensUIProject.ScanComplete(const result: IDLScanResult);
begin
  FScanResult := result;
end; { TDelphiLensUIProject.ScanComplete }

procedure TDelphiLensUIProject.SetConfig(const config: TDLUIProjectConfig);
begin
  FWorker.Invoke(@TDelphiLensUIWorker.SetConfig, TOmniValue.FromRecord<TDLUIProjectConfig>(config))
end; { TDelphiLensUIProject.SetConfig }

{ TDelphiLensUIWorker }

procedure TDelphiLensUIWorker.Close;
begin
  FDelphiLens := nil;
end; { TDelphiLensUIWorker.Close }

procedure TDelphiLensUIWorker.FileModified(const fileModified: TOmniValue);
begin
  ScheduleRescan;
end; { TDelphiLensUIWorker.FileModified }

function TDelphiLensUIWorker.Initialize: boolean;
begin
  Result := inherited Initialize;
  if Result then
    FOwner := Task.Param['owner'];
end; { TDelphiLensUIWorker.Initialize }

procedure TDelphiLensUIWorker.Open(const projectName: TOmniValue);
begin
  FDelphiLens := CreateDelphiLens(projectName);
end; { TDelphiLensUIWorker.Open }

procedure TDelphiLensUIWorker.ProjectModified;
begin
  ScheduleRescan;
end; { TDelphiLensUIWorker.ProjectModified }

procedure TDelphiLensUIWorker.Rescan;
var
  scanResult: IDLScanResult;
begin
  if not assigned(FDelphiLens) then
    Exit;

  Task.ClearTimer(CTimerRescan);
  scanResult := FDelphiLens.Rescan;

  Task.Invoke(
    procedure
    begin
      FOwner.ScanComplete(scanResult);
    end);
end; { TDelphiLensUIWorker.Rescan }

procedure TDelphiLensUIWorker.ScheduleRescan;
begin
  if assigned(FDelphiLens) then
    Task.SetTimer(CTimerRescan, CTimerRescanDelay_ms, @TDelphiLensUIWorker.Rescan);
end; { TDelphiLensUIWorker.ScheduleRescan }

procedure TDelphiLensUIWorker.SetConfig(const configInfo: TOmniValue);
var
  config: TDLUIProjectConfig;
begin
  if assigned(FDelphiLens) then begin
    config := configInfo.ToRecord<TDLUIProjectConfig>;
    { TODO : Implement: SetProjectConfig }
//    FDelphiLens.Platform := config.PlatformName;
    FDelphiLens.ConditionalDefines := config.ConditionalDefines;
    FDelphiLens.SearchPath := config.SearchPath;
  end;
end; { TDelphiLensUIWorker.SetConfig }

end.
