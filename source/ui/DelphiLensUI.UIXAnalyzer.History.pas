unit DelphiLensUI.UIXAnalyzer.History;

interface

uses
  DelphiLensUI.UIXStorage,
  DelphiLensUI.UIXAnalyzer.Intf, DelphiLensUI.UIXAnalyzer.Attributes;

function CreateHistoryAnalyzer: IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
  Spring.Collections,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  [TBackNavigation]
  TDLUIXHistoryAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private const
    CMaxHistoryEntries = 10;
  strict protected
    function  BuildLocationList(const context: IDLUIWorkerContext): IDLUIXNamedLocationList;
    function  MakeLocationName(const location: TDLUIXLocation): string;
  public
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXHistoryAnalyzer }

{ exports }

function CreateHistoryAnalyzer: IDLUIXAnalyzer;
begin
  Result := TDLUIXHistoryAnalyzer.Create;
end; { CreateHistoryAnalyzer }

{ TDLUIXHistoryAnalyzer }

procedure TDLUIXHistoryAnalyzer.BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
  const context: IDLUIWorkerContext);
begin
  frame.CreateAction(CreateListNavigationAction('', BuildLocationList(context)));
end; { TDLUIXHistoryAnalyzer.BuildFrame }

function TDLUIXHistoryAnalyzer.BuildLocationList(const context: IDLUIWorkerContext): IDLUIXNamedLocationList;
var
  loc: TDLUIXLocation;
begin
  Result := TCollections.CreateList<IDLUIXNavigationAction>;

  for loc in context.Storage.History.Reversed.Take(CMaxHistoryEntries) do begin
    //TODO: location name should include method name
    Result.Add(CreateNavigationAction(MakeLocationName(loc), loc, true) as IDLUIXNavigationAction);
  end;
end; { TDLUIXHistoryAnalyzer.BuildLocationList }

function TDLUIXHistoryAnalyzer.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := not context.Storage.History.IsEmpty;
end; { TDLUIXHistoryAnalyzer.CanHandle }

function TDLUIXHistoryAnalyzer.MakeLocationName(const location: TDLUIXLocation): string;
begin
  Result := Format('%s, line %d', [location.UnitName, location.Line]);
end; { TDLUIXHistoryAnalyzer.MakeLocationName }

end.
