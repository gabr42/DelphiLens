unit DelphiLens.Analyzers.Intf;

interface

uses
  Spring.Collections;

type
  IDLUnitAnalyzer = interface ['{2C9AD172-D7C7-426E-B395-50307F02E836}']
    function All: ICollection<string>;
    function UnitUsedBy(const unitName: string): ICollection<string>;
    function UnitUses(const unitName: string): ICollection<string>;
  end; { IDLUnitAnalyzer }

  IDLAnalyzers = interface ['{50F73F1A-6563-4405-95CA-A75E30F4D2BC}']
    function  GetUnits: IDLUnitAnalyzer;
  //
    property Units: IDLUnitAnalyzer read GetUnits;
  end; { IDLAnalyzers }

implementation

end.
