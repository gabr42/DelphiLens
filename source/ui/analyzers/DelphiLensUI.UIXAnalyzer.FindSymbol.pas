unit DelphiLensUI.UIXAnalyzer.FindSymbol;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateFindSymbol: IDLUIXAnalyzer;

implementation

uses
  Spring,
  DelphiAST.Consts,
  DelphiLens.UnitInfo,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXSymbolFinder = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  strict private
    FContext: IDLUIWorkerContext;
    FSearch : IDLUIXSearchAction;
  strict protected
    function  DoTheSearch(const searchTerm: string): ICoordinates;
    procedure ProgressCallback(const unitName: string; var abort: boolean);
  public
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXSymbolFinder }

{ exports }

function CreateFindSymbol: IDLUIXAnalyzer;
begin
  Result := TDLUIXSymbolFinder.Create;
end; { CreateFindSymbol }

{ TDLUIXSymbolFinder }

procedure TDLUIXSymbolFinder.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
var
  initialSearch : string;
  navigateToUnit: IDLUIXAction;
begin
  FContext := context;
  initialSearch := '';
  if assigned(context.NamedSyntaxNode) then
    initialSearch := context.NamedSyntaxNode.GetAttribute(anName);

  FSearch := CreateSearchAction('', initialSearch, DoTheSearch, ProgressCallback);
  navigateToUnit := CreateNavigationAction('&Open', Default(TDLUIXLocation), false);
  FSearch.ManagedActions.Add(TDLUIXManagedAction.Create(navigateToUnit, TDLUIXManagedAction.AnySelected()));
  FSearch.DefaultAction := navigateToUnit;

  frame.CreateAction(FSearch);
  frame.CreateAction(navigateToUnit, [faoDefault]);
end; { TDLUIXSymbolFinder.BuildFrame }

function TDLUIXSymbolFinder.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (context.Project.Analysis.Count > 0);
end; { TDLUIXSymbolFinder.CanHandle }

function TDLUIXSymbolFinder.DoTheSearch(const searchTerm: string): ICoordinates;
begin
  Result := FContext.Project.Analyzers.Find.All(searchTerm, ProgressCallback);
end; { TDLUIXSymbolFinder.DoTheSearch }

procedure TDLUIXSymbolFinder.ProgressCallback(const unitName: string;
  var abort: boolean);
begin
  if assigned(FSearch.ProgressCallback) then
    FSearch.ProgressCallback(unitName, abort);
end; { TDLUIXSymbolFinder.ProgressCallback }

end.
