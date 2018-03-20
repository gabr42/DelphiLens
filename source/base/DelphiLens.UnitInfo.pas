unit DelphiLens.UnitInfo;

interface

uses
  System.Types,
  DelphiAST.Consts, DelphiAST.Classes,
  Spring, Spring.Collections, Spring.Collections.Extensions;

type
  TDLCoordinate = record
  public
    Line  : integer;
    Column: integer;
    class function Create(const node: TSyntaxNode): TDLCoordinate; static;
    class function Invalid: TDLCoordinate; static; inline;
    function  IsValid: boolean; inline;
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

  TDLTypeInfoList = IList<TDLTypeInfo>;

  TDLSectionNodeType = (sntUnit, sntInterface, sntInterfaceUses,
    sntImplementation, sntImplementationUses, sntContains,
    sntInitialization, sntFinalization);

  TDLSectionInfo = record
  public
    NodeType: TDLSectionNodeType;
    Location: TDLCoordinate;
  end; { TDLSectionInfo }

  IDLSectionList = interface ['{9B9CEDED-20B2-44FA-A526-60BC8FE2BA23}']
    procedure Add(const values: Vector<TDLSectionInfo>);
    procedure AddOrSetLocation(nodeType: TDLSectionNodeType; value: TDLCoordinate);
    function  Count: integer;
    function  FindLocation(nodeType: TDLSectionNodeType): TDLCoordinate;
    function  GetEnumerator: IEnumerator<TDLSectionInfo>;
    procedure RemoveLocation(nodeType: TDLSectionNodeType);
    procedure UpdateLocation(nodeType: TDLSectionNodeType; value: TDLCoordinate);
    property Location[nodeType: TDLSectionNodeType]: TDLCoordinate read FindLocation write UpdateLocation; default;
  end; { IDLSectionList }

  TDLSectionList = class(TInterfacedObject, IDLSectionList)
  strict private
    FSections: IDictionary<TDLSectionNodeType, TDLCoordinate>;
  public
    constructor Create;
    procedure Add(const values: Vector<TDLSectionInfo>); inline;
    procedure AddOrSetLocation(nodeType: TDLSectionNodeType; value: TDLCoordinate);
    function  Count: integer; inline;
    function  FindLocation(nodeType: TDLSectionNodeType): TDLCoordinate;
    function  GetEnumerator: IEnumerator<TDLSectionInfo>;
    procedure RemoveLocation(nodeType: TDLSectionNodeType);
    procedure UpdateLocation(nodeType: TDLSectionNodeType; value: TDLCoordinate);
    property Location[nodeType: TDLSectionNodeType]: TDLCoordinate read FindLocation write UpdateLocation; default;
  end; { TDLSectionList }

  TDLUnitList = Vector<string>;

  TDLUnitListHelper = record helper for TDLUnitList
    //TODO: Simplify when Spring 1.2.2 is released
    function ContainsI(const item: string): boolean;
  end; { TDLUnitListHelper }

  TDLUnitType = (utProgram, utUnit, utPackage);

  IDLUnitInfo = interface ['{66126E24-1395-4EAB-A2B7-117A42A3EAF2}']
    function  GetImplementationTypes: TDLTypeInfoList;
    function  GetImplementationUses: TDLUnitList;
    function  GetInterfaceTypes: TDLTypeInfoList;
    function  GetInterfaceUses: TDLUnitList;
    function  GetName: string;
    function  GetPackageContains: TDLUnitList;
    function  GetSections: IDLSectionList;
    function  GetUnitType: TDLUnitType;
    procedure SetImplementationTypes(const value: TDLTypeInfoList);
    procedure SetImplementationUses(const value: TDLUnitList);
    procedure SetInterfaceTypes(const value: TDLTypeInfoList);
    procedure SetInterfaceUses(const value: TDLUnitList);
    procedure SetName(const value: string);
    procedure SetPackageContains(const value: TDLUnitList);
  //
    property Sections: IDLSectionList read GetSections;

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
    FImplementationTypes: TDLTypeInfoList;
    FImplementationUses : TDLUnitList; // also used to store PackageContains
    FInterfaceTypes     : TDLTypeInfoList;
    FInterfaceUses      : TDLUnitList;
    FName               : string;
    FSections           : IDLSectionList;
  strict protected
    function  GetImplementationTypes: TDLTypeInfoList;
    function  GetImplementationUses: TDLUnitList;
    function  GetInterfaceTypes: TDLTypeInfoList;
    function  GetInterfaceUses: TDLUnitList;
    function  GetName: string;
    function  GetPackageContains: TDLUnitList;
    function  GetSections: IDLSectionList;
    function  GetUnitType: TDLUnitType;
    procedure SetImplementationTypes(const value: TDLTypeInfoList);
    procedure SetImplementationUses(const value: TDLUnitList);
    procedure SetInterfaceTypes(const value: TDLTypeInfoList);
    procedure SetInterfaceUses(const value: TDLUnitList);
    procedure SetName(const value: string);
    procedure SetPackageContains(const value: TDLUnitList);
  public
    constructor Create;
    property ImplementationTypes: TDLTypeInfoList read GetImplementationTypes write SetImplementationTypes;
    property ImplementationUses: TDLUnitList read GetImplementationUses write SetImplementationUses;
    property InterfaceTypes: TDLTypeInfoList read GetInterfaceTypes write SetInterfaceTypes;
    property InterfaceUses: TDLUnitList read GetInterfaceUses write SetInterfaceUses;
    property Name: string read GetName write SetName;
    property PackageContains: TDLUnitList read GetPackageContains write SetPackageContains;
    property Sections: IDLSectionList read GetSections;
    property UnitType: TDLUnitType read GetUnitType;
  end; { TDLUnitInfo }

{ exports }

function CreateDLUnitInfo: IDLUnitInfo;
begin
  Result := TDLUnitInfo.Create;
end; { CreateDLUnitInfo }

{ TDLCoordinate }

class function TDLCoordinate.Create(const node: TSyntaxNode): TDLCoordinate;
begin
  if not assigned(node) then
    Result := TDLCoordinate.Invalid
  else begin
    Result.Line := node.Line;
    Result.Column := node.Col;
  end;
end; { TDLCoordinate.Create }

class function TDLCoordinate.Invalid: TDLCoordinate;
begin
  Result.Line := -1;
  Result.Column := -1;
end; { TDLCoordinate.Invalid }

function TDLCoordinate.IsValid: boolean;
begin
  Result := (Line >= 0) and (Column >= 0);
end; { TDLCoordinate.IsValid }

function TDLCoordinate.ToString: string;
begin
  Result := Format('%d,%d', [Line, Column]);
end; { TDLCoordinate.ToString }

{ TDLUnitInfo }

constructor TDLUnitInfo.Create;
begin
  inherited Create;
  InterfaceTypes := TCollections.CreateObjectList<TDLTypeInfo>;
  ImplementationTypes := TCollections.CreateObjectList<TDLTypeInfo>;
  FSections := TDLSectionList.Create;
end; { TDLUnitInfo.Create }

function TDLUnitInfo.GetImplementationTypes: TDLTypeInfoList;
begin
  Result := FImplementationTypes;
end; { TDLUnitInfo.GetImplementationTypes }

function TDLUnitInfo.GetImplementationUses: TDLUnitList;
begin
  Result := FImplementationUses;
end; { TDLUnitInfo.GetImplementationUses }

function TDLUnitInfo.GetInterfaceTypes: TDLTypeInfoList;
begin
  Result := FInterfaceTypes;
end; { TDLUnitInfo.GetInterfaceTypes }

function TDLUnitInfo.GetInterfaceUses: TDLUnitList;
begin
  Result := FInterfaceUses;
end; { TDLUnitInfo.GetInterfaceUses }

function TDLUnitInfo.GetName: string;
begin
  Result := FName;
end; { TDLUnitInfo.GetName }

function TDLUnitInfo.GetPackageContains: TDLUnitList;
begin
  Result := FImplementationUses;
end; { TDLUnitInfo.GetPackageContains }

function TDLUnitInfo.GetSections: IDLSectionList;
begin
  Result := FSections;
end; { TDLUnitInfo.GetSections }

function TDLUnitInfo.GetUnitType: TDLUnitType;
begin
  Result := utProgram;
  if Sections[sntContains].IsValid then
    Result := utPackage
  else if Sections[sntInterface].IsValid then
    Result := utUnit;
end; { TDLUnitInfo.GetUnitType }

procedure TDLUnitInfo.SetImplementationTypes(const value: TDLTypeInfoList);
begin
  FImplementationTypes := value;
end; { TDLUnitInfo.SetImplementationTypes }

procedure TDLUnitInfo.SetImplementationUses(const value: TDLUnitList);
begin
  FImplementationUses := value;
end; { TDLUnitInfo.SetImplementationUses }

procedure TDLUnitInfo.SetInterfaceTypes(const value: TDLTypeInfoList);
begin
  FInterfaceTypes := value;
end; { TDLUnitInfo.SetInterfaceTypes }

procedure TDLUnitInfo.SetInterfaceUses(const value: TDLUnitList);
begin
  FInterfaceUses := value;
end; { TDLUnitInfo.SetInterfaceUses }

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

{ TDLSectionList }

constructor TDLSectionList.Create;
begin
  inherited Create;
  FSections := TCollections.CreateDictionary<TDLSectionNodeType, TDLCoordinate>;
end; { TDLSectionList.Create }

procedure TDLSectionList.Add(const values: Vector<TDLSectionInfo>);
var
  value: TDLSectionInfo;
begin
  for value in values do
    FSections.Add(value.NodeType, value.Location);
end; { TDLSectionList.Add }

procedure TDLSectionList.AddOrSetLocation(nodeType: TDLSectionNodeType; value: TDLCoordinate);
begin
  FSections.AddOrSetValue(nodeType, value);
end; { TDLSectionList.AddOrSetLocation }

function TDLSectionList.Count: integer;
begin
  Result := FSections.Count;
end; { TDLSectionList.Count }

function TDLSectionList.FindLocation(nodeType: TDLSectionNodeType): TDLCoordinate;
begin
  if not FSections.TryGetValue(nodeType, Result) then
    Result := TDLCoordinate.Invalid;
end; { TDLSectionList.FindLocation }

function TDLSectionList.GetEnumerator: IEnumerator<TDLSectionInfo>;
begin
  Result := IEnumerator<TDLSectionInfo>(FSections.GetEnumerator);
end; { TDLSectionList.GetEnumerator }

procedure TDLSectionList.RemoveLocation(nodeType: TDLSectionNodeType);
begin
  FSections.Remove(nodeType);
end; { TDLSectionList.RemoveLocation }

procedure TDLSectionList.UpdateLocation(nodeType: TDLSectionNodeType;
  value: TDLCoordinate);
begin
  if value.IsValid then
    AddOrSetLocation(nodeType, value)
  else
    RemoveLocation(nodeType);
end; { TDLSectionList.UpdateLocation }

end.
