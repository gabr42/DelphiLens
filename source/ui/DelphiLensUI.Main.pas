unit DelphiLensUI.Main;

interface

uses
  Spring,
  DelphiLens.Intf,
  DelphiLensUI.UIXStorage,
  DelphiLensUI.UIXEngine.Intf;

procedure DLUIShowUI(const uixStorage: IDLUIXStorage; const projectInfo: IDLScanResult;
  const currentLocation: TDLUIXLocation; var navigateTo: Nullable<TDLUIXLocation>);

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Spring.Collections,
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXAnalyzer.Navigation,
  DelphiLensUI.UIXAnalyzer.History,
  DelphiLensUI.UIXEngine.Actions,
  DelphiLensUI.UIXEngine.VCLFloating;

type
  TDLAnalyzerInfo = TPair<string, IDLUIXAnalyzer>;
  TDLAnalyzers = IList<TDLAnalyzerInfo>;

  TDLUserInterface = class
  strict private type
    TUIXFrameBuilder = reference to procedure (const frame: IDLUIXFrame);
  var
    FAnalysisState: TDLAnalysisState;
    FExecuteAction: IDLUIXAction;
    FUIXAnalyzers : TDLAnalyzers;
    FUIXEngine    : IDLUIXEngine;
  strict protected
    procedure ShowAnalyzerPanel(const parentFrame: IDLUIXFrame;
      const parentAction: IDLUIXAction; const analyzer: IDLUIXAnalyzer);
    procedure ShowPanel(const parentFrame: IDLUIXFrame; const parentAction: IDLUIXAction;
      const frameBuilder: TUIXFrameBuilder);
  public
    constructor Create(const uixEngine: IDLUIXEngine; const analyzers: TDLAnalyzers);
    procedure Initialize(const projectInfo: IDLScanResult; const fileName: string;
      const line, column: integer);
    procedure ShowMain;
    property ExecuteAction: IDLUIXAction read FExecuteAction;
  end; { TDLUserInterface }

{ exports }

procedure DLUIShowUI(const uixStorage: IDLUIXStorage; const projectInfo: IDLScanResult;
  const currentLocation: TDLUIXLocation; var navigateTo: Nullable<TDLUIXLocation>);
var
  analyzers     : TDLAnalyzers;
  navigation    : IDLUIXNavigationAction;
  ui            : TDLUserInterface;
begin
  navigateTo := nil;

  analyzers := TCollections.CreateList<TDLAnalyzerInfo>;
  analyzers.Add(TDLAnalyzerInfo.Create('&Navigation', CreateNavigationAnalyzer));
  analyzers.Add(TDLAnalyzerInfo.Create('&History', CreateHistoryAnalyzer(uixStorage)));

  ui := TDLUserInterface.Create(CreateUIXEngine, analyzers);
  try
    ui.Initialize(projectInfo, currentLocation.UnitName, currentLocation.line, currentLocation.column);
    ui.ShowMain;
    if assigned(ui.ExecuteAction) then begin
      if Supports(ui.ExecuteAction, IDLUIXNavigationAction, navigation) then begin
        navigateTo := TDLUIXLocation.Create(navigation.Location.UnitName,
          navigation.Location.Line, navigation.Location.Column);
        if navigation.IsBackNavigation then
          uixStorage.History.Remove(navigateTo)
        else
          uixStorage.History.Add(TDLUIXLocation.Create(currentLocation));
      end;
    end;
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
  const parentAction: IDLUIXAction; const analyzer: IDLUIXAnalyzer);
begin
  ShowPanel(parentFrame, parentAction,
    procedure (const frame: IDLUIXFrame)
    begin
      analyzer.BuildFrame(frame);
    end);
end; { TDLUserInterface.ShowAnalyzerPanel }

procedure TDLUserInterface.ShowMain;
begin
  ShowPanel(nil, nil,
    procedure (const frame: IDLUIXFrame)
    var
      analyzer: TDLAnalyzerInfo;
    begin
      for analyzer in FUIXAnalyzers do
        if analyzer.Value.CanHandle(FAnalysisState) then
          frame.CreateAction(CreateOpenAnalyzerAction(analyzer.Key, analyzer.Value));
    end);
end; { TDLUserInterface.ShowMain }

procedure TDLUserInterface.ShowPanel(const parentFrame: IDLUIXFrame;
  const parentAction: IDLUIXAction; const frameBuilder: TUIXFrameBuilder);
var
  frame       : IDLUIXFrame;
  navigation  : IDLUIXNavigationAction;
  openAnalyzer: IDLUIXOpenAnalyzerAction;
begin
  frame := FUIXEngine.CreateFrame(parentFrame);
  frame.OnAction :=
    procedure (const frame: IDLUIXFrame; const action: IDLUIXAction)
    begin
      if Supports(action, IDLUIXOpenAnalyzerAction, openAnalyzer) then
        ShowAnalyzerPanel(frame, action, openAnalyzer.Analyzer)
      else if Supports(action, IDLUIXNavigationAction, navigation) then begin
        FExecuteAction := action;
        frame.Close;
      end;
    end;

  frameBuilder(frame);

  if assigned(parentFrame) then
    parentFrame.MarkActive(false);

  frame.Show(parentAction);

  if assigned(parentFrame) then begin
    if assigned(FExecuteAction) then
      parentFrame.Close
    else
      parentFrame.MarkActive(true);
  end;

  FUIXEngine.DestroyFrame(frame);
end; { TDLUserInterface.ShowPanel }

end.
