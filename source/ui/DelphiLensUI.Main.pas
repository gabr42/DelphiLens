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
  DelphiLensUI.UIXEngine.Actions,
  DelphiLensUI.UIXEngine.VCLFloating;

type
  TDLAnalyzerInfo = TPair<string, IDLUIXAnalyzer>;
  TDLAnalyzers = IList<TDLAnalyzerInfo>;

  TDLUserInterface = class
  strict private
    FAnalysisState: TDLAnalysisState;
    FUIXAnalyzers : TDLAnalyzers;
    FUIXEngine    : IDLUIXEngine;
  strict protected
    procedure ShowAnalyzerPanel(const parentFrame: IDLUIXFrame;
      const analyzer: IDLUIXAnalyzer);
  public
    constructor Create(const uixEngine: IDLUIXEngine; const analyzers: TDLAnalyzers);
    procedure Initialize(const projectInfo: IDLScanResult; const fileName: string;
      const line, column: integer);
    procedure ShowMain;
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
    ui.Initialize(projectInfo, fileName, line, column);
    ui.ShowMain;
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

procedure TDLUserInterface.Initialize(const projectInfo: IDLScanResult;
  const fileName: string; const line, column: integer);
begin
  FAnalysisState := TDLAnalysisState.Create(projectInfo, fileName, line, column);
end; { TDLUserInterface.Initialize }

procedure TDLUserInterface.ShowAnalyzerPanel(const parentFrame: IDLUIXFrame;
  const  analyzer: IDLUIXAnalyzer);
var
  frame: IDLUIXFrame;
begin
  frame := FUIXEngine.CreateFrame(parentFrame);
  // build content according to the frame
  FUIXEngine.CompleteFrame(frame);
//  frame.OnAction :=
//    procedure (const frame: IDLUIXFrame; const action: IDLUIXAction)
//    begin
//      if Supports(action, IDLUIXOpenAnalyzerAction, openAnalyzer) then
//        ShowAnalyzerPanel(frame, openAnalyzer.Analyzer);
//    end;
//  FUIXEngine.Disable(parentFrame);
  FUIXEngine.ShowFrame(frame);
  FUIXEngine.DestroyFrame(frame);
end; { TDLUserInterface.ShowAnalyzerPanel }

procedure TDLUserInterface.ShowMain;
var
  analyzer    : TDLAnalyzerInfo;
  frame       : IDLUIXFrame;
  openAnalyzer: IDLUIXOpenAnalyzerAction;
begin
  frame := FUIXEngine.CreateFrame(nil);
  for analyzer in FUIXAnalyzers do
    if analyzer.Value.CanHandle(FAnalysisState) then
      frame.CreateAction(CreateOpenAnalyzerAction(analyzer.Key, analyzer.Value));

  FUIXEngine.CompleteFrame(frame);
  frame.OnAction :=
    procedure (const frame: IDLUIXFrame; const action: IDLUIXAction)
    begin
      if Supports(action, IDLUIXOpenAnalyzerAction, openAnalyzer) then
        ShowAnalyzerPanel(frame, openAnalyzer.Analyzer);
    end;
  FUIXEngine.ShowFrame(frame);
  FUIXEngine.DestroyFrame(frame);
end; { TDLUserInterface.ShowMain }

end.
