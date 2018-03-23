unit DelphiLens.UnitInfo.Serializer;

interface

uses
  DelphiLens.UnitInfo.Serializer.Intf;

function CreateSerializer: IDLUnitInfoSerializer;

implementation

uses
  System.SysUtils, System.Classes,
  Spring, Spring.Collections,
  DelphiAST.Consts,
  DelphiLens.UnitInfo;

type
  TDLUnitInfoSerializer = class(TInterfacedObject, IDLUnitInfoSerializer)
  strict private const
    CVersion = 5;
  type
    TDLSectionArr = Vector<TDLSectionInfo>;
  var
    FStream: TStream;
  strict protected
    function  ReadByte(var b: byte): boolean; inline;
    function  ReadInteger(var val: integer): boolean; inline;
    function  ReadLocation(var loc: TDLCoordinate): boolean; inline;
    function  ReadRange(var range: TDLRange): boolean;
    function  ReadWord(var w: word): boolean; inline;
    function  ReadString(var s: string): boolean; inline;
    function  ReadStrings(var strings: TDLUnitList): boolean;
    function  ReadSection(var sec: TDLSectionInfo): boolean; inline;
    function  ReadSections(var sec: TDLSectionArr): boolean;
    function  ReadTypeInfo(typeInfo: TDLTypeInfo): boolean;
    function  ReadTypeList(types: TDLTypeInfoList): boolean;
    function  ReadTypeSectionInfo(typeSection: IDLTypeSectionInfo): boolean;
    procedure WriteByte(b: byte); inline;
    procedure WriteInteger(val: integer); inline;
    procedure WriteLocation(const loc: TDLCoordinate); inline;
    procedure WriteRange(const range: TDLRange); inline;
    procedure WriteSection(const sec: TDLSectionInfo); inline;
    procedure WriteSections(sec: IDLSectionList); inline;
    procedure WriteString(const s: string); inline;
    procedure WriteStrings(const strings: TDLUnitList);
    procedure WriteTypeInfo(typeInfo: TDLTypeInfo);
    procedure WriteTypeList(types: TDLTypeInfoList);
    procedure WriteTypeSectionInfo(typeSection: IDLTypeSectionInfo);
    procedure WriteWord(w: word); inline;
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
  s     : string;
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
  if not ReadTypeList(unitInfo.InterfaceTypes) then Exit;
  if not ReadTypeList(unitInfo.ImplementationTypes) then Exit;
  Result := true;
end; { TDLUnitInfoSerializer.Read }

function TDLUnitInfoSerializer.ReadByte(var b: byte): boolean;
begin
  Result := FStream.Read(b, 1) = 1;
end; { TDLUnitInfoSerializer.ReadByte }

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

function TDLUnitInfoSerializer.ReadRange(var range: TDLRange): boolean;
var
  loc: TDLCoordinate;
begin
  Result := false;
  if not ReadLocation(loc) then Exit;
  range.Start := loc;
  if not ReadLocation(loc) then Exit;
  range.&End := loc;
  Result := true;
end; { TDLUnitInfoSerializer.ReadRange }

function TDLUnitInfoSerializer.ReadSection(var sec: TDLSectionInfo): boolean;
var
  loc     : TDLCoordinate;
  nodeType: byte;
begin
  Result := false;
  if not ReadByte(nodeType) then
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

function TDLUnitInfoSerializer.ReadTypeInfo(typeInfo: TDLTypeInfo): boolean;
var
  b      : byte;
  loc    : TDLRange;
  s      : string;
  secInfo: IDLTypeSectionInfo;
  section: TDLTypeSection;
begin
  Result := false;
  if not ReadString(s) then Exit;
  typeInfo.Name := s;
  if not ReadRange(loc) then Exit;
  typeInfo.Location := loc;

  repeat
    if not ReadByte(b) then Exit;
    if b = High(byte) then
      break; //repeat
    if (b < Ord(Low(TDLTypeSection))) or (b > Ord(High(TDLTypeSection))) then Exit;
    section := TDLTypeSection(b);
    secInfo := TDLTypeSectionInfo.Create;
    if not ReadTypeSectionInfo(secInfo) then begin
      FreeAndNil(secInfo);
      Exit;
    end;
    typeInfo.Sections[section] := secInfo;
  until false;
  Result := true;
end; { TDLUnitInfoSerializer.ReadTypeInfo }

function TDLUnitInfoSerializer.ReadTypeList(types: TDLTypeInfoList): boolean;
var
  i       : integer;
  len     : word;
  typeInfo: TDLTypeInfo;
begin
  Result := false;
  if not ReadWord(len) then
    Exit;

  types.Clear;
  for i := 1 to len do begin
    typeInfo := TDLTypeInfo.Create;
    if not ReadTypeInfo(typeInfo) then begin
      FreeAndNil(typeInfo);
      Exit;
    end;
    types.Add(typeInfo);
  end;
  Result := true;
end; { TDLUnitInfoSerializer.ReadTypeList }

function TDLUnitInfoSerializer.ReadTypeSectionInfo(
  typeSection: IDLTypeSectionInfo): boolean;
var
  loc     : TDLCoordinate;
  typeList: TDLTypeInfoList;
begin
  Result := false;
  if not ReadLocation(loc) then Exit;
  typeSection.Location := loc;
  typeList := TDLTypeInfoList.Create;
  if not ReadTypeList(typeList) then begin
    FreeAndNil(typeList);
    Exit;
  end;
  if typeList.Count = 0 then
    FreeAndNil(typeList);
  typeSection.Types := typeList;
  Result := true;
end; { TDLUnitInfoSerializer.ReadTypeSectionInfo }

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
  WriteTypeList(unitInfo.InterfaceTypes);
  WriteTypeList(unitInfo.ImplementationTypes);
end; { TDLUnitInfoSerializer.Write }

procedure TDLUnitInfoSerializer.WriteByte(b: byte);
begin
  FStream.Write(b, 1);
end; { TDLUnitInfoSerializer.WriteByte }

procedure TDLUnitInfoSerializer.WriteInteger(val: integer);
begin
  FStream.Write(val, 4);
end; { TDLUnitInfoSerializer.WriteInteger }

procedure TDLUnitInfoSerializer.WriteLocation(const loc: TDLCoordinate);
begin
  WriteInteger(loc.Line);
  WriteInteger(loc.Column);
end; { TDLUnitInfoSerializer.WriteLocation }

procedure TDLUnitInfoSerializer.WriteRange(const range: TDLRange);
begin
  WriteLocation(range.Start);
  WriteLocation(range.&End);
end; { TDLUnitInfoSerializer.WriteRange }

procedure TDLUnitInfoSerializer.WriteSection(const sec: TDLSectionInfo);
begin
  WriteByte(Ord(sec.NodeType));
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

procedure TDLUnitInfoSerializer.WriteTypeInfo(typeInfo: TDLTypeInfo);
var
  section: TDLTypeSection;
begin
  WriteString(typeInfo.Name);
  WriteRange(typeInfo.Location);
  for section := Low(TDLTypeSection) to High(TDLTypeSection) do
    if assigned(typeInfo.Sections[section]) then begin
      WriteByte(Ord(section));
      WriteTypeSectionInfo(typeInfo.Sections[section]);
    end;
  WriteByte(High(byte));
end; { TDLUnitInfoSerializer.WriteTypeInfo }

procedure TDLUnitInfoSerializer.WriteTypeList(types: TDLTypeInfoList);
var
  typeInfo: TDLTypeInfo;
begin
  if not assigned(types) then
    WriteWord(0)
  else begin
    WriteWord(types.Count);
    for typeInfo in types do
      WriteTypeInfo(typeInfo);
  end;
end; { TDLUnitInfoSerializer.WriteTypeList }

procedure TDLUnitInfoSerializer.WriteTypeSectionInfo(
  typeSection: IDLTypeSectionInfo);
begin
  WriteLocation(typeSection.Location);
  WriteTypeList(typeSection.Types);
end; { TDLUnitInfoSerializer.WriteTypeSectionInfo }

procedure TDLUnitInfoSerializer.WriteWord(w: word);
begin
  FStream.Write(w, 2);
end; { TDLUnitInfoSerializer.WriteWord }

end.
