unit DelphiLensUI.UIXEngine.Intf;

interface

uses
  Spring, Spring.Collections,
  DelphiLens.UnitInfo;

type
  TDLUIXLocation = record
    UnitName: string;
    Line    : integer;
    Column  : integer;
    constructor Create(const AUnitName: string; ALine, AColumn: integer); overload;
    constructor Create(const ALocation: TDLUIXLocation); overload;
    constructor Create(const AUnitName: string; const ADLCoordinate: TDLCoordinate); overload;
  end; { TDLUIXLocation }

  IDLUIXLocationList = IList<TDLUIXLocation>;

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
    procedure Close;
    procedure CreateAction(const action: IDLUIXAction);
    procedure MarkActive(isActive: boolean);
    procedure Show(const parentAction: IDLUIXAction);
    property OnAction: TDLUIXFrameAction read GetOnAction write SetOnAction;
  end; { IDLUIXFrame }

  IDLUIXEngine = interface ['{E263D5F4-6050-46C0-9802-5AAA8D664747}']
    function  CreateFrame(const parentFrame: IDLUIXFrame): IDLUIXFrame;
    procedure DestroyFrame(var frame: IDLUIXFrame);
  end; { IDLUIXEngine }

implementation

constructor TDLUIXLocation.Create(const AUnitName: string; ALine, AColumn: integer);
begin
  UnitName := AUnitName;
  Line := ALine;
  Column := AColumn;
end; { TDLUIXLocation.Create }

constructor TDLUIXLocation.Create(const ALocation: TDLUIXLocation);
begin
  Self := ALocation;
end; { TDLUIXLocation.Create }

constructor TDLUIXLocation.Create(const AUnitName: string;
  const ADLCoordinate: TDLCoordinate);
begin
  UnitName := AUnitName;
  Line := ADLCoordinate.Line;
  Column := ADLCoordinate.Column;
end; { TDLUIXLocation.Create }

end.
