unit DelphiLensUI.UIXAnalyzer.Intf;

interface

uses
  System.Generics.Collections,
  Spring.Collections,
  DelphiLens.Intf,
  DelphiLensUI.UIXEngine.Intf;

type
  TDLAnalysisState = record
    Column     : integer;
    FileName   : string;
    Line       : integer;
    ProjectInfo: IDLScanResult;
    constructor Create(const AProjectInfo: IDLScanResult; const AFileName: string;
      ALine, AColumn: integer);
  end; { TDLAnalysisState }

  IDLUIXAnalyzer = interface ['{CB412130-697D-4486-B2B6-153E5BDF4E4A}']
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const state: TDLAnalysisState);
    function  CanHandle(const state: TDLAnalysisState): boolean;
  end; { IDLUIXAnalyzer }

implementation

constructor TDLAnalysisState.Create(const AProjectInfo: IDLScanResult; const AFileName:
  string; ALine, AColumn: integer);
begin
  ProjectInfo := AProjectInfo;
  FileName := AFileName;
  Line := ALine;
  Column := AColumn;
end; { TDLAnalysisState.Create }

end.
