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
  search        : IDLUIXSearchAction;
begin
  initialSearch := '';
  if assigned(context.NamedSyntaxNode) then
    initialSearch := context.NamedSyntaxNode.GetAttribute(anName);

  search := CreateSearchAction('', DoTheSearch, ProgressCallback);
  navigateToUnit := CreateNavigationAction('&Open', Default(TDLUIXLocation), false);
  search.ManagedActions.Add(TDLUIXManagedAction.Create(navigateToUnit, TDLUIXManagedAction.AnySelected()));
  search.DefaultAction := navigateToUnit;

  frame.CreateAction(search);
  frame.CreateAction(navigateToUnit, [faoDefault]);
end; { TDLUIXSymbolFinder.BuildFrame }

function TDLUIXSymbolFinder.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (context.Project.Analysis.Count > 0);
end; { TDLUIXSymbolFinder.CanHandle }

function TDLUIXSymbolFinder.DoTheSearch(const searchTerm: string): ICoordinates;
begin
  //
end; { TDLUIXSymbolFinder.DoTheSearch }

procedure TDLUIXSymbolFinder.ProgressCallback(const unitName: string;
  var abort: boolean);
begin
  //
end; { TDLUIXSymbolFinder.ProgressCallback }

end.
