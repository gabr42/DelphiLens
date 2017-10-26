unit DelphiLens.DelphiASTHelpers;

interface

uses
  System.Generics.Collections,
  Spring,
  DelphiAST.Consts, DelphiAST.Classes;

type
  TSyntaxNodeTypes = set of TSyntaxNodeType;

  TSyntaxTreeEnumerator = class(TManagedObject)
  strict private
    FCanGoDeeper : boolean;
    FChildrenOnly: boolean;
    FCurrentNode : TSyntaxNode;
    FNodeTypes   : TSyntaxNodeTypes;
    [Managed] FUnVisited: TStack<TSyntaxNode>;
  strict protected
    procedure PushChildrenOnStack(node: TSyntaxNode);
  public
    constructor Create(parentNode: TSyntaxNode; childTypes: TSyntaxNodeTypes; childrenOnly: boolean);
    function  GetEnumerator: TSyntaxTreeEnumerator;
    function  GetCurrent: TSyntaxNode; inline;
    function  MoveNext: boolean;
    property Current: TSyntaxNode read GetCurrent;
  end; { TSyntaxTreeEnumeratorIntf }

  TSyntaxNodeHelper = class helper for TSyntaxNode
  public
    function  FindAll(nodeType: TSyntaxNodeType; childrenOnly: boolean = true): TSyntaxTreeEnumerator; overload;
    function  FindAll(nodeTypes: TSyntaxNodeTypes; childrenOnly: boolean = true): TSyntaxTreeEnumerator; overload;
    function  FindFirst(nodeType: TSyntaxNodeType): TSyntaxNode; overload;
    function  FindFirst(nodeType: TSyntaxNodeType; var childNode: TSyntaxNode): boolean; overload; inline;
  end; { TSyntaxNodeHelper }

implementation

{ TSyntaxTreeEnumerator }

constructor TSyntaxTreeEnumerator.Create(parentNode: TSyntaxNode;
  childTypes: TSyntaxNodeTypes; childrenOnly: boolean);
begin
  inherited Create;
  FNodeTypes := childTypes;
  FChildrenOnly := childrenOnly;
  FCanGoDeeper := true;
  FUnvisited.Push(parentNode);
end; { TSyntaxTreeEnumerator.Create }

function TSyntaxTreeEnumerator.GetCurrent: TSyntaxNode;
begin
  Result := FCurrentNode;
end; { TSyntaxTreeEnumerator.GetCurrent }

function TSyntaxTreeEnumerator.GetEnumerator: TSyntaxTreeEnumerator;
begin
  Result := Self;
end; { TSyntaxTreeEnumerator.GetEnumerator }

function TSyntaxTreeEnumerator.MoveNext: boolean;
begin
  Result := false;
  while FUnvisited.Count > 0 do begin
    FCurrentNode := FUnvisited.Pop;
    if FCurrentNode.Typ in FNodeTypes then
      Exit(true);
    PushChildrenOnStack(FCurrentNode);
  end;
end; { TSyntaxTreeEnumerator.MoveNext }

procedure TSyntaxTreeEnumerator.PushChildrenOnStack(node: TSyntaxNode);
var
  children: TArray<TSyntaxNode>;
  iChild  : integer;
begin
  if not FCanGoDeeper then
    Exit;
  if FChildrenOnly then
    FCanGoDeeper := false;

  children := node.ChildNodes;
  for iChild := High(children) downto Low(children) do
    FUnvisited.Push(children[iChild]);
end; { TSyntaxTreeEnumerator.PushChildrenOnStack }

{ TSyntaxNodeHelper }

function TSyntaxNodeHelper.FindAll(nodeType: TSyntaxNodeType; childrenOnly: boolean): TSyntaxTreeEnumerator;
begin
  Result := TSyntaxTreeEnumerator.Create(Self, [nodeType], childrenOnly);
end; { TSyntaxNodeHelper.FindAll }

function TSyntaxNodeHelper.FindAll(nodeTypes: TSyntaxNodeTypes; childrenOnly: boolean): TSyntaxTreeEnumerator;
begin
  Result := TSyntaxTreeEnumerator.Create(Self, nodeTypes, childrenOnly);
end; { TSyntaxNodeHelper.FindAll }

function TSyntaxNodeHelper.FindFirst(nodeType: TSyntaxNodeType): TSyntaxNode;
begin
  if Typ = nodeType then
    Exit(Self)
  else
    Result := FindNode(nodeType);
end; { TSyntaxNodeHelper.FindFirst }

function TSyntaxNodeHelper.FindFirst(nodeType: TSyntaxNodeType; var childNode:
  TSyntaxNode): boolean;
begin
  childNode := FindFirst(nodetype);
  Result := assigned(childNode);
end; { TSyntaxNodeHelper.FindFirst }

end.
