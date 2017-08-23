unit DelphiLens.Cache.Intf;

interface

uses
  System.SysUtils,
  DelphiAST.Classes,
  ProjectIndexer;

type
  IDLCache = interface ['{F71C65F0-74C5-4CB8-89E6-67C8258353EE}']
    function  GetSyntaxFilter: TProc<TSyntaxNode>;
    procedure SetSyntaxFilter(const value: TProc<TSyntaxNode>);
  //
    procedure BindTo(indexer: TProjectIndexer);
    property SyntaxFilter: TProc<TSyntaxNode> read GetSyntaxFilter write SetSyntaxFilter;
  end; { IDLCache }

implementation

end.
