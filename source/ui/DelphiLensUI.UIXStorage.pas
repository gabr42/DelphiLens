unit DelphiLensUI.UIXStorage;

interface

type
  IDLUIXStorage = interface ['{6B71F4E7-C860-4958-A33A-AD01F18D501B}']

  end; { IDLUIXStorage }

function CreateUIXStorage: IDLUIXStorage;

implementation

type
  TUIXStorage = class(TInterfacedObject, IDLUIXStorage)
  end; { TUIXStorage }

{ exports }

function CreateUIXStorage: IDLUIXStorage;
begin
  Result := TUIXStorage.Create;
end; { CreateUIXStorage }

end.
