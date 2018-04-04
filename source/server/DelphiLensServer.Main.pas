unit DelphiLensServer.Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  IdContext, IdBaseComponent, IdComponent, IdTCPConnection, IdCommandHandlers,
  IdCustomTCPServer, IdTCPServer, IdCmdTCPServer,
  Spring, Spring.Collections,
  DelphiLens.Intf,
  DelphiLensServer.Connection;

type
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
  private
    FConnections: IDictionary<TIdTCPConnection,TConnectionData>;
  protected
    function MakeIncludeList(includes: TIncludeFiles): string;
    function MakeProblemList(problems: TProblems): string;
    function MakeUnitList(units: TParsedUnits): string;
  public
  end;

var
  frmDelphiLensServer: TfrmDelphiLensServer;

implementation

uses
  DelphiAST.ProjectIndexer,
  DelphiLens;

{$R *.dfm}

procedure TfrmDelphiLensServer.CmdClose(ASender: TIdCommand);
var
  connData: TConnectionData;
begin
  connData := FConnections[ASender.Context.Connection];
  if assigned(connData.ScanResult) then
    connData.ScanResult.ReleaseAnalyzers;
  connData.ScanResult := nil;
  connData.DelphiLens := nil;
end;

procedure TfrmDelphiLensServer.CmdOpen(ASender: TIdCommand);
var
  connData: TConnectionData;
begin
  if ASender.Params.Count <> 1 then
    ASender.Reply.SetReply(400, 'Expected: OPEN <project>')
  else begin
    connData := FConnections[ASender.Context.Connection];
    connData.DelphiLens := CreateDelphiLens(ASender.Params[0]);
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
  else if not assigned(FConnections[ASender.Context.Connection].DelphiLens) then
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
begin
  connData := FConnections[ASender.Context.Connection];
  if not assigned(connData.DelphiLens) then
    ASender.Reply.SetReply(400, 'Project is not open')
  else if ASender.Params.Count <> 1 then
    ASender.Reply.SetReply(400, 'Expected: SHOW UNITS|MISSING|INCLUDES|PROBLEMS')
  else if SameText(ASender.Params[0], 'UNITS') then
    ASender.Reply.SetReply(200, MakeUnitList(connData.ScanResult.ParsedUnits))
  else if SameText(ASender.Params[0], 'MISSING') then
    ASender.Reply.SetReply(200, connData.ScanResult.NotFoundUnits.Text)
  else if SameText(ASender.Params[0], 'INCLUDES') then
    ASender.Reply.SetReply(200, MakeIncludeList(connData.ScanResult.IncludeFiles))
  else if SameText(ASender.Params[0], 'PROBLEMS') then
    ASender.Reply.SetReply(200, MakeProblemList(connData.ScanResult.Problems))
  else
    ASender.Reply.SetReply(400, 'Expected: SHOW UNITS|MISSING|INCLUDES|PROBLEMS');
end;

procedure TfrmDelphiLensServer.FormCreate(Sender: TObject);
begin
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

function TfrmDelphiLensServer.MakeUnitList(units: TParsedUnits): string;
var
  unitInfo: TUnitInfo;
  unitList: IList<string>;
begin
  unitList := TCollections.CreateList<string>;
  for unitInfo in units do
    unitList.Add(unitInfo.Name);
  Result := string.Join(#13#10, unitList.ToArray);
end;

end.
