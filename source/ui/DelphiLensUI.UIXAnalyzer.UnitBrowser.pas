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
    procedure PrepareAllUnits(const projectInfo: IDLScanResult; const initialUnit: string;
      const units: ICollection<string>);
    procedure PrepareParentUnits(const projectInfo: IDLScanResult; const initialUnit: string;
      const units: ICollection<string>);
    procedure PrepareUnitNames(const projectInfo: IDLScanResult;
      filterType: TDLUIXUnitBrowserType; const initialUnit: string;
      const units: TUnitNames);
    procedure PrepareUsedUnits(const projectInfo: IDLScanResult; const initialUnit: string;
      const units: ICollection<string>);
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

procedure TDLUIXUnitBrowser.PrepareAllUnits(const projectInfo: IDLScanResult;
  const initialUnit: string; const units: ICollection<string>);
var
  dlUnitInfo: TDLUnitInfo;
begin
  for dlUnitInfo in projectInfo.Analysis do
    units.Add(dlUnitInfo.Name);
end; { TDLUIXUnitBrowser.PrepareAllUnits }

procedure TDLUIXUnitBrowser.PrepareParentUnits(const projectInfo: IDLScanResult;
  const initialUnit: string; const units: ICollection<string>);
var
  dlUnitInfo: TDLUnitInfo;
begin
  for dlUnitInfo in projectInfo.Analysis do begin
    if dlUnitInfo.ImplementationUses.Contains(initialUnit)
       or dlUnitInfo.InterfaceUses.Contains(initialUnit)
       or dlUnitInfo.PackageContains.Contains(initialUnit)
    then
      units.Add(dlUnitInfo.Name);
  end;
end; { TDLUIXUnitBrowser.PrepareParentUnits }

procedure TDLUIXUnitBrowser.PrepareUnitNames(const projectInfo: IDLScanResult;
  filterType: TDLUIXUnitBrowserType; const initialUnit: string; const units: TUnitNames);
var
  unsortedUnits: ISet<string>;
begin
  unsortedUnits := TCollections.CreateSet<string>(TIStringComparer.Ordinal);
  case filterType of
    ubtNormal: PrepareAllUnits(projectInfo, initialUnit, unsortedUnits);
    ubtUses:   PrepareUsedUnits(projectInfo, initialUnit, unsortedUnits);
    ubtUsedBy: PrepareParentUnits(projectInfo, initialUnit, unsortedUnits);
  end;
  units.AddRange(unsortedUnits);
  units.Sort;
end; { TDLUIXUnitBrowser.PrepareUnitNames }

procedure TDLUIXUnitBrowser.PrepareUsedUnits(const projectInfo: IDLScanResult;
  const initialUnit: string; const units: ICollection<string>);
var
  dlUnitInfo: TDLUnitInfo;
begin
  if not projectInfo.Analysis.Find(initialUnit, dlUnitInfo) then
    Exit;

  units.AddRange(dlUnitInfo.InterfaceUses);
  units.AddRange(dlUnitInfo.ImplementationUses);
  units.AddRange(dlUnitInfo.PackageContains);
end; { TDLUIXUnitBrowser.PrepareUsedUnits }

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

  filteredList.ManagedActions := [openUses, openUsedBy, navigateToUnit];
  filteredList.DefaultAction := navigateToUnit;

  frame.CreateAction(filteredList);
  frame.CreateAction(openUses);
  frame.CreateAction(openUsedBy);
  frame.CreateAction(navigateToUnit, [faoDefault]);
end; { TDLUIXUnitBrowser.BuildFrame }

function TDLUIXUnitBrowser.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (context.Project.ParsedUnits.Count > 0);
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
