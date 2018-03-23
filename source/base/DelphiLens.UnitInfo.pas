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
    class function Create(const node: TSyntaxNode): TDLCoordinate; overload; static;
    class function Create(ALine, AColumn: integer): TDLCoordinate; overload; static;
    class function Invalid: TDLCoordinate; static; inline;
    class function Max(const coord1, coord2: TDLCoordinate): TDLCoordinate; static;
    class function Min(const coord1, coord2: TDLCoordinate): TDLCoordinate; static;
    function  IsValid: boolean; inline;
    function  ToString: string; inline;
  end; { TDLCoordinateHelper }

  TDLRange = record
  public
    Start: TDLCoordinate;
    &End : TDLCoordinate;
    class function Create(const node: TSyntaxNode): TDLRange; static;
    class function Invalid: TDLRange; static; inline;
    function  ToString: string; inline;
    function  Union(const range: TDLRange): TDLRange;
  end; { TDLRange }

  TDLTypeSection = (secStrictPrivate, secPrivate, secStrictProtected, secProtected,
    secPublic, secPublished);

  TDLTypeInfoList = class;

  IDLTypeSectionInfo = interface ['{2D11D33C-2946-40EA-9716-B5D1C9086529}']
    function  GetLocation: TDLCoordinate;
    function  GetTypes: TDLTypeInfoList;
    procedure SetLocation(const value: TDLCoordinate);
    procedure SetTypes(value: TDLTypeInfoList);
  //
    property Location: TDLCoordinate read GetLocation write SetLocation;
    property Types   : TDLTypeInfoList read GetTypes write SetTypes;
  end; { IDLTypeSectionInfo }

  TDLTypeSectionInfo = class(TInterfacedObject, IDLTypeSectionInfo)
  strict private
    FLocation: TDLCoordinate;
    FTypes   : TDLTypeInfoList;
  strict protected
    function  GetLocation: TDLCoordinate; inline;
    function  GetTypes: TDLTypeInfoList; inline;
    procedure SetLocation(const value: TDLCoordinate); inline;
    procedure SetTypes(value: TDLTypeInfoList); inline;
  public
    constructor Create;
    destructor  Destroy;
    property Location: TDLCoordinate read GetLocation write SetLocation;
    property Types   : TDLTypeInfoList read GetTypes write SetTypes;
  end; { TDLTypeSectionInfo }

  TDLTypeInfo = class
  public
    Name    : string;
    Location: TDLRange;
    Sections: array [TDLTypeSection] of IDLTypeSectionInfo;
    function  EnsureSection(sectionType: TDLTypeSection): IDLTypeSectionInfo;
  end; { TDLTypeInfo }

  TDLTypeInfoList = class
  strict private
    FList: IList<TDLTypeInfo>;
  strict protected
    function  GetItem(idx: integer): TDLTypeInfo; inline;
  public
    constructor Create;
    procedure Add(typeInfo: TDLTypeInfo); inline;
    procedure Clear; inline;
    function  Count: integer; inline;
    function  GetEnumerator: IEnumerator<TDLTypeInfo>; inline;
    property Items[idx: integer]: TDLTypeInfo read GetItem; default;
  end; { TDLTypeInfoList }

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
    destructor  Destroy; override;
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

class function TDLCoordinate.Create(ALine, AColumn: integer): TDLCoordinate;
begin
  Result.Line := ALine;
  Result.Column := AColumn;
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

class function TDLCoordinate.Max(const coord1,
  coord2: TDLCoordinate): TDLCoordinate;
begin
  if not coord1.IsValid then
    Result := coord2
  else if not coord2.IsValid then
    Result := coord1
  else if coord1.Line > coord2.Line then
    Result := coord1
  else if coord2.Line > coord1.Line then
    Result := coord2
  else if coord1.Column > coord2.Column then
    Result := coord1
  else
    Result := coord2;
end; { TDLCoordinate.Max }

class function TDLCoordinate.Min(const coord1,
  coord2: TDLCoordinate): TDLCoordinate;
begin
  if not coord1.IsValid then
    Result := coord2
  else if not coord2.IsValid then
    Result := coord1
  else if coord1.Line < coord2.Line then
    Result := coord1
  else if coord2.Line < coord1.Line then
    Result := coord2
  else if coord1.Column < coord2.Column then
    Result := coord1
  else
    Result := coord2;
end; { TDLCoordinate.Min }

function TDLCoordinate.ToString: string;
begin
  Result := Format('%d,%d', [Line, Column]);
end; { TDLCoordinate.ToString }

{ TDLRange }

class function TDLRange.Create(const node: TSyntaxNode): TDLRange;
begin
  if not assigned(node) then begin
    Result.Start := TDLCoordinate.Invalid;
    Result.&End := TDLCoordinate.Invalid;
  end
  else begin
    Result.Start := TDLCoordinate.Create(node);
    if node is TCompoundSyntaxNode then
      Result.&End := TDLCoordinate.Create(TCompoundSyntaxNode(node).EndLine,
                                          TCompoundSyntaxNode(node).EndCol)
    else
      Result.&End := TDLCoordinate.Invalid;
  end;
end; { TDLRange.Create }

class function TDLRange.Invalid: TDLRange;
begin
  Result.Start := TDLCoordinate.Invalid;
  Result.&End  := TDLCoordinate.Invalid;
end; { TDLRange.Invalid }

function TDLRange.ToString: string;
begin
  Result := Start.ToString;
  if &End.IsValid then
    Result := Result + ' - ' + &End.ToString;
end; { TDLRange.ToString }

function TDLRange.Union(const range: TDLRange): TDLRange;
begin
  Result.Start := TDLCoordinate.Min(Start, range.Start);
  if &End.IsValid and range.&End.IsValid then
    Result.&End := TDLCoordinate.Max(&End, range.&End)
  else if range.&End.IsValid then
    Result.&End := TDLCoordinate.Max(Start, range.&End)
  else if &End.IsValid then
    Result.&End := TDLCoordinate.Max(&End, range.Start)
  else
    Result.&End := Result.Start;
end; { TDLRange.Union }

{ TDLUnitInfo }

constructor TDLUnitInfo.Create;
begin
  inherited Create;
  FInterfaceTypes := TDLTypeInfoList.Create;
  FImplementationTypes := TDLTypeInfoList.Create;
  FSections := TDLSectionList.Create;
end; { TDLUnitInfo.Create }

destructor TDLUnitInfo.Destroy;
begin
  FreeAndNil(FInterfaceTypes);
  FreeAndNil(FImplementationTypes);
  inherited;
end; { TDLUnitInfo.Destroy }

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

function TDLTypeInfo.EnsureSection(sectionType: TDLTypeSection): IDLTypeSectionInfo;
begin
  if not assigned(Sections[sectionType]) then
    Sections[sectionType] := TDLTypeSectionInfo.Create;
  Result := Sections[sectionType];
end; { TDLTypeInfo.EnsureSection }

{ TDLTypeInfoList }

constructor TDLTypeInfoList.Create;
begin
  inherited Create;
  FList := TCollections.CreateObjectList<TDLTypeInfo>;
end; { TDLTypeInfoList.Create }

procedure TDLTypeInfoList.Add(typeInfo: TDLTypeInfo);
begin
  FList.Add(typeInfo);
end; { TDLTypeInfoList.Add }

procedure TDLTypeInfoList.Clear;
begin
  FList.Clear;
end; { TDLTypeInfoList.Clear }

function TDLTypeInfoList.Count: integer;
begin
  Result := FList.Count;
end; { TDLTypeInfoList.Count }

function TDLTypeInfoList.GetEnumerator: IEnumerator<TDLTypeInfo>;
begin
  Result := FList.GetEnumerator;
end; { TDLTypeInfoList.GetEnumerator }

function TDLTypeInfoList.GetItem(idx: integer): TDLTypeInfo;
begin
  Result := FList[idx];
end; { TDLTypeInfoList.GetItem }

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

{ TDLTypeSectionInfo }

constructor TDLTypeSectionInfo.Create;
begin
  inherited Create;
  FLocation := TDLCoordinate.Invalid;
end; { TDLTypeSectionInfo.Create }

destructor TDLTypeSectionInfo.Destroy;
begin
  FreeAndNil(FTypes);
  inherited;
end; { TDLTypeSectionInfo.Destroy }

function TDLTypeSectionInfo.GetLocation: TDLCoordinate;
begin
  Result := FLocation;
end; { TDLTypeSectionInfo.GetLocation }

function TDLTypeSectionInfo.GetTypes: TDLTypeInfoList;
begin
  Result := FTypes;
end; { TDLTypeSectionInfo.GetTypes }

procedure TDLTypeSectionInfo.SetLocation(const value: TDLCoordinate);
begin
  FLocation := value;
end; { TDLTypeSectionInfo.SetLocation }

procedure TDLTypeSectionInfo.SetTypes(value: TDLTypeInfoList);
begin
  if assigned(FTypes) then
    FTypes.Free;
  FTypes := value;
end; { TDLTypeSectionInfo.SetTypes }

end.
