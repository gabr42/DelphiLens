unit DelphiLens.Analyzers.Units;

interface

uses
  DelphiLens.Intf, DelphiLens.Analyzers.Intf;

function CreateDLUnitAnalyzer(const scanResult: IDLScanResult): IDLUnitAnalyzer;

implementation

uses
  System.Generics.Defaults,
  Spring.Collections,
  DelphiLens.UnitInfo;

type
  TDLUnitAnalyzer = class(TInterfacedObject, IDLUnitAnalyzer)
  strict private
    FScanResult: IDLScanResult;
  public
    constructor Create(const scanResult: IDLScanResult);
    function  All: ICollection<string>;
    function  UnitUsedBy(const unitName: string): ICollection<string>;
    function  UnitUses(const unitName: string): ICollection<string>;
  end; { TDLUnitAnalyzer }

{ exports }

function CreateDLUnitAnalyzer(const scanResult: IDLScanResult): IDLUnitAnalyzer;
begin
  Result := TDLUnitAnalyzer.Create(scanResult);
end; { CreateDLUnitAnalyzer }

{ TDLUnitAnalyzer }

constructor TDLUnitAnalyzer.Create(const scanResult: IDLScanResult);
begin
  inherited Create;
  FScanResult := scanResult;
end; { TDLUnitAnalyzer.Create }

function TDLUnitAnalyzer.All: ICollection<string>;
var
  dlUnitInfo: TDLUnitInfo;
begin
  Result := TCollections.CreateSet<string>(TIStringComparer.Ordinal);
  for dlUnitInfo in FScanResult.Analysis do
    Result.Add(dlUnitInfo.Name);
end; { TDLUnitAnalyzer.All }

function TDLUnitAnalyzer.UnitUsedBy(const unitName: string): ICollection<string>;
var
  dlUnitInfo: TDLUnitInfo;
begin
  Result := TCollections.CreateSet<string>(TIStringComparer.Ordinal);
  for dlUnitInfo in FScanResult.Analysis do begin
    if dlUnitInfo.ImplementationUses.Contains(unitName)
       or dlUnitInfo.InterfaceUses.Contains(unitName)
       or dlUnitInfo.PackageContains.Contains(unitName)
    then
      Result.Add(dlUnitInfo.Name);
  end;
end; { TDLUnitAnalyzer.UnitUsedBy }

function TDLUnitAnalyzer.UnitUses(const unitName: string): ICollection<string>;
var
  dlUnitInfo: TDLUnitInfo;
begin
  Result := TCollections.CreateSet<string>(TIStringComparer.Ordinal);
  if not FScanResult.Analysis.Find(unitName, dlUnitInfo) then
    Exit;

  Result.AddRange(dlUnitInfo.InterfaceUses);
  Result.AddRange(dlUnitInfo.ImplementationUses);
  Result.AddRange(dlUnitInfo.PackageContains);
end; { TDLUnitAnalyzer.UnitUses }

end.
