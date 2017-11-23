unit DelphiLensUI.UIXAnalyzer.History;

interface

uses
  DelphiLensUI.UIXStorage,
  DelphiLensUI.UIXAnalyzer.Intf, DelphiLensUI.UIXAnalyzer.Attributes;

function CreateHistoryAnalyzer(const uixStorage: IDLUIXStorage): IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
  Spring.Collections,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  [TBackNavigation]
  TDLUIXHistoryAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private const
    CMaxHistoryEntries = 10;
  var
    FUIXStorage: IDLUIXStorage;
  strict protected
    function  BuildLocationList: IDLUIXNamedLocationList;
    function  MakeLocationName(const location: TDLUIXLocation): string;
  public
    constructor Create(const AUIXStorage: IDLUIXStorage);
    procedure BuildFrame(const frame: IDLUIXFrame; const state: TDLAnalysisState);
    function  CanHandle(const state: TDLAnalysisState): boolean;
  end; { TDLUIXHistoryAnalyzer }

function CreateHistoryAnalyzer(const uixStorage: IDLUIXStorage): IDLUIXAnalyzer;
begin
  Result := TDLUIXHistoryAnalyzer.Create(uixStorage);
end; { CreateHistoryAnalyzer }

constructor TDLUIXHistoryAnalyzer.Create(const AUIXStorage: IDLUIXStorage);
begin
  inherited Create;
  FUIXStorage := AUIXStorage;
end; { TDLUIXHistoryAnalyzer.Create }

procedure TDLUIXHistoryAnalyzer.BuildFrame(const frame: IDLUIXFrame;
  const state: TDLAnalysisState);
begin
  frame.CreateAction(CreateListNavigationAction('', BuildLocationList));
end; { TDLUIXHistoryAnalyzer.BuildFrame }

function TDLUIXHistoryAnalyzer.BuildLocationList: IDLUIXNamedLocationList;
var
  loc: TDLUIXLocation;
begin
  Result := TCollections.CreateList<IDLUIXNavigationAction>;

  for loc in FUIXStorage.History.Reversed.Take(CMaxHistoryEntries) do begin
    //TODO: location name should include method name
    Result.Add(CreateNavigationAction(MakeLocationName(loc), loc, true) as IDLUIXNavigationAction);
  end;
end; { TDLUIXHistoryAnalyzer.BuildLocationList }

function TDLUIXHistoryAnalyzer.CanHandle(const state: TDLAnalysisState): boolean;
begin
  Result := not FUIXStorage.History.IsEmpty;
end; { TDLUIXHistoryAnalyzer.CanHandle }

function TDLUIXHistoryAnalyzer.MakeLocationName(const location: TDLUIXLocation): string;
begin
  Result := Format('%s, line %d', [location.UnitName, location.Line]);
end; { TDLUIXHistoryAnalyzer.MakeLocationName }

end.
