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
    function  FindType(node: TSyntaxNode; nodeType: TSyntaxNodeType): TSyntaxNode;
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
begin
  unitInfo := TDLUnitInfo.Empty;
  // TODO 1 -oPrimoz Gabrijelcic : implement: TDLTreeAnalyzer.AnalyzeTree
end; { TDLTreeAnalyzer.AnalyzeTree }

function TDLTreeAnalyzer.FindType(node: TSyntaxNode; nodeType: TSyntaxNodeType):
  TSyntaxNode;
begin
  if node.Typ = nodeType then
    Exit(node)
  else
    Result := node.FindNode(nodeType);
end; { TDLTreeAnalyzer.FindType }

end.
