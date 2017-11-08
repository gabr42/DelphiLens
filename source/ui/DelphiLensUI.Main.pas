unit DelphiLensUI.Main;

interface

uses
  DelphiLens.Intf;

procedure DLUIShowUI(const projectInfo: IDLScanResult; const fileName: string;
  line, column: integer);

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Spring.Collections,
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXAnalyzer.Navigation,
  DelphiLensUI.UIXEngine.Intf,
  DelphiLensUI.UIXEngine.VCLFloating;

type
  TDLUserInterface = class
  strict private
    FAnalysisState: TDLAnalysisState;
    FUIXAnalyzers : TDLAnalyzers;
    FUIXEngine    : IDLUIXEngine;
  strict protected
    procedure BuildUIXForAnalyzer(const analyzer: TDLAnalyzerInfo);
  public
    constructor Create(const uixEngine: IDLUIXEngine; const analyzers: TDLAnalyzers);
    procedure Activate;
    procedure Build(const projectInfo: IDLScanResult; const fileName: string;
      const line, column: integer);
    procedure Teardown;
  end; { TDLUserInterface }

{ exports }

procedure DLUIShowUI(const projectInfo: IDLScanResult; const fileName: string;
  line, column: integer);
var
  analyzers: TDLAnalyzers;
  ui       : TDLUserInterface;
begin
  analyzers := TCollections.CreateList<TDLAnalyzerInfo>;
  analyzers.Add(TDLAnalyzerInfo.Create('Navigation', CreateNavigationAnalyzer));

  ui := TDLUserInterface.Create(CreateUIXEngine, analyzers);
  try
    ui.Build(projectInfo, fileName, line, column);
    try
      ui.Activate;
    finally ui.Teardown; end;
  finally FreeAndNil(ui); end;
end; { DLUIShowUI }

{ TDLUserInterface }

constructor TDLUserInterface.Create(const uixEngine: IDLUIXEngine;
  const analyzers: TDLAnalyzers);
begin
  inherited Create;
  FUIXEngine := uixEngine;
  FUIXAnalyzers := analyzers;
end; { TDLUserInterface.Create }

procedure TDLUserInterface.Activate;
begin
  FUIXEngine.ShowFrame;
end; { TDLUserInterface.Activate }

procedure TDLUserInterface.Build(const projectInfo: IDLScanResult;
  const fileName: string; const line, column: integer);
var
  analyzer: TDLAnalyzerInfo;
begin
  FAnalysisState := TDLAnalysisState.Create(projectInfo, fileName, line, column);

  FUIXEngine.CreateFrame;

  for analyzer in FUIXAnalyzers do
    BuildUIXForAnalyzer(analyzer);

  FUIXEngine.CompleteFrame;
end; { TDLUserInterface.Build }

procedure TDLUserInterface.BuildUIXForAnalyzer(const analyzer: TDLAnalyzerInfo);
begin
  if analyzer.Value.CanHandle(FAnalysisState) then begin
    FUIXEngine.CreateAction(analyzer);
  end;
end;

procedure TDLUserInterface.Teardown;
begin
  // TODO 1 -oPrimoz Gabrijelcic : implement: TDLUserInterface.Teardown
end; { TDLUserInterface.Teardown }

end.
