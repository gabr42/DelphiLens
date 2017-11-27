unit DelphiLensUI.UIXAnalyzer.Navigation;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateNavigationAnalyzer: IDLUIXAnalyzer;

implementation

uses
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers,
  DelphiLens.UnitInfo,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXNavigationAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private
    FDLUnitInfo: TDLUnitInfo;
    FUnitInfo  : TProjectIndexer.TUnitInfo;
  public
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXNavigationAnalyzer }

{ exports }

function CreateNavigationAnalyzer: IDLUIXAnalyzer;
begin
  Result := TDLUIXNavigationAnalyzer.Create;
end; { CreateNavigationAnalyzer }

procedure TDLUIXNavigationAnalyzer.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const context: IDLUIWorkerContext);

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

function TDLUIXNavigationAnalyzer.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  if not assigned(context.Project) then
    Exit(false);

  Result := context.Project.ParsedUnits.Find(context.Source.FileName, FUnitInfo)
        and context.Project.Analysis.Find(context.Source.FileName, FDLUnitInfo);

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
