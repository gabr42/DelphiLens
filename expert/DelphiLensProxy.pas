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
  Winapi.Windows, Winapi.Messages,
  System.Win.Registry,
  System.SysUtils, System.Classes,
  ToolsAPI, DCCStrs,
  UtilityFunctions,
  DSiWin32,
  DelphiLens.Intf, DelphiLens,
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
  strict private const
    CTimerRescan         = 1;
    CTimerRescanDelay_ms = 3000;
  var
    FDelphiLens: IDelphiLens;
    FScanResult: IDLScanResult;
  public
    procedure OpenProject(const projectName: TOmniValue);
    procedure CloseProject;
    procedure FileModified(const fileModified: TOmniValue);
    procedure Rescan;
  end; { TDelphiLensEngine }

{ TDelphiLensProxy }

procedure GetLibraryPath(Paths: TStrings; PlatformName: string);
var
  Svcs: IOTAServices;
  Options: IOTAEnvironmentOptions;
  Text: string;
  List: TStrings;
  ValueCompiler: string;
  RegRead: TRegistry;
begin
  Svcs := BorlandIDEServices as IOTAServices;
  if not Assigned(Svcs) then Exit;
  Options := Svcs.GetEnvironmentOptions;
  if not Assigned(Options) then Exit;

  ValueCompiler := Svcs.GetBaseRegistryKey;

  OutputMessage('ValueCompiler: ' + ValueCompiler, 'DelphiLens');

  RegRead := TRegistry.Create;
  List := TStringList.Create;
  try
    if PlatformName = '' then
      Text := Options.GetOptionValue('LibraryPath')
    else
    begin
      RegRead.RootKey := HKEY_CURRENT_USER;
      RegRead.OpenKey(ValueCompiler + '\Library\' + PlatformName, False);
      Text := RegRead.GetDataAsString('Search Path');
    end;

    List.Text := StringReplace(Text, ';', #13#10, [rfReplaceAll]);
    Paths.AddStrings(List);

{    if PlatformName = '' then
      Text := Options.GetOptionValue('BrowsingPath')
    else
    begin
      RegRead.RootKey := HKEY_CURRENT_USER;
      RegRead.OpenKey(ValueCompiler + '\Library\' + PlatformName, False);
      Text := RegRead.GetDataAsString('Browsing Path');
    end;
    List.Text := StringReplace(Text, ';', #13#10, [rfReplaceAll]);
    Paths.AddStrings(List);
}
  finally
    RegRead.Free;
    List.Free;
  end;
end;

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
    OutputMessage('Activate', 'DelphiLens');
    proj := ActiveProject;
    if assigned(proj) then begin
      options := proj.ProjectOptions;
      if assigned(options) then begin
      end;
      if Supports(options, IOTAProjectOptionsConfigurations, configs) then begin
        activeConfig := configs.ActiveConfiguration;
        if assigned(activeConfig) then begin
          OutputMessage('Search: ' + activeConfig.Value[sUnitSearchPath], 'DelphiLens');
          { that works:
          sl := TStringList.Create;
          try
            GetLibraryPath(sl, configs.ActivePlatformName);
            for s in sl do
              OutputMessage('> ' + s, 'DelphiLens');
          finally FreeAndNil(sl); end;
          }
          OutputMessage('$(BDS) = ' + DSiGetEnvironmentVariable('BDS'), 'DelphiLens');
          OutputMessage('$(BDSCatalogRepository) = ' + DSiGetEnvironmentVariable('BDSCatalogRepository'), 'DelphiLens');
          OutputMessage('$(BDSLIB) = ' + DSiGetEnvironmentVariable('BDSLIB'), 'DelphiLens');
          OutputMessage('$(BDSUSERDIR) = ' + DSiGetEnvironmentVariable('BDSUSERDIR'), 'DelphiLens');
          OutputMessage('$(BDSCOMMONDIR) = ' + DSiGetEnvironmentVariable('BDSCOMMONDIR'), 'DelphiLens');
        end;
      end;
    end;
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
  if not assigned(FDelphiLens) then
    Exit;

  Task.SetTimer(CTimerRescan, CTimerRescanDelay_ms, @TDelphiLensEngine.Rescan);
end; { TDelphiLensEngine.FileModified }

procedure TDelphiLensEngine.OpenProject(const projectName: TOmniValue);
begin
  FDelphiLens := CreateDelphiLens(projectName);
end; { TDelphiLensEngine.OpenProject }

procedure TDelphiLensEngine.Rescan;
begin
  if not assigned(FDelphiLens) then
    Exit;

  Task.ClearTimer(CTimerRescan);
  FScanResult := FDelphiLens.Rescan;
end; { TDelphiLensEngine.Rescan }

initialization
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
