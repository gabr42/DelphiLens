unit DelphiLensUI.WorkerContext;

interface

uses
  Spring,
  DelphiAST.Classes,
  DelphiLens.Intf,
  DelphilensUI.UIXStorage,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIWorkerContext = interface ['{D27B5BBF-B172-49ED-86BE-FCBC2CB80AFA}']
    function  GetMonitorNum: integer;
    function  GetNamedSyntaxNode: TSyntaxNode;
    function  GetProject: IDLScanResult;
    function  GetProjectName: string;
    function  GetSource: TDLUIXLocation;
    function  GetStorage: IDLUIXStorage;
    function  GetSyntaxNode: TSyntaxNode;
    function  GetTarget: Nullable<TDLUIXLocation>;
    procedure SetTarget(const value: Nullable<TDLUIXLocation>);
  //
    property MonitorNum: integer read GetMonitorNum;
    property Storage: IDLUIXStorage read GetStorage;
    property Project: IDLScanResult read GetProject;
    property ProjectName: string read GetProjectName;
    property Source: TDLUIXLocation read GetSource;
    property Target: Nullable<TDLUIXLocation> read GetTarget write SetTarget;
    property SyntaxNode: TSyntaxNode read GetSyntaxNode;
    property NamedSyntaxNode: TSyntaxNode read GetNamedSyntaxNode;
  end; { IDLUIWorkerContext }

function CreateWorkerContext(const AStorage: IDLUIXStorage; const AProjectName: string;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation;
  AMonitorNum: integer): IDLUIWorkerContext;

implementation

uses
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers;

type
  TDLUIWorkerContext = class(TInterfacedObject, IDLUIWorkerContext)
  strict private
    FMonitorNum     : integer;
    FNamedSyntaxNode: TSyntaxNode;
    FProject        : IDLScanResult;
    FProjectName    : string;
    FSource         : TDLUIXLocation;
    FStorage        : IDLUIXStorage;
    FSyntaxNode     : TSyntaxNode;
    FTarget         : Nullable<TDLUIXLocation>;
  strict protected
    function  GetProjectName: string;
    function  GetMonitorNum: integer;
    function  GetNamedSyntaxNode: TSyntaxNode;
    function  GetProject: IDLScanResult;
    function  GetSyntaxNode: TSyntaxNode;
    function  GetSource: TDLUIXLocation;
    function  GetStorage: IDLUIXStorage;
    function  GetTarget: Nullable<TDLUIXLocation>;
    procedure SetTarget(const value: Nullable<TDLUIXLocation>);
  public
    constructor Create(const AStorage: IDLUIXStorage; const AProjectName: string;
      const AProject: IDLScanResult; const ASource: TDLUIXLocation; AMonitorNum: integer);
    property MonitorNum: integer read GetMonitorNum;
    property Storage: IDLUIXStorage read GetStorage;
    property Project: IDLScanResult read GetProject;
    property ProjectName: string read GetProjectName;
    property Source: TDLUIXLocation read GetSource;
    property Target: Nullable<TDLUIXLocation> read GetTarget write SetTarget;
    property SyntaxNode: TSyntaxNode read GetSyntaxNode;
    property NamedSyntaxNode: TSyntaxNode read GetNamedSyntaxNode;
  end; { TDLUIWorkerContext }

{ exports }

function CreateWorkerContext(const AStorage: IDLUIXStorage; const AProjectName: string;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation;
  AMonitorNum: integer): IDLUIWorkerContext;
begin
  Result := TDLUIWorkerContext.Create(AStorage, AProjectName, AProject, ASource, AMonitorNum);
end; { CreateWorkerContext }

{ TDLUIXContext }

constructor TDLUIWorkerContext.Create(const AStorage: IDLUIXStorage; const AProjectName: string;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation; AMonitorNum: integer);
var
  unitInfo: TProjectIndexer.TUnitInfo;
begin
  FStorage := AStorage;
  FProjectName := AProjectName;
  FProject := AProject;
  FSource := ASource;
  FMonitorNum := AMonitorNum;

  if AProject.ParsedUnits.Find(ASource.UnitName, unitInfo)
     and assigned(unitInfo.SyntaxTree)
  then
    FSyntaxNode := unitInfo.SyntaxTree.FindLocation(ASource.Line, ASource.Column);
  if assigned(FSyntaxNode) then
    FNamedSyntaxNode := FSyntaxNode.FindParentWithName;
end; { TDLUIWorkerContext.Create }

function TDLUIWorkerContext.GetMonitorNum: integer;
begin
  Result := FMonitorNum;
end; { TDLUIWorkerContext.GetMonitorNum }

function TDLUIWorkerContext.GetNamedSyntaxNode: TSyntaxNode;
begin
  Result := FNamedSyntaxNode;
end; { TDLUIWorkerContext.GetNamedSyntaxNode }

function TDLUIWorkerContext.GetProject: IDLScanResult;
begin
  Result := FProject;
end; { TDLUIWorkerContext.GetProject }

function TDLUIWorkerContext.GetProjectName: string;
begin
  Result := FProjectName;
end; { TDLUIWorkerContext.GetProjectName }

function TDLUIWorkerContext.GetSource: TDLUIXLocation;
begin
  Result := FSource;
end; { TDLUIWorkerContext.GetSource }

function TDLUIWorkerContext.GetStorage: IDLUIXStorage;
begin
  Result := FStorage;
end; { TDLUIWorkerContext.GetStorage }

function TDLUIWorkerContext.GetSyntaxNode: TSyntaxNode;
begin
  Result := FSyntaxNode;
end; { TDLUIWorkerContext.GetSyntaxNode }

function TDLUIWorkerContext.GetTarget: Nullable<TDLUIXLocation>;
begin
  Result := FTarget;
end; { TDLUIWorkerContext.GetTarget }

procedure TDLUIWorkerContext.SetTarget(const value: Nullable<TDLUIXLocation>);
begin
  FTarget := value;
end; { TDLUIWorkerContext.SetTarget }

end.
