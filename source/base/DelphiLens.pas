unit DelphiLens;

interface

uses
  DelphiLens.Intf;

function CreateDelphiLens(const projectFile: string): IDelphiLens;

implementation

uses
  System.SysUtils, System.Classes,
  DelphiAST.Consts, DelphiAST.Classes, DelphiAST.Serialize.Binary, DelphiAST.ProjectIndexer,
  DelphiLens.Cache.Intf, DelphiLens.Cache,
  DelphiLens.UnitInfo.Serializer.Intf, DelphiLens.UnitInfo.Serializer,
  DelphiLens.UnitInfo,
  DelphiLens.TreeAnalyzer.Intf, DelphiLens.TreeAnalyzer;

type
  TDLScanResult = class(TInterfacedObject, IDLScanResult)
  strict private
    [weak] FAnalysis: TAnalyzedUnits;
           FCache   : IDLCache;
    [weak] FIndexer : TProjectIndexer;
  strict protected
    function  GetAnalysis: TAnalyzedUnits;
    function  GetCacheStatistics: TCacheStatistics;
    function  GetIncludeFiles: TIncludeFiles;
    function  GetNotFoundUnits: TStringList;
    function  GetParsedUnits: TParsedUnits;
    function  GetProblems: TProblems;
  public
    constructor Create(AAnalysis: TAnalyzedUnits; ACache: IDLCache;
      AIndexer: TProjectIndexer);
    property Analysis: TAnalyzedUnits read GetAnalysis;
    property CacheStatistics: TCacheStatistics read GetCacheStatistics;
    property ParsedUnits: TParsedUnits read GetParsedUnits;
    property IncludeFiles: TIncludeFiles read GetIncludeFiles;
    property Problems: TProblems read GetProblems;
    property NotFoundUnits: TStringList read GetNotFoundUnits;
  end; { TDLScanResult }

  TDelphiLens = class(TInterfacedObject, IDelphiLens)
  strict private const
    CCacheDataVersion = 1;
    CCacheExt = '.dlens';
  var
    FAnalysis          : TAnalyzedUnits;
    FCache             : IDLCache;
    FConditionalDefines: string;
    FIndexer           : TProjectIndexer;
    FInterestingTypes  : set of TSyntaxNodeType;
    FProject           : string;
    FSearchPath        : string;
    FTreeAnalyzer      : IDLTreeAnalyzer;
  strict protected
    procedure AnalyzeTree(tree: TSyntaxNode; var unitInfo: TDLUnitInfo);
    procedure FilterSyntax(node: TSyntaxNode);
    function  GetConditionalDefines: string;
    function  GetProject: string;
    function  GetSearchPath: string;
    procedure SetConditionalDefines(const value: string);
    procedure SetSearchPath(const value: string);
    function  SyntaxTreeDeserializer(data: TStream; var tree: TSyntaxNode): boolean;
    procedure SyntaxTreeSerializer(tree: TSyntaxNode; data: TStream);
  public
    constructor Create(const AProject: string);
    destructor  Destroy; override;
    function  Rescan: IDLScanResult;
    property ConditionalDefines: string read GetConditionalDefines write SetConditionalDefines;
    property Project: string read GetProject;
    property SearchPath: string read GetSearchPath write SetSearchPath;
  end; { TDelphiLens }

{ exports }

function CreateDelphiLens(const projectFile: string): IDelphiLens;
begin
  Result := TDelphiLens.Create(projectFile);
end; { CreateDelphiLens }

{ TDelphiLens }

constructor TDelphiLens.Create(const AProject: string);
begin
  inherited Create;
  // Minimum set of types needed for ProjectIndexer to walk the 'uses' chain
  //FInterestingTypes := [ntFinalization, ntImplementation, ntInitialization,
  //  ntInterface, ntUnit, ntUses];
  // For now, store everything.
  // Maybe sometimes later I'll want to filter this information and store it in a different - faster format.
  FInterestingTypes := [];
  FProject := AProject;
  FIndexer := TProjectIndexer.Create;
  FCache := CreateDLCache(ChangeFileExt(FProject, CCacheExt), CCacheDataVersion);
  FCache.BindTo(FIndexer);
  FCache.DeserializeSyntaxTree := SyntaxTreeDeserializer;
  FCache.SerializeSyntaxTree := SyntaxTreeSerializer;
  FConditionalDefines := FCache.DataVersioning;
  FAnalysis := TAnalyzedUnits.Create;
  FTreeAnalyzer := CreateDLTreeAnalyzer;
end; { TDelphiLens.Create }

destructor TDelphiLens.Destroy;
begin
  FreeAndNil(FAnalysis);
  FreeAndNil(FIndexer);
  inherited;
end; { TDelphiLens.Destroy }

procedure TDelphiLens.AnalyzeTree(tree: TSyntaxNode; var unitInfo: TDLUnitInfo);
begin
  FTreeAnalyzer.AnalyzeTree(tree, unitInfo);
end; { TDelphiLens.AnalyzeTree }

procedure TDelphiLens.FilterSyntax(node: TSyntaxNode);
var
  iChild: integer;
begin
  for iChild := High(node.ChildNodes) downto Low(node.ChildNodes) do
    if (FInterestingTypes = []) or (node.ChildNodes[iChild].Typ in FInterestingTypes) then
      FilterSyntax(node.ChildNodes[iChild])
    else
      node.DeleteChild(node.ChildNodes[iChild]);
end; { TDelphiLens.FilterSyntax }

function TDelphiLens.GetConditionalDefines: string;
begin
  Result := FConditionalDefines;
end; { TDelphiLens.GetConditionalDefines }

function TDelphiLens.GetProject: string;
begin
  Result := FProject;
end; { TDelphiLens.GetProject }

function TDelphiLens.GetSearchPath: string;
begin
  Result := FSearchPath;
end; { TDelphiLens.GetSearchPath }

function TDelphiLens.Rescan: IDLScanResult;
begin
  FCache.DataVersioning := ConditionalDefines;
  FCache.ClearStatistics;
  FIndexer.SearchPath := SearchPath;
  FIndexer.Defines := ConditionalDefines;
  FAnalysis.Clear;
  FIndexer.Index(Project);
  Result := TDLScanResult.Create(FAnalysis, FCache, FIndexer);
end; { TDelphiLens.Rescan }

procedure TDelphiLens.SetConditionalDefines(const value: string);
begin
  FConditionalDefines := value;
end; { TDelphiLens.SetConditionalDefines }

procedure TDelphiLens.SetSearchPath(const value: string);
begin
  FSearchPath := value;
end; { TDelphiLens.SetSearchPath }

function TDelphiLens.SyntaxTreeDeserializer(data: TStream; var tree: TSyntaxNode): boolean;
var
  len       : integer;
  mem       : TMemoryStream;
  reader    : TBinarySerializer;
  unitInfo  : TDLUnitInfo;
  unitReader: IDLUnitInfoSerializer;
begin
  Result := true;
  mem := TMemoryStream.Create;
  try
    Assert(SizeOf(integer) = 4);
    if data.Read(len, 4) <> 4 then
      Exit(false);
    mem.CopyFrom(data, len);
    mem.Position := 0;

    reader := TBinarySerializer.Create;
    try
      if not reader.Read(mem, tree) then
        Exit(false);
    finally FreeAndNil(reader); end;

    // Successful deserialization, therefore SyntaxTreeSerializer won't be called and
    // we have to store analysis in the cache.

    unitReader := CreateSerializer;
    data.Position := len + 4;
    if not unitReader.Read(data, unitInfo) then
      Exit(false);
    FAnalysis.Add(unitInfo);
  finally FreeAndNil(mem); end;
end; { TDelphiLens.SyntaxTreeDeserializer }

procedure TDelphiLens.SyntaxTreeSerializer(tree: TSyntaxNode; data: TStream);
var
  len       : integer;
  mem       : TMemoryStream;
  unitInfo  : TDLUnitInfo;
  unitWriter: IDLUnitInfoSerializer;
  writer    : TBinarySerializer;
begin
  AnalyzeTree(tree, unitInfo);
  FilterSyntax(tree);

  FAnalysis.Add(unitInfo);

  mem := TMemoryStream.Create;
  try
    writer := TBinarySerializer.Create;
    try
      writer.Write(mem, tree);
    finally FreeAndNil(writer); end;

    len := mem.Size;
    Assert(SizeOf(integer) = 4);
    data.Write(len, 4);
    data.CopyFrom(mem, 0);

    mem.Size := 0;
    unitWriter := CreateSerializer;
    unitWriter.Write(unitInfo, mem);
    data.CopyFrom(mem, 0);
  finally FreeAndNil(mem); end;
end; { TDelphiLens.SyntaxTreeSerializer }

{ TDLScanResult }

constructor TDLScanResult.Create(AAnalysis: TAnalyzedUnits; ACache: IDLCache;
  AIndexer: TProjectIndexer);
begin
  inherited Create;
  FAnalysis := AAnalysis;
  FCache := ACache;
  FIndexer := AIndexer;
end; { TDLScanResult.Create }

function TDLScanResult.GetAnalysis: TAnalyzedUnits;
begin
  Result := FAnalysis;
end; { TDLScanResult.GetAnalysis }

function TDLScanResult.GetCacheStatistics: TCacheStatistics;
begin
  Result := FCache.Statistics;
end; { TDLScanResult.GetCacheStatistics }

function TDLScanResult.GetIncludeFiles: TIncludeFiles;
begin
  Result := FIndexer.IncludeFiles;
end; { TDLScanResult.GetIncludeFiles }

function TDLScanResult.GetNotFoundUnits: TStringList;
begin
  Result := FIndexer.NotFoundUnits;
end; { TDLScanResult.GetNotFoundUnits }

function TDLScanResult.GetParsedUnits: TParsedUnits;
begin
  Result := FIndexer.ParsedUnits;
end; { TDLScanResult.GetParsedUnits }

function TDLScanResult.GetProblems: TProblems;
begin
  Result := FIndexer.Problems;
end; { TDLScanResult.GetProblems }

end.
