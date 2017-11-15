unit DelphiLensUITest.Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Actions,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ActnList, Vcl.Samples.Spin,
  Spring.Collections,
  DelphiAST.Classes,
  DelphiLens.DelphiASTHelpers,
  DelphiLens.Intf, DelphiLens.UnitInfo;

type
  TfrmDLUITestMain = class(TForm)
    btnRescan        : TButton;
    btnSelect        : TButton;
    dlgOpenProject   : TFileOpenDialog;
    inpDefines       : TEdit;
    inpProject       : TEdit;
    inpSearchPath    : TEdit;
    lbFiles          : TListBox;
    lblDefines       : TLabel;
    lblProject       : TLabel;
    lblSearchPath    : TLabel;
    outSource        : TMemo;
    btnShowUI: TButton;
    procedure btnRescanClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure btnShowUIClick(Sender: TObject);
    procedure inpProjectChange(Sender: TObject);
    procedure lbFilesClick(Sender: TObject);
    procedure SettingExit(Sender: TObject);
  private const
    CSettingsKey = '\SOFTWARE\Gp\DelphiLens\DelphiLensDesktop';
    CSettingsProject            = 'Project';
    CSettingsSearchPath         = 'SearchPath';
    CSettingsConditionalDefines = 'ConditionalDefines';
  type
    TShowing = (shAnalysis, shParsedUnits, shIncludeFiles, shNotFound, shProblems);
  var
    FLoading  : boolean;
    FUIProject: integer;
    FUnits    : IDictionary<string,string>;
  strict protected
    procedure CloseUIProject;
    procedure CopyUnitNames(const units: TParsedUnits);
    procedure CreateUnitNamesList;
    procedure LoadSettings;
    procedure NavigateTo(navToFile: string; navToLine, navToColumn: integer);
    procedure ReportUIError(const functionName: string);
    procedure OpenUIProject;
    procedure SaveSettings;
  public
  end;

var
  frmDLUITestMain: TfrmDLUITestMain;

implementation

uses
  System.Types,
  DSiWin32,
  GpStuff, GpVCL,
  DelphiAST.Consts, DelphiAST.ProjectIndexer,
  DelphiLens,
  DelphiLensUI.Import;

{$R *.dfm}

procedure TfrmDLUITestMain.btnRescanClick(Sender: TObject);
begin
  CloseUIProject;
  CreateUnitNamesList;
  OpenUIProject;
end;

procedure TfrmDLUITestMain.FormCreate(Sender: TObject);
begin
  if not IsDLUIAvailable then begin
    ShowMessage('Cannot find DelphiLensUI.dll');
    Application.Terminate;
    Exit;
  end;

  FUnits := TCollections.CreateDictionary<string, string>(1000);
  LoadSettings;
end;

procedure TfrmDLUITestMain.btnSelectClick(Sender: TObject);
begin
  if dlgOpenProject.Execute then begin
    inpProject.Text := dlgOpenProject.FileName;
    CloseUIProject;
  end;
end;

procedure TfrmDLUITestMain.btnShowUIClick(Sender: TObject);
var
  navToColumn: integer;
  navToFile  : PChar;
  navToLine  : integer;
begin
  if lbFiles.ItemIndex < 0 then
    Exit;

  if DLUIActivate(FUIProject, PChar(lbFiles.Items[lbFiles.ItemIndex]),
       outSource.CaretPos.Y + 1, outSource.CaretPos.X + 1,
       navToFile, navToLine, navToColumn) <> 0
  then
    ReportUIError('DLUIActivate')
  else if assigned(navToFile) then
    NavigateTo(navToFile, navToLine, navToColumn);
end;

procedure TfrmDLUITestMain.CloseUIProject;
begin
  if FUIProject <> 0 then begin
    if DLUICloseProject(FUIProject) <> 0 then
      ReportUIError('DLUICloseProject');
    FUIProject := 0;
  end;
end;

procedure TfrmDLUITestMain.CopyUnitNames(const units: TParsedUnits);
var
  sl      : TStringList;
  unitInfo: TUnitInfo;
begin
  FUnits.Clear;
  sl := TStringList.Create;
  try
    for unitInfo in units do begin
      sl.Add(unitInfo.Name);
      FUnits.Add(unitInfo.Name, unitInfo.Path);
    end;
    sl.Sorted := true;
    lbFiles.Items.BeginUpdate;
    try
      lbFiles.Items.Clear;
      lbFiles.Items.Assign(sl);
    finally lbFiles.Items.EndUpdate; end;
  finally FreeAndNil(sl); end;
end;

procedure TfrmDLUITestMain.CreateUnitNamesList;
var
  delphiLens: IDelphiLens;
begin
  delphiLens := CreateDelphiLens(inpProject.Text);
  delphiLens.SearchPath := inpSearchPath.Text;
  delphiLens.ConditionalDefines := inpDefines.Text;
  with AutoRestoreCursor(crHourGlass) do
    CopyUnitNames(delphiLens.Rescan.ParsedUnits);
end;

procedure TfrmDLUITestMain.inpProjectChange(Sender: TObject);
begin
  SaveSettings;
end;

procedure TfrmDLUITestMain.lbFilesClick(Sender: TObject);
begin
  if lbFiles.ItemIndex < 0 then
    Exit;
  outSource.Lines.LoadFromFile(FUnits[lbFiles.Items[lbFiles.ItemIndex]]);
end;

procedure TfrmDLUITestMain.LoadSettings;
begin
  FLoading := true;
  inpProject.Text := DSiReadRegistry(CSettingsKey, CSettingsProject, '');
  inpSearchPath.Text := DSiReadRegistry(CSettingsKey, CSettingsSearchPath, '');
  inpDefines.Text := DSiReadRegistry(CSettingsKey, CSettingsConditionalDefines, '');
  FLoading := false;
end;

procedure TfrmDLUITestMain.NavigateTo(navToFile: string; navToLine, navToColumn: integer);
var
  idxFile: integer;
begin
  idxFile := lbFiles.Items.IndexOf(navToFile);
  if idxFile >= 0 then begin
    if idxFile <> lbFiles.ItemIndex then begin
      lbFiles.ItemIndex := idxFile;
      lbFiles.OnClick(lbFiles);
    end;
    outSource.CaretPos := Point(navToColumn - 1, navToLine - 1);
    outSource.Perform(EM_LINESCROLL, 0, navToLine - 1 - outSource.Perform(EM_GETFIRSTVISIBLELINE, 0, 0));
    ActiveControl := outSource;
  end;
end; { TfrmDLUITestMain.NavigateTo }

procedure TfrmDLUITestMain.OpenUIProject;
begin
  if FUIProject <> 0 then
    ShowMessage('UI project is already open!')
  else begin
    if DLUIOpenProject(PChar(inpProject.Text), FUIProject) <> 0 then begin
      ReportUIError('DLUIOpenProject');
      FUIProject := 0;
    end
    else if DLUISetProjectConfig(FUIProject, nil, PChar(inpDefines.Text), PChar(inpSearchPath.Text)) <> 0 then
      ReportUIError('DLUISetProjectConfig')
    else if DLUIRescanProject(FUIProject) <> 0 then
      ReportUIError('DLUIRescanProject');
  end;
end;

procedure TfrmDLUITestMain.ReportUIError(const functionName: string);
var
  err     : integer;
  errorMsg: PChar;
begin
  err := DLUIGetLastError(FUIProject, errorMsg);
  if err <> 0 then
    ShowMessageFmt('%s returned error [%d] %s', [functionName, err, errorMsg]);
end;

procedure TfrmDLUITestMain.SaveSettings;
begin
  if FLoading then
    Exit;

  DSiWriteRegistry(CSettingsKey, CSettingsProject, inpProject.Text);
  DSiWriteRegistry(CSettingsKey, CSettingsSearchPath, inpSearchPath.Text);
  DSiWriteRegistry(CSettingsKey, CSettingsConditionalDefines, inpDefines.Text);
end;

procedure TfrmDLUITestMain.SettingExit(Sender: TObject);
begin
  SaveSettings;
end;

initialization
  // test
end.
