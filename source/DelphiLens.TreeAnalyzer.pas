unit DelphiLens.TreeAnalyzer;

interface

uses
  DelphiLens.TreeAnalyzer.Intf;

function CreateDLTreeAnalyzer: IDLTreeAnalyzer;

implementation

uses
  DelphiAST.Consts, DelphiAST.Classes,
  DelphiLens.UnitInfo;

type
  TDLTreeAnalyzer = class(TInterfacedObject, IDLTreeAnalyzer)
  strict protected
    function  CountType(node: TSyntaxNode; nodeType: TSyntaxNodeType): integer;
    function  FindNode(node: TSyntaxNode; nodeType: TSyntaxNodeType;
      var childNode: TSyntaxNode): boolean;
    function  FindType(node: TSyntaxNode; nodeType: TSyntaxNodeType): TSyntaxNode;
    function  GetUnitList(usesNode: TSyntaxNode; var units: TArray<string>): boolean;
  public
    procedure AnalyzeTree(tree: TSyntaxNode; var unitInfo: TDLUnitInfo);
  end; { TDLTreeAnalyzer }

{ exports }

function CreateDLTreeAnalyzer: IDLTreeAnalyzer;
begin
  Result := TDLTreeAnalyzer.Create;
end; { CreateDLTreeAnalyzer }

{ TDLTreeAnalyzer }

procedure TDLTreeAnalyzer.AnalyzeTree(tree: TSyntaxNode; var unitInfo: TDLUnitInfo);
var
  ndImpl: TSyntaxNode;
  ndIntf: TSyntaxNode;
  ndUnit: TSyntaxNode;
  units : TArray<string>;
begin
  unitInfo := TDLUnitInfo.Empty;
  if not FindNode(tree, ntUnit, ndUnit) then
    Exit;

  ndIntf := FindType(ndUnit, ntInterface);
  if assigned(ndIntf) then
    ndImpl := FindType(ndUnit, ntImplementation)
  else begin
    ndIntf := ndUnit; //alias to simplify .dpr parsing
    ndImpl := nil;
  end;

  if GetUnitList(FindType(ndImpl, ntUses), units) then
    unitinfo.InterfaceUses := units;

  if assigned(ndImpl) then begin
    if GetUnitList(FindType(ndImpl, ntUses), units) then
      unitinfo.InterfaceUses := units;
  end;
end; { TDLTreeAnalyzer.AnalyzeTree }

function TDLTreeAnalyzer.CountType(node: TSyntaxNode; nodeType: TSyntaxNodeType): integer;
var
  child: TSyntaxNode;
begin
  Result := 0;
  for child in node.ChildNodes do
    if child.Typ = nodeType then
      Inc(Result);
end; { TDLTreeAnalyzer.CountType }

function TDLTreeAnalyzer.FindNode(node: TSyntaxNode; nodeType: TSyntaxNodeType;
  var childNode: TSyntaxNode): boolean;
begin
  childNode := FindType(node, nodetype);
  Result := assigned(childNode);
end; { TDLTreeAnalyzer.FindNode }

function TDLTreeAnalyzer.FindType(node: TSyntaxNode; nodeType: TSyntaxNodeType):
  TSyntaxNode;
begin
  if node.Typ = nodeType then
    Exit(node)
  else
    Result := node.FindNode(nodeType);
end; { TDLTreeAnalyzer.FindType }

function TDLTreeAnalyzer.GetUnitList(usesNode: TSyntaxNode; var units: TArray<string>): boolean;
var
  childNode: TSyntaxNode;
  iUnit    : integer;
begin
  Result := false;
  if not assigned(usesNode) then
    Exit;

  SetLength(units, CountType(usesNode, ntUnit));

  iUnit := Low(units);
  for childNode in usesNode.ChildNodes do
    if childNode.Typ = ntUnit then begin
      units[iUnit] := childNode.GetAttribute(anName);
      Inc(iUnit);
    end;
end; { TDLTreeAnalyzer.GetUnitList }

end.
