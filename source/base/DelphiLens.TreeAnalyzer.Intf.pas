unit DelphiLens.TreeAnalyzer.Intf;

interface

uses
  DelphiAST.Classes,
  DelphiLens.UnitInfo;

type
  IDLTreeAnalyzer = interface ['{FBF77EBB-1300-41C8-B50F-7C4F094D2433}']
    procedure AnalyzeTree(tree: TSyntaxNode; var unitInfo: IDLUnitInfo);
  end; { IDLTreeAnalyzer }

implementation

end.
