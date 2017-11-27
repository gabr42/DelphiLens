unit DelphiLensUI.UIXAnalyzer.UnitBrowser;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateUnitBrowser: IDLUIXAnalyzer;

implementation

uses
  Spring, Spring.Collections,
  DelphiAST.ProjectIndexer,
  DelphiLens.Intf,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXUnitBrowser = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  strict private
    FUnitNames: IList<string>;
  public
    constructor Create;
    procedure BuildFrame(const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXNavigationAnalyzer }

{ exports }

function CreateUnitBrowser: IDLUIXAnalyzer;
begin
  Result := TDLUIXUnitBrowser.Create;
end; { CreateUnitBrowser }

{ TDLUIXUnitBrowser }

constructor TDLUIXUnitBrowser.Create;
begin
  inherited;
  FUnitNames := TCollections.CreateList<string>;
end;

procedure TDLUIXUnitBrowser.BuildFrame(const frame: IDLUIXFrame;
  const context: IDLUIWorkerContext);
var
  filteredList  : IDLUIXFilteredListAction;
  navigateToUnit: IDLUIXAction;
  openUsedIn    : IDLUIXAction;
  openUses      : IDLUIXAction;
  unitInfo      : TProjectIndexer.TUnitInfo;
begin
  FUnitNames.Clear;
  for unitInfo in context.Project.ParsedUnits do
    FUnitNames.Add(unitInfo.Name);
  FUnitNames.Sort;

  filteredList := CreateFilteredListAction('', FUnitNames, context.Source.FileName) as IDLUIXFilteredListAction;
  openUses := CreateOpenUnitBrowserAction('&Uses', CreateUnitBrowser, '', ubtUses);
  openUsedIn := CreateOpenUnitBrowserAction('Used &by', CreateUnitBrowser, '', ubtUsedBy);
  navigateToUnit := CreateNavigationAction('&Open', Default(TDLUIXLocation), false);

  filteredList.ManagedActions := [{openUses, openUsed, }navigateToUnit];
  filteredList.DefaultAction := navigateToUnit;

  frame.CreateAction(filteredList);
  frame.CreateAction(openUses, [faoDisabled]);
  frame.CreateAction(openUsedIn, [faoDisabled]);
  frame.CreateAction(navigateToUnit, [faoDefault]);
end; { TDLUIXUnitBrowser.BuildFrame }

function TDLUIXUnitBrowser.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (context.Project.ParsedUnits.Count > 0);
end; { TDLUIXUnitBrowser.CanHandle }

end.
