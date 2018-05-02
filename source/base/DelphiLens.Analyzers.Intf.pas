unit DelphiLens.Analyzers.Intf;

interface

uses
  Spring.Collections,
  DelphiLens.UnitInfo;

type
  IDLUnitAnalyzer = interface ['{2C9AD172-D7C7-426E-B395-50307F02E836}']
    function All: ICollection<string>;
    function UnitUsedBy(const unitName: string): ICollection<string>;
    function UnitUses(const unitName: string): ICollection<string>;
  end; { IDLUnitAnalyzer }

  TDLFindOption = (foAllowSubstring);
  TDLFindOptions = set of TDLFindOption;

  TFindProgressProc = reference to procedure (const unitName: string; var abort: boolean);

  IDLFindAnalyzer = interface ['{3E7D804D-6F80-48D1-B8BD-27B2547F74AF}']
    function All(const ident: string; options: TDLFindOptions = [];
      progress: TFindProgressProc = nil): ICoordinates;
  end; { IDLFindAnalyzer }

  IDLAnalyzers = interface ['{50F73F1A-6563-4405-95CA-A75E30F4D2BC}']
    function  GetFind: IDLFindAnalyzer;
    function  GetUnits: IDLUnitAnalyzer;
  //
    property Find: IDLFindAnalyzer read GetFind;
    property Units: IDLUnitAnalyzer read GetUnits;
  end; { IDLAnalyzers }

implementation

end.
