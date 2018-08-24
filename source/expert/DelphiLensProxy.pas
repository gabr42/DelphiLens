unit DelphiLensProxy;

interface

type
  IDelphiLensProxy = interface ['{1602B867-C10C-4C0C-866E-CE04DFE06224}']
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure FileSaved(const fileName: string);
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
  Vcl.Forms,
  ToolsAPI, DCCStrs,
  UtilityFunctions,
  GpStuff, GpConsole,
  DSiWin32,
  DelphiLens.OTAUtils,
  DelphiLensUI.Worker,
  DelphiLensUI.Error;

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
    FDLUILastProjectID: integer;
    FDLUIProject      : TDelphiLensUIProject;
  strict protected
    function  ActivateTabs(const fileNames: string): boolean;
    procedure CloseProject;
    procedure SetCursorPosition(line, column: integer);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure FileSaved(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string; const sPlatform, conditionals, searchPath, libPath: string);
    procedure ProjectModified;
    procedure SetProjectConfig(const sPlatform, conditionals, searchPath, libPath: string);
  end; { TDelphiLensProxy }

procedure LoggerHook(projectID: integer; const msg: PChar); stdcall;
begin
  try
  Log(lcHook, string(msg));
  except
    on E: Exception do
      Console.Writeln(['[hook] *** ', E.ClassName, ': ', E.Message]);
  end;
end; { LoggerHook }

{ TDelphiLensProxy }

constructor TDelphiLensProxy.Create;
begin
  inherited Create;
  GLogHook := LoggerHook;
end; { TDelphiLensProxy.Create }

destructor TDelphiLensProxy.Destroy;
begin
  CloseProject;
  GLogHook := nil;
  inherited;
end; { TDelphiLensProxy.Destroy }

procedure TDelphiLensProxy.Activate;
var
  col        : integer;
  edit       : IOTAEditorServices;
  editBuffer : IOTAEditBuffer;
  editIter   : IOTAEditBufferIterator;
  filePath   : string;
  iTab       : integer;
  line       : integer;
  navigate   : boolean;
  navInfo    : PDLUINavigationInfo;
  tabNames   : string;
begin
  try
    Log(lcActivation, 'Activate');
    if not assigned(FDLUIProject) then begin
      Log(lcActivation, '... no project');
      Exit;
    end;

    filePath := '';
    line := -1;
    col := -1;

    edit := (BorlandIDEServices as IOTAEditorServices);
    if not assigned(edit) then
      Log(lcActivation, '... no editor')
    else if not assigned(edit.TopView) then
      Log(lcActivation, '... no top view')
    else if not assigned(edit.TopView.Buffer) then
      Log(lcActivation, '... no top view buffer')
    else begin
      filePath := edit.TopView.Buffer.GetSubViewIdentifier(0);
      line := edit.TopView.CursorPos.Line;
      col := edit.TopView.CursorPos.Col;
      Log(lcActivation, 'Activate in %s @ %d,%d', [filePath, line, col]);
      tabNames := '';
      if edit.GetEditBufferIterator(editIter) then
        for iTab := 0 to editIter.Count - 1 do begin
          editBuffer := editIter.EditBuffers[iTab];
          if editBuffer.GetSubViewCount > 0 then
            tabNames := AddToList(tabNames, #13, editBuffer.FileName);
        end;
    end;

    FDLUIProject.Activate(Application.MainForm.Monitor.MonitorNum, filePath, line, col, tabNames, navigate);

    if navigate then begin
      navInfo := FDLUIProject.GetNavigationInfo;
      Log(lcActivation, 'Navigate to: %s', [string(navInfo.FileName)]);
      if ActivateTabs(string(navInfo.FileName)) and (navInfo.Line > 0) and (navInfo.Column > 0) then
      begin
        Log(lcActivation, '... @ %d,%d', [navInfo.Line, navInfo.Column]);
        SetCursorPosition(navInfo.Line, navInfo.Column);
      end;
    end;
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.Activate', E);
  end;
end; { TDelphiLensProxy.Activate }

function TDelphiLensProxy.ActivateTabs(const fileNames: string): boolean;
var
  fileName: string;
begin
  Result := true;
  for fileName in fileNames.Split([#13]) do
    Result := ActivateTab(fileName) and Result;
end; { TDelphiLensProxy.ActivateTabs }

procedure TDelphiLensProxy.CloseProject;
begin
  if FCurrentProject.Name = '' then
    Exit;

  FCurrentProject.Name := '';
  FCurrentProject.ActivePlatform := '';
  FCurrentProject.Conditionals := '';
  FCurrentProject.SearchPath := '';
  FCurrentProject.LibPath := '';

  if not assigned(FDLUIProject) then
    Exit;

  FreeAndNil(FDLUIProject);
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
    //
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.FileModified', E);
  end;
end; { TDelphiLensProxy.FileModified }

procedure TDelphiLensProxy.FileSaved(const fileName: string);
begin
  try
    if assigned(FDLUIProject) then
      FDLUIProject.FileModified(fileName);
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.FileSaved', E);
  end;
end; { TDelphiLensProxy.FileSaved }

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
    if assigned(FDLUIProject) then
      FDLUIProject.ProjectModified;
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

    Inc(FDLUILastProjectID);
    FDLUIProject := TDelphiLensUIProject.Create(projName, FDLUILastProjectID);

    Log(lcActiveProject, 'DelphiLens project recreated');

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
  edit   : IOTAEditorServices;
  editPos: TOTAEditPos;
begin
  edit := (BorlandIDEServices as IOTAEditorServices);
  editPos.Line := line;
  editPos.Col := column;
  edit.TopView.CursorPos := editPos;
  edit.TopView.MoveViewToCursor;
  edit.TopView.Paint;
end; { TDelphiLensProxy.SetCursorPosition }

procedure TDelphiLensProxy.SetProjectConfig(const sPlatform, conditionals, searchPath, libPath: string);
var
  path: string;
begin
  try
    if assigned(FDLUIProject) then begin
      path := ''.Join(';', [searchPath, libPath]);

      Log(lcActiveProject, 'Project config set to:');
      Log(lcActiveProject, '... platform = ' + sPlatform);
      Log(lcActiveProject, '... defines  = ' + conditionals);
      Log(lcActiveProject, '... path     = ' + searchPath + ';' + libPath);

      FDLUIProject.SetConfig(TDLUIProjectConfig.Create(sPlatform, conditionals, path));
    end;
  except
    on E: Exception do
      Log(lcError, 'TDelphiLensProxy.SetProjectConfig', E);
  end;
end; { TDelphiLensProxy.SetProjectConfig }

initialization
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
