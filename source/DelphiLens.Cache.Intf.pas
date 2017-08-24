unit DelphiLens.Cache.Intf;

interface

uses
  System.SysUtils,
  DelphiAST.Classes,
  ProjectIndexer;

type
  IDLCache = interface ['{F71C65F0-74C5-4CB8-89E6-67C8258353EE}']
    function  GetDataVersioning: string;
    function  GetSyntaxFilter: TProc<TSyntaxNode>;
    procedure SetDataVersioning(const value: string);
    procedure SetSyntaxFilter(const value: TProc<TSyntaxNode>);
  //
    procedure BindTo(indexer: TProjectIndexer);
    property DataVersioning: string read GetDataVersioning write SetDataVersioning;
    property SyntaxFilter: TProc<TSyntaxNode> read GetSyntaxFilter write SetSyntaxFilter;
  end; { IDLCache }

implementation

end.
