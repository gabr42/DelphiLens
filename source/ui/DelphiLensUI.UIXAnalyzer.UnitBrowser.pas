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
  DelphiLens.Intf,
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
    procedure BuildFrame(const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
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
  unitInfo: TProjectIndexer.TUnitInfo;
begin
  for unitInfo in projectInfo.ParsedUnits do
    units.Add(unitInfo.Name);
  units.Sort;
end; { TDLUIXUnitBrowser.PrepareAllUnits }

procedure TDLUIXUnitBrowser.BuildFrame(const frame: IDLUIXFrame;
  const context: IDLUIWorkerContext);
var
  dlUnitInfo  : TDLUnitInfo;
  unitInfo    : TProjectIndexer.TUnitInfo;
  treeAnalyzer: IDLTreeAnalyzer;
begin
  FUnitNames.Clear;
  for unitInfo in context.Project.ParsedUnits do
    FUnitNames.Add(unitInfo.Name);
  FUnitNames.Sort;

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
end; { TDLUIXUnitBrowser.CanHandle }

end.
