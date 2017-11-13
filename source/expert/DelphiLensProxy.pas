unit DelphiLensProxy;

interface

type
  IDelphiLensProxy = interface ['{1602B867-C10C-4C0C-866E-CE04DFE06224}']
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string; const sPlatform, conditionals, searchPath, libPath: string);
    procedure ProjectModified;
    procedure SetProjectConfig(const sPlatform, conditionals, searchPath, libPath: string);
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
  DelphiLens.Intf, DelphiLens, DelphiLens.OTAUtils, DelphiLensUI.Import,
  OtlCommon, OtlComm, OtlTaskControl;

const
  MSG_FEEDBACK = WM_USER;

type
  TDelphiLensProxy = class(TInterfacedObject, IDelphiLensProxy)
  private
    FWorker: IOmniTaskControl;
    FCurrentProject: record
      Name: string;
      ActivePlatform: string;
      Conditionals: string;
      SearchPath: string;
      LibPath: string;
    end;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Activate;
    procedure EngineFeedback(const task: IOmniTaskControl; const msg: TOmniMessage);
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string; const sPlatform, conditionals, searchPath, libPath: string);
    procedure ProjectModified;
    procedure SetProjectConfig(const sPlatform, conditionals, searchPath, libPath: string);
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
    procedure SetProjectConfig(const configInfo: TOmniValue);
  end; { TDelphiLensEngine }

{ TDelphiLensProxy }

procedure TDelphiLensProxy.Activate;
begin
  try
    Log('Activate');
    !
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
    if FCurrentProject.Name = '' then
      Exit;

    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.CloseProject);
    FCurrentProject.Name := '';
    FCurrentProject.ActivePlatform := '';
    FCurrentProject.Conditionals := '';
    FCurrentProject.SearchPath := '';
    FCurrentProject.LibPath := '';
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

procedure TDelphiLensProxy.ProjectOpened(const projName: string; const sPlatform, conditionals, searchPath, libPath: string);
begin
  try
    if SameText(FCurrentProject.Name, projName)
       and SameText(FCurrentProject.ActivePlatform, sPlatform)
       and SameText(FCurrentProject.Conditionals, conditionals)
       and SameText(FCurrentProject.SearchPath, searchPath)
       and SameText(FCurrentProject.LibPath, libPath)
    then
      Exit;

    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.OpenProject, [projName, sPlatform, searchPath, libPath]);
    FCurrentProject.Name := projName;
    FCurrentProject.ActivePlatform := sPlatform;
    FCurrentProject.Conditionals := conditionals;
    FCurrentProject.SearchPath := searchPath;
    FCurrentProject.LibPath := libPath;
  except
    on E: Exception do
      Log('TDelphiLensProxy.ProjectOpened', E);
  end;
end; { TDelphiLensProxy.ProjectOpened }

procedure TDelphiLensProxy.SetProjectConfig(const sPlatform, conditionals, searchPath, libPath: string);
begin
  try
    if FCurrentProject.Name = '' then
      Exit;

    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.SetProjectConfig, [sPlatform, conditionals, searchPath, libPath]);
  except
    on E: Exception do
      Log('TDelphiLensProxy.SetProjectConfig', E);
  end;
end; { TDelphiLensProxy.SetProjectConfig }

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
  SetProjectConfig(TOmniValue.Create([projectInfo[1].AsString, projectInfo[2].AsString, projectInfo[3].AsString]));
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

procedure TDelphiLensEngine.SetProjectConfig(const configInfo: TOmniValue);
begin
  if assigned(FDelphiLens) then begin
    { TODO : Implement: SetProjectConfig }
//    FDelphiLens.Platform := configInfo[0];
    FDelphiLens.ConditionalDefines := configInfo[1];
    FDelphiLens.SearchPath := configInfo[2].AsString + ';' + configInfo[3].AsString;
  end;
end; { TDelphiLensEngine.SetProjectConfig }

initialization
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
