unit DelphiLensUI.UIXStorage;

interface

type
  IUIXStorage = interface ['{6B71F4E7-C860-4958-A33A-AD01F18D501B}']
  end; { IUIXStorage }

function CreateUIXStorage: IUIXStorage;

implementation

type
  TUIXStorage = class(TInterfacedObject, IUIXStorage)

  end; { TUIXStorage }

{ exports }

function CreateUIXStorage: IUIXStorage;
begin
  Result := TUIXStorage.Create;
end; { CreateUIXStorage }

end.
