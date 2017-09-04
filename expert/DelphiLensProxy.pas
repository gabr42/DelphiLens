unit DelphiLensProxy;

interface

type
  IDelphiLensProxy = interface ['{1602B867-C10C-4C0C-866E-CE04DFE06224}']
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string);
  end; { IDelphiLensProxy }

var
  DLProxy: IDelphiLensProxy;

implementation

uses
  Windows,
  Messages,
  SysUtils,
  UtilityFunctions,
  DelphiLens.Intf,
  DelphiLens,
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
    procedure ProjectOpened(const projName: string);
  end; { TDelphiLensProxy }

  TDelphiLensEngine = class(TOmniWorker)
  strict private
    FDelphiLens: IDelphiLens;
  public
    procedure OpenProject(const projectName: TOmniValue);
    procedure CloseProject;
    procedure FileModified(const fileModified: TOmniValue);
  end; { TDelphiLensEngine }

{ TDelphiLensProxy }

procedure TDelphiLensProxy.Activate;
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.Activate
  except
    on E: Exception do
      OutputMessage(Format('%s in Activate, %s', [E.ClassName, E.Message]), 'DelphiLens');
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
      OutputMessage(Format('%s in EngineFeedback, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end;

procedure TDelphiLensProxy.FileActivated(const fileName: string);
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.FileActivated
    // If files does not belong to a current project, create another 'temp'
    // indexer and index that file. Maybe keep a small number of such indexers?
    // Index into some temp cache?
  except
    on E: Exception do
      OutputMessage(Format('%s in FileActivated, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.FileActivated }

procedure TDelphiLensProxy.FileModified(const fileName: string);
begin
  try
    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.FileModified, fileName);
  except
    on E: Exception do
      OutputMessage(Format('%s in FileModified, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.FileModified }

procedure TDelphiLensProxy.ProjectClosed;
begin
  try
    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.CloseProject);
  except
    on E: Exception do
      OutputMessage(Format('%s in ProjectClosed, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.ProjectClosed }

procedure TDelphiLensProxy.ProjectOpened(const projName: string);
begin
  try
    if assigned(FWorker) then
      FWorker.Invoke(@TDelphiLensEngine.OpenProject, projName);
  except
    on E: Exception do
      OutputMessage(Format('%s in ProjectOpened, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.ProjectOpened }

{ TDelphiLensEngine }

procedure TDelphiLensEngine.CloseProject;
begin
  FDelphiLens := nil;
end; { TDelphiLensEngine.CloseProject }

procedure TDelphiLensEngine.FileModified(const fileModified: TOmniValue);
begin
end; { TDelphiLensEngine.FileModified }

procedure TDelphiLensEngine.OpenProject(const projectName: TOmniValue);
begin
  FDelphiLens := CreateDelphiLens(projectName);
end; { TDelphiLensEngine.OpenProject }

initialization
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
