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
  DelphiLens.DelphiASTHelpers,
  DelphiLens.Intf, DelphiLens.UnitInfo,
  DelphiLens.TreeAnalyzer.Intf, DelphiLens.TreeAnalyzer,
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
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const state: TDLAnalysisState);
    function  CanHandle(const state: TDLAnalysisState): boolean;
  end; { TDLUIXNavigationAnalyzer }

{ exports }

function CreateUnitBrowser: IDLUIXAnalyzer;
begin
  Result := TDLUIXUnitBrowser.Create;
end; { CreateUnitBrowser }

{ TDLUIXUnitBrowser }

procedure TDLUIXUnitBrowser.PrepareAllUnits(const projectInfo: IDLScanResult; const initialUnit: string; const units: TUnitNames);
var
  unitInfo: TProjectIndexer.TUnitInfo;
begin
  for unitInfo in projectInfo.ParsedUnits do
    units.Add(unitInfo.Name);
  units.Sort;
end; { TDLUIXUnitBrowser.PrepareAllUnits }

procedure TDLUIXUnitBrowser.PrepareParentUnits(const projectInfo: IDLScanResult; const initialUnit: string; const units: TUnitNames);
begin
  //TODO: *** Implement
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
  dlUnitInfo  : TDLUnitInfo;
  unitInfo    : TProjectIndexer.TUnitInfo;
  treeAnalyzer: IDLTreeAnalyzer;
begin
  if not projectInfo.ParsedUnits.Find(initialUnit, unitInfo) then
    Exit;

  //TODO: *** This approach is not good. Initial state could be downloaded from the .dlens file. All analyzers must share this information.
  treeAnalyzer := CreateDLTreeAnalyzer;
  treeAnalyzer.AnalyzeTree(unitInfo.SyntaxTree, dlUnitInfo);

  units.AddRange(dlUnitInfo.InterfaceUses);
  units.AddRange(dlUnitInfo.ImplementationUses);
  units.AddRange(dlUnitInfo.PackageContains);
  units.Sort;
end; { TDLUIXUnitBrowser.PrepareUsedUnits }

procedure TDLUIXUnitBrowser.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const state: TDLAnalysisState);
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
  PrepareUnitNames(state.ProjectInfo, filterType, initialUnit, FUnitNames);

  filteredList := CreateFilteredListAction('', FUnitNames, state.FileName) as IDLUIXFilteredListAction;
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

function TDLUIXUnitBrowser.CanHandle(const state: TDLAnalysisState): boolean;
begin
  Result := (state.ProjectInfo.ParsedUnits.Count > 0);
end; { TDLUIXUnitBrowser.CanHandle }

end.
