unit DelphiLens.Analyzers.Find;

interface

uses
  DelphiLens.Intf, DelphiLens.Analyzers.Intf;

function CreateDLFindAnalyzer(const scanResult: IDLScanResult): IDLFindAnalyzer;

implementation

uses
  Spring.Collections,
  DelphiLens.UnitInfo;

type
  TDLFindAnalyzer = class(TInterfacedObject, IDLFindAnalyzer)
  strict private
    FScanResult: IDLScanResult;
  public
    constructor Create(const scanResult: IDLScanResult);
    function All(const ident: string): ICollection<TDLUnitCoordinates>;
  end; { TDLUnitAnalyzer }

{ exports }

function CreateDLFindAnalyzer(const scanResult: IDLScanResult): IDLFindAnalyzer;
begin
  Result := TDLFindAnalyzer.Create(scanResult);
end; { CreateDLFindAnalyzer }

{ TDLFindAnalyzer }

function TDLFindAnalyzer.All(const ident: string): ICollection<TDLUnitCoordinates>;
begin
  Result := TCollections.CreateList<TDLUnitCoordinates>;
end; { TDLFindAnalyzer.All }

constructor TDLFindAnalyzer.Create(const scanResult: IDLScanResult);
begin
  inherited Create;
  FScanResult := scanResult;
end; { TDLFindAnalyzer.Create }

end.
