unit DelphiLens.Cache;

interface

uses
  DelphiLens.Cache.Intf;

function CreateDLCache(const cacheFileName: string): IDLCache;

implementation

uses
  System.SysUtils, System.Classes,
  DelphiAST.Classes, DelphiAST.Serialize.Binary,
  ProjectIndexer,
  GpStuff, GpStructuredStorage;

type
  TDLCache = class(TInterfacedObject, IDLCache)
  strict private
    FStorageFile  : string;
    FStorage      : IGpStructuredStorage;
    FSyntaxFilter : TProc<TSyntaxNode>;
  strict protected
    function  CleanupFileName(const fileName: string): string;
    function  GetSyntaxFilter: TProc<TSyntaxNode>;
    procedure IndexerGetUnitSyntax(Sender: TObject; const fileName: string;
      var syntaxTree: TSyntaxNode; var doParseUnit, doAbort: boolean);
    procedure IndexerUnitParsed(Sender: TObject; const unitName: string; const fileName: string;
      var syntaxTree: TSyntaxNode; syntaxTreeFromParser: boolean; var doAbort: boolean);
    procedure SetSyntaxFilter(const value: TProc<TSyntaxNode>);
  public
    constructor Create(const AStorageFile: string);
    procedure BindTo(indexer: TProjectIndexer);
    property SyntaxFilter: TProc<TSyntaxNode> read GetSyntaxFilter write SetSyntaxFilter;
  end; { TDLCache }

{ exports }

function CreateDLCache(const cacheFileName: string): IDLCache;
begin
  Result := TDLCache.Create(cacheFileName);
end; { CreateDLCache }

constructor TDLCache.Create(const AStorageFile: string);
begin
  inherited Create;
  FStorageFile := AStorageFile;
  FStorage := CreateStructuredStorage;
  FStorage.Initialize(FStorageFile, IFF(FileExists(FStorageFile), fmOpenReadWrite, fmCreate));
end; { TDLCache.Create }

procedure TDLCache.BindTo(indexer: TProjectIndexer);
begin
  indexer.OnGetUnitSyntax := IndexerGetUnitSyntax;
  indexer.OnUnitParsed := IndexerUnitParsed;
end; { TDLCache.BindTo }

function TDLCache.CleanupFileName(const fileName: string): string;
begin
  Result := StringReplace(fileName, ':\', '_\', []);
  Result := StringReplace(Result,   '\\', '\_\', []);
  Result := '\' + Result;
end; { TDLCache.CleanupFileName }

function TDLCache.GetSyntaxFilter: TProc<TSyntaxNode>;
begin
  Result := FSyntaxFilter;
end; { TDLCache.GetSyntaxFilter }

procedure TDLCache.IndexerGetUnitSyntax(Sender: TObject; const fileName: string;
  var syntaxTree: TSyntaxNode; var doParseUnit, doAbort: boolean);
var
  fn : string;
  mem: TMemoryStream;
  ser: TBinarySerializer;
  str: TStream;
begin
  fn := CleanupFileName(fileName);
  if FStorage.FileExists(fn) then begin
    str := FStorage.OpenFile(fn, fmOpenRead);
    try
      ser := TBinarySerializer.Create;
      try
        mem := TMemoryStream.Create;
        try
          mem.CopyFrom(str, 0);
          mem.Position := 0;
          if ser.Read(mem, syntaxTree) then
            doParseUnit := false;
        finally FreeAndNil(mem); end;
      finally FreeAndNil(ser); end;
    finally FreeAndNil(str); end;
  end;
end; { TDLCache.IndexerGetUnitSyntax }

procedure TDLCache.IndexerUnitParsed(Sender: TObject; const unitName, fileName: string;
  var syntaxTree: TSyntaxNode; syntaxTreeFromParser: boolean; var doAbort: boolean);
var
  mem: TMemoryStream;
  str: TStream;
  ser: TBinarySerializer;
begin
  if not syntaxTreeFromParser then
    Exit; //already cached

  str := FStorage.OpenFile(CleanupFileName(fileName), fmCreate);
  try
    ser := TBinarySerializer.Create;
    try
      mem := TMemoryStream.Create;
      try
        if assigned(SyntaxFilter) then
          SyntaxFilter(syntaxTree);
        ser.Write(mem, syntaxTree);
        str.CopyFrom(mem, 0);
      finally FreeAndNil(mem); end;
    finally FreeAndNil(ser); end;
  finally FreeAndNil(str); end;
end; { TDLCache.IndexerUnitParsed }

procedure TDLCache.SetSyntaxFilter(const value: TProc<TSyntaxNode>);
begin
  FSyntaxFilter := value;
end; { TDLCache.SetSyntaxFilter }

end.
