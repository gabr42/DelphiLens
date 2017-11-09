unit DelphiLensUI.UIXEngine.Intf;

interface

type
  IDLUIXAction = interface ['{1A7D1495-0533-4749-9851-B2CEF1B44E25}']
    function GetName: string;
  //
    property Name: string read GetName;
  end; { IDLUIXAction }

  IDLUIXFrame = interface;

  TDLUIXFrameAction = reference to procedure (const frame: IDLUIXFrame; const action: IDLUIXAction);

  IDLUIXFrame = interface ['{826510F1-0964-4D02-944E-1A561810675E}']
    function  GetOnAction: TDLUIXFrameAction;
    procedure SetOnAction(const value: TDLUIXFrameAction);
  //
    procedure CreateAction(const action: IDLUIXAction);
    procedure Show;
    property OnAction: TDLUIXFrameAction read GetOnAction write SetOnAction;
  end; { IDLUIXFrame }

  IDLUIXEngine = interface ['{E263D5F4-6050-46C0-9802-5AAA8D664747}']
    procedure CompleteFrame(const frame: IDLUIXFrame);
    function  CreateFrame(const parentFrame: IDLUIXFrame): IDLUIXFrame;
    procedure DestroyFrame(var frame: IDLUIXFrame);
    procedure ShowFrame(const frame: IDLUIXFrame);
  end; { IDLUIXEngine }

implementation

end.
