unit DelphiLens.Analyzers.Find;

interface

uses
  DelphiLens.Intf, DelphiLens.Analyzers.Intf;

function CreateDLFindAnalyzer(const scanResult: IDLScanResult): IDLFindAnalyzer;

implementation

{ exports }

function CreateDLFindAnalyzer(const scanResult: IDLScanResult): IDLFindAnalyzer;
begin
  Result := nil;
end; { CreateDLFindAnalyzer }

end.
