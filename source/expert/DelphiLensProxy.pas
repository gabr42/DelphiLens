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
  DelphiLens.OTAUtils,
  DelphiLensUI.Import, DelphiLensUI.Error;

const
  MSG_FEEDBACK = WM_USER;

type
  TDelphiLensProxy = class(TInterfacedObject, IDelphiLensProxy)
  strict private
    FCurrentProject: record
      Name          : string;
      ActivePlatform: string;
      Conditionals  : string;
      SearchPath    : string;
      LibPath       : string;
    end;
    FDLUIHasProject: boolean;
    FDLUIProjectID : integer;
  strict protected
    function  CheckAPI(const apiName: string; apiResult: integer): boolean;
    procedure CloseProject;
  public
    destructor  Destroy; override;
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string; const sPlatform, conditionals, searchPath, libPath: string);
    procedure ProjectModified;
    procedure SetProjectConfig(const sPlatform, conditionals, searchPath, libPath: string);
  end; { TDelphiLensProxy }

{ TDelphiLensProxy }

procedure TDelphiLensProxy.Activate;
begin
  try
    Log('Activate');
    if IsDLUIAvailable then
//      CheckAPI('DLUIActivate', DLUIActivate(
  except
    on E: Exception do
      Log('TDelphiLensProxy.Activate', E);
  end;
end; { TDelphiLensProxy.Activate }

destructor TDelphiLensProxy.Destroy;
begin
  CloseProject;
  inherited;
end; { TDelphiLensProxy.Destroy }

function TDelphiLensProxy.CheckAPI(const apiName: string; apiResult: integer): boolean;
var
  error   : integer;
  errorMsg: PChar;
begin
  Result := (apiResult = DelphiLensUI.Error.NO_ERROR);
  if not Result then begin
    error := DLUIGetLastError(FDLUIProjectID, errorMsg);
    Log('%s failed with error [%d] %s', [apiName, error, string(errorMsg)]);
  end;
end; { TDelphiLensProxy.CheckAPI }

procedure TDelphiLensProxy.CloseProject;
begin
  if FCurrentProject.Name = '' then
    Exit;

  FCurrentProject.Name := '';
  FCurrentProject.ActivePlatform := '';
  FCurrentProject.Conditionals := '';
  FCurrentProject.SearchPath := '';
  FCurrentProject.LibPath := '';

  if not FDLUIHasProject then
    Exit;

  CheckAPI('DLUICloseProject', DLUICloseProject(FDLUIProjectID));
  FDLUIHasProject := false;
end; { TDelphiLensProxy.CloseProject }

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
    if FDLUIHasProject then
      CheckAPI('DLUIFileModified', DLUIFileModified(FDLUIProjectID, PChar(fileName)));
  except
    on E: Exception do
      Log('TDelphiLensProxy.FileModified', E);
  end;
end; { TDelphiLensProxy.FileModified }

procedure TDelphiLensProxy.ProjectClosed;
begin
  try
    CloseProject;
  except
    on E: Exception do
      Log('TDelphiLensProxy.ProjectClosed', E);
  end;
end; { TDelphiLensProxy.ProjectClosed }

procedure TDelphiLensProxy.ProjectModified;
begin
  try
    if FDLUIHasProject then
      CheckAPI('DLUIProjectModified', DLUIProjectModified(FDLUIProjectID));
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

    CloseProject;

    FDLUIHasProject := CheckAPI('DLUIOpenProject', DLUIOpenProject(PChar(projName), FDLUIProjectID));
    if not FDLUIHasProject then
      Exit;

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
var
  path: string;
begin
  try
    if FDLUIHasProject then begin
      path := ''.Join(';', [searchPath, libPath]);
      CheckAPI('DLUISetProjectConfig', DLUISetProjectConfig(FDLUIProjectID, PChar(sPlatform), PChar(conditionals), PChar(path)));
    end;
  except
    on E: Exception do
      Log('TDelphiLensProxy.SetProjectConfig', E);
  end;
end; { TDelphiLensProxy.SetProjectConfig }

{ TDelphiLensEngine }

initialization
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
