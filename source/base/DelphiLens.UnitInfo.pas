unit DelphiLens.UnitInfo;

interface

uses
  System.Types,
  DelphiAST.Classes,
  Spring.Collections;

type
  TDLCoordinate = record
  public
    Line  : integer;
    Column: integer;
    class function Invalid: TDLCoordinate; static; inline;
    function  IsValid: boolean; inline;
    procedure SetLocation(const node: TSyntaxNode);
    function  ToString: string; inline;
  end; { TDLCoordinateHelper }

  TDLTypeSection = (secStrictPrivate, secPrivate, secStrictProtected, secProtected,
    secPublic, secPublished);

  TDLTypeInfo = class;

  TDLTypeSectionInfo = class
  public
    Location: TDLCoordinate;
    Types   : IList<TDLTypeInfo>;
  end; { TDLTypeSectionInfo }

  TDLTypeInfo = class
  public
    Location: TDLCoordinate;
    Sections: array [TDLTypeSection] of TDLTypeSectionInfo;
    function  EnsureSection(sectionType: TDLTypeSection): TDLTypeSectionInfo;
  end; { TDLTypeInfo }

  TDLUnitType = (utProgram, utUnit);

  TDLUnitInfo = record
    Name                 : string;
    InterfaceLoc         : TDLCoordinate;
    InterfaceUsesLoc     : TDLCoordinate;
    ImplementationLoc    : TDLCoordinate;
    ImplementationUsesLoc: TDLCoordinate;
    InitializationLoc    : TDLCoordinate;
    FinalizationLoc      : TDLCoordinate;
    InterfaceUses        : IList<string>;      //program 'uses' when UnitType = utProgram
    InterfaceTypes       : IList<TDLTypeInfo>; //program types when UnitType = utProgram
    ImplementationUses   : IList<string>;
    ImplementationTypes  : IList<TDLTypeInfo>;
    class function Create: TDLUnitInfo; static;
    function UnitType: TDLUnitType; inline;
  end; { TDLUnitInfo }

implementation

uses
  System.SysUtils;

{ TDLCoordinate }

class function TDLCoordinate.Invalid: TDLCoordinate;
begin
  Result.Line := -1;
  Result.Column := -1;
end; { TDLCoordinate.Invalid }

function TDLCoordinate.IsValid: boolean;
begin
  Result := (Line >= 0) and (Column >= 0);
end; { TDLCoordinate.IsValid }

procedure TDLCoordinate.SetLocation(const node: TSyntaxNode);
begin
  if not assigned(node) then
    Self := TDLCoordinate.Invalid
  else begin
    Line := node.Line;
    Column := node.Col;
  end;
end;

function TDLCoordinate.ToString: string;
begin
  Result := Format('%d,%d', [Line, Column]);
end; { TDLCoordinate.ToString }

{ TDLUnitInfo }

class function TDLUnitInfo.Create: TDLUnitInfo;
begin
  Result.Name := '';
  Result.InterfaceLoc := TDLCoordinate.Invalid;
  Result.InterfaceUsesLoc := TDLCoordinate.Invalid;
  Result.ImplementationLoc := TDLCoordinate.Invalid;
  Result.ImplementationUsesLoc := TDLCoordinate.Invalid;
  Result.InitializationLoc := TDLCoordinate.Invalid;
  Result.FinalizationLoc := TDLCoordinate.Invalid;
  Result.InterfaceUses := TCollections.CreateList<string>;
  Result.InterfaceTypes := TCollections.CreateObjectList<TDLTypeInfo>;
  Result.ImplementationUses := TCollections.CreateList<string>;
  Result.ImplementationTypes := TCollections.CreateObjectList<TDLTypeInfo>;
end; { TDLUnitInfo.Create }

function TDLUnitInfo.UnitType: TDLUnitType;
begin
  Result := utProgram;
  if InterfaceLoc.Line >= 0 then
    Result := utUnit;
end; { TDLUnitInfo.UnitType }

function TDLTypeInfo.EnsureSection(sectionType: TDLTypeSection): TDLTypeSectionInfo;
begin
  if not assigned(Sections[sectionType]) then
    Sections[sectionType] := TDLTypeSectionInfo.Create;
  Result := Sections[sectionType];
end; { TDLTypeInfo.EnsureSection }

end.
