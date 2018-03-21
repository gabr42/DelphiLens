unit DelphiLensUI.UIXAnalyzer.Navigation;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateNavigationAnalyzer: IDLUIXAnalyzer;

implementation

uses
  Spring.Collections,
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers, DelphiLens.UnitInfo,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXNavigationAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private
    FDLUnitInfo: IDLUnitInfo;
    FUnitInfo  : TProjectIndexer.TUnitInfo;
  strict protected
    procedure GetFirstLastCoordinate(typeList: TDLTypeInfoList;
      var range: TDLRange);
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

var
  locations: IDLUIXNamedLocationList;

  procedure AddNavigation(const name: string; const location: TDLCoordinate);
  begin
    locations.Add(CreateNavigationAction(name, TDLUIXLocation.Create(FUnitInfo.Path, FDLUnitInfo.Name, location), false) as IDLUIXNavigationAction);
  end; { AddNavigation }

var
  range: TDLRange;

begin
  locations := TCollections.CreateList<IDLUIXNavigationAction>;

  if FDLUnitInfo.UnitType = utProgram then begin
    if FDLUnitInfo.Sections[sntContains].IsValid then
      AddNavigation('&Contains', FDLUnitInfo.Sections[sntContains])
    else
      AddNavigation('&Uses list', FDLUnitInfo.Sections[sntInterface]);

    if FDLUnitInfo.InterfaceTypes.Count >  0 then begin
      GetFirstLastCoordinate(FDLUnitInfo.InterfaceTypes, range);
      AddNavigation('"type" start', range.Start);
      if range.&End.IsValid then
        AddNavigation('"type" end', range.&End);
    end;
  end
  else begin
    if FDLUnitInfo.Sections[sntInterfaceUses].IsValid then
      AddNavigation('I&nterface "uses"', FDLUnitInfo.Sections[sntInterfaceUses])
    else if FDLUnitInfo.Sections[sntInterface].IsValid then
      AddNavigation('I&nterface', FDLUnitInfo.Sections[sntInterface]);

    if FDLUnitInfo.InterfaceTypes.Count >  0 then begin
      GetFirstLastCoordinate(FDLUnitInfo.InterfaceTypes, range);
      AddNavigation('Interface "type" start', range.Start);
      if range.&End.IsValid then
        AddNavigation('Interface "type" end', range.&End);
    end;

    if FDLUnitInfo.Sections[sntImplementationUses].IsValid then
      AddNavigation('I&mplementation Uses list', FDLUnitInfo.Sections[sntImplementationUses])
    else if FDLUnitInfo.Sections[sntImplementation].IsValid then
      AddNavigation('I&mplementation', FDLUnitInfo.Sections[sntImplementation]);

    if FDLUnitInfo.ImplementationTypes.Count > 0 then begin
      GetFirstLastCoordinate(FDLUnitInfo.ImplementationTypes, range);
      AddNavigation('Implementation "type" start', range.Start);
      if range.&End.IsValid then
        AddNavigation('Implementation "type" end', range.&End);
    end;
  end;

  frame.CreateAction(CreateListNavigationAction('', locations));

  if (FDLUnitInfo.InterfaceTypes.Count + FDLUnitInfo.ImplementationTypes.Count) >  0 then
    frame.CreateAction(CreateOpenAnalyzerAction('Classes >', nil));

end; { TDLUIXNavigationAnalyzer.BuildFrame }

function TDLUIXNavigationAnalyzer.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := true;

  if not assigned(context.Project) then
    Exit(false);

  if not (context.Project.ParsedUnits.Find(context.Source.UnitName, FUnitInfo)
          and context.Project.Analysis.Find(context.Source.UnitName, FDLUnitInfo))
  then
    Exit(false);

  if FDLUnitInfo.UnitType = utProgram then begin
    if not (FDLUnitInfo.Sections[sntInterfaceUses].IsValid
            or FDLUnitInfo.Sections[sntContains].IsValid)
    then
      Result := false;
  end
  else begin
    if not (FDLUnitInfo.Sections[sntInterface].IsValid
            or FDLUnitInfo.Sections[sntInterfaceUses].IsValid
            or FDLUnitInfo.Sections[sntImplementation].IsValid
            or FDLUnitInfo.Sections[sntImplementationUses].IsValid)
    then
      Result := false;
  end;
end; { TDLUIXNavigationAnalyzer.CanHandle }

procedure TDLUIXNavigationAnalyzer.GetFirstLastCoordinate(
  typeList: TDLTypeInfoList; var range: TDLRange);
var
  typeInfo: TDLTypeInfo;
begin
  range := TDLRange.Invalid;
  if assigned(typeList) then
    for typeInfo in typeList do
      range := range.Union(typeInfo.Location);
end; { TDLUIXNavigationAnalyzer.GetFirstLastCoordinate }

end.
