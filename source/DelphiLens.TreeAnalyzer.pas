unit DelphiLens.TreeAnalyzer;

interface

uses
  DelphiLens.TreeAnalyzer.Intf;

function CreateDLTreeAnalyzer: IDLTreeAnalyzer;

implementation

uses
  Spring.Collections,
  DelphiAST.Consts, DelphiAST.Classes,
  DelphiLens.UnitInfo;

type
  TDLTreeAnalyzer = class(TInterfacedObject, IDLTreeAnalyzer)
  strict protected
    function  FindNode(node: TSyntaxNode; nodeType: TSyntaxNodeType;
      var childNode: TSyntaxNode): boolean;
    function  FindType(node: TSyntaxNode; nodeType: TSyntaxNodeType): TSyntaxNode;
    procedure GetUnitList(usesNode: TSyntaxNode; const units: IList<string>);
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
  unitInfo := TDLUnitInfo.Create;
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
    GetUnitList(ndUses, unitInfo.InterfaceUses);
    unitInfo.InterfaceUsesLoc.SetLocation(ndUses);
  end;

  if assigned(ndImpl) then begin
    ndUses := FindType(ndImpl, ntUses);
    if assigned(ndUses) then begin
      GetUnitList(ndUses, unitInfo.ImplementationUses);
      unitInfo.ImplementationUsesLoc.SetLocation(ndUses);
    end;
  end;

//  unitInfo.InterfaceTypes := ParseTypes(ndIntf);
//  if assigned(ndImpl) then
//    unitInfo.ImplementationTypes := ParseTypes(ndImpl);
end; { TDLTreeAnalyzer.AnalyzeTree }

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

procedure TDLTreeAnalyzer.GetUnitList(usesNode: TSyntaxNode; const units: IList<string>);
var
  childNode: TSyntaxNode;
begin
  for childNode in usesNode.ChildNodes do
    if childNode.Typ = ntUnit then
      units.Add(childNode.GetAttribute(anName));
end; { TDLTreeAnalyzer.GetUnitList }

end.
