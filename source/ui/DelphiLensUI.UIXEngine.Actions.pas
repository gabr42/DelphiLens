unit DelphiLensUI.UIXEngine.Actions;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIXOpenAnalyzerAction = interface(IDLUIXAction)
  ['{00E07ADB-97C6-42AA-8865-E1EF8B7274A2}']
    function GetAnalyzer: IDLUIXAnalyzer;
  //
    property Analyzer: IDLUIXAnalyzer read GetAnalyzer;
  end; { IDLUIXOpenAnalyzerAction }

function CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;

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

{ exports }

function CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
begin
  Result := TDLUIXOpenAnalyzerAction.Create(name, analyzer);
end; { CreateOpenAnalyzerAction }

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

end.
