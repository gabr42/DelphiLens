unit DelphiLensProxy;

interface

type
  IDelphiLensProxy = interface ['{1602B867-C10C-4C0C-866E-CE04DFE06224}']
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string; const searchPath: string);
    procedure ProjectModified;
  end; { IDelphiLensProxy }

var
  DLProxy: IDelphiLensProxy;

implementation

uses
  Winapi.Windows, Winapi.Messages,
  System.Win.Registry,
  System.SysUtils, System.Classes,
  ToolsAPI, DCCStrs,
  UtilityFunctions,
  DSiWin32,
  DelphiLens.Intf, DelphiLens, DelphiLens.OTAUtils,
  OtlCommon, OtlComm, OtlTaskControl;

const
  MSG_FEEDBACK = WM_USER;

type
  TDelphiLensProxy = class(TInterfacedObject, IDelphiLensProxy)
  private
    FWorker: IOmniTaskControl;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Activate;
    procedure EngineFeedback(const task: IOmniTaskControl; const msg: TOmniMessage);
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string; const searchPath: string);
    procedure ProjectModified;
  end; { TDelphiLensProxy }

  TDelphiLensEngine = class(TOmniWorker)
  strict private const
    CTimerRescan         = 1;
    CTimerRescanDelay_ms = 3000;
  var
    FDelphiLens: IDelphiLens;
    FScanResult: IDLScanResult;
  strict protected
    procedure ScheduleRescan;
  public
    procedure OpenProject(const projectInfo: TOmniValue);
    procedure CloseProject;
    procedure ProjectModified;
    procedure FileModified(const fileModified: TOmniValue);
    procedure Rescan;
  end; { TDelphiLensEngine }

{ TDelphiLensProxy }

procedure TDelphiLensProxy.Activate;
var
  proj: IOTAProject;
  options: IOTAProjectOptions;
  names: TOTAOptionNameArray;
  name: TOTAOptionName;
  configs: IOTAProjectOptionsConfigurations;
  activeConfig: IOTABuildConfiguration;
  sl: TStringList;
  s: string;
begin
  try
    Log('Activate');
    proj := ActiveProject;
    if assigned(proj) then begin
      options := proj.ProjectOptions;
      if assigned(options) then begin
      end;
      if Supports(options, IOTAProjectOptionsConfigurations, configs) then begin
        activeConfig := configs.ActiveConfiguration;
        if assigned(activeConfig) then begin
          Log('Search: ' + activeConfig.Value[sUnitSearchPath]);
          Log('Library: ' + GetLibraryPath(configs.ActivePlatformName, true));
        end;
      end;
    end;
  except
    on E: Exception do
      Log('TDelphiLensProxy.Activate', E);
  end;
end; { TDelphiLensProxy.Activate }

constructor TDelphiLensProxy.Create;
begin
  inherited Create;
  FWorker := CreateTask(TDelphiLensEngine.Create(), 'DelphiLens engine')
               .OnMessage(EngineFeedback)
               .Run;
end; { TDelphiLensProxy.Create }

destructor TDelphiLensProxy.Destroy;
begin
  if assigned(FWorker) then begin
    FWorker.Terminate(5000);
    FWorker := nil;
  end;
  inherited;
end; { TDelphiLensProxy.Destroy }

procedure TDelphiLensProxy.EngineFeedback(const task: IOmniTaskControl; const msg: TOmniMessage);
begin
  try

  except
    on E: Exception do
      Log('TDelphiLensProxy.EngineFeedback', E);
  end;
end; { TDelphiLensProxy.EngineFeedback }

procedure TDelphiLensProxy.FileActivated(const fileName: string);
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.FileActivated
    // If files does not belong to a current project, create another 'temp'
    // indexer and index that file. Maybe keep a small number of such indexers?
    // Index into some temp cache?
  except
    on E: Exception do
      Log('TDelphiLensProxy.FileActivated', E);
  end;
end; { TDelphiLensProxy.FileActivated }

procedure TDelphiLensProxy.FileModified(const fileName: string);
begin
  try
    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.FileModified, fileName);
  except
    on E: Exception do
      Log('TDelphiLensProxy.FileModified', E);
  end;
end; { TDelphiLensProxy.FileModified }

procedure TDelphiLensProxy.ProjectClosed;
begin
  try
    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.CloseProject);
  except
    on E: Exception do
      Log('TDelphiLensProxy.ProjectClosed', E);
  end;
end; { TDelphiLensProxy.ProjectClosed }

procedure TDelphiLensProxy.ProjectModified;
begin
  try
    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.ProjectModified);
  except
    on E: Exception do
      Log('TDelphiLensProxy.ProjectModified', E);
  end;
end; { TDelphiLensProxy.ProjectModified }

procedure TDelphiLensProxy.ProjectOpened(const projName: string; const searchPath: string);
begin
  try
    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.OpenProject, [projName, searchPath]);
  except
    on E: Exception do
      Log('TDelphiLensProxy.ProjectOpened', E);
  end;
end; { TDelphiLensProxy.ProjectOpened }

{ TDelphiLensEngine }

procedure TDelphiLensEngine.CloseProject;
begin
  FDelphiLens := nil;
end; { TDelphiLensEngine.CloseProject }

procedure TDelphiLensEngine.FileModified(const fileModified: TOmniValue);
begin
  ScheduleRescan;
end; { TDelphiLensEngine.FileModified }

procedure TDelphiLensEngine.OpenProject(const projectInfo: TOmniValue);
begin
  FDelphiLens := CreateDelphiLens(projectInfo[0]);
  FDelphiLens.SearchPath := projectInfo[1];
end; { TDelphiLensEngine.OpenProject }

procedure TDelphiLensEngine.ProjectModified;
begin
  ScheduleRescan;
end; { TDelphiLensEngine.ProjectModified }

procedure TDelphiLensEngine.Rescan;
begin
  if not assigned(FDelphiLens) then
    Exit;

  Task.ClearTimer(CTimerRescan);
  FScanResult := FDelphiLens.Rescan;
end; { TDelphiLensEngine.Rescan }

procedure TDelphiLensEngine.ScheduleRescan;
begin
  if assigned(FDelphiLens) then
    Task.SetTimer(CTimerRescan, CTimerRescanDelay_ms, @TDelphiLensEngine.Rescan);
end; { TDelphiLensEngine.ScheduleRescan }

initialization
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
