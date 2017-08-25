unit DelphiLens.UnitInfo;

interface

uses
  System.Types;

type
  TCoordinate = TPoint; //Y = line, X = column

  TDLUnitInfo = record
    InterfaceLoc      : TCoordinate;    //Y = -1 if missing
    ImplementationLoc : TCoordinate;    //Y = -1 if missing
    InitializationLoc : TCoordinate;    //Y = -1 if missing
    FinalizationLoc   : TCoordinate;    //Y = -1 if missing
    InterfaceUses     : TArray<string>; //program 'uses' when InterfaceLoc = -1
    ImplementationUses: TArray<string>;
  end; { TDLUnitInfo }

implementation

end.
