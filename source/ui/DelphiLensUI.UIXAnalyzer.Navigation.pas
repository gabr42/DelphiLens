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
  TDLUIXAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private
    FDLUnitInfo  : TDLUnitInfo;
    FTreeAnalyzer: IDLTreeAnalyzer;
    FUnitInfo    : TProjectIndexer.TUnitInfo;
  public
    procedure BuildFrame(const frame: IDLUIXFrame);
    function  CanHandle(const state: TDLAnalysisState): boolean;
  end; { TDLUIXAnalyzer }

{ exports }

function CreateNavigationAnalyzer: IDLUIXAnalyzer;
begin
  Result := TDLUIXAnalyzer.Create;
end; { CreateNavigationAnalyzer }

procedure TDLUIXAnalyzer.BuildFrame(const frame: IDLUIXFrame);

  procedure AddNavigation(const name: string; const location: TDLCoordinate);
  begin
    frame.CreateAction(CreateNavigationAction(name, FUnitInfo.Name,
      location.Line, location.Column));
  end; { AddNavigation }

begin { TDLUIXAnalyzer.BuildFrame }
  if FDLUnitInfo.UnitType = utProgram then begin
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
end; { TDLUIXAnalyzer.BuildFrame }

function TDLUIXAnalyzer.CanHandle(const state: TDLAnalysisState): boolean;
begin
  Result := state.ProjectInfo.ParsedUnits.Find(state.FileName, FUnitInfo);
  if not assigned(FTreeAnalyzer) then begin
    FTreeAnalyzer := CreateDLTreeAnalyzer;
    FTreeAnalyzer.AnalyzeTree(FUnitInfo.SyntaxTree, FDLUnitInfo);
  end;

  if FDLUnitInfo.UnitType = utProgram then begin
    if not FDLUnitInfo.InterfaceUsesLoc.IsValid then
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
end; { TDLUIXAnalyzer.CanHandle }

end.
