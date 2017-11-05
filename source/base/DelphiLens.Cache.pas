unit DelphiLens.Cache;

interface

uses
  DelphiLens.Cache.Intf;

function CreateDLCache(const cacheFileName: string; dataFormatVersion: integer): IDLCache;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Defaults, System.Generics.Collections,
  DelphiAST.Classes,
  ProjectIndexer,
  DSiWin32,
  GpStuff, GpStructuredStorage;

type
  TDLCache = class(TInterfacedObject, IDLCache)
  strict private const
    AttrDataFormatVersion = 'DataFormatVersion';
    AttrDataVersioning    = 'DataVersioning';
    AttrFileModified      = 'FileModificationTime';
  type
    TLastGet = record
      FileName: string;
      FileTime: string;
    end;
    TUnitInfo = record
      FullName: string;
      FileTime: string;
      constructor Create(const AFullName, AFileTime: string);
    end;
    TCacheInfo = TDictionary<string{unit name}, TUnitInfo>;
  var
    FCacheInfo   : TCacheInfo;
    FDeserializeSyntaxTree: TDLTreeDeserializer;
    FLastGet     : TLastGet;
    FSerializeSyntaxTree: TDLTreeSerializer;
    FStatistics  : TCacheStatistics;
    FStorageFile : string;
    FStorage     : IGpStructuredStorage;
  strict protected
    function  CleanupFileName(const fileName: string): string;
    function  DateDumpStr(dt: TDateTime): string;
    function  GetDataVersioning: string;
    function  GetDeserializeSyntaxTree: TDLTreeDeserializer;
    function  GetSerializeSyntaxTree: TDLTreeSerializer;
    function  GetStatistics: TCacheStatistics;
    procedure IndexerGetUnitSyntax(Sender: TObject; const fileName: string;
      var syntaxTree: TSyntaxNode; var doParseUnit, doAbort: boolean);
    procedure IndexerUnitParsed(Sender: TObject; const unitName: string; const fileName: string;
      var syntaxTree: TSyntaxNode; syntaxTreeFromParser: boolean; var doAbort: boolean);
    procedure LoadCacheInfo(const folder: string);
    procedure SetDataVersioning(const value: string);
    procedure SetDeserializeSyntaxTree(const value: TDLTreeDeserializer);
    procedure SetSerializeSyntaxTree(const value: TDLTreeSerializer);
  public
    constructor Create(const AStorageFile: string; ADataFormatVersion: integer);
    destructor  Destroy; override;
    procedure BindTo(indexer: TProjectIndexer);
    procedure ClearStatistics;
    property DataVersioning: string read GetDataVersioning write SetDataVersioning;
    property Statistics: TCacheStatistics read GetStatistics;
    property DeserializeSyntaxTree: TDLTreeDeserializer read GetDeserializeSyntaxTree write
      SetDeserializeSyntaxTree;
    property SerializeSyntaxTree: TDLTreeSerializer read GetSerializeSyntaxTree write
      SetSerializeSyntaxTree;
  end; { TDLCache }

{ exports }

function CreateDLCache(const cacheFileName: string; dataFormatVersion: integer): IDLCache;
begin
  Result := TDLCache.Create(cacheFileName, dataFormatVersion);
end; { CreateDLCache }

constructor TDLCache.Create(const AStorageFile: string; ADataFormatVersion: integer);

  procedure CreateStorage;
  begin
    FStorage := CreateStructuredStorage;
  end;

begin
  inherited Create;
  FStorageFile := AStorageFile;
  CreateStorage;
  FStorage.Initialize(FStorageFile, IFF(FileExists(FStorageFile), fmOpenReadWrite, fmCreate));
  if StrToIntDef(FStorage.FileInfo['/'].Attribute[AttrDataFormatVersion], 0) <> ADataFormatVersion then begin
    CreateStorage;
    FStorage.Initialize(FStorageFile, fmCreate);
    FStorage.FileInfo['/'].Attribute[AttrDataFormatVersion] := IntToStr(ADataFormatVersion);
  end;
  FCacheInfo := TCacheInfo.Create(1000, TIStringComparer.Ordinal);
  LoadCacheInfo('/');
end; { TDLCache.Create }

destructor TDLCache.Destroy;
begin
  FreeAndNil(FCacheInfo);
  inherited;
end; { TDLCache.Destroy }

procedure TDLCache.BindTo(indexer: TProjectIndexer);
begin
  indexer.OnGetUnitSyntax := IndexerGetUnitSyntax;
  indexer.OnUnitParsed := IndexerUnitParsed;
end; { TDLCache.BindTo }

function TDLCache.CleanupFileName(const fileName: string): string;
begin
  Result := StringReplace(fileName, ':\', '_\',  []);
  Result := StringReplace(Result,   '\\', '\_\', []);
  Result := StringReplace(Result,   '\',  '/',   [rfReplaceAll]);
  Result := '/' + Result;
end; { TDLCache.CleanupFileName }

procedure TDLCache.ClearStatistics;
begin
  FStatistics := Default(TCacheStatistics);
end; { TDLCache.ClearStatistics }

function TDLCache.DateDumpStr(dt: TDateTime): string;
begin
  Assert(SizeOf(dt) = SizeOf(int64));
  Result := IntToHex(PInt64(@dt)^, SizeOf(dt));
end; { TDLCache.DateDumpStr }

function TDLCache.GetDataVersioning: string;
begin
  Result := FStorage.FileInfo['/'].Attribute[AttrDataVersioning];
end; { TDLCache.GetDataVersioning }

function TDLCache.GetDeserializeSyntaxTree: TDLTreeDeserializer;
begin
  Result := FDeserializeSyntaxTree;
end; { TDLCache.GetDeserializeSyntaxTree }

function TDLCache.GetSerializeSyntaxTree: TDLTreeSerializer;
begin
  Result := FSerializeSyntaxTree;
end; { TDLCache.GetSerializeSyntaxTree }

function TDLCache.GetStatistics: TCacheStatistics;
begin
  Result := FStatistics;
end; { TDLCache.GetStatistics }

procedure TDLCache.IndexerGetUnitSyntax(Sender: TObject; const fileName: string;
  var syntaxTree: TSyntaxNode; var doParseUnit, doAbort: boolean);
var
  fn      : string;
  mem     : TMemoryStream;
  str     : TStream;
  unitInfo: TUnitInfo;
begin
  FLastGet.FileName := fileName;
  FLastGet.FileTime := DateDumpStr(DSiGetFileTime(fileName, ftLastModification));

  fn := CleanupFileName(fileName);

  if FCacheInfo.TryGetValue(ExtractFileName(fileName), unitInfo) then begin
    if not SameText(fn, unitInfo.FullName) then
      //unit moved or different unit found, remove cached info
      FStorage.Delete(fn)
    else
      if FStorage.FileExists(fn) and (unitInfo.FileTime = FLastGet.FileTime) then begin
        str := FStorage.OpenFile(fn, fmOpenRead);
        try
          mem := TMemoryStream.Create;
          try
            mem.CopyFrom(str, 0);
            mem.Position := 0;
            if DeserializeSyntaxTree(mem, syntaxTree) then
              doParseUnit := false;
          finally FreeAndNil(mem); end;
        finally FreeAndNil(str); end;
      end;
  end;

  if doParseUnit then
    Inc(FStatistics.NumScanned)
  else
    Inc(FStatistics.NumCached);
end; { TDLCache.IndexerGetUnitSyntax }

procedure TDLCache.IndexerUnitParsed(Sender: TObject; const unitName, fileName: string;
  var syntaxTree: TSyntaxNode; syntaxTreeFromParser: boolean; var doAbort: boolean);
var
  fn      : string;
  mem     : TMemoryStream;
  str     : TStream;
  unitInfo: TUnitInfo;
begin
  if not syntaxTreeFromParser then
    Exit; //already cached

  fn := CleanupFileName(fileName);

  unitInfo.FullName := fn;
  unitInfo.FileTime := FLastGet.FileTime;
  FCacheInfo.AddOrSetValue(ExtractFileName(fileName), unitInfo);

  str := FStorage.OpenFile(fn, fmCreate);
  try
    mem := TMemoryStream.Create;
    try
      SerializeSyntaxTree(syntaxTree, mem);
      str.Size := 0;
      str.CopyFrom(mem, 0);
    finally FreeAndNil(mem); end;
  finally FreeAndNil(str); end;

  if FLastGet.FileName <> fileName then
    FLastGet.FileTime := DateDumpStr(DSiGetFileTime(fileName, ftLastModification));
  FStorage.FileInfo[fn].Attribute[AttrFileModified] := FLastGet.FileTime;
end; { TDLCache.IndexerUnitParsed }

procedure TDLCache.LoadCacheInfo(const folder: string);
var
  fullName: string;
  item    : string;
  items   : TStringList;
begin
  items := TStringList.Create;
  try
    FStorage.FileNames(folder, items);
    for item in items do begin
      fullName := folder + item;
      FCacheInfo.Add(item, TUnitInfo.Create(fullName, FStorage.FileInfo[fullName].Attribute[AttrFileModified]));
    end;
    FStorage.FolderNames(folder, items);
    for item in items do
      LoadCacheInfo(folder + item + '/');
  finally FreeAndNil(items); end;
end; { TDLCache.LoadCacheInfo }

procedure TDLCache.SetDataVersioning(const value: string);
var
  dataFormat: string;
begin
  if value = FStorage.FileInfo['/'].Attribute[AttrDataVersioning] then
    Exit;

  dataFormat := FStorage.FileInfo['/'].Attribute[AttrDataFormatVersion];
  FStorage := CreateStructuredStorage;
  FStorage.Initialize(FStorageFile, fmCreate);
  FStorage.FileInfo['/'].Attribute[AttrDataFormatVersion] := dataFormat;
  FStorage.FileInfo['/'].Attribute[AttrDataVersioning] := value;

  FCacheInfo.Clear;
end; { TDLCache.SetDataVersioning }

procedure TDLCache.SetDeserializeSyntaxTree(const value: TDLTreeDeserializer);
begin
  FDeserializeSyntaxTree := value;
end; { TDLCache.SetDeserializeSyntaxTree }

procedure TDLCache.SetSerializeSyntaxTree(const value: TDLTreeSerializer);
begin
  FSerializeSyntaxTree := value;
end; { TDLCache.SetSerializeSyntaxTree }

{ TDLCache.TUnitInfo }

constructor TDLCache.TUnitInfo.Create(const AFullName, AFileTime: string);
begin
  FullName := AFullName;
  FileTime := AFileTime;
end; { TDLCache.TUnitInfo.Create }

end.
