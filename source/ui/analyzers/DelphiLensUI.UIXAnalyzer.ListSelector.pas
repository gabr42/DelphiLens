unit DelphiLensUI.UIXAnalyzer.ListSelector;

interface

uses
  DelphiLens.UnitInfo,
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXEngine.Actions;

function CreateListSelector(const name: string; const list: IDLUIXNamedLocationList): IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
  Spring,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf;

type
  TDLUIXListSelector = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  strict private
    FList: IDLUIXNamedLocationList;
    FName: string;
  public
    constructor Create(const name: string; const list: IDLUIXNamedLocationList);
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXListSelector }

{ exports }

function CreateListSelector(const name: string; const list: IDLUIXNamedLocationList): IDLUIXAnalyzer;
begin
  Result := TDLUIXListSelector.Create(name, list);
end; { CreateListSelector }

{ TDLUIXListSelector }

constructor TDLUIXListSelector.Create(const name: string; const list: IDLUIXNamedLocationList);
begin
  inherited Create;
  FName := name;
  FList := list;
end; { TDLUIXListSelector.Create }

procedure TDLUIXListSelector.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
begin
  frame.CreateAction(CreateListNavigationAction(FName, FList));
end; { TDLUIXListSelector.BuildFrame }

function TDLUIXListSelector.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := FList.Count > 0;
end; { TDLUIXListSelector.CanHandle }

end.
