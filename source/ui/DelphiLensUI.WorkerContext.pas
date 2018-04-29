unit DelphiLensUI.WorkerContext;

interface

uses
  Spring,
  DelphiAST.Classes,
  DelphiLens.Intf, DelphiLens.FileCache.Intf,
  DelphilensUI.UIXStorage,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIWorkerContext = interface ['{D27B5BBF-B172-49ED-86BE-FCBC2CB80AFA}']
    function  GetFileCache: IDLFileCache;
    function  GetMonitorNum: integer;
    function  GetNamedSyntaxNode: TSyntaxNode;
    function  GetProject: IDLScanResult;
    function  GetProjectName: string;
    function  GetSource: TDLUIXLocation;
    function  GetStorage: IDLUIXStorage;
    function  GetSyntaxNode: TSyntaxNode;
    function  GetTabNames: TArray<string>;
    function  GetTarget: Nullable<TDLUIXLocation>;
    procedure SetTarget(const value: Nullable<TDLUIXLocation>);
  //
    property FileCache: IDLFileCache read GetFileCache;
    property MonitorNum: integer read GetMonitorNum;
    property NamedSyntaxNode: TSyntaxNode read GetNamedSyntaxNode;
    property Project: IDLScanResult read GetProject;
    property ProjectName: string read GetProjectName;
    property Source: TDLUIXLocation read GetSource;
    property Storage: IDLUIXStorage read GetStorage;
    property SyntaxNode: TSyntaxNode read GetSyntaxNode;
    property TabNames: TArray<string> read GetTabNames;
    property Target: Nullable<TDLUIXLocation> read GetTarget write SetTarget;
  end; { IDLUIWorkerContext }

function CreateWorkerContext(const AStorage: IDLUIXStorage; const AProjectName: string;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation;
  const ATabNames: TArray<string>; AMonitorNum: integer): IDLUIWorkerContext;

implementation

uses
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers, DelphiLens.FileCache;

type
  TDLUIWorkerContext = class(TInterfacedObject, IDLUIWorkerContext)
  strict private
    FFileCache      : IDLFileCache;
    FMonitorNum     : integer;
    FNamedSyntaxNode: TSyntaxNode;
    FProject        : IDLScanResult;
    FProjectName    : string;
    FSource         : TDLUIXLocation;
    FStorage        : IDLUIXStorage;
    FSyntaxNode     : TSyntaxNode;
    FTabNames       : TArray<string>;
    FTarget         : Nullable<TDLUIXLocation>;
  strict protected
    function  GetFileCache: IDLFileCache;
    function  GetMonitorNum: integer;
    function  GetNamedSyntaxNode: TSyntaxNode;
    function  GetProject: IDLScanResult;
    function  GetProjectName: string;
    function  GetSource: TDLUIXLocation;
    function  GetStorage: IDLUIXStorage;
    function  GetSyntaxNode: TSyntaxNode;
    function  GetTabNames: TArray<string>;
    function  GetTarget: Nullable<TDLUIXLocation>;
    procedure SetTarget(const value: Nullable<TDLUIXLocation>);
  public
    constructor Create(const AStorage: IDLUIXStorage; const AProjectName: string;
      const AProject: IDLScanResult; const ASource: TDLUIXLocation;
      const ATabNames: TArray<string>; AMonitorNum: integer);
    property FileCache: IDLFileCache read GetFileCache;
    property MonitorNum: integer read GetMonitorNum;
    property NamedSyntaxNode: TSyntaxNode read GetNamedSyntaxNode;
    property Project: IDLScanResult read GetProject;
    property ProjectName: string read GetProjectName;
    property Storage: IDLUIXStorage read GetStorage;
    property Source: TDLUIXLocation read GetSource;
    property SyntaxNode: TSyntaxNode read GetSyntaxNode;
    property TabNames: TArray<string> read GetTabNames;
    property Target: Nullable<TDLUIXLocation> read GetTarget write SetTarget;
  end; { TDLUIWorkerContext }

{ exports }

function CreateWorkerContext(const AStorage: IDLUIXStorage; const AProjectName: string;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation;
  const ATabNames: TArray<string>; AMonitorNum: integer): IDLUIWorkerContext;
begin
  Result := TDLUIWorkerContext.Create(AStorage, AProjectName, AProject, ASource,
              ATabNames, AMonitorNum);
end; { CreateWorkerContext }

{ TDLUIXContext }

constructor TDLUIWorkerContext.Create(const AStorage: IDLUIXStorage; const AProjectName: string;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation;
  const ATabNames: TArray<string>; AMonitorNum: integer);
var
  unitInfo: TProjectIndexer.TUnitInfo;
begin
  FStorage := AStorage;
  FProjectName := AProjectName;
  FProject := AProject;
  FSource := ASource;
  FTabNames := ATabNames;
  FMonitorNum := AMonitorNum;

  if AProject.ParsedUnits.Find(ASource.UnitName, unitInfo)
     and assigned(unitInfo.SyntaxTree)
  then
    FSyntaxNode := unitInfo.SyntaxTree.FindLocation(ASource.Line, ASource.Column);
  if assigned(FSyntaxNode) then
    FNamedSyntaxNode := FSyntaxNode.FindParentWithName;
end; { TDLUIWorkerContext.Create }

function TDLUIWorkerContext.GetFileCache: IDLFileCache;
begin
  if not assigned(FFileCache) then
    FFileCache := CreateFileCache;
  Result := FFileCache;
end; { TDLUIWorkerContext.GetFileCache }

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

function TDLUIWorkerContext.GetTabNames: TArray<string>;
begin
  Result := FTabNames;
end; { TDLUIWorkerContext.GetTabNames }

function TDLUIWorkerContext.GetTarget: Nullable<TDLUIXLocation>;
begin
  Result := FTarget;
end; { TDLUIWorkerContext.GetTarget }

procedure TDLUIWorkerContext.SetTarget(const value: Nullable<TDLUIXLocation>);
begin
  FTarget := value;
end; { TDLUIWorkerContext.SetTarget }

end.
