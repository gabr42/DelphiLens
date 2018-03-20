unit DelphiLens.UnitInfo.Serializer;

interface

uses
  DelphiLens.UnitInfo.Serializer.Intf;

function CreateSerializer: IDLUnitInfoSerializer;

implementation

uses
  System.Classes,
  Spring, Spring.Collections,
  DelphiAST.Consts,
  DelphiLens.UnitInfo;

type
  TDLUnitInfoSerializer = class(TInterfacedObject, IDLUnitInfoSerializer)
  strict private const
    CVersion = 4;
  type
    TDLSectionArr = Vector<TDLSectionInfo>;
  var
    FStream: TStream;
  strict protected
    function  ReadInteger(var val: integer): boolean; inline;
    function  ReadLocation(var loc: TDLCoordinate): boolean; inline;
    function  ReadWord(var w: word): boolean; inline;
    function  ReadString(var s: string): boolean; inline;
    function  ReadStrings(var strings: TDLUnitList): boolean;
    function  ReadSection(var sec: TDLSectionInfo): boolean; inline;
    function  ReadSections(var sec: TDLSectionArr): boolean;
    procedure WriteInteger(val: integer); inline;
    procedure WriteWord(w: word); inline;
    procedure WriteLocation(loc: TDLCoordinate); inline;
    procedure WriteSection(sec: TDLSectionInfo); inline;
    procedure WriteSections(sec: IDLSectionList); inline;
    procedure WriteString(const s: string); inline;
    procedure WriteStrings(const strings: TDLUnitList);
  public
    function  Read(stream: TStream; var unitInfo: IDLUnitInfo): boolean;
    procedure Write(const unitInfo: IDLUnitInfo; stream: TStream);
  end; { TDLUnitInfoSerializer }

{ exports }

function CreateSerializer: IDLUnitInfoSerializer;
begin
  Result := TDLUnitInfoSerializer.Create;
end; { CreateSerializer }

{ TDLUnitInfoSerializer }

function TDLUnitInfoSerializer.Read(stream: TStream; var unitInfo: IDLUnitInfo): boolean;
var
  s      : string;
  sec    : TDLSectionArr;
  units  : TDLUnitList;
  version: integer;
begin
  Result := false;
  FStream := stream;
  unitInfo := CreateDLUnitInfo;
  if not ReadInteger(version) then Exit;
  if version <> CVersion then Exit;
  if not ReadString(s) then Exit;
  unitInfo.Name := s;
  if not ReadStrings(units) then Exit;
  unitInfo.InterfaceUses := units;
  if not ReadStrings(units) then Exit;
  unitInfo.ImplementationUses := units;
  if not ReadStrings(units) then Exit;
  unitInfo.PackageContains := units;
  if not ReadSections(sec) then Exit;
  unitInfo.Sections.Add(sec);
  Result := true;
end; { TDLUnitInfoSerializer.Read }

function TDLUnitInfoSerializer.ReadInteger(var val: integer): boolean;
begin
  Result := FStream.Read(val, 4) = 4;
end; { TDLUnitInfoSerializer.ReadInteger }

function TDLUnitInfoSerializer.ReadLocation(var loc: TDLCoordinate): boolean;
begin
  Result := ReadInteger(loc.Line);
  if Result then
    Result := ReadInteger(loc.Column);
end; { TDLUnitInfoSerializer.ReadLocation }

function TDLUnitInfoSerializer.ReadSection(var sec: TDLSectionInfo): boolean;
var
  loc     : TDLCoordinate;
  nodeType: integer;
begin
  Result := false;
  if not ReadInteger(nodeType) then
    Exit;
  if (nodeType < Ord(Low(TSyntaxNodeType))) or (nodeType > Ord(High(TSyntaxNodeType))) then
    Exit;
  sec.NodeType := TDLSectionNodeType(nodeType);
  if not ReadLocation(loc) then
    Exit;
  sec.Location := loc;
  Result := true;
end; { TDLUnitInfoSerializer.ReadSection }

function TDLUnitInfoSerializer.ReadSections(var sec: TDLSectionArr): boolean;
var
  i      : integer;
  len    : word;
  section: TDLSectionInfo;
begin
  Result := false;
  if not ReadWord(len) then
    Exit;

  sec.Length := len;
  for i := 0 to len - 1 do begin
    if not ReadSection(section) then
      Exit;
    sec[i] := section;
  end;
  Result := true;
end; { TDLUnitInfoSerializer.ReadSections }

function TDLUnitInfoSerializer.ReadString(var s: string): boolean;
var
  dataLen: integer;
  len    : word;
begin
  Result := false;
  if not ReadWord(len) then
    Exit;
  SetLength(s, len);
  if len > 0 then begin
    dataLen := Length(s) * SizeOf(s[1]);
    if FStream.Read(s[1], dataLen) <> dataLen then
      Exit;
  end;
  Result := true;
end; { TDLUnitInfoSerializer.ReadString }

function TDLUnitInfoSerializer.ReadStrings(var strings: TDLUnitList): boolean;
var
  i  : integer;
  len: word;
  s  : string;
begin
  Result := false;
  if not ReadWord(len) then
    Exit;

  strings.Length := len;
  for i := 0 to len - 1 do begin
    if not ReadString(s) then
      Exit;
    strings[i] := s;
  end;
  Result := true;
end; { TDLUnitInfoSerializer.ReadStrings }

function TDLUnitInfoSerializer.ReadWord(var w: word): boolean;
begin
  Result := FStream.Read(w, 2) = 2;
end; { TDLUnitInfoSerializer.ReadWord }

procedure TDLUnitInfoSerializer.Write(const unitInfo: IDLUnitInfo; stream: TStream);
begin
  FStream := stream;
  WriteInteger(CVersion);
  WriteString(unitInfo.Name);
  WriteStrings(unitInfo.InterfaceUses);
  WriteStrings(unitInfo.ImplementationUses);
  WriteStrings(unitInfo.PackageContains);
  WriteSections(unitInfo.Sections);
end; { TDLUnitInfoSerializer.Write }

procedure TDLUnitInfoSerializer.WriteInteger(val: integer);
begin
  FStream.Write(val, 4);
end; { TDLUnitInfoSerializer.WriteInteger }

procedure TDLUnitInfoSerializer.WriteLocation(loc: TDLCoordinate);
begin
  WriteInteger(loc.Line);
  WriteInteger(loc.Column);
end; { TDLUnitInfoSerializer.WriteLocation }

procedure TDLUnitInfoSerializer.WriteSection(sec: TDLSectionInfo);
begin
  WriteInteger(Ord(sec.NodeType));
  WriteLocation(sec.Location);
end; { TDLUnitInfoSerializer.WriteSection }

procedure TDLUnitInfoSerializer.WriteSections(sec: IDLSectionList);
var
  section: TDLSectionInfo;
begin
  WriteWord(sec.Count);
  for section in sec do
    WriteSection(section);
end; { TDLUnitInfoSerializer.WriteSections }

procedure TDLUnitInfoSerializer.WriteString(const s: string);
begin
  WriteWord(Length(s));
  if s <> '' then
    FStream.Write(s[1], Length(s) * SizeOf(s[1]));
end; { TDLUnitInfoSerializer.WriteString }

procedure TDLUnitInfoSerializer.WriteStrings(const strings: TDLUnitList);
var
  s: string;
begin
  WriteWord(strings.Length);
  for s in strings do
    WriteString(s);
end; { TDLUnitInfoSerializer.WriteStrings }

procedure TDLUnitInfoSerializer.WriteWord(w: word);
begin
  FStream.Write(w, 2);
end; { TDLUnitInfoSerializer.WriteWord }

end.
