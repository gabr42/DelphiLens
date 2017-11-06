unit DelphiLensUI.Worker;

interface

uses
  OtlTaskControl;

type
  TDLUIProjectConfig = record
    Platform   : string;
    SearchPath : string;
    LibraryPath: string;
    constructor Create(const APlatform, ASearchPath, ALibraryPath: string);
  end; { TDLUIProjectConfig }

  TDelphiLensUIProject = class
  strict private
    FWorker: IOmniTaskControl;
  public
    constructor Create(const projectName: string);
    destructor  Destroy; override;
    procedure FileModified(const fileName: string);
    procedure ProjectModified;
    procedure Rescan;
    procedure SetConfig(const config: TDLUIProjectConfig);
  end; { TDelphiLensUIProject }

implementation

uses
  System.SysUtils,
  OtlCommon,
  DelphiLens.Intf, DelphiLens;

type
  TDelphiLensUIWorker = class(TOmniWorker)
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
  end; { TDelphiLensUIWorker }

{ TDLUIProjectConfig }

constructor TDLUIProjectConfig.Create(const APlatform, ASearchPath, ALibraryPath: string);
begin
  Platform := APlatform;
  SearchPath := ASearchPath;
  LibraryPath := ALibraryPath;
end; { TDLUIProjectConfig.Create }

{ TDelphiLensUIProject }

constructor TDelphiLensUIProject.Create(const projectName: string);
begin
  inherited Create;
  FWorker := CreateTask(TDelphiLensUIWorker.Create(), 'DelphiLens engine for ' + projectName)
//               .OnMessage(EngineFeedback)
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

procedure TDelphiLensUIWorker.Open(const projectName: TOmniValue);
begin
  FDelphiLens := CreateDelphiLens(projectName);
end; { TDelphiLensUIWorker.Open }

procedure TDelphiLensUIWorker.ProjectModified;
begin
  ScheduleRescan;
end; { TDelphiLensUIWorker.ProjectModified }

procedure TDelphiLensUIWorker.Rescan;
begin
  if not assigned(FDelphiLens) then
    Exit;

  Task.ClearTimer(CTimerRescan);
  FScanResult := FDelphiLens.Rescan;
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
//    FDelphiLens.Platform := configInfo[0];
    FDelphiLens.ConditionalDefines := configInfo[1];
    FDelphiLens.SearchPath := configInfo[2];
  end;
end; { TDelphiLensUIWorker.SetConfig }

end.
