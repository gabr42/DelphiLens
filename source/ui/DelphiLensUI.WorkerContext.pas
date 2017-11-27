unit DelphiLensUI.WorkerContext;

interface

uses
  Spring,
  DelphiLens.Intf,
  DelphilensUI.UIXStorage,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIWorkerContext = interface ['{D27B5BBF-B172-49ED-86BE-FCBC2CB80AFA}']
    function  GetProject: IDLScanResult;
    function  GetSource: TDLUIXLocation;
    function  GetStorage: IDLUIXStorage;
    function  GetTarget: Nullable<TDLUIXLocation>;
    procedure SetTarget(const value: Nullable<TDLUIXLocation>);
  //
    property Storage: IDLUIXStorage read GetStorage;
    property Project: IDLScanResult read GetProject;
    property Source: TDLUIXLocation read GetSource;
    property Target: Nullable<TDLUIXLocation> read GetTarget write SetTarget;
  end; { IDLUIWorkerContext }

function CreateWorkerContext(const AStorage: IDLUIXStorage;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation): IDLUIWorkerContext;

implementation

type
  TDLUIWorkerContext = class(TInterfacedObject, IDLUIWorkerContext)
  strict private
    FStorage: IDLUIXStorage;
    FProject: IDLScanResult;
    FSource : TDLUIXLocation;
    FTarget : Nullable<TDLUIXLocation>;
  strict protected
    function  GetProject: IDLScanResult;
    function  GetSource: TDLUIXLocation;
    function  GetStorage: IDLUIXStorage;
    function  GetTarget: Nullable<TDLUIXLocation>;
    procedure SetTarget(const value: Nullable<TDLUIXLocation>);
  public
    constructor Create(const AStorage: IDLUIXStorage; const AProject: IDLScanResult;
      const ASource: TDLUIXLocation);
    property Storage: IDLUIXStorage read GetStorage;
    property Project: IDLScanResult read GetProject;
    property Source: TDLUIXLocation read GetSource;
    property Target: Nullable<TDLUIXLocation> read GetTarget write SetTarget;
  end; { TDLUIWorkerContext }

{ exports }

function CreateWorkerContext(const AStorage: IDLUIXStorage; const AProject:
  IDLScanResult; const ASource: TDLUIXLocation): IDLUIWorkerContext;
begin
  Result := TDLUIWorkerContext.Create(AStorage, AProject, ASource);
end; { CreateWorkerContext }

{ TDLUIXContext }

constructor TDLUIWorkerContext.Create(const AStorage: IDLUIXStorage; const AProject:
  IDLScanResult; const ASource: TDLUIXLocation);
begin
  FStorage := AStorage;
  FProject := AProject;
  FSource := ASource;
end; { TDLUIWorkerContext.Create }

function TDLUIWorkerContext.GetProject: IDLScanResult;
begin
  Result := FProject;
end;

function TDLUIWorkerContext.GetSource: TDLUIXLocation;
begin
  Result := FSource;
end;

function TDLUIWorkerContext.GetStorage: IDLUIXStorage;
begin
  Result := FStorage;
end;

function TDLUIWorkerContext.GetTarget: Nullable<TDLUIXLocation>;
begin
  Result := FTarget;
end;

procedure TDLUIWorkerContext.SetTarget(const value: Nullable<TDLUIXLocation>);
begin
  FTarget := value;
end; { TDLUIWorkerContext.SetTarget }

end.
