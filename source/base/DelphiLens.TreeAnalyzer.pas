unit DelphiLens.TreeAnalyzer;

interface

uses
  DelphiLens.TreeAnalyzer.Intf;

function CreateDLTreeAnalyzer: IDLTreeAnalyzer;

implementation

uses
  Spring.Collections,
  GpStuff,
  DelphiAST.Consts, DelphiAST.Classes,
  DelphiLens.DelphiASTHelpers, DelphiLens.UnitInfo;

type
  TDLTreeAnalyzer = class(TInterfacedObject, IDLTreeAnalyzer)
  strict private
    FNodeToSection: array [TSyntaxNodeType] of TDLTypeSection;
  strict protected
    procedure GetUnitList(usesNode: TSyntaxNode; const units: IList<string>);
    function  ParseTypes(node: TSyntaxNode): IList<TDLTypeInfo>;
  public
    constructor Create;
    procedure AnalyzeTree(tree: TSyntaxNode; var unitInfo: TDLUnitInfo);
  end; { TDLTreeAnalyzer }

{ exports }

function CreateDLTreeAnalyzer: IDLTreeAnalyzer;
begin
  Result := TDLTreeAnalyzer.Create;
end; { CreateDLTreeAnalyzer }

{ TDLTreeAnalyzer }

constructor TDLTreeAnalyzer.Create;
begin
  inherited Create;
  FillChar(FNodeToSection, SizeOf(FNodeToSection), $FF);
  FNodeToSection[ntStrictPrivate]   := secStrictPrivate;
  FNodeToSection[ntPrivate]         := secPrivate;
  FNodeToSection[ntStrictProtected] := secStrictProtected;
  FNodeToSection[ntProtected]       := secProtected;
  FNodeToSection[ntPublic]          := secPublic;
  FNodeToSection[ntPublished]       := secPublished;
end; { TDLTreeAnalyzer.Create }

procedure TDLTreeAnalyzer.AnalyzeTree(tree: TSyntaxNode; var unitInfo: TDLUnitInfo);
var
  ndImpl: TSyntaxNode;
  ndIntf: TSyntaxNode;
  ndUnit: TSyntaxNode;
  ndUses: TSyntaxNode;
begin
  unitInfo := TDLUnitInfo.Create;
  if not tree.FindFirst(ntUnit, ndUnit) then
    Exit;

  unitInfo.Name := ndUnit.GetAttribute(anName);

  ndIntf := ndUnit.FindFirst(ntInterface);
  if assigned(ndIntf) then begin
    ndImpl := ndUnit.FindFirst(ntImplementation);
    unitInfo.InterfaceLoc.SetLocation(ndIntf);
    unitInfo.ImplementationLoc.SetLocation(ndImpl);
  end
  else begin
    ndIntf := ndUnit; //alias to simplify .dpr parsing
    ndImpl := nil;
  end;

  unitInfo.InitializationLoc.SetLocation(ndUnit.FindFirst(ntInitialization));
  unitInfo.FinalizationLoc.SetLocation(ndUnit.FindFirst(ntFinalization));

  ndUses := ndIntf.FindFirst(ntUses);
  if assigned(ndUses) then begin
    GetUnitList(ndUses, unitInfo.InterfaceUses);
    unitInfo.InterfaceUsesLoc.SetLocation(ndUses);
  end;

  if assigned(ndImpl) then begin
    ndUses := ndImpl.FindFirst(ntUses);
    if assigned(ndUses) then begin
      GetUnitList(ndUses, unitInfo.ImplementationUses);
      unitInfo.ImplementationUsesLoc.SetLocation(ndUses);
    end;
  end;

  unitInfo.InterfaceTypes := ParseTypes(ndIntf);
  if assigned(ndImpl) then
    unitInfo.ImplementationTypes := ParseTypes(ndImpl);
end; { TDLTreeAnalyzer.AnalyzeTree }

procedure TDLTreeAnalyzer.GetUnitList(usesNode: TSyntaxNode; const units: IList<string>);
var
  childNode: TSyntaxNode;
begin
  for childNode in usesNode.ChildNodes do
    if childNode.Typ = ntUnit then
      units.Add(childNode.GetAttribute(anName));
end; { TDLTreeAnalyzer.GetUnitList }

function TDLTreeAnalyzer.ParseTypes(node: TSyntaxNode): IList<TDLTypeInfo>;
var
  nodeSection : TSyntaxNode;
  nodeType    : TSyntaxNode;
  nodeTypeDecl: TSyntaxNode;
  nodeTypeSect: TSyntaxNode;
  typeInfo    : TDLTypeInfo;
begin
  Result := TCollections.CreateObjectList<TDLTypeInfo>;
  for nodeTypeSect in node.FindAll(ntTypeSection, false) do begin
    for nodeTypeDecl in nodeTypeSect.FindAll(ntTypeDecl) do begin
      typeInfo := TDLTypeInfo.Create;
      typeInfo.Location.SetLocation(nodeTypeDecl);
      if nodeTypeDecl.FindFirst(ntType, nodeType) then begin
        for nodeSection in nodeType.FindAll([ntStrictPrivate, ntPrivate, ntStrictProtected,
                                             ntProtected, ntPublic, ntPublished]) do
        begin
          typeInfo.EnsureSection(FNodeToSection[nodeSection.Typ]).Location.SetLocation(nodeSection);
          // TODO 1 -oPrimoz Gabrijelcic : Parse subtypes
        end;
      end;
      Result.Add(typeInfo);
    end;
  end;
end; { TDLTreeAnalyzer.ParseTypes }

end.
