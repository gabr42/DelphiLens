unit DelphiLens.UnitInfo;

interface

uses
  System.Types,
  DelphiAST.Classes,
  Spring, Spring.Collections;

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

  TDLUnitType = (utProgram, utUnit, utPackage);

  TDLTypeInfoList = IList<TDLTypeInfo>;

  TDLUnitList = Vector<string>;

  TDLUnitListHelper = record helper for TDLUnitList
    //TODO: Simplify when Spring 1.3 is released
    function ContainsI(const item: string): boolean;
  end; { TDLUnitListHelper }

  IDLUnitInfo = interface ['{66126E24-1395-4EAB-A2B7-117A42A3EAF2}']
    function  GetContainsLoc: TDLCoordinate;
    function  GetFinalizationLoc: TDLCoordinate;
    function  GetImplementationLoc: TDLCoordinate;
    function  GetImplementationTypes: TDLTypeInfoList;
    function  GetImplementationUses: TDLUnitList;
    function  GetImplementationUsesLoc: TDLCoordinate;
    function  GetInitializationLoc: TDLCoordinate;
    function  GetInterfaceLoc: TDLCoordinate;
    function  GetInterfaceTypes: TDLTypeInfoList;
    function  GetInterfaceUses: TDLUnitList;
    function  GetInterfaceUsesLoc: TDLCoordinate;
    function  GetName: string;
    function  GetPackageContains: TDLUnitList;
    function  GetUnitType: TDLUnitType;
    procedure SetContainsLoc(const value: TDLCoordinate);
    procedure SetFinalizationLoc(const value: TDLCoordinate);
    procedure SetImplementationLoc(const value: TDLCoordinate);
    procedure SetImplementationTypes(const value: TDLTypeInfoList);
    procedure SetImplementationUses(const value: TDLUnitList);
    procedure SetImplementationUsesLoc(const value: TDLCoordinate);
    procedure SetInitializationLoc(const value: TDLCoordinate);
    procedure SetInterfaceLoc(const value: TDLCoordinate);
    procedure SetInterfaceTypes(const value: TDLTypeInfoList);
    procedure SetInterfaceUses(const value: TDLUnitList);
    procedure SetInterfaceUsesLoc(const value: TDLCoordinate);
    procedure SetName(const value: string);
    procedure SetPackageContains(const value: TDLUnitList);
  //
    property InterfaceLoc: TDLCoordinate read GetInterfaceLoc write SetInterfaceLoc;
    property InterfaceUsesLoc: TDLCoordinate read GetInterfaceUsesLoc write SetInterfaceUsesLoc;
    property ImplementationLoc: TDLCoordinate read GetImplementationLoc write SetImplementationLoc;
    property ImplementationUsesLoc: TDLCoordinate read GetImplementationUsesLoc write SetImplementationUsesLoc;
    property ContainsLoc: TDLCoordinate read GetContainsLoc write SetContainsLoc;
    property InitializationLoc: TDLCoordinate read GetInitializationLoc write SetInitializationLoc;
    property FinalizationLoc: TDLCoordinate read GetFinalizationLoc write SetFinalizationLoc;

    property InterfaceUses: TDLUnitList read GetInterfaceUses write SetInterfaceUses;
    property InterfaceTypes: TDLTypeInfoList read GetInterfaceTypes write SetInterfaceTypes;
    property ImplementationUses: TDLUnitList read GetImplementationUses write SetImplementationUses;
    property ImplementationTypes: TDLTypeInfoList read GetImplementationTypes write SetImplementationTypes;
    property PackageContains: TDLUnitList read GetPackageContains write SetPackageContains;

    property Name: string read GetName write SetName;
    property UnitType: TDLUnitType read GetUnitType;
  end; { IDLUnitInfo }

function CreateDLUnitInfo: IDLUnitInfo;

implementation

uses
  System.SysUtils, System.Generics.Defaults;

type
  TDLUnitInfo = class(TInterfacedObject, IDLUnitInfo)
  strict private
    FContainsLoc          : TDLCoordinate;
    FFinalizationLoc      : TDLCoordinate;
    FImplementationLoc    : TDLCoordinate;
    FImplementationTypes  : TDLTypeInfoList;
    FImplementationUses   : TDLUnitList; // also used to store PackageContains
    FImplementationUsesLoc: TDLCoordinate;
    FInitializationLoc    : TDLCoordinate;
    FInterfaceLoc         : TDLCoordinate;
    FInterfaceTypes       : TDLTypeInfoList;
    FInterfaceUses        : TDLUnitList;
    FInterfaceUsesLoc     : TDLCoordinate;
    FName                 : string;
  strict protected
    function  GetContainsLoc: TDLCoordinate;
    function  GetFinalizationLoc: TDLCoordinate;
    function  GetImplementationLoc: TDLCoordinate;
    function  GetImplementationTypes: TDLTypeInfoList;
    function  GetImplementationUses: TDLUnitList;
    function  GetImplementationUsesLoc: TDLCoordinate;
    function  GetInitializationLoc: TDLCoordinate;
    function  GetInterfaceLoc: TDLCoordinate;
    function  GetInterfaceTypes: TDLTypeInfoList;
    function  GetInterfaceUses: TDLUnitList;
    function  GetInterfaceUsesLoc: TDLCoordinate;
    function  GetName: string;
    function  GetPackageContains: TDLUnitList;
    function  GetUnitType: TDLUnitType;
    procedure SetContainsLoc(const value: TDLCoordinate);
    procedure SetFinalizationLoc(const value: TDLCoordinate);
    procedure SetImplementationLoc(const value: TDLCoordinate);
    procedure SetImplementationTypes(const value: TDLTypeInfoList);
    procedure SetImplementationUses(const value: TDLUnitList);
    procedure SetImplementationUsesLoc(const value: TDLCoordinate);
    procedure SetInitializationLoc(const value: TDLCoordinate);
    procedure SetInterfaceLoc(const value: TDLCoordinate);
    procedure SetInterfaceTypes(const value: TDLTypeInfoList);
    procedure SetInterfaceUses(const value: TDLUnitList);
    procedure SetInterfaceUsesLoc(const value: TDLCoordinate);
    procedure SetName(const value: string);
    procedure SetPackageContains(const value: TDLUnitList);
  public
    constructor Create;
    property ContainsLoc: TDLCoordinate read GetContainsLoc write SetContainsLoc;
    property FinalizationLoc: TDLCoordinate read GetFinalizationLoc write SetFinalizationLoc;
    property ImplementationLoc: TDLCoordinate read GetImplementationLoc write SetImplementationLoc;
    property ImplementationTypes: TDLTypeInfoList read GetImplementationTypes write SetImplementationTypes;
    property ImplementationUses: TDLUnitList read GetImplementationUses write SetImplementationUses;
    property ImplementationUsesLoc: TDLCoordinate read GetImplementationUsesLoc write SetImplementationUsesLoc;
    property InitializationLoc: TDLCoordinate read GetInitializationLoc write SetInitializationLoc;
    property InterfaceLoc: TDLCoordinate read GetInterfaceLoc write SetInterfaceLoc;
    property InterfaceTypes: TDLTypeInfoList read GetInterfaceTypes write SetInterfaceTypes;
    property InterfaceUses: TDLUnitList read GetInterfaceUses write SetInterfaceUses;
    property InterfaceUsesLoc: TDLCoordinate read GetInterfaceUsesLoc write SetInterfaceUsesLoc;
    property Name: string read GetName write SetName;
    property PackageContains: TDLUnitList read GetPackageContains write SetPackageContains;
    property UnitType: TDLUnitType read GetUnitType;
  end; { TDLUnitInfo }

{ exports }

function CreateDLUnitInfo: IDLUnitInfo;
begin
  Result := TDLUnitInfo.Create;
end; { CreateDLUnitInfo }

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

constructor TDLUnitInfo.Create;
begin
  inherited Create;
  InterfaceLoc := TDLCoordinate.Invalid;
  InterfaceUsesLoc := TDLCoordinate.Invalid;
  ImplementationLoc := TDLCoordinate.Invalid;
  ImplementationUsesLoc := TDLCoordinate.Invalid;
  InitializationLoc := TDLCoordinate.Invalid;
  FinalizationLoc := TDLCoordinate.Invalid;
  InterfaceTypes := TCollections.CreateObjectList<TDLTypeInfo>;
  ImplementationTypes := TCollections.CreateObjectList<TDLTypeInfo>;
end; { TDLUnitInfo.Create }

function TDLUnitInfo.GetContainsLoc: TDLCoordinate;
begin
  Result := FContainsLoc;
end; { TDLUnitInfo.GetContainsLoc }

function TDLUnitInfo.GetFinalizationLoc: TDLCoordinate;
begin
  Result := FFinalizationLoc;
end; { TDLUnitInfo.GetFinalizationLoc }

function TDLUnitInfo.GetImplementationLoc: TDLCoordinate;
begin
  Result := FImplementationLoc;
end; { TDLUnitInfo.GetImplementationLoc }

function TDLUnitInfo.GetImplementationTypes: TDLTypeInfoList;
begin
  Result := FImplementationTypes;
end; { TDLUnitInfo.GetImplementationTypes }

function TDLUnitInfo.GetImplementationUses: TDLUnitList;
begin
  Result := FImplementationUses;
end; { TDLUnitInfo.GetImplementationUses }

function TDLUnitInfo.GetImplementationUsesLoc: TDLCoordinate;
begin
  Result := FImplementationUsesLoc;
end; { TDLUnitInfo.GetImplementationUsesLoc }

function TDLUnitInfo.GetInitializationLoc: TDLCoordinate;
begin
  Result := FInitializationLoc;
end; { TDLUnitInfo.GetInitializationLoc }

function TDLUnitInfo.GetInterfaceLoc: TDLCoordinate;
begin
  Result := FInterfaceLoc;
end; { TDLUnitInfo.GetInterfaceLoc }

function TDLUnitInfo.GetInterfaceTypes: TDLTypeInfoList;
begin
  Result := FInterfaceTypes;
end; { TDLUnitInfo.GetInterfaceTypes }

function TDLUnitInfo.GetInterfaceUses: TDLUnitList;
begin
  Result := FInterfaceUses;
end; { TDLUnitInfo.GetInterfaceUses }

function TDLUnitInfo.GetInterfaceUsesLoc: TDLCoordinate;
begin
  Result := FInterfaceUsesLoc;
end; { TDLUnitInfo.GetInterfaceUsesLoc }

function TDLUnitInfo.GetName: string;
begin
  Result := FName;
end; { TDLUnitInfo.GetName }

function TDLUnitInfo.GetPackageContains: TDLUnitList;
begin
  Result := FImplementationUses;
end; { TDLUnitInfo.GetPackageContains }

function TDLUnitInfo.GetUnitType: TDLUnitType;
begin
  Result := utProgram;
  if InterfaceLoc.Line >= 0 then
    Result := utUnit
  else if ContainsLoc.Line >= 0 then
    Result := utPackage;
end; { TDLUnitInfo.GetUnitType }

procedure TDLUnitInfo.SetContainsLoc(const value: TDLCoordinate);
begin
  FContainsLoc := value;
end; { TDLUnitInfo.SetContainsLoc }

procedure TDLUnitInfo.SetFinalizationLoc(const value: TDLCoordinate);
begin
  FFinalizationLoc := value;
end; { TDLUnitInfo.SetFinalizationLoc }

procedure TDLUnitInfo.SetImplementationLoc(const value: TDLCoordinate);
begin
  FImplementationLoc := value;
end; { TDLUnitInfo.SetImplementationLoc }

procedure TDLUnitInfo.SetImplementationTypes(const value: TDLTypeInfoList);
begin
  FImplementationTypes := value;
end; { TDLUnitInfo.SetImplementationTypes }

procedure TDLUnitInfo.SetImplementationUses(const value: TDLUnitList);
begin
  FImplementationUses := value;
end; { TDLUnitInfo.SetImplementationUses }

procedure TDLUnitInfo.SetImplementationUsesLoc(const value: TDLCoordinate);
begin
  FImplementationUsesLoc := value;
end; { TDLUnitInfo.SetImplementationUsesLoc }

procedure TDLUnitInfo.SetInitializationLoc(const value: TDLCoordinate);
begin
  FInitializationLoc := value;
end; { TDLUnitInfo.SetInitializationLoc }

procedure TDLUnitInfo.SetInterfaceLoc(const value: TDLCoordinate);
begin
  FInterfaceLoc := value;
end; { TDLUnitInfo.SetInterfaceLoc }

procedure TDLUnitInfo.SetInterfaceTypes(const value: TDLTypeInfoList);
begin
  FInterfaceTypes := value;
end; { TDLUnitInfo.SetInterfaceTypes }

procedure TDLUnitInfo.SetInterfaceUses(const value: TDLUnitList);
begin
  FInterfaceUses := value;
end; { TDLUnitInfo.SetInterfaceUses }

procedure TDLUnitInfo.SetInterfaceUsesLoc(const value: TDLCoordinate);
begin
  FInterfaceUsesLoc := value;
end; { TDLUnitInfo.SetInterfaceUsesLoc }

procedure TDLUnitInfo.SetName(const value: string);
begin
  FName := value;
end; { TDLUnitInfo.SetName }

procedure TDLUnitInfo.SetPackageContains(const value: TDLUnitList);
begin
  FImplementationUses := value;
end; { TDLUnitInfo.SetPackageContains }

{ TDLTypeInfo }

function TDLTypeInfo.EnsureSection(sectionType: TDLTypeSection): TDLTypeSectionInfo;
begin
  if not assigned(Sections[sectionType]) then
    Sections[sectionType] := TDLTypeSectionInfo.Create;
  Result := Sections[sectionType];
end; { TDLTypeInfo.EnsureSection }

{ TDLUnitListHelper }

function TDLUnitListHelper.ContainsI(const item: string): boolean;
var
  s: string;
begin
  Result := false;
  for s in Self do
    if SameText(item, s) then
      Exit(true);
end; { TDLUnitListHelper.Contains }

end.
