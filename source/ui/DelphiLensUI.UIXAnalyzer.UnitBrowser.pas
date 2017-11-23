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
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXUnitBrowser = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  strict private
    FUnitNames: IList<string>;
  public
    constructor Create;
    procedure BuildFrame(const frame: IDLUIXFrame; const state: TDLAnalysisState);
    function  CanHandle(const state: TDLAnalysisState): boolean;
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
  const state: TDLAnalysisState);
var
  unitInfo: TProjectIndexer.TUnitInfo;
begin
  FUnitNames.Clear;
  for unitInfo in state.ProjectInfo.ParsedUnits do
    FUnitNames.Add(unitInfo.Name);
  FUnitNames.Sort;

  frame.CreateAction(CreateFilteredListAction('', FUnitNames, state.FileName));
  frame.CreateAction(CreateOpenAnalyzerAction('Used &in', CreateUnitBrowser));
  frame.CreateAction(CreateOpenAnalyzerAction('Used &by', CreateUnitBrowser));
  frame.CreateAction(CreateNavigationAction('&Open', Default(TDLUIXLocation), false));
end; { TDLUIXUnitBrowser.BuildFrame }

function TDLUIXUnitBrowser.CanHandle(const state: TDLAnalysisState): boolean;
begin
  Result := (state.ProjectInfo.ParsedUnits.Count > 0);
end; { TDLUIXUnitBrowser.CanHandle }

end.
