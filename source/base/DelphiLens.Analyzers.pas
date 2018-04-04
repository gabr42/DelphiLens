unit DelphiLens.Analyzers;

interface

uses
  DelphiLens.Intf, DelphiLens.Analyzers.Intf;

function CreateDLAnalyzers(const scanResult: IDLScanResult): IDLAnalyzers;

implementation

uses
  DelphiLens.Analyzers.Units;

type
  TDLAnalyzers = class(TInterfacedObject, IDLAnalyzers)
  strict private
    [weak] FScanResult: IDLScanResult;
    FUnitAnalyzer     : IDLUnitAnalyzer;
  strict protected
    function GetUnits: IDLUnitAnalyzer;
  public
    constructor Create(const scanResult: IDLScanResult);
    property Units: IDLUnitAnalyzer read GetUnits;
  end; { TDLAnalyzers }

{ exports }

function CreateDLAnalyzers(const scanResult: IDLScanResult): IDLAnalyzers;
begin
  Result := TDLAnalyzers.Create(scanResult);
end; { CreateDLAnalyzers }

{ TDLAnalyzers }

constructor TDLAnalyzers.Create(const scanResult: IDLScanResult);
begin
  inherited Create;
  FScanResult := scanResult;
end; { TDLAnalyzers.Create }

function TDLAnalyzers.GetUnits: IDLUnitAnalyzer;
begin
  if not assigned(FUnitAnalyzer) then
    FUnitAnalyzer := CreateDLUnitAnalyzer(FScanResult);
  Result := FUnitAnalyzer;
end; { TDLAnalyzers.GetUnits }

end.
