unit DelphiLensUI.UIXAnalyzer.Navigation;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateNavigationAnalyzer: IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
  Spring.Collections,
  GpStuff,
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers, DelphiLens.UnitInfo,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions,
  DelphiLensUI.UIXAnalyzer.ClassSelector, DelphiLensUI.UIXAnalyzer.ListSelector;

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

  procedure AddNavigation(const name: string; const location: TDLCoordinate;
    isSection: boolean);
  begin
    if isSection then
      locations.Add(
        CreateNavigationAction(name,
          TDLUIXLocation.Create(FUnitInfo.Path, FDLUnitInfo.Name, location),
          false) as IDLUIXNavigationAction)
    else
      frame.CreateAction(
        CreateNavigationAction(name,
          TDLUIXLocation.Create(FUnitInfo.Path, FDLUnitInfo.Name, location),
          false));
  end; { AddNavigation }

var
  range: TDLRange;

begin
  locations := TCollections.CreateList<IDLUIXNavigationAction>;

  if FDLUnitInfo.UnitType = utProgram then begin
    if FDLUnitInfo.Sections[sntContains].IsValid then
      AddNavigation('"&contains"', FDLUnitInfo.Sections[sntContains], false)
    else
      AddNavigation('"&uses"', FDLUnitInfo.Sections[sntInterface], false);

    if FDLUnitInfo.InterfaceTypes.Count >  0 then begin
      GetFirstLastCoordinate(FDLUnitInfo.InterfaceTypes, range);
      AddNavigation('"type" start', range.Start, true);
      if range.&End.IsValid then
        AddNavigation('"type" end', range.&End, true);
    end;
  end
  else begin
    if FDLUnitInfo.Sections[sntInterfaceUses].IsValid then
      AddNavigation('I&nterface "uses"', FDLUnitInfo.Sections[sntInterfaceUses], false)
    else if FDLUnitInfo.Sections[sntInterface].IsValid then
      AddNavigation('I&nterface', FDLUnitInfo.Sections[sntInterface], false);

    if FDLUnitInfo.InterfaceTypes.Count >  0 then begin
      GetFirstLastCoordinate(FDLUnitInfo.InterfaceTypes, range);
      AddNavigation('Interface "type" start', range.Start, true);
      if range.&End.IsValid then
        AddNavigation('Interface "type" end', range.&End, true);
    end;

    if FDLUnitInfo.Sections[sntImplementationUses].IsValid then
      AddNavigation('I&mplementation "uses"', FDLUnitInfo.Sections[sntImplementationUses], false)
    else if FDLUnitInfo.Sections[sntImplementation].IsValid then
      AddNavigation('I&mplementation', FDLUnitInfo.Sections[sntImplementation], false);

    if FDLUnitInfo.ImplementationTypes.Count > 0 then begin
      GetFirstLastCoordinate(FDLUnitInfo.ImplementationTypes, range);
      AddNavigation('Implementation "type" start', range.Start, true);
      if range.&End.IsValid then
        AddNavigation('Implementation "type" end', range.&End, true);
    end;
  end;

  frame.CreateAction(
    CreateOpenAnalyzerAction('&Sections',
      CreateListSelector('Sections', locations)));

  frame.CreateAction(
    CreateOpenAnalyzerAction('&Classes',
      CreateClassSelector(FDLUnitInfo.InterfaceTypes, FDLUnitInfo.ImplementationTypes)));
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
