unit DelphiLens.UnitInfo;

interface

uses
  System.Types;

type
  TDLCoordinate = TPoint; //Y = line, X = column

  TDLCoordinateHelper = record helper for TDLCoordinate
  private
    function  GetColumn: integer; inline;
    function  GetLine: integer; inline;
    procedure SetColumn(const value: integer); inline;
    procedure SetLine(const value: integer); inline;
  public
    class function Invalid: TDLCoordinate; static;
    function IsValid: boolean;
    property Column: integer read GetColumn write SetColumn;
    property Line: integer read GetLine write SetLine;
  end; { TDLCoordinateHelper }

  TDLUnitInfo = record
    InterfaceLoc      : TDLCoordinate;
    ImplementationLoc : TDLCoordinate;
    InitializationLoc : TDLCoordinate;
    FinalizationLoc   : TDLCoordinate;
    InterfaceUses     : TArray<string>; //program 'uses' when InterfaceLoc = -1
    ImplementationUses: TArray<string>;
    class function Empty: TDLUnitInfo; static;
  end; { TDLUnitInfo }

implementation

{ TDLCoordinateHelper }

function TDLCoordinateHelper.GetColumn: integer;
begin
  Result := X;
end; { TDLCoordinateHelper.GetColumn }

function TDLCoordinateHelper.GetLine: integer;
begin
  Result := Y;
end; { TDLCoordinateHelper.GetLine }

class function TDLCoordinateHelper.Invalid: TDLCoordinate;
begin
  Result.X := -1;
  Result.Y := -1;
end; { TDLCoordinateHelper.Invalid }

function TDLCoordinateHelper.IsValid: boolean;
begin
  Result := (Line >= 0) and (Column >= 0);
end; { TDLCoordinateHelper.IsValid }

procedure TDLCoordinateHelper.SetColumn(const value: integer);
begin
  X := value;
end; { TDLCoordinateHelper.SetColumn }

procedure TDLCoordinateHelper.SetLine(const value: integer);
begin
  Y := value;
end; { TDLCoordinateHelper.SetLine }

{ TDLUnitInfo }

class function TDLUnitInfo.Empty: TDLUnitInfo;
begin
  Result.InterfaceLoc := TDLCoordinate.Invalid;
  Result.ImplementationLoc := TDLCoordinate.Invalid;
  Result.InitializationLoc := TDLCoordinate.Invalid;
  Result.FinalizationLoc := TDLCoordinate.Invalid;
  SetLength(Result.InterfaceUses, 0);
  SetLength(Result.ImplementationUses, 0);
end; { TDLUnitInfo.Empty }

end.
