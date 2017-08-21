program ProjectIndexerResearch;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  FastMM4,
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiAST.Classes, DelphiAST.Serialize.Binary,
  GpStuff, GpStructuredStorage,
  ProjectIndexer;

type
  TEvents = class
  strict private
    FStorage: IGpStructuredStorage;
  strict protected
    function Cleanup(const fileName: string): string;
  public
    constructor Create(AStorage: IGpStructuredStorage);
    procedure GetUnitSyntax(Sender: TObject; const fileName: string; var syntaxTree: TSyntaxNode;
      var doParseUnit, doAbort: boolean);
    procedure UnitParsed(Sender: TObject; const unitName: string; const fileName: string;
      var syntaxTree: TSyntaxNode; syntaxTreeFromParser: boolean; var doAbort: boolean);
    property Storage: IGpStructuredStorage read FStorage;
  end;

var
  i      : integer;
  events : TEvents;
  indexer: TProjectIndexer;
  project: string;
  storage: IGpStructuredStorage;
  storageFile: string;

{ TEvents }

constructor TEvents.Create(AStorage: IGpStructuredStorage);
begin
  inherited Create;
  FStorage := AStorage;
end;

function TEvents.Cleanup(const fileName: string): string;
begin
  Result := StringReplace(fileName, ':\', '_\', []);
  Result := StringReplace(Result,   '\\', '\_\', []);
  Result := '\' + Result;
end;

procedure TEvents.GetUnitSyntax(Sender: TObject; const fileName: string;
  var syntaxTree: TSyntaxNode; var doParseUnit, doAbort: boolean);
var
  fn : string;
  mem: TMemoryStream;
  ser: TBinarySerializer;
  str: TStream;
begin
  fn := Cleanup(fileName);
  if storage.FileExists(fn) then begin
    str := storage.OpenFile(fn, fmOpenRead);
    try
      ser := TBinarySerializer.Create;
      try
        mem := TMemoryStream.Create;
        try
          mem.CopyFrom(str, 0);
          mem.Position := 0;
          if ser.Read(mem, syntaxTree) then begin
            doParseUnit := false;
            Writeln('Cached ', fileName);
          end;
        finally FreeAndNil(mem); end;
      finally FreeAndNil(ser); end;
    finally FreeAndNil(str); end;
  end;
end;

procedure TEvents.UnitParsed(Sender: TObject; const unitName, fileName: string;
  var syntaxTree: TSyntaxNode; syntaxTreeFromParser: boolean; var doAbort: boolean);
var
  mem: TMemoryStream;
  str: TStream;
  ser: TBinarySerializer;
begin
  if not syntaxTreeFromParser then
    Exit;

  str := storage.OpenFile(Cleanup(fileName), fmCreate);
  try
    ser := TBinarySerializer.Create;
    try
      mem := TMemoryStream.Create;
      try
        ser.Write(mem, syntaxTree);
        str.CopyFrom(mem, 0);
      finally FreeAndNil(mem); end;
      Writeln('Serialize ', fileName);
    finally FreeAndNil(ser); end;
  finally FreeAndNil(str); end;
end;

begin
  try
    project := 'h:\RAZVOJ\DelphiLens\stuff\ProjectIndexerResearch.dpr';
    indexer := TProjectIndexer.Create;
    try
      storage := CreateStructuredStorage;
      try
        events := TEvents.Create(storage);
        try
          storageFile := ChangeFileExt(project, '.dlens');
          storage.Initialize(storageFile, IFF(FileExists(storageFile), fmOpenReadWrite, fmCreate));
          indexer.SearchPath := '..\delphiast\source;..\delphiast\source\simpleparser;..\delphiast\project indexer';
          indexer.Defines := 'DEBUG';
          indexer.OnGetUnitSyntax := events.GetUnitSyntax;
          indexer.OnUnitParsed := events.UnitParsed;
          indexer.Index(project);
          Writeln(indexer.ParsedUnits.Count, ' units');
          for i := 0 to indexer.ParsedUnits.Count - 1 do
            Writeln(indexer.ParsedUnits[i].Name, ' in ', indexer.ParsedUnits[i].Path);
          Writeln;
          Writeln(indexer.IncludeFiles.Count, ' includes');
          for i := 0 to indexer.IncludeFiles.Count - 1 do
            Writeln(indexer.IncludeFiles[i].Name, ' @ ', indexer.IncludeFiles[i].Path);
          Writeln;
          Writeln(indexer.NotFoundUnits.Count, ' not found');
          for i := 0 to indexer.NotFoundUnits.Count - 1 do
            Writeln(indexer.NotFoundUnits[i]);
          Writeln;
          Writeln(indexer.Problems.Count, ' problems');
          for i := 0 to indexer.Problems.Count - 1 do
            Writeln(Ord(indexer.Problems[i].ProblemType), ' ', indexer.Problems[i].FileName, ': ',
              indexer.Problems[i].Description);
          Write('>');
          Readln;
        finally FreeAndNil(events); end;
      finally storage := nil; end;
    finally FreeAndNil(indexer); end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
