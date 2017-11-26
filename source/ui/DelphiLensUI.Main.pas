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
  GpConsole,
  DelphiLens.DelphiASTHelpers,
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXAnalyzer.Navigation,
  DelphiLensUI.UIXAnalyzer.UnitBrowser,
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
      const parentAction: IDLUIXAction; const action: IDLUIXOpenAnalyzerAction);
    procedure ShowPanel(const parentFrame: IDLUIXFrame; const parentAction: IDLUIXAction;
      const frameBuilder: TUIXFrameBuilder);
  public
    constructor Create(const uixEngine: IDLUIXEngine; const analyzers: TDLAnalyzers);
    procedure Initialize(const projectInfo: IDLScanResult; const fileName: string;
      const line, column: integer);
    procedure ProcessExecuteAction(const uixStorage: IDLUIXStorage;
      const currentLocation: TDLUIXLocation;
      var navigateTo: Nullable<TDLUIXLocation>);
    procedure ShowMain;
    property ExecuteAction: IDLUIXAction read FExecuteAction;
  end; { TDLUserInterface }

{ exports }

procedure DLUIShowUI(const uixStorage: IDLUIXStorage; const projectInfo: IDLScanResult;
  const currentLocation: TDLUIXLocation; var navigateTo: Nullable<TDLUIXLocation>);
var
  analyzers: TDLAnalyzers;
  ui       : TDLUserInterface;
begin
  navigateTo := nil;

  analyzers := TCollections.CreateList<TDLAnalyzerInfo>;
  analyzers.Add(TDLAnalyzerInfo.Create('&Navigation', CreateNavigationAnalyzer));
  analyzers.Add(TDLAnalyzerInfo.Create('&Units', CreateUnitBrowser));
  analyzers.Add(TDLAnalyzerInfo.Create('&History', CreateHistoryAnalyzer(uixStorage)));

  ui := TDLUserInterface.Create(CreateUIXEngine, analyzers);
  try
    ui.Initialize(projectInfo, currentLocation.UnitName, currentLocation.line, currentLocation.column);
    ui.ShowMain;
    ui.ProcessExecuteAction(uixStorage, currentLocation, navigateTo);
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

procedure TDLUserInterface.ProcessExecuteAction(
  const uixStorage: IDLUIXStorage; const currentLocation: TDLUIXLocation;
  var navigateTo: Nullable<TDLUIXLocation>);
var
  fileName  : string;
  navigation: IDLUIXNavigationAction;
begin
  if assigned(ExecuteAction) then begin
    if Supports(ExecuteAction, IDLUIXNavigationAction, navigation) then begin
      fileName := navigation.Location.FileName;
      if fileName = '' then
        fileName := FAnalysisState.ProjectInfo.ParsedUnits.FindOrDefault(navigation.Location.UnitName).Path;
      navigateTo := TDLUIXLocation.Create(fileName,
        navigation.Location.UnitName,
        navigation.Location.Line, navigation.Location.Column);
      if navigation.IsBackNavigation then
        uixStorage.History.Remove(navigateTo)
      else
        uixStorage.History.Add(TDLUIXLocation.Create(currentLocation));
    end;
  end;
end; { TDLUserInterface.ProcessExecuteAction }

procedure TDLUserInterface.ShowAnalyzerPanel(const parentFrame: IDLUIXFrame;
  const parentAction: IDLUIXAction; const action: IDLUIXOpenAnalyzerAction);
begin
  ShowPanel(parentFrame, parentAction,
    procedure (const frame: IDLUIXFrame)
    begin
      action.Analyzer.BuildFrame(action, frame, FAnalysisState);
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
        ShowAnalyzerPanel(frame, action, openAnalyzer)
      else if Supports(action, IDLUIXNavigationAction, navigation) then begin
        FExecuteAction := action;
        frame.Close;
      end;
    end;

  frameBuilder(frame);

  if not frame.IsEmpty then begin
    if assigned(parentFrame) then
      parentFrame.MarkActive(false);

    frame.Show(parentAction);

    if assigned(parentFrame) then begin
      if assigned(FExecuteAction) then
        parentFrame.Close
      else
        parentFrame.MarkActive(true);
    end;
  end;

  FUIXEngine.DestroyFrame(frame);
end; { TDLUserInterface.ShowPanel }

end.
