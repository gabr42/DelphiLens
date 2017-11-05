unit DelphiLens.Cache.Intf;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiAST.Classes,
  ProjectIndexer;

type
  TCacheStatistics = record
    NumCached : integer;
    NumScanned: integer;
  end; { TCacheStatistics }

  TDLTreeDeserializer = reference to function (data: TStream; var tree: TSyntaxNode): boolean;
  TDLTreeSerializer = reference to procedure (tree: TSyntaxNode; data: TStream);

  IDLCache = interface ['{F71C65F0-74C5-4CB8-89E6-67C8258353EE}']
    function  GetDataVersioning: string;
    function  GetDeserializeSyntaxTree: TDLTreeDeserializer;
    function  GetSerializeSyntaxTree: TDLTreeSerializer;
    function  GetStatistics: TCacheStatistics;
    procedure SetDataVersioning(const value: string);
    procedure SetDeserializeSyntaxTree(const value: TDLTreeDeserializer);
    procedure SetSerializeSyntaxTree(const value: TDLTreeSerializer);
  //
    procedure BindTo(indexer: TProjectIndexer);
    procedure ClearStatistics;
    property DataVersioning: string read GetDataVersioning write SetDataVersioning;
    property Statistics: TCacheStatistics read GetStatistics;
    property DeserializeSyntaxTree: TDLTreeDeserializer read GetDeserializeSyntaxTree write
      SetDeserializeSyntaxTree;
    property SerializeSyntaxTree: TDLTreeSerializer read GetSerializeSyntaxTree write
      SetSerializeSyntaxTree;
  end; { IDLCache }

implementation

end.
