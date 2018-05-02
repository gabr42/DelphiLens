unit DelphiLens.FileCache;

interface

uses
  DelphiLens.FileCache.Intf;

function  CreateFileCache: IDLFileCache;

implementation

uses
  System.SysUtils, System.Classes,
  Spring, Spring.Collections;

type
  TDLFileCache = class(TInterfacedObject, IDLFileCache)
  strict private
  type
    TDLFileCacheItem = Tuple<string, string, IDLFileContent>;
  var
    FCache: IDictionary<string, TDLFileCacheItem>;
  public
    constructor Create;
    function GetFile(const unitName: string; var fileContent: IDLFileContent): boolean;
    function Load(const unitName, unitPath: string; var fileContent: IDLFileContent): boolean;
  end; { TDLFileCache }

{ exports }

function CreateFileCache: IDLFileCache;
begin
  Result := TDLFileCache.Create;
end; { CreateFileCache }

{ TDLFileCache }

constructor TDLFileCache.Create;
begin
  inherited;
  FCache := TCollections.CreateDictionary<string, TDLFileCacheItem>(TStringComparer.OrdinalIgnoreCase);
end; { TDLFileCacheItem }

function TDLFileCache.GetFile(const unitName: string;
  var fileContent: IDLFileContent): boolean;
var
  item: TDLFileCacheItem;
begin
  Result := FCache.TryGetValue(unitName, item);
  if Result then
    fileContent := item.Value3;
end; { TDLFileCache.GetFile }

function TDLFileCache.Load(const unitName, unitPath: string;
  var fileContent: IDLFileContent): boolean;
var
  sl: TStringList;
begin
  Result := false;
  sl := TStringList.Create;
  try
    try
      sl.LoadFromFile(unitPath);
    except
      Exit;
    end;
    fileContent := TCollections.CreateList<string>(sl.ToStringArray);
    FCache.Add(unitName,
      Tuple<string,string,IDLFileContent>.Create(unitName, unitPath, fileContent));
    Result := true;
  finally FreeAndNil(sl); end;
end; { TDLFileCache.Load }

end.
