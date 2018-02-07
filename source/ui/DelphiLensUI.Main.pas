unit DelphiLensUI.Main;

interface

uses
  Spring,
  DelphiLens.Intf,
  DelphiLensUI.UIXStorage,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.WorkerContext;

procedure DLUIShowUI(const workerContext: IDLUIWorkerContext);

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
    FExecuteAction: IDLUIXAction;
    FUIContext    : IDLUIWorkerContext;
    FUIXAnalyzers : TDLAnalyzers;
    FUIXEngine    : IDLUIXEngine;
  strict protected
    function  MapUnitNamesToFileNames(const unitNames: string): string;
    procedure ShowAnalyzerPanel(const parentFrame: IDLUIXFrame;
      const parentAction: IDLUIXAction; const action: IDLUIXOpenAnalyzerAction);
    procedure ShowPanel(const parentFrame: IDLUIXFrame; const parentAction: IDLUIXAction;
      const frameBuilder: TUIXFrameBuilder);
  public
    constructor Create(const uixEngine: IDLUIXEngine; const analyzers: TDLAnalyzers;
      const workerContext: IDLUIWorkerContext);
    procedure ProcessExecuteAction;
    procedure ShowMain;
    property ExecuteAction: IDLUIXAction read FExecuteAction;
  end; { TDLUserInterface }

{ exports }

procedure DLUIShowUI(const workerContext: IDLUIWorkerContext);
var
  analyzers: TDLAnalyzers;
  ui       : TDLUserInterface;
begin
  analyzers := TCollections.CreateList<TDLAnalyzerInfo>;
  analyzers.Add(TDLAnalyzerInfo.Create('&Navigation', CreateNavigationAnalyzer));
  analyzers.Add(TDLAnalyzerInfo.Create('&Units', CreateUnitBrowser));
  analyzers.Add(TDLAnalyzerInfo.Create('&History', CreateHistoryAnalyzer));

  ui := TDLUserInterface.Create(CreateUIXEngine, analyzers, workerContext);
  try
    ui.ShowMain;
    ui.ProcessExecuteAction;
  finally FreeAndNil(ui); end;
end; { DLUIShowUI }

{ TDLUserInterface }

constructor TDLUserInterface.Create(const uixEngine: IDLUIXEngine; const analyzers:
  TDLAnalyzers; const workerContext: IDLUIWorkerContext);
begin
  inherited Create;
  FUIXEngine := uixEngine;
  FUIXAnalyzers := analyzers;
  FUIContext := workerContext;
end; { TDLUserInterface.Create }

function TDLUserInterface.MapUnitNamesToFileNames(const unitNames: string): string;
var
  fileNames: TArray<string>;
  i        : integer;
  units    : TArray<string>;
begin
  units := unitNames.Split([#13]);
  SetLength(fileNames, Length(units));
  for i := Low(units) to High(units) do
    fileNames[i] := FUIContext.Project.ParsedUnits.FindOrDefault(units[i]).Path;
  Result := string.Join(#13, fileNames);
end; { TDLUserInterface.MapUnitNamesToFileNames }

procedure TDLUserInterface.ProcessExecuteAction;
var
  fileName  : string;
  navigation: IDLUIXNavigationAction;
begin
  if assigned(ExecuteAction) then begin
    if Supports(ExecuteAction, IDLUIXNavigationAction, navigation) then begin
      fileName := navigation.Location.FileName;
      if fileName = '' then
        fileName := MapUnitNamesToFileNames(navigation.Location.UnitName);
      FUIContext.Target := TDLUIXLocation.Create(fileName,
        navigation.Location.UnitName,
        navigation.Location.Line, navigation.Location.Column);
      if navigation.IsBackNavigation then
        FUIContext.Storage.History.Remove(FUIContext.Target)
      else if FUIContext.Source <> FUIContext.Target then
        FUIContext.Storage.History.Add(TDLUIXLocation.Create(FUIContext.Source));
    end;
  end;
end; { TDLUserInterface.ProcessExecuteAction }

procedure TDLUserInterface.ShowAnalyzerPanel(const parentFrame: IDLUIXFrame;
  const parentAction: IDLUIXAction; const action: IDLUIXOpenAnalyzerAction);
begin
  ShowPanel(parentFrame, parentAction,
    procedure (const frame: IDLUIXFrame)
    begin
      action.Analyzer.BuildFrame(action, frame, FUIContext);
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
        if analyzer.Value.CanHandle(FUIContext) then
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
