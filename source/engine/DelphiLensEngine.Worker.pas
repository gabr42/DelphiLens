unit DelphiLensEngine.Worker;

interface

uses
  OtlTaskControl;

type
  TDLEProjectConfig = record
    Platform   : string;
    SearchPath : string;
    LibraryPath: string;
    constructor Create(const APlatform, ASearchPath, ALibraryPath: string);
  end; { TDLEProjectConfig }

  TDelphiLensEngineProject = class
  strict private
    FWorker: IOmniTaskControl;
  public
    constructor Create(const projectName: string);
    destructor  Destroy; override;
    procedure FileModified(const fileName: string);
    procedure ProjectModified;
    procedure Rescan;
    procedure SetConfig(const config: TDLEProjectConfig);
  end; { TDelphiLensEngineProject }

implementation

uses
  OtlCommon,
  DelphiLens.Intf, DelphiLens;

type
  TDelphiLensEngineWorker = class(TOmniWorker)
  strict private const
    CTimerRescan         = 1;
    CTimerRescanDelay_ms = 3000;
  var
    FDelphiLens: IDelphiLens;
    FScanResult: IDLScanResult;
  strict protected
    procedure ScheduleRescan;
  public
    procedure Open(const projectName: TOmniValue);
    procedure Close;
    procedure ProjectModified;
    procedure FileModified(const fileModified: TOmniValue);
    procedure Rescan;
    procedure SetConfig(const configInfo: TOmniValue);
  end; { TDelphiLensEngineWorker }

{ TDLEProjectConfig }

constructor TDLEProjectConfig.Create(const APlatform, ASearchPath, ALibraryPath: string);
begin
  Platform := APlatform;
  SearchPath := ASearchPath;
  LibraryPath := ALibraryPath;
end; { TDLEProjectConfig.Create }

{ TDelphiLensEngineProject }

constructor TDelphiLensEngineProject.Create(const projectName: string);
begin
  inherited Create;
  FWorker := CreateTask(TDelphiLensEngineWorker.Create(), 'DelphiLens engine for ' + projectName)
//               .OnMessage(EngineFeedback)
               .Run;
  FWorker.Invoke(@TDelphiLensEngineWorker.Open, projectName);
end; { TDelphiLensEngineProject.Create }

destructor TDelphiLensEngineProject.Destroy;
begin
  if assigned(FWorker) then
    FWorker.Invoke(@TDelphiLensEngineWorker.Close);
  FWorker.Terminate;
  FWorker := nil;
  inherited;
end; { TDelphiLensEngineProject.Destroy }

procedure TDelphiLensEngineProject.FileModified(const fileName: string);
begin
  FWorker.Invoke(@TDelphiLensEngineWorker.FileModified, fileName);
end; { TDelphiLensEngineProject.FileModified }

procedure TDelphiLensEngineProject.ProjectModified;
begin
  FWorker.Invoke(@TDelphiLensEngineWorker.ProjectModified);
end; { TDelphiLensEngineProject.ProjectModified }

procedure TDelphiLensEngineProject.Rescan;
begin
  FWorker.Invoke(@TDelphiLensEngineWorker.Rescan);
end; { TDelphiLensEngineProject.Rescan }

procedure TDelphiLensEngineProject.SetConfig(const config: TDLEProjectConfig);
begin
  FWorker.Invoke(@TDelphiLensEngineWorker.SetConfig, TOmniValue.FromRecord<TDLEProjectConfig>(config))
end; { TDelphiLensEngineProject.SetConfig }

{ TDelphiLensEngineWorker }

procedure TDelphiLensEngineWorker.Close;
begin
  FDelphiLens := nil;
end; { TDelphiLensEngineWorker.Close }

procedure TDelphiLensEngineWorker.FileModified(const fileModified: TOmniValue);
begin
  ScheduleRescan;
end; { TDelphiLensEngineWorker.FileModified }

procedure TDelphiLensEngineWorker.Open(const projectName: TOmniValue);
begin
  FDelphiLens := CreateDelphiLens(projectName);
end; { TDelphiLensEngineWorker.Open }

procedure TDelphiLensEngineWorker.ProjectModified;
begin
  ScheduleRescan;
end; { TDelphiLensEngineWorker.ProjectModified }

procedure TDelphiLensEngineWorker.Rescan;
begin
  if not assigned(FDelphiLens) then
    Exit;

  Task.ClearTimer(CTimerRescan);
  FScanResult := FDelphiLens.Rescan;
end; { TDelphiLensEngineWorker.Rescan }

procedure TDelphiLensEngineWorker.ScheduleRescan;
begin
  if assigned(FDelphiLens) then
    Task.SetTimer(CTimerRescan, CTimerRescanDelay_ms, @TDelphiLensEngineWorker.Rescan);
end; { TDelphiLensEngineWorker.ScheduleRescan }

procedure TDelphiLensEngineWorker.SetConfig(const configInfo: TOmniValue);
var
  config: TDLEProjectConfig;
begin
  if assigned(FDelphiLens) then begin
    config := configInfo.ToRecord<TDLEProjectConfig>;
    { TODO : Implement: SetProjectConfig }
//    FDelphiLens.Platform := configInfo[0];
    FDelphiLens.ConditionalDefines := configInfo[1];
    FDelphiLens.SearchPath := configInfo[2].AsString;
  end;
end; { TDelphiLensEngineWorker.SetConfig }

end.
