unit DelphiLensUI.UIXEngine.Intf;

interface

uses
  System.SysUtils,
  Spring, Spring.Collections,
  DelphiLens.UnitInfo;

type
  TDLUIXLocation = record
    FileName: string;
    UnitName: string;
    Line    : integer;
    Column  : integer;
    constructor Create(const AFileName, AUnitName: string; ALine, AColumn: integer); overload;
    constructor Create(const ALocation: TDLUIXLocation); overload;
    constructor Create(const AFileName, AUnitName: string; const ADLCoordinate: TDLCoordinate); overload;
  end; { TDLUIXLocation }

  IDLUIXLocationList = IList<TDLUIXLocation>;

  IDLUIXAction = interface;

  TDLUIXManagedActionTest = TFunc<integer, boolean>;

  TDLUIXManagedAction = record
  private
    FAction: IDLUIXAction;
    FTest  : TDLUIXManagedActionTest;
  public
    constructor Create(const action: IDLUIXAction; const test: TDLUIXManagedActionTest);
    class function  AnySelected: TDLUIXManagedActionTest; static;
    class function  SingleSelected: TDLUIXManagedActionTest; static;
    property Action: IDLUIXAction read FAction;
    property Test: TDLUIXManagedActionTest read FTest;
  end; { TDLUIXManagedAction }

  IDLUIXManagedActions = IList<TDLUIXManagedAction>;

  IDLUIXAction = interface ['{1A7D1495-0533-4749-9851-B2CEF1B44E25}']
    function  GetDefaultAction: IDLUIXAction;
    function  GetManagedActions: IDLUIXManagedActions;
    function  GetName: string;
    procedure SetDefaultAction(const value: IDLUIXAction);
  //
    property DefaultAction: IDLUIXAction read GetDefaultAction write SetDefaultAction;
    property ManagedActions: IDLUIXManagedActions read GetManagedActions;
    property Name: string read GetName;
  end; { IDLUIXAction }

  TDLUIXActions = TArray<IDLUIXAction>;

  IDLUIXFrame = interface;

  TDLUIXFrameAction = reference to procedure (const frame: IDLUIXFrame; const action: IDLUIXAction);

  TDLUIXFrameActionOption = (faoDefault, faoDisabled, faoSmall);
  TDLUIXFrameActionOptions = set of TDLUIXFrameActionOption;

  IDLUIXFrame = interface ['{826510F1-0964-4D02-944E-1A561810675E}']
    function  GetCaption: string;
    function  GetOnAction: TDLUIXFrameAction;
    function  GetParent: IDLUIXFrame;
    procedure SetCaption(const value: string);
    procedure SetOnAction(const value: TDLUIXFrameAction);
  //
    procedure Close;
    procedure CreateAction(const action: IDLUIXAction; options: TDLUIXFrameActionOptions = []);
    function  IsEmpty: boolean;
    procedure MarkActive(isActive: boolean);
    procedure Show(monitorNum: integer; const parentAction: IDLUIXAction);
    property Caption: string read GetCaption write SetCaption;
    property OnAction: TDLUIXFrameAction read GetOnAction write SetOnAction;
    property Parent: IDLUIXFrame read GetParent;
  end; { IDLUIXFrame }

  IDLUIXEngine = interface ['{E263D5F4-6050-46C0-9802-5AAA8D664747}']
    function  CreateFrame(const parentFrame: IDLUIXFrame): IDLUIXFrame;
    procedure DestroyFrame(var frame: IDLUIXFrame);
  end; { IDLUIXEngine }

implementation

constructor TDLUIXLocation.Create(const AFileName, AUnitName: string;
  ALine, AColumn: integer);
begin
  FileName := AFileName;
  UnitName := AUnitName;
  Line := ALine;
  Column := AColumn;
end; { TDLUIXLocation.Create }

constructor TDLUIXLocation.Create(const ALocation: TDLUIXLocation);
begin
  Self := ALocation;
end; { TDLUIXLocation.Create }

constructor TDLUIXLocation.Create(const AFileName, AUnitName: string;
  const ADLCoordinate: TDLCoordinate);
begin
  FileName := AFileName;
  UnitName := AUnitName;
  Line := ADLCoordinate.Line;
  Column := ADLCoordinate.Column;
end; { TDLUIXLocation.Create }

{ TDLUIXManagedAction }

constructor TDLUIXManagedAction.Create(const action: IDLUIXAction;
  const test: TDLUIXManagedActionTest);
begin
  FAction := action;
  FTest := test;
end; { TDLUIXManagedAction.Create }

class function TDLUIXManagedAction.AnySelected: TDLUIXManagedActionTest;
begin
  Result :=
    function (numSelected: integer): boolean
    begin
      Result := (numSelected > 0);
    end;
end; { TDLUIXManagedAction.AnySelected }

class function TDLUIXManagedAction.SingleSelected: TDLUIXManagedActionTest;
begin
  Result :=
    function (numSelected: integer): boolean
    begin
      Result := (numSelected = 1);
    end;
end; { TDLUIXManagedAction.SingleSelected }

end.
