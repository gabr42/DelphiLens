unit DelphiLensDesktop.Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DelphiLens.Intf, System.Actions, Vcl.ActnList, DelphiAST.Classes;

type
  TfrmDLMain = class(TForm)
    btnRescan     : TButton;
    btnSelect     : TButton;
    dlgOpenProject: TFileOpenDialog;
    inpDefines    : TEdit;
    inpProject    : TEdit;
    inpSearchPath : TEdit;
    lbFiles       : TListBox;
    lblDefines    : TLabel;
    lblProject    : TLabel;
    lblSearchPath : TLabel;
    outLog        : TMemo;
    btnParsedUnits: TButton;
    btnIncludeFiles: TButton;
    btnNotFound: TButton;
    ActionList: TActionList;
    actParsedUnits: TAction;
    actIncludeFiles: TAction;
    actNotFound: TAction;
    btnProblems: TButton;
    actProblems: TAction;
    procedure actIncludeFilesExecute(Sender: TObject);
    procedure actNotFoundExecute(Sender: TObject);
    procedure actParsedUnitsExecute(Sender: TObject);
    procedure actProblemsExecute(Sender: TObject);
    procedure btnRescanClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure EnableResultActions(Sender: TObject);
    procedure inpProjectChange(Sender: TObject);
    procedure lbFilesClick(Sender: TObject);
    procedure SettingExit(Sender: TObject);
  private const
    CSettingsKey = '\SOFTWARE\Gp\DelphiLens\DelphiLensDesktop';
    CSettingsProject            = 'Project';
    CSettingsSearchPath         = 'SearchPath';
    CSettingsConditionalDefines = 'ConditionalDefines';
  type
    TShowing = (shParsedUnits, shIncludeFiles, shNotFound, shProblems);
  var
    FDelphiLens: IDelphiLens;
    FLoading   : boolean;
    FScanResult: IDLScanResult;
    FShowing   : TShowing;
    function AttributestoStr(const attributes: TArray<TAttributeEntry>): string;
  strict protected
    procedure DumpSyntaxTree(node: TSyntaxNode; const prefix: string);
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ShowIncludeFiles;
    procedure ShowMissingFiles;
    procedure ShowParsedUnits;
    procedure ShowProblems;
  public
  end;

var
  frmDLMain: TfrmDLMain;

implementation

uses
  System.RTTI,
  DSiWin32,
  GpVCL,
  DelphiAST.Consts,
  DelphiLens;

{$R *.dfm}

procedure TfrmDLMain.actIncludeFilesExecute(Sender: TObject);
begin
  ShowIncludeFiles;
end;

procedure TfrmDLMain.actNotFoundExecute(Sender: TObject);
begin
  ShowMissingFiles;
end;

procedure TfrmDLMain.actParsedUnitsExecute(Sender: TObject);
begin
  ShowParsedUnits;
end;

procedure TfrmDLMain.actProblemsExecute(Sender: TObject);
begin
  ShowProblems;
end;

function TfrmDLMain.AttributestoStr(const attributes: TArray<TAttributeEntry>): string;
var
  i: integer;
begin
  Result := '';
  if Length(attributes) > 0 then begin
    Result := '[';
    for i := Low(attributes) to High(attributes) do begin
      if i > Low(attributes) then
        Result := Result + ',';
      Result := Result + TRttiEnumerationType.GetName<TAttributeName>(attributes[i].Key) + '=' + attributes[i].Value;
    end;
    Result := Result + ']';
  end;
end;

procedure TfrmDLMain.btnRescanClick(Sender: TObject);
begin
  FScanResult := nil;
  if not assigned(FDelphiLens) then
    FDelphiLens := CreateDelphiLens(inpProject.Text);
  FDelphiLens.SearchPath := inpSearchPath.Text;
  FDelphiLens.ConditionalDefines := inpDefines.Text;
  with AutoRestoreCursor(crHourGlass) do begin
    FScanResult := FDelphiLens.Rescan;
    outLog.Text := Format(
      'Indexer'#13#10 +
      '  Parsed units: %d'#13#10 +
      '  Include files: %d'#13#10 +
      '  Not found: %d'#13#10 +
      '  Problems: %d'#13#10 +
      'Cache'#13#10 +
      '  Scanned: %d'#13#10 +
      '  Cached: %d',
      [FScanResult.ParsedUnits.Count, FScanResult.IncludeFiles.Count,
       FScanResult.NotFoundUnits.Count, FScanResult.Problems.Count,
      FScanResult.CacheStatistics.NumScanned, FScanResult.CacheStatistics.NumCached]);
    ShowParsedUnits;
  end;
end;

procedure TfrmDLMain.FormCreate(Sender: TObject);
begin
  LoadSettings;
end;

procedure TfrmDLMain.btnSelectClick(Sender: TObject);
begin
  if dlgOpenProject.Execute then begin
    inpProject.Text := dlgOpenProject.FileName;
    FDelphiLens := nil;
  end;
end;

procedure TfrmDLMain.DumpSyntaxTree(node: TSyntaxNode; const prefix: string);
var
  children   : TArray<TSyntaxNode>;
  i          : integer;
  newPrefix  : string;
  sAttributes: string;
begin
  sAttributes := AttributestoStr(node.Attributes);
  outLog.Lines.Add(prefix + TRttiEnumerationType.GetName<TSyntaxNodeType>(node.Typ) + ' ' + sAttributes);
  newPrefix := prefix + '  ';
  children := node.ChildNodes;
  for i := Low(children) to High(children) do
    DumpSyntaxTree(children[i], newPrefix);
end;

procedure TfrmDLMain.EnableResultActions(Sender: TObject);
begin
  (Sender as TAction).Enabled := assigned(FScanResult);
end;

procedure TfrmDLMain.inpProjectChange(Sender: TObject);
begin
  SaveSettings;
end;

procedure TfrmDLMain.lbFilesClick(Sender: TObject);
var
  i: integer;
begin
  if FShowing <> shParsedUnits then
    Exit;

  outLog.Clear;
  outLog.Lines.BeginUpdate;
  try
    for i := 0 to FScanResult.ParsedUnits.Count - 1 do
      if FScanResult.ParsedUnits[i].Name = lbFiles.Items[lbFiles.ItemIndex] then begin
        DumpSyntaxTree(FScanResult.ParsedUnits[i].SyntaxTree, '');
        break; //for
      end;
  finally outLog.Lines.EndUpdate; end;
end;

procedure TfrmDLMain.LoadSettings;
begin
  FLoading := true;
  inpProject.Text := DSiReadRegistry(CSettingsKey, CSettingsProject, '');
  inpSearchPath.Text := DSiReadRegistry(CSettingsKey, CSettingsSearchPath, '');
  inpDefines.Text := DSiReadRegistry(CSettingsKey, CSettingsConditionalDefines, '');
  FLoading := false;
end;

procedure TfrmDLMain.SaveSettings;
begin
  if FLoading then
    Exit;

  DSiWriteRegistry(CSettingsKey, CSettingsProject, inpProject.Text);
  DSiWriteRegistry(CSettingsKey, CSettingsSearchPath, inpSearchPath.Text);
  DSiWriteRegistry(CSettingsKey, CSettingsConditionalDefines, inpDefines.Text);
end;

procedure TfrmDLMain.SettingExit(Sender: TObject);
begin
  SaveSettings;
end;

procedure TfrmDLMain.ShowIncludeFiles;
var
  i: integer;
begin
  lbFiles.Clear;
  lbFiles.Items.BeginUpdate;
  try
    for i := 0 to FScanResult.IncludeFiles.Count - 1 do
      lbFiles.Items.Add(FScanResult.IncludeFiles[i].Name);
  finally lbFiles.Items.EndUpdate; end;
  FShowing := shIncludeFiles;
end;

procedure TfrmDLMain.ShowMissingFiles;
var
  i: integer;
begin
  lbFiles.Clear;
  lbFiles.Items.BeginUpdate;
  try
    for i := 0 to FScanResult.NotFoundUnits.Count - 1 do
      lbFiles.Items.Add(FScanResult.NotFoundUnits[i]);
  finally lbFiles.Items.EndUpdate; end;
  FShowing := shParsedUnits;
end;

procedure TfrmDLMain.ShowParsedUnits;
var
  i: integer;
begin
  lbFiles.Clear;
  lbFiles.Items.BeginUpdate;
  try
    for i := 0 to FScanResult.ParsedUnits.Count - 1 do
      lbFiles.Items.Add(FScanResult.ParsedUnits[i].Name);
  finally lbFiles.Items.EndUpdate; end;
  FShowing := shParsedUnits;
end;

procedure TfrmDLMain.ShowProblems;
var
  i: integer;
begin
  lbFiles.Clear;
  outLog.Clear;
  for i := 0 to FScanResult.Problems.Count - 1 do
    outLog.Lines.Add(FScanResult.Problems[i].FileName + ': ' + FScanResult.Problems[i].Description);
  FShowing := shProblems;
end;

end.
