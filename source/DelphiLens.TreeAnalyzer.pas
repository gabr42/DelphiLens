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
    procedure GetUnitList(usesNode: TSyntaxNode; var units: TArray<string>);
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
  ndUses: TSyntaxNode;
  units : TArray<string>;
begin
  unitInfo := TDLUnitInfo.Empty;
  if not FindNode(tree, ntUnit, ndUnit) then
    Exit;

  unitInfo.Name := ndUnit.GetAttribute(anName);

  ndIntf := FindType(ndUnit, ntInterface);
  if assigned(ndIntf) then begin
    ndImpl := FindType(ndUnit, ntImplementation);
    unitInfo.InterfaceLoc.SetLocation(ndIntf);
    unitInfo.ImplementationLoc.SetLocation(ndImpl);
  end
  else begin
    ndIntf := ndUnit; //alias to simplify .dpr parsing
    ndImpl := nil;
  end;

  unitInfo.InitializationLoc.SetLocation(FindType(ndUnit, ntInitialization));
  unitInfo.FinalizationLoc.SetLocation(FindType(ndUnit, ntFinalization));

  ndUses := FindType(ndIntf, ntUses);
  if assigned(ndUses) then begin
    GetUnitList(ndUses, units);
    unitinfo.InterfaceUses := units;
    unitInfo.InterfaceUsesLoc.SetLocation(ndUses);
  end;

  if assigned(ndImpl) then begin
    ndUses := FindType(ndImpl, ntUses);
    if assigned(ndUses) then begin
      GetUnitList(ndUses, units);
      unitinfo.ImplementationUses := units;
      unitInfo.ImplementationUsesLoc.SetLocation(ndUses);
    end;
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

procedure TDLTreeAnalyzer.GetUnitList(usesNode: TSyntaxNode; var units: TArray<string>);
var
  childNode: TSyntaxNode;
  iUnit    : integer;
begin
  SetLength(units, CountType(usesNode, ntUnit));

  iUnit := Low(units);
  for childNode in usesNode.ChildNodes do
    if childNode.Typ = ntUnit then begin
      units[iUnit] := childNode.GetAttribute(anName);
      Inc(iUnit);
    end;
end; { TDLTreeAnalyzer.GetUnitList }

end.
