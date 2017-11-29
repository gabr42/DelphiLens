unit DelphiLens.UnitInfo.Serializer;

interface

uses
  DelphiLens.UnitInfo.Serializer.Intf;

function CreateSerializer: IDLUnitInfoSerializer;

implementation

uses
  System.Classes,
  Spring, Spring.Collections,
  DelphiLens.UnitInfo;

type
  TDLUnitInfoSerializer = class(TInterfacedObject, IDLUnitInfoSerializer)
  strict private const
    CVersion = 3;
  var
    FStream: TStream;
  strict protected
    function  ReadInteger(var val: integer): boolean; inline;
    function  ReadLocation(var loc: TDLCoordinate): boolean; inline;
    function  ReadWord(var w: word): boolean; inline;
    function  ReadString(var s: string): boolean; inline;
    function  ReadStrings(var strings: Vector<string>): boolean;
    procedure WriteInteger(val: integer); inline;
    procedure WriteWord(w: word); inline;
    procedure WriteLocation(loc: TDLCoordinate); inline;
    procedure WriteString(const s: string); inline;
    procedure WriteStrings(const strings: Vector<string>);
  public
    function  Read(stream: TStream; var unitInfo: TDLUnitInfo): boolean;
    procedure Write(const unitInfo: TDLUnitInfo; stream: TStream);
  end; { TDLUnitInfoSerializer }

{ exports }

function CreateSerializer: IDLUnitInfoSerializer;
begin
  Result := TDLUnitInfoSerializer.Create;
end; { CreateSerializer }

{ TDLUnitInfoSerializer }

function TDLUnitInfoSerializer.Read(stream: TStream; var unitInfo: TDLUnitInfo): boolean;
var
  version: integer;
begin
  Result := false;
  FStream := stream;
  unitInfo := TDLUnitInfo.Create;
  if not ReadInteger(version) then Exit;
  if version <> CVersion then Exit;
  if not ReadString(unitInfo.Name) then Exit;
  if not ReadLocation(unitInfo.InterfaceLoc) then Exit;
  if not ReadLocation(unitInfo.InterfaceUsesLoc) then Exit;
  if not ReadLocation(unitInfo.ImplementationLoc) then Exit;
  if not ReadLocation(unitInfo.ImplementationUsesLoc) then Exit;
  if not ReadLocation(unitInfo.ContainsLoc) then Exit;
  if not ReadLocation(unitInfo.InitializationLoc) then Exit;
  if not ReadLocation(unitInfo.FinalizationLoc) then Exit;
  if not ReadStrings(unitInfo.InterfaceUses) then Exit;
  if not ReadStrings(unitInfo.ImplementationUses) then Exit;
  if not ReadStrings(unitInfo.PackageContains) then Exit;
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

function TDLUnitInfoSerializer.ReadStrings(var strings: Vector<string>): boolean;
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

procedure TDLUnitInfoSerializer.Write(const unitInfo: TDLUnitInfo; stream: TStream);
begin
  FStream := stream;
  WriteInteger(CVersion);
  WriteString(unitInfo.Name);
  WriteLocation(unitInfo.InterfaceLoc);
  WriteLocation(unitInfo.InterfaceUsesLoc);
  WriteLocation(unitInfo.ImplementationLoc);
  WriteLocation(unitInfo.ImplementationUsesLoc);
  WriteLocation(unitInfo.ContainsLoc);
  WriteLocation(unitInfo.InitializationLoc);
  WriteLocation(unitInfo.FinalizationLoc);
  WriteStrings(unitInfo.InterfaceUses);
  WriteStrings(unitInfo.ImplementationUses);
  WriteStrings(unitInfo.PackageContains);
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

procedure TDLUnitInfoSerializer.WriteString(const s: string);
begin
  WriteWord(Length(s));
  if s <> '' then
    FStream.Write(s[1], Length(s) * SizeOf(s[1]));
end; { TDLUnitInfoSerializer.WriteString }

procedure TDLUnitInfoSerializer.WriteStrings(const strings: Vector<string>);
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
