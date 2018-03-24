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
    function  GetNamedSyntaxNode: TSyntaxNode;
    function  GetProject: IDLScanResult;
    function  GetSource: TDLUIXLocation;
    function  GetStorage: IDLUIXStorage;
    function  GetSyntaxNode: TSyntaxNode;
    function  GetTarget: Nullable<TDLUIXLocation>;
    procedure SetTarget(const value: Nullable<TDLUIXLocation>);
  //
    property Storage: IDLUIXStorage read GetStorage;
    property Project: IDLScanResult read GetProject;
    property Source: TDLUIXLocation read GetSource;
    property Target: Nullable<TDLUIXLocation> read GetTarget write SetTarget;
    property SyntaxNode: TSyntaxNode read GetSyntaxNode;
    property NamedSyntaxNode: TSyntaxNode read GetNamedSyntaxNode;
  end; { IDLUIWorkerContext }

function CreateWorkerContext(const AStorage: IDLUIXStorage;
  const AProject: IDLScanResult; const ASource: TDLUIXLocation): IDLUIWorkerContext;

implementation

uses
  DelphiAST.ProjectIndexer,
  DelphiLens.DelphiASTHelpers;

type
  TDLUIWorkerContext = class(TInterfacedObject, IDLUIWorkerContext)
  strict private
    FNamedSyntaxNode: TSyntaxNode;
    FProject        : IDLScanResult;
    FSource         : TDLUIXLocation;
    FStorage        : IDLUIXStorage;
    FSyntaxNode     : TSyntaxNode;
    FTarget         : Nullable<TDLUIXLocation>;
  strict protected
    function  GetNamedSyntaxNode: TSyntaxNode;
    function  GetProject: IDLScanResult;
    function  GetSyntaxNode: TSyntaxNode;
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
    property SyntaxNode: TSyntaxNode read GetSyntaxNode;
    property NamedSyntaxNode: TSyntaxNode read GetNamedSyntaxNode;
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
var
  unitInfo: TProjectIndexer.TUnitInfo;
begin
  FStorage := AStorage;
  FProject := AProject;
  FSource := ASource;
  if AProject.ParsedUnits.Find(ASource.UnitName, unitInfo)
     and assigned(unitInfo.SyntaxTree)
  then
    FSyntaxNode := unitInfo.SyntaxTree.FindLocation(ASource.Line, ASource.Column);
  if assigned(FSyntaxNode) then
    FNamedSyntaxNode := FSyntaxNode.FindParentWithName;
end; { TDLUIWorkerContext.Create }

function TDLUIWorkerContext.GetNamedSyntaxNode: TSyntaxNode;
begin
  Result := FNamedSyntaxNode;
end; { TDLUIWorkerContext.GetNamedSyntaxNode }

function TDLUIWorkerContext.GetProject: IDLScanResult;
begin
  Result := FProject;
end; { TDLUIWorkerContext.GetProject }

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
