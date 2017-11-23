unit DelphiLensUI.UIXAnalyzer.Navigation;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateNavigationAnalyzer: IDLUIXAnalyzer;

implementation

uses
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers,
  DelphiLens.UnitInfo, DelphiLens.TreeAnalyzer.Intf, DelphiLens.TreeAnalyzer,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXNavigationAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private
    FDLUnitInfo  : TDLUnitInfo;
    FTreeAnalyzer: IDLTreeAnalyzer;
    FUnitInfo    : TProjectIndexer.TUnitInfo;
  public
    procedure BuildFrame(const frame: IDLUIXFrame; const state: TDLAnalysisState);
    function  CanHandle(const state: TDLAnalysisState): boolean;
  end; { TDLUIXNavigationAnalyzer }

{ exports }

function CreateNavigationAnalyzer: IDLUIXAnalyzer;
begin
  Result := TDLUIXNavigationAnalyzer.Create;
end; { CreateNavigationAnalyzer }

procedure TDLUIXNavigationAnalyzer.BuildFrame(const frame: IDLUIXFrame;
  const state: TDLAnalysisState);

  procedure AddNavigation(const name: string; const location: TDLCoordinate);
  begin
    frame.CreateAction(CreateNavigationAction(name, TDLUIXLocation.Create(FUnitInfo.Path, FDLUnitInfo.Name, location), false));
  end; { AddNavigation }

begin { TDLUIXNavigationAnalyzer.BuildFrame }
  if FDLUnitInfo.UnitType = utProgram then begin
    if FDLUnitInfo.ContainsLoc.IsValid then
      AddNavigation('&Contains', FDLUnitInfo.ContainsLoc)
    else
      AddNavigation('&Uses list', FDLUnitInfo.InterfaceLoc);
  end
  else begin
    if FDLUnitInfo.InterfaceUsesLoc.IsValid then
      AddNavigation('I&nterface Uses list', FDLUnitInfo.InterfaceUsesLoc)
    else if FDLUnitInfo.InterfaceLoc.IsValid then
      AddNavigation('I&nterface', FDLUnitInfo.InterfaceLoc);

    if FDLUnitInfo.ImplementationUsesLoc.IsValid then
      AddNavigation('I&mplementation Uses list', FDLUnitInfo.ImplementationUsesLoc)
    else if FDLUnitInfo.ImplementationLoc.IsValid then
      AddNavigation('I&mplementation', FDLUnitInfo.ImplementationLoc);
  end;
end; { TDLUIXNavigationAnalyzer.BuildFrame }

function TDLUIXNavigationAnalyzer.CanHandle(const state: TDLAnalysisState): boolean;
begin
  if not assigned(state.ProjectInfo) then
    Exit(false);

  Result := state.ProjectInfo.ParsedUnits.Find(state.FileName, FUnitInfo);
  if Result and (not assigned(FTreeAnalyzer)) then begin
    FTreeAnalyzer := CreateDLTreeAnalyzer;
    FTreeAnalyzer.AnalyzeTree(FUnitInfo.SyntaxTree, FDLUnitInfo);
  end;

  if FDLUnitInfo.UnitType = utProgram then begin
    if not (FDLUnitInfo.InterfaceUsesLoc.IsValid or FDLUnitInfo.ContainsLoc.IsValid) then
      Result := false;
  end
  else begin
    if not (FDLUnitInfo.InterfaceLoc.IsValid
            or FDLUnitInfo.InterfaceUsesLoc.IsValid
            or FDLUnitInfo.ImplementationLoc.IsValid
            or FDLUnitInfo.ImplementationUsesLoc.IsValid)
    then
      Result := false;
  end;
end; { TDLUIXNavigationAnalyzer.CanHandle }

end.
