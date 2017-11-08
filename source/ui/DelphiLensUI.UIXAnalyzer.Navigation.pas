unit DelphiLensUI.UIXAnalyzer.Navigation;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateNavigationAnalyzer: IDLUIXAnalyzer;

implementation

uses
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers,
  DelphiLens.UnitInfo, DelphiLens.TreeAnalyzer.Intf, DelphiLens.TreeAnalyzer;

type
  TDLUIXAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  public
    function CanHandle(const state: TDLAnalysisState): boolean;
  end; { TDLUIXAnalyzer }

{ exports }

function CreateNavigationAnalyzer: IDLUIXAnalyzer;
begin
  Result := TDLUIXAnalyzer.Create;
end; { CreateNavigationAnalyzer }

function TDLUIXAnalyzer.CanHandle(const state: TDLAnalysisState): boolean;
var
  dlUnitInfo  : TDLUnitInfo;
  treeAnalyzer: IDLTreeAnalyzer;
  unitInfo    : TProjectIndexer.TUnitInfo;
begin
  Result := state.ProjectInfo.ParsedUnits.Find(state.FileName, unitInfo);
  treeAnalyzer := CreateDLTreeAnalyzer;
  treeAnalyzer.AnalyzeTree(unitInfo.SyntaxTree, dlUnitInfo);
end;

end.
