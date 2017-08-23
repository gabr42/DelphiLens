unit DelphiLens;

interface

uses
  DelphiLens.Intf;

function CreateDelphiLens(const projectFile: string): IDelphiLens;

implementation

uses
  System.SysUtils,
  DelphiAST.Consts, DelphiAST.Classes,
  ProjectIndexer,
  DelphiLens.Cache.Intf, DelphiLens.Cache;

type
  TDelphiLens = class(TInterfacedObject, IDelphiLens)
  strict private const
    CCacheExt = '.dlens';
  var
    FCache             : IDLCache;
    FConditionalDefines: string;
    FIndexer           : TProjectIndexer;
    FInterestingTypes  : set of TSyntaxNodeType;
    FProject           : string;
    FSearchPath        : string;
  strict protected
    procedure FilterSyntax(node: TSyntaxNode);
    function  GetConditionalDefines: string;
    function  GetProject: string;
    function  GetSearchPath: string;
    procedure SetConditionalDefines(const value: string);
    procedure SetSearchPath(const value: string);
  public
    constructor Create(const AProject: string);
    destructor  Destroy; override;
    procedure Rescan;
    property ConditionalDefines: string read GetConditionalDefines write SetConditionalDefines;
    property Project: string read GetProject;
    property SearchPath: string read GetSearchPath write SetSearchPath;
  end; { TDelphiLens }

{ exports }

function CreateDelphiLens(const projectFile: string): IDelphiLens;
begin
  Result := TDelphiLens.Create(projectFile);
end; { CreateDelphiLens }

{ TDelphiLens }

constructor TDelphiLens.Create(const AProject: string);
begin
  inherited Create;
  FInterestingTypes := [ntAnonymousMethod, ntArguments, ntAs, ntAttribute, ntAttributes,
      ntCall, ntConstant, ntConstants, ntEnum, ntExternal, ntField, ntFields, ntGeneric,
      ntHelper, ntIdentifier, ntImplementation, ntImplements, ntInherited, ntInitialization,
      ntInterface, ntLabel, ntMethod, ntName, ntNamedArgument, ntPackage, ntParameter,
      ntParameters, ntPath, ntPositionalArgument, ntProtected, ntPrivate, ntProperty,
      ntPublic, ntPublished, ntResolutionClause, ntResourceString, ntStrictPrivate,
      ntStrictProtected, ntType, ntTypeArgs, ntTypeDecl, ntTypeParam, ntTypeParams,
      ntTypeSection, ntVariable, ntVariables, ntUnit, ntUses];
  FProject := AProject;
  FIndexer := TProjectIndexer.Create;
  FCache := CreateDLCache(ChangeFileExt(FProject, CCacheExt));
  FCache.BindTo(FIndexer);
  FCache.SyntaxFilter := FilterSyntax;
end; { TDelphiLens.Create }

destructor TDelphiLens.Destroy;
begin
  FreeAndNil(FIndexer);
  inherited;
end; { TDelphiLens.Destroy }

procedure TDelphiLens.FilterSyntax(node: TSyntaxNode);
var
  iChild: integer;
begin
  for iChild := High(node.ChildNodes) downto Low(node.ChildNodes) do
    if node.ChildNodes[iChild].Typ in FInterestingTypes then
      FilterSyntax(node.ChildNodes[iChild])
    else
      node.DeleteChild(node.ChildNodes[iChild]);
end; { TDelphiLens.FilterSyntax }

function TDelphiLens.GetConditionalDefines: string;
begin
  Result := FConditionalDefines;
end; { TDelphiLens.GetConditionalDefines }

function TDelphiLens.GetProject: string;
begin
  Result := FProject;
end; { TDelphiLens.GetProject }

function TDelphiLens.GetSearchPath: string;
begin
  Result := FSearchPath;
end; { TDelphiLens.GetSearchPath }

procedure TDelphiLens.Rescan;
begin
  FIndexer.SearchPath := SearchPath;
  FIndexer.Defines := ConditionalDefines;
  FIndexer.Index(Project);
end; { TDelphiLens.Rescan }

procedure TDelphiLens.SetConditionalDefines(const value: string);
begin
  FConditionalDefines := value;
end; { TDelphiLens.SetConditionalDefines }

procedure TDelphiLens.SetSearchPath(const value: string);
begin
  FSearchPath := value;
end; { TDelphiLens.SetSearchPath }

end.
