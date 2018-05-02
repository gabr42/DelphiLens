unit DelphiLensServer.Main;

(* Test protocol:

SET SEARCHPATH=analyzers;engines;..\base;..\..\GpDelphiUnits\src;..\..\DelphiAST\Project indexer;..\..\DelphiAST\source;..\..\DelphiAST\source\SimpleParser;..\..\OmniThreadLibrary;..\..\Spring4D\Source\Base;..\..\Spring4D\Source\Base\Collections;..\..\Spring4D\Source
OPEN h:\RAZVOJ\DelphiLens\source\ui\DelphiLensUI.dpr
SHOW UNITS UIXEngine
UNIT DelphiLensUI.UIXEngine.Intf USES
UNIT DelphiLensUI.UIXEngine.Intf USEDIN
UNIT DelphiLensUI.UIXEngine.Intf TYPES
FIND TDLCoordinate
CLOSE
QUIT
*)

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  IdContext, IdBaseComponent, IdComponent, IdTCPConnection, IdCommandHandlers,
  IdCustomTCPServer, IdTCPServer, IdCmdTCPServer,
  Spring, Spring.Collections,
  DelphiLens.Intf;

type
  TConnectionData = class
  strict private
    FConditionals: string;
    FDelphiLens  : IDelphiLens;
    FScanResult  : IDLScanResult;
    FSearchPath  : string;
  public
    destructor Destroy; override;
    procedure Close;
    property Conditionals: string read FConditionals write FConditionals;
    property DelphiLens: IDelphiLens read FDelphiLens write FDelphiLens;
    property ScanResult: IDLScanResult read FScanResult write FScanResult;
    property SearchPath: string read FSearchPath write FSearchPath;
  end;

  TfrmDelphiLensServer = class(TForm)
    IdCmdTCPServer1: TIdCmdTCPServer;
    lbLog: TListBox;
    procedure IdCmdTCPServer1Connect(AContext: TIdContext);
    procedure IdCmdTCPServer1Disconnect(AContext: TIdContext);
    procedure CmdOpen(ASender: TIdCommand);
    procedure CmdQuit(ASender: TIdCommand);
    procedure FormCreate(Sender: TObject);
    procedure CmdClose(ASender: TIdCommand);
    procedure CmdSet(ASender: TIdCommand);
    procedure CmdShow(ASender: TIdCommand);
    procedure CmdUnit(ASender: TIdCommand);
    procedure CmdFind(ASender: TIdCommand);
  private
    FConnections: IDictionary<TIdTCPConnection,TConnectionData>;
  protected
    procedure CloseConnection(connection: TIdTCPConnection);
    function FindIdentifier(const scanResult: IDLScanResult; const ident: string): string;
    function MakeIncludeList(includes: TIncludeFiles): string;
    function MakeProblemList(problems: TProblems): string;
    function MakeUnitList(units: TParsedUnits; const substring: string): string;
    function UnitTypes(const scanResult: IDLScanResult;
      const unitName: string): string;
  public
  end;

var
  frmDelphiLensServer: TfrmDelphiLensServer;

implementation

uses
  System.StrUtils,
  DelphiAST.ProjectIndexer,
  DelphiLens, DelphiLens.UnitInfo, DelphiLens.Analyzers.Intf;

{$R *.dfm}

{ TConnectionData }

procedure TConnectionData.Close;
begin
  if assigned(FScanResult) then
    FScanResult.ReleaseAnalyzers;
  FScanResult := nil;
  FDelphiLens := nil;
end;

destructor TConnectionData.Destroy;
begin
  Close;
  inherited;
end;

{ TfrmDelphiLensServer }

procedure TfrmDelphiLensServer.CloseConnection(connection: TIdTCPConnection);
var
  connData: TConnectionData;
begin
  if FConnections.TryGetValue(connection, connData) then
    connData.Close;
end;

procedure TfrmDelphiLensServer.CmdClose(ASender: TIdCommand);
begin
  CloseConnection(ASender.Context.Connection);
end;

procedure TfrmDelphiLensServer.CmdFind(ASender: TIdCommand);
var
  connData: TConnectionData;
begin
  connData := FConnections[ASender.Context.Connection];
  if ASender.Params.Count <> 1 then
    ASender.Reply.SetReply(400, 'Expected: FIND identifier')
  else if not assigned(connData.ScanResult) then
    ASender.Reply.SetReply(400, 'Project is not open')
  else
    ASender.Reply.SetReply(200, FindIdentifier(connData.ScanResult, ASender.Params[0]));
end;

procedure TfrmDelphiLensServer.CmdOpen(ASender: TIdCommand);
var
  connData: TConnectionData;
begin
  if ASender.Params.Count <> 1 then
    ASender.Reply.SetReply(400, 'Expected: OPEN <project>')
  else begin
    connData := FConnections[ASender.Context.Connection];
    try
      connData.DelphiLens := CreateDelphiLens(ASender.Params[0]);
    except
      on E: Exception do begin
        ASender.Reply.SetReply(400, E.Message);
        Exit;
      end;
    end;
    connData.DelphiLens.ConditionalDefines := connData.Conditionals;
    connData.DelphiLens.SearchPath := connData.SearchPath;
    connData.ScanResult := connData.DelphiLens.Rescan;
    ASender.Reply.SetReply(200, 'OK' + #13#10 +
      connData.ScanResult.ParsedUnits.Count.ToString + ' parsed units' + #13#10 +
      connData.ScanResult.NotFoundUnits.Count.ToString + ' missing units' + #13#10 +
      connData.ScanResult.IncludeFiles.Count.ToString + ' include files' + #13#10 +
      connData.ScanResult.Problems.Count.ToString + ' problems' + #13#10);
  end;
end;

procedure TfrmDelphiLensServer.CmdQuit(ASender: TIdCommand);
begin
  ASender.Context.Connection.Disconnect;
end;

procedure TfrmDelphiLensServer.CmdSet(ASender: TIdCommand);
begin
  if ASender.Params.Count <> 2 then
    ASender.Reply.SetReply(400, 'Expected: SET parameter=value')
  else if assigned(FConnections[ASender.Context.Connection].DelphiLens) then
    ASender.Reply.SetReply(400, 'Project is already open')
  else if SameText(ASender.Params[0], 'SEARCHPATH') then
    FConnections[ASender.Context.Connection].SearchPath := ASender.Params[1]
  else if SameText(ASender.Params[0], 'CONDITIONALS') then
    FConnections[ASender.Context.Connection].Conditionals := ASender.Params[1]
  else
    ASender.Reply.SetReply(400, 'Supported parameters: SEARCHPATH, CONDITIONALS');
end;

procedure TfrmDelphiLensServer.CmdShow(ASender: TIdCommand);
var
  connData: TConnectionData;
  param2  : string;
begin
  connData := FConnections[ASender.Context.Connection];
  param2 := '';
  if ASender.Params.Count >= 2 then
    param2 := ASender.Params[1];
  if not assigned(connData.ScanResult) then
    ASender.Reply.SetReply(400, 'Project is not open')
  else if SameText(ASender.Params[0], 'UNITS') then
    ASender.Reply.SetReply(200, MakeUnitList(connData.ScanResult.ParsedUnits, param2))
  else if SameText(ASender.Params[0], 'MISSING') then
    ASender.Reply.SetReply(200, connData.ScanResult.NotFoundUnits.Text)
  else if SameText(ASender.Params[0], 'INCLUDES') then
    ASender.Reply.SetReply(200, MakeIncludeList(connData.ScanResult.IncludeFiles))
  else if SameText(ASender.Params[0], 'PROBLEMS') then
    ASender.Reply.SetReply(200, MakeProblemList(connData.ScanResult.Problems))
  else
    ASender.Reply.SetReply(400, 'Expected: SHOW UNITS|MISSING|INCLUDES|PROBLEMS');
end;

procedure TfrmDelphiLensServer.CmdUnit(ASender: TIdCommand);
var
  connData: TConnectionData;
begin
  connData := FConnections[ASender.Context.Connection];
  if ASender.Params.Count < 2 then begin
    ASender.Reply.SetReply(400, 'Expected: UNIT unit_name command');
    Exit;
  end;
  if not assigned(connData.ScanResult) then
    ASender.Reply.SetReply(400, 'Project is not open')
  else if SameText(ASender.Params[1], 'USES') then
    ASender.Reply.SetReply(200,
      string.Join(#13#10, connData.ScanResult.Analyzers.Units.UnitUses(ASender.Params[0]).ToArray))
  else if SameText(ASender.Params[1], 'USEDIN') then
    ASender.Reply.SetReply(200,
      string.Join(#13#10, connData.ScanResult.Analyzers.Units.UnitUsedBy(ASender.Params[0]).ToArray))
  else if SameText(ASender.Params[1], 'TYPES') then
    ASender.Reply.SetReply(200, UnitTypes(connData.ScanResult, ASender.Params[0]))
  else
    ASender.Reply.SetReply(400, 'Expected: UNIT unit_name USES|USEDIN|TYPES');
end;

function TfrmDelphiLensServer.FindIdentifier(const scanResult: IDLScanResult;
  const ident: string): string;
var
  coord    : TDLCoordinate;
  oneFile  : IList<string>;
  output   : IList<string>;
  unitCoord: TDLUnitCoordinates;
begin
  output := TCollections.CreateList<string>;
  oneFile := TCollections.CreateList<string>;
  for unitCoord in scanResult.Analyzers.Find.All(ident) do begin
    oneFile.Clear;
    for coord in unitCoord.Coordinates do
      oneFile.Add(coord.Line.ToString + ',' + coord.Column.ToString);
    output.Add(unitCoord.UnitName + ' ' + string.Join('/', oneFile.ToArray));
  end;
  Result := string.Join(#13#10, output.ToArray);
end;

procedure TfrmDelphiLensServer.FormCreate(Sender: TObject);
begin
  lbLog.Items.Add('Listening on port ' + IdCmdTCPServer1.Bindings[0].Port.ToString);
  FConnections := TCollections.CreateDictionary<TIdTCPConnection,TConnectionData>([doOwnsValues]);
end;

procedure TfrmDelphiLensServer.IdCmdTCPServer1Connect(AContext: TIdContext);
begin
  FConnections.Add(AContext.Connection, TConnectionData.Create);
end;

procedure TfrmDelphiLensServer.IdCmdTCPServer1Disconnect(AContext: TIdContext);
begin
  FConnections.Remove(AContext.Connection);
end;

function TfrmDelphiLensServer.MakeIncludeList(includes: TIncludeFiles): string;
var
  includeInfo: TProjectIndexer.TIncludeFileInfo;
  includeList: IList<string>;
begin
  includeList := TCollections.CreateList<string>;
  for includeInfo in includes do
    includeList.Add(includeInfo.Name);
  Result := string.Join(#13#10, includeList.ToArray);
end;

function TfrmDelphiLensServer.MakeProblemList(problems: TProblems): string;
var
  problemInfo: TProjectIndexer.TProblemInfo;
  problemList: IList<string>;
begin
  problemList := TCollections.CreateList<string>;
  for problemInfo in problems do
    problemList.Add(problemInfo.FileName + ' ' + problemInfo.Description);
  Result := string.Join(#13#10, problemList.ToArray);
end;

function TfrmDelphiLensServer.MakeUnitList(units: TParsedUnits; const substring: string): string;
var
  unitInfo: TUnitInfo;
  unitList: IList<string>;
begin
  unitList := TCollections.CreateList<string>;
  for unitInfo in units do
    if (substring = '') or ContainsText(unitInfo.Name, substring) then
      unitList.Add(unitInfo.Name);
  Result := string.Join(#13#10, unitList.ToArray);
end;

function TfrmDelphiLensServer.UnitTypes(const scanResult: IDLScanResult;
  const unitName: string): string;
var
  classes : IList<string>;
  typeInfo: TDLTypeInfo;
  unitInfo: IDLUnitInfo;
begin
  if not scanResult.Analysis.Find(unitName, unitInfo) then
    Exit('');

  classes := TCollections.CreateList<string>;
  for typeInfo in unitInfo.InterfaceTypes do
    classes.Add(typeInfo.Name);
  for typeInfo in unitInfo.ImplementationTypes do
    classes.Add(typeInfo.Name);
  classes.Sort;

  Result := string.Join(#13#10, classes.ToArray);
end;

end.
