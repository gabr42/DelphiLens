unit DelphiLensUI.UIXStorage;

interface

uses
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIXStorage = interface ['{6B71F4E7-C860-4958-A33A-AD01F18D501B}']
    function GetHistory: IDLUIXLocationList;
  //
    property History: IDLUIXLocationList read GetHistory;
  end; { IDLUIXStorage }

function CreateUIXStorage: IDLUIXStorage;

implementation

uses
  Spring.Collections;

type
  TUIXStorage = class(TInterfacedObject, IDLUIXStorage)
  strict private
    FHistory: IDLUIXLocationList;
  strict protected
    function GetHistory: IDLUIXLocationList;
  public
    constructor Create;
    property History: IDLUIXLocationList read GetHistory;
  end; { TUIXStorage }

{ exports }

function CreateUIXStorage: IDLUIXStorage;
begin
  Result := TUIXStorage.Create;
end; { CreateUIXStorage }

{ TUIXStorage }

constructor TUIXStorage.Create;
begin
  inherited Create;
  FHistory := TCollections.CreateList<TDLUIXLocation>;
end; { TUIXStorage.Create }

function TUIXStorage.GetHistory: IDLUIXLocationList;
begin
  Result := FHistory;
end; { TUIXStorage.GetHistory }

end.
