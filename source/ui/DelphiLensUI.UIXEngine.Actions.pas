unit DelphiLensUI.UIXEngine.Actions;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIXOpenAnalyzerAction = interface(IDLUIXAction) ['{00E07ADB-97C6-42AA-8865-E1EF8B7274A2}']
    function GetAnalyzer: IDLUIXAnalyzer;
  //
    property Analyzer: IDLUIXAnalyzer read GetAnalyzer;
  end; { IDLUIXOpenAnalyzerAction }

  IDLUIXNavigationAction = interface(IDLUIXAction) ['{4370BAEB-860F-42C0-8831-F361289A7AF3}']
    function  GetColumn: integer;
    function  GetFileName: string;
    function  GetLine: integer;
  //
    property FileName: string read GetFileName;
    property Line: integer read GetLine;
    property Column: integer read GetColumn;
  end; { IDLUIXNavigationAction }

function CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
function CreateNavigationAction(const name, fileName: string; line, column: integer): IDLUIXAction;

implementation

type
  TDLUIXAction = class(TInterfacedObject, IDLUIXAction)
  strict private
    FName: string;
  strict protected
    function GetName: string;
  public
    property Name: string read GetName;
    constructor Create(const name: string);
  end; { TDLUIXAction}

  TDLUIXOpenAnalyzerAction = class(TDLUIXAction, IDLUIXOpenAnalyzerAction)
  strict private
    FAnalyzer: IDLUIXAnalyzer;
  strict protected
    function GetAnalyzer: IDLUIXAnalyzer;
  public
    constructor Create(const name: string; const analyzer: IDLUIXAnalyzer);
    property Analyzer: IDLUIXAnalyzer read GetAnalyzer;
  end; { TDLUIXOpenAnalyzerAction }

  TDLUIXNavigationAction = class(TDLUIXAction, IDLUIXNavigationAction)
  strict private
    FColumn  : integer;
    FFileName: string;
    FLine    : integer;
  strict protected
    function  GetColumn: integer;
    function  GetFileName: string;
    function  GetLine: integer;
  public
    constructor Create(const name, fileName: string; line, column: integer);
    property FileName: string read GetFileName;
    property Line: integer read GetLine;
    property Column: integer read GetColumn;
  end; { TDLUIXNavigationAction }

{ exports }

function CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
begin
  Result := TDLUIXOpenAnalyzerAction.Create(name, analyzer);
end; { CreateOpenAnalyzerAction }

function CreateNavigationAction(const name, fileName: string; line, column: integer): IDLUIXAction;
begin
  Result := TDLUIXNavigationAction.Create(name, fileName, line, column);
end; { CreateNavigationAction }

{ TDLUIXAction }

constructor TDLUIXAction.Create(const name: string);
begin
  inherited Create;
  FName := name;
end; { TDLUIXAction.Create }

function TDLUIXAction.GetName: string;
begin
  Result := FName;
end; { TDLUIXAction.GetName }

{ TDLUIXOpenAnalyzerAction }

constructor TDLUIXOpenAnalyzerAction.Create(const name: string; const analyzer:
  IDLUIXAnalyzer);
begin
  inherited Create(name);
  FAnalyzer := analyzer;
end; { TDLUIXOpenAnalyzerAction.Create }

function TDLUIXOpenAnalyzerAction.GetAnalyzer: IDLUIXAnalyzer;
begin
  Result := FAnalyzer;
end; { TDLUIXOpenAnalyzerAction.GetAnalyzer }

{ TDLUIXNavigationAction }

constructor TDLUIXNavigationAction.Create(const name, fileName: string;
  line, column: integer);
begin
  inherited Create(name);
  FFileName := fileName;
  FLine := line;
  FColumn := column;
end; { TDLUIXNavigationAction.Create }

function TDLUIXNavigationAction.GetColumn: integer;
begin
  Result := FColumn;
end; { TDLUIXNavigationAction.GetColumn }

function TDLUIXNavigationAction.GetFileName: string;
begin
  Result := FFileName;
end; { TDLUIXNavigationAction.GetFileName }

function TDLUIXNavigationAction.GetLine: integer;
begin
  Result := FLine;
end; { TDLUIXNavigationAction.GetLine }

end.
