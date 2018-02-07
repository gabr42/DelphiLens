unit DelphiLensUI.UIXAnalyzer.UnitBrowser;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateUnitBrowser: IDLUIXAnalyzer;

implementation

uses
  System.SysUtils, System.Generics.Defaults,
  Spring, Spring.Collections,
  DelphiAST.ProjectIndexer,
  DelphiLens.Intf, DelphiLens.UnitInfo,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXUnitBrowser = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  strict private type
    TUnitNames = IList<string>;
  var
    FUnitNames: TUnitNames;
  strict protected
    procedure MakeUnique(const units: TUnitNames);
    procedure PrepareUnitNames(const projectInfo: IDLScanResult;
      filterType: TDLUIXUnitBrowserType; const initialUnit: string;
      const units: TUnitNames);
  public
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXNavigationAnalyzer }

{ exports }

function CreateUnitBrowser: IDLUIXAnalyzer;
begin
  Result := TDLUIXUnitBrowser.Create;
end; { CreateUnitBrowser }

{ TDLUIXUnitBrowser }

procedure TDLUIXUnitBrowser.PrepareUnitNames(const projectInfo: IDLScanResult;
  filterType: TDLUIXUnitBrowserType; const initialUnit: string; const units: TUnitNames);
var
  unsortedUnits: ICollection<string>;
begin
  units.Clear;
  case filterType of
    ubtNormal: unsortedUnits := projectInfo.Analyzers.Units.All;
    ubtUses:   unsortedUnits := projectInfo.Analyzers.Units.UnitUses(initialUnit);
    ubtUsedBy: unsortedUnits := projectInfo.Analyzers.Units.UnitUsedBy(initialUnit);
  end;
  units.AddRange(unsortedUnits);
  units.Sort;
end; { TDLUIXUnitBrowser.PrepareUnitNames }

procedure TDLUIXUnitBrowser.BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
  const context: IDLUIWorkerContext);
var
  filteredList   : IDLUIXFilteredListAction;
  filterType     : TDLUIXUnitBrowserType;
  initialUnit    : string;
  navigateToUnit : IDLUIXAction;
  openUnitBrowser: IDLUIXOpenUnitBrowserAction;
  openUsedBy     : IDLUIXAction;
  openUses       : IDLUIXAction;
begin
  if Supports(action, IDLUIXOpenUnitBrowserAction, openUnitBrowser) then begin
    filterType := openUnitBrowser.FilterType;
    initialUnit := openUnitBrowser.InitialUnit;
  end
  else begin
    filterType := ubtNormal;
    initialUnit := '';
  end;

  FUnitNames := TCollections.CreateList<string>(TIStringComparer.Ordinal);
  PrepareUnitNames(context.Project, filterType, initialUnit, FUnitNames);

  filteredList := CreateFilteredListAction('', FUnitNames, context.Source.UnitName) as IDLUIXFilteredListAction;
  openUses := CreateOpenUnitBrowserAction('&Uses', CreateUnitBrowser, '', ubtUses);
  openUsedBy := CreateOpenUnitBrowserAction('Used &by', CreateUnitBrowser, '', ubtUsedBy);
  navigateToUnit := CreateNavigationAction('&Open', Default(TDLUIXLocation), false);

  filteredList.ManagedActions.Add(TDLUIXManagedAction.Create(openUses, TDLUIXManagedAction.SingleSelected()));
  filteredList.ManagedActions.Add(TDLUIXManagedAction.Create(openUsedBy, TDLUIXManagedAction.SingleSelected()));
  filteredList.ManagedActions.Add(TDLUIXManagedAction.Create(navigateToUnit, TDLUIXManagedAction.AnySelected()));
  filteredList.DefaultAction := navigateToUnit;

  frame.CreateAction(filteredList);
  frame.CreateAction(openUses);
  frame.CreateAction(openUsedBy);
  frame.CreateAction(navigateToUnit, [faoDefault]);
end; { TDLUIXUnitBrowser.BuildFrame }

function TDLUIXUnitBrowser.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (context.Project.Analysis.Count > 0);
end; { TDLUIXUnitBrowser.CanHandle }

procedure TDLUIXUnitBrowser.MakeUnique(const units: TUnitNames);
var
  i: integer;
begin
  for i := units.Count - 1 downto 1 do
    if SameText(units[i], units[i-1]) then
      units.Delete(i);
end; { TDLUIXUnitBrowser.MakeUnique }

end.
