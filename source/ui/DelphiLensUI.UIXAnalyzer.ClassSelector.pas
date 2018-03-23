unit DelphiLensUI.UIXAnalyzer.ClassSelector;

interface

uses
  DelphiLens.UnitInfo,
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateClassSelector(refListIntf, refListImpl: TDLTypeInfoList): IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
  Spring,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf;

type
  TDLUIXUnitBrowser = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  strict private
    FTypeList: TDLTypeInfoList;
  public
    constructor Create(refListIntf, refListImpl: TDLTypeInfoList);
    destructor  Destroy; override;
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXUnitBrowser }

{ exports }

function CreateClassSelector(refListIntf, refListImpl: TDLTypeInfoList): IDLUIXAnalyzer;
begin
  Result := TDLUIXUnitBrowser.Create(refListIntf, refListImpl);
end; { CreateClassSelector }

{ TDLUIXUnitBrowser }

constructor TDLUIXUnitBrowser.Create(refListIntf, refListImpl: TDLTypeInfoList);
var
  typeInfo: TDLTypeInfo;
begin
  inherited Create;
  FTypeList := TDLTypeInfoList.Create;
  for typeInfo in refListIntf do
    FTypeList.Add(typeInfo);
  for typeInfo in refListImpl do
    FTypeList.Add(typeInfo);
  FTypeList.SortByName;
end; { TDLUIXUnitBrowser.Create }

destructor TDLUIXUnitBrowser.Destroy;
begin
  FreeAndNil(FTypeList);
  inherited;
end; { TDLUIXUnitBrowser.Destroy }

procedure TDLUIXUnitBrowser.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
begin

end; { TDLUIXUnitBrowser.BuildFrame }

function TDLUIXUnitBrowser.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := false;
end; { TDLUIXUnitBrowser.CanHandle }

end.
