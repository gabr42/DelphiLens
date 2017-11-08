unit DelphiLensUI.UIXEngine.VCLFloating;

interface

uses
  DelphiLensUI.UIXEngine.Intf;

function CreateUIXEngine: IDLUIXEngine;

implementation

type
  TDLUIXEngine = class(TInterfacedObject, IDLUIXEngine)
  public
  end; { TDLUIXEngine }

{ exports }

function CreateUIXEngine: IDLUIXEngine;
begin
  Result := TDLUIXEngine.Create;
end; { CreateUIXEngine }

{ TDLUIXEngine }

end.
