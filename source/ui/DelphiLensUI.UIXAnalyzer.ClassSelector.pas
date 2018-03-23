unit DelphiLensUI.UIXAnalyzer.ClassSelector;

interface

uses
  DelphiLens.UnitInfo,
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateClassSelector(refListIntf, refListImpl: TDLTypeInfoList): IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
  Spring, Spring.Collections,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXClassSelector = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  strict private
    FClassNames: IList<string>;
    FTypeList  : TDLTypeInfoList;
  strict protected
    function  FindCoordinate(const name: string; var loc: TDLCoordinate): boolean;
  public
    constructor Create(refListIntf, refListImpl: TDLTypeInfoList);
    destructor  Destroy; override;
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXClassSelector }

{ exports }

function CreateClassSelector(refListIntf, refListImpl: TDLTypeInfoList): IDLUIXAnalyzer;
begin
  Result := TDLUIXClassSelector.Create(refListIntf, refListImpl);
end; { CreateClassSelector }

{ TDLUIXClassSelector }

constructor TDLUIXClassSelector.Create(refListIntf, refListImpl: TDLTypeInfoList);
var
  typeInfo: TDLTypeInfo;
begin
  inherited Create;
  FClassNames := TCollections.CreateList<string>;
  FTypeList := TDLTypeInfoList.Create(false);
  for typeInfo in refListIntf do
    FTypeList.Add(typeInfo);
  for typeInfo in refListImpl do
    FTypeList.Add(typeInfo);
  FTypeList.SortByName;
  for typeInfo in FTypeList do
    FClassNames.Add(typeInfo.Name);
end; { TDLUIXClassSelector.Create }

destructor TDLUIXClassSelector.Destroy;
begin
  FreeAndNil(FTypeList);
  inherited;
end; { TDLUIXClassSelector.Destroy }

function TDLUIXClassSelector.FindCoordinate(const name: string;
  var loc: TDLCoordinate): boolean;
var
  typeInfo: TDLTypeInfo;
begin
  Result := FTypeList.Find(name, typeInfo);
  if Result then
    loc := typeInfo.Location.Start;
end; { TDLUIXClassSelector.FindCoordinate }

procedure TDLUIXClassSelector.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
var
  filteredList  : IDLUIXFilteredListAction;
  navigateToDecl: IDLUIXAction;
begin
  filteredList := CreateFilteredListAction('', FClassNames, '') as IDLUIXFilteredListAction;
  filteredList.LocationQuery :=
    function (const name: string;
      var unitName: string; var location: TDLCoordinate): boolean
    begin
      Result := FindCoordinate(name, location);
      if Result then
        unitName := context.Source.UnitName;
    end;

  navigateToDecl := CreateNavigationAction('Go to &definition', Default(TDLUIXLocation), false);
  filteredList.ManagedActions.Add(TDLUIXManagedAction.Create(navigateToDecl, TDLUIXManagedAction.AnySelected()));
  filteredList.DefaultAction := navigateToDecl;

  frame.CreateAction(filteredList);
  frame.CreateAction(navigateToDecl, [faoDefault]);
end; { TDLUIXClassSelector.BuildFrame }

function TDLUIXClassSelector.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := true;
end; { TDLUIXClassSelector.CanHandle }

end.
