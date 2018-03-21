unit DelphiLensUI.UIXAnalyzer.ClassSelector;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateClassSelector: IDLUIXAnalyzer;

implementation

uses
  Spring,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf;

type
  TDLUIXUnitBrowser = class(TManagedInterfacedObject, IDLUIXAnalyzer)
  public
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXUnitBrowser }

{ exports }

function CreateClassSelector: IDLUIXAnalyzer;
begin
  Result := TDLUIXUnitBrowser.Create;
end; { CreateClassSelector }

{ TDLUIXUnitBrowser }

procedure TDLUIXUnitBrowser.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
begin

end; { TDLUIXUnitBrowser.BuildFrame }

function TDLUIXUnitBrowser.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := false;
end; { TDLUIXUnitBrowser.CanHandle }

end.
