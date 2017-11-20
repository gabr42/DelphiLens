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
  System.SysUtils, System.Classes, System.Math,
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
    function  ActivateTab(const fileName: string): boolean;
    function  CheckAPI(const apiName: string; apiResult: integer): boolean;
    procedure CloseProject;
    procedure SetCursorPosition(line, column: integer);
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
var
  edit: IOTAEditorServices;
  fileName: string;
  navToFile: PChar;
  navToLine, navToColumn: integer;
  apiRes: integer;
begin
  try
    Log(lcActivation, 'Activate');
    if not (IsDLUIAvailable and FDLUIHasProject) then begin
      Log(lcActivation, '... no DLL or no project');
      Exit;
    end;
    edit := (BorlandIDEServices as IOTAEditorServices);
    if not assigned(edit) then
      Log(lcActivation, '... no editor')
    else if not assigned(edit.TopView) then
      Log(lcActivation, '... no top view')
    else if not assigned(edit.TopView.Buffer) then
      Log(lcActivation, '... no top view buffer')
    else begin
      fileName := ExtractFileName(edit.TopView.Buffer.FileName);
      if SameText(ExtractFileExt(fileName), '.pas') then
        fileName := ChangeFileExt(fileName, '');
      Log(lcActivation, 'Activate in %s @ %d,%d',
        [fileName, edit.TopView.CursorPos.Line, edit.TopView.CursorPos.Col]);
      apiRes := DLUIActivate(FDLUIProjectID,
        PChar(fileName), edit.TopView.CursorPos.Line, edit.TopView.CursorPos.Col,
        navToFile, navToLine, navToColumn);
      if CheckAPI('DLUIActivate', apiRes) and assigned(navToFile) and ActivateTab(string(navToFile)) then
      begin
        Log(lcActivation, '... navigate to %s @ %d,%d',
          [string(navToFile), navToLine, navToColumn]);
        SetCursorPosition(navToLine, navToColumn);
      end;
    end;
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.Activate', E);
  end;
end; { TDelphiLensProxy.Activate }

destructor TDelphiLensProxy.Destroy;
begin
  CloseProject;
  inherited;
end; { TDelphiLensProxy.Destroy }

function TDelphiLensProxy.ActivateTab(const fileName: string): boolean;
var
  actSvc: IOTAActionServices;
begin
  actSvc := (BorlandIDEServices as IOTAActionServices);
  Result := assigned(actSvc) and actSvc.OpenFile(fileName);
end; { TDelphiLensProxy.ActivateTag }

function TDelphiLensProxy.CheckAPI(const apiName: string; apiResult: integer): boolean;
var
  error   : integer;
  errorMsg: PChar;
begin
  Result := (apiResult = DelphiLensUI.Error.NO_ERROR);
  if not Result then begin
    error := DLUIGetLastError(FDLUIProjectID, errorMsg);
    Log(lcError, '%s failed with error [%d] %s', [apiName, error, string(errorMsg)]);
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
      Log(lcError, 'TDelphiLensProxy.FileActivated', E);
  end;
end; { TDelphiLensProxy.FileActivated }

procedure TDelphiLensProxy.FileModified(const fileName: string);
begin
  try
    if FDLUIHasProject then
      CheckAPI('DLUIFileModified', DLUIFileModified(FDLUIProjectID, PChar(fileName)));
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.FileModified', E);
  end;
end; { TDelphiLensProxy.FileModified }

procedure TDelphiLensProxy.ProjectClosed;
begin
  try
    CloseProject;
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.ProjectClosed', E);
  end;
end; { TDelphiLensProxy.ProjectClosed }

procedure TDelphiLensProxy.ProjectModified;
begin
  try
    if FDLUIHasProject then
      CheckAPI('DLUIProjectModified', DLUIProjectModified(FDLUIProjectID));
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.ProjectModified', E);
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

    if IsDLUIAvailable then
      FDLUIHasProject := CheckAPI('DLUIOpenProject', DLUIOpenProject(PChar(projName), FDLUIProjectID));
    if not FDLUIHasProject then
      Exit;

    Log(lcActiveProject, 'DelphiLens project recreated');

//    SetProjectConfig(sPlatform, conditionals, searchPath, libPath);

    FCurrentProject.Name := projName;
    FCurrentProject.ActivePlatform := sPlatform;
    FCurrentProject.Conditionals := conditionals;
    FCurrentProject.SearchPath := searchPath;
    FCurrentProject.LibPath := libPath;
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.ProjectOpened', E);
  end;
end; { TDelphiLensProxy.ProjectOpened }

procedure TDelphiLensProxy.SetCursorPosition(line, column: integer);
var
  edit: IOTAEditorServices;
  editPos: TOTAEditPos;
  topPos: TOTAEditPos;
  newTop: TOTAEditPos;
  moveTop: boolean;
  viewSize: TSize;
begin
  edit := (BorlandIDEServices as IOTAEditorServices);
  editPos.Line := line;
  editPos.Col := column;
  edit.TopView.CursorPos := editPos;

  topPos := edit.TopView.TopPos;
  viewSize := edit.TopView.ViewSize;
  newTop := topPos;
  moveTop := false;

  if editPos.Line < topPos.Line then begin
    newTop.Line := Max(1, editPos.Line - 3);
    moveTop := true;
  end
  else if editPos.Line >= (topPos.Line + viewSize.cy) then begin
    newTop.Line := Max(1, editPos.Line - viewSize.cy div 2);
    moveTop := true;
  end;

  //TODO: also move in X

  if moveTop then begin
    edit.TopView.TopPos := newTop;
    edit.TopView.Paint;
  end;
end;

procedure TDelphiLensProxy.SetProjectConfig(const sPlatform, conditionals, searchPath, libPath: string);
var
  path: string;
begin
  try
    if FDLUIHasProject then begin
      path := ''.Join(';', [searchPath, libPath]);

      Log(lcActiveProject, 'Project config set to:');
      Log(lcActiveProject, '... platform = ' + sPlatform);
      Log(lcActiveProject, '... defines  = ' + conditionals);
      Log(lcActiveProject, '... path     = ' + searchPath + ';' + libPath);

      if CheckAPI('DLUISetProjectConfig', DLUISetProjectConfig(FDLUIProjectID, PChar(sPlatform), PChar(conditionals), PChar(path))) then
        CheckAPI('DLUIRescan', DLUIRescanProject(FDLUIProjectID));
    end;
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.SetProjectConfig', E);
  end;
end; { TDelphiLensProxy.SetProjectConfig }

{ TDelphiLensEngine }

initialization
  if not IsDLUIAvailable then
    Log(lcError, '%s.dll not found!', [DelphiLensUIDLL]);
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
