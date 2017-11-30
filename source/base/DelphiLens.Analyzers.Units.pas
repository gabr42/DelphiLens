unit DelphiLens.Analyzers.Units;

interface

uses
  DelphiLens.Intf, DelphiLens.Analyzers.Intf;

function CreateDLUnitAnalyzer(const scanResult: IDLScanResult): IDLUnitAnalyzer;

implementation

uses
  System.Generics.Defaults,
  Spring, Spring.Collections,
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
  dlUnitInfo: IDLUnitInfo;
begin
  Result := TCollections.CreateSet<string>(TIStringComparer.Ordinal);
  for dlUnitInfo in FScanResult.Analysis do
    Result.Add(dlUnitInfo.Name);
end; { TDLUnitAnalyzer.All }

function TDLUnitAnalyzer.UnitUsedBy(const unitName: string): ICollection<string>;
var
  dlUnitInfo: IDLUnitInfo;
begin
  Result := TCollections.CreateSet<string>(TIStringComparer.Ordinal);
  for dlUnitInfo in FScanResult.Analysis do begin
    if dlUnitInfo.ImplementationUses.ContainsI(unitName)
       or dlUnitInfo.InterfaceUses.ContainsI(unitName)
       or dlUnitInfo.PackageContains.ContainsI(unitName)
    then
      Result.Add(dlUnitInfo.Name);
  end;
end; { TDLUnitAnalyzer.UnitUsedBy }

function TDLUnitAnalyzer.UnitUses(const unitName: string): ICollection<string>;
var
  dlUnitInfo: IDLUnitInfo;

  procedure Add(const collection: ICollection<string>; const units: TDLUnitList);
  var
    unitName: string;
  begin
    for unitName in units do
      if FScanResult.Analysis.ContainsUnit(unitName) then
        collection.Add(unitName);
  end; { Add }

begin { TDLUnitAnalyzer.UnitUses }
  Result := TCollections.CreateSet<string>(TIStringComparer.Ordinal);
  if not FScanResult.Analysis.Find(unitName, dlUnitInfo) then
    Exit;

  Add(Result, dlUnitInfo.InterfaceUses);
  Add(Result, dlUnitInfo.ImplementationUses);
  Add(Result, dlUnitInfo.PackageContains);
end; { TDLUnitAnalyzer.UnitUses }

end.
