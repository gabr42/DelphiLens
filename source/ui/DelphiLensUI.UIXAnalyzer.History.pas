unit DelphiLensUI.UIXAnalyzer.History;

interface

uses
  DelphiLensUI.UIXStorage,
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateHistoryAnalyzer(const uixStorage: IDLUIXStorage): IDLUIXAnalyzer;

implementation

uses
  DelphiLensUI.UIXEngine.Intf;

type
  TDLUIXHistoryAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private
    FUIXStorage: IDLUIXStorage;
  public
    constructor Create(const AUIXStorage: IDLUIXStorage);
    procedure BuildFrame(const frame: IDLUIXFrame);
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

procedure TDLUIXHistoryAnalyzer.BuildFrame(const frame: IDLUIXFrame);
begin
end; { TDLUIXHistoryAnalyzer.BuildFrame }

function TDLUIXHistoryAnalyzer.CanHandle(const state: TDLAnalysisState): boolean;
begin
  Result := true;
end; { TDLUIXHistoryAnalyzer.CanHandle }

end.
