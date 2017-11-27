unit DelphiLensUI.UIXAnalyzer.UnitBrowser;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateUnitBrowser: IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
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
    procedure PrepareAllUnits(const projectInfo: IDLScanResult;
      const initialUnit: string; const units: TUnitNames);
    procedure PrepareParentUnits(const projectInfo: IDLScanResult;
      const initialUnit: string; const units: TUnitNames);
    procedure PrepareUnitNames(const projectInfo: IDLScanResult;
      filterType: TDLUIXUnitBrowserType; const initialUnit: string;
      const units: TUnitNames);
    procedure PrepareUsedUnits(const projectInfo: IDLScanResult;
      const initialUnit: string; const units: TUnitNames);
  public
    constructor Create;
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

procedure TDLUIXUnitBrowser.PrepareAllUnits(const projectInfo: IDLScanResult; const initialUnit: string; const units: TUnitNames);
var
  dlUnitInfo: TDLUnitInfo;
begin
  for dlUnitInfo in projectInfo.Analysis do
    units.Add(dlUnitInfo.Name);
  units.Sort;
end; { TDLUIXUnitBrowser.PrepareAllUnits }

procedure TDLUIXUnitBrowser.PrepareParentUnits(const projectInfo: IDLScanResult;
  const initialUnit: string; const units: TUnitNames);
begin
  // TODO 1 -oPrimoz Gabrijelcic : implement: TDLUIXUnitBrowser.PrepareParentUnits
end; { TDLUIXUnitBrowser.PrepareParentUnits }

procedure TDLUIXUnitBrowser.PrepareUnitNames(const projectInfo: IDLScanResult;
  filterType: TDLUIXUnitBrowserType; const initialUnit: string; const units: TUnitNames);
begin
  case filterType of
    ubtNormal: PrepareAllUnits(projectInfo, initialUnit, units);
    ubtUses:   PrepareUsedUnits(projectInfo, initialUnit, units);
    ubtUsedBy: PrepareParentUnits(projectInfo, initialUnit, units);
  end;
end; { TDLUIXUnitBrowser.PrepareUnitNames }

procedure TDLUIXUnitBrowser.PrepareUsedUnits(const projectInfo: IDLScanResult;
  const initialUnit: string; const units: TUnitNames);
var
  dlUnitInfo: TDLUnitInfo;
begin
  if not projectInfo.Analysis.Find(initialUnit, dlUnitInfo) then
    Exit;

  units.AddRange(dlUnitInfo.InterfaceUses);
  units.AddRange(dlUnitInfo.ImplementationUses);
  units.AddRange(dlUnitInfo.PackageContains);
  units.Sort;
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

  FUnitNames := TCollections.CreateList<string>;
  PrepareUnitNames(context.Project, filterType, initialUnit, FUnitNames);

  filteredList := CreateFilteredListAction('', FUnitNames, context.Source.FileName) as IDLUIXFilteredListAction;
  openUses := CreateOpenUnitBrowserAction('&Uses', CreateUnitBrowser, '', ubtUses);
  openUsedBy := CreateOpenUnitBrowserAction('Used &by', CreateUnitBrowser, '', ubtUsedBy);
  navigateToUnit := CreateNavigationAction('&Open', Default(TDLUIXLocation), false);

  filteredList.ManagedActions := [openUses, {openUsedIn, }navigateToUnit];
  filteredList.DefaultAction := navigateToUnit;

  frame.CreateAction(filteredList);
  frame.CreateAction(openUses);
  frame.CreateAction(openUsedBy, [faoDisabled]);
  frame.CreateAction(navigateToUnit, [faoDefault]);
end; { TDLUIXUnitBrowser.BuildFrame }

function TDLUIXUnitBrowser.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (context.Project.ParsedUnits.Count > 0);
end; constructor TDLUIXUnitBrowser.Create;
begin

end;

{ TDLUIXUnitBrowser.CanHandle }

end.
