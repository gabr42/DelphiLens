unit DelphiLensDesktop.Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DelphiLens.Intf, System.Actions, Vcl.ActnList, DelphiAST.Classes, DelphiLens.UnitInfo;

type
  TfrmDLMain = class(TForm)
    actAnalysis     : TAction;
    actIncludeFiles : TAction;
    ActionList      : TActionList;
    actNotFound     : TAction;
    actParsedUnits  : TAction;
    actProblems     : TAction;
    btnAnalysis     : TButton;
    btnIncludeFiles : TButton;
    btnNotFound     : TButton;
    btnParsedUnits  : TButton;
    btnProblems     : TButton;
    btnRescan       : TButton;
    btnSelect       : TButton;
    dlgOpenProject  : TFileOpenDialog;
    inpDefines      : TEdit;
    inpProject      : TEdit;
    inpSearchPath   : TEdit;
    lbFiles         : TListBox;
    lblDefines      : TLabel;
    lblProject      : TLabel;
    lblSearchPath   : TLabel;
    lblWhatIsShowing: TLabel;
    outLog          : TMemo;
    procedure actAnalysisExecute(Sender: TObject);
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
    TShowing = (shAnalysis, shParsedUnits, shIncludeFiles, shNotFound, shProblems);
  var
    FDelphiLens: IDelphiLens;
    FLoading   : boolean;
    FScanResult: IDLScanResult;
    FShowing   : TShowing;
  strict protected
    function  AttributestoStr(const attributes: TArray<TAttributeEntry>): string;
    procedure DumpAnalysis(const unitInfo: TDLUnitInfo);
    procedure DumpSyntaxTree(node: TSyntaxNode; const prefix: string);
    procedure DumpUses(const usesList: TArray<string>; const location: TDLCoordinate);
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ShowAnalysis;
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
  GpStuff, GpVCL,
  DelphiAST.Consts,
  DelphiLens;

{$R *.dfm}

procedure TfrmDLMain.actAnalysisExecute(Sender: TObject);
begin
  ShowAnalysis;
end;

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
    ShowAnalysis;
  end;
end;

procedure TfrmDLMain.FormCreate(Sender: TObject);
begin
  lblWhatIsShowing.Caption := '';
  LoadSettings;
end;

procedure TfrmDLMain.btnSelectClick(Sender: TObject);
begin
  if dlgOpenProject.Execute then begin
    inpProject.Text := dlgOpenProject.FileName;
    FDelphiLens := nil;
  end;
end;

procedure TfrmDLMain.DumpAnalysis(const unitInfo: TDLUnitInfo);
var
  isProgram: boolean;
begin
  isProgram := not unitInfo.InterfaceLoc.IsValid;
  outLog.Lines.Add(IFF(isProgram, 'program ', 'unit ') + unitInfo.Name);
  if isProgram then
    DumpUses(unitInfo.InterfaceUses, unitInfo.InterfaceUsesLoc)
  else begin
    outLog.Lines.Add('Interface @ ' + unitInfo.InterfaceLoc.ToString);
    DumpUses(unitInfo.InterfaceUses, unitInfo.InterfaceUsesLoc);
    outLog.Lines.Add('Implementation @ ' + unitInfo.ImplementationLoc.ToString);
    DumpUses(unitInfo.ImplementationUses, unitInfo.ImplementationUsesLoc);
  end;
  if unitInfo.InitializationLoc.IsValid then
    outLog.Lines.Add('Initialization @ ' + unitInfo.InitializationLoc.ToString);
  if unitInfo.FinalizationLoc.IsValid then
    outLog.Lines.Add('Finalization @ ' + unitInfo.FinalizationLoc.ToString);
end;

procedure TfrmDLMain.DumpSyntaxTree(node: TSyntaxNode; const prefix: string);
var
  children    : TArray<TSyntaxNode>;
  i           : integer;
  newPrefix   : string;
  nodePosition: string;
  sAttributes : string;
begin
  sAttributes := AttributestoStr(node.Attributes);
  if Node is TCompoundSyntaxNode then
    nodePosition := Format('%d,%d - %d,%d', [
             TCompoundSyntaxNode(Node).Line, TCompoundSyntaxNode(Node).Col,
             TCompoundSyntaxNode(Node).EndLine, TCompoundSyntaxNode(Node).EndCol])
  else
    nodePosition := Format('%d,%d', [node.Line, node.Col]);
  outLog.Lines.Add(Format('%s%s %s @%s',
    [prefix, TRttiEnumerationType.GetName<TSyntaxNodeType>(node.Typ),
     sAttributes, nodePosition]));
  newPrefix := prefix + '  ';
  children := node.ChildNodes;
  for i := Low(children) to High(children) do
    DumpSyntaxTree(children[i], newPrefix);
end;

procedure TfrmDLMain.DumpUses(const usesList: TArray<string>; const location: TDLCoordinate);
var
  unitName: string;
begin
  if not location.IsValid then
    Exit;

  outLog.Lines.Add('uses @ ' + location.ToString);
  for unitName in usesList do
    outLog.Lines.Add('  ' + unitName);
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
  if not (FShowing in [shAnalysis, shParsedUnits]) then
    Exit;

  outLog.Clear;
  outLog.Lines.BeginUpdate;
  try
    if FShowing = shAnalysis then begin
      for i := 0 to FScanResult.Analysis.Count - 1 do
        if FScanResult.Analysis[i].Name = lbFiles.Items[lbFiles.ItemIndex] then begin
          DumpAnalysis(FScanResult.Analysis[i]);
          break; //for
        end
    end
    else begin
      for i := 0 to FScanResult.ParsedUnits.Count - 1 do
        if FScanResult.ParsedUnits[i].Name = lbFiles.Items[lbFiles.ItemIndex] then begin
          DumpSyntaxTree(FScanResult.ParsedUnits[i].SyntaxTree, '');
          break; //for
        end;
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

procedure TfrmDLMain.ShowAnalysis;
var
  i: integer;
begin
  lblWhatIsShowing.Caption := 'Analysis';
  lbFiles.Clear;
  lbFiles.Items.BeginUpdate;
  try
    for i := 0 to FScanResult.Analysis.Count - 1 do
      lbFiles.Items.Add(FScanResult.Analysis[i].Name);
  finally lbFiles.Items.EndUpdate; end;
  FShowing := shAnalysis;
end;

procedure TfrmDLMain.ShowIncludeFiles;
var
  i: integer;
begin
  lblWhatIsShowing.Caption := 'Include files';
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
  lblWhatIsShowing.Caption := 'Missing files';
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
  lblWhatIsShowing.Caption := 'Parsed units';
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
  lblWhatIsShowing.Caption := 'Problems';
  lbFiles.Clear;
  outLog.Clear;
  for i := 0 to FScanResult.Problems.Count - 1 do
    outLog.Lines.Add(FScanResult.Problems[i].FileName + ': ' + FScanResult.Problems[i].Description);
  FShowing := shProblems;
end;

initialization
  // test
end.
