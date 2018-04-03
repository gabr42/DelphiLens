unit DelphiLensUI.UIXAnalyzer.FindSymbol;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateFindSymbol: IDLUIXAnalyzer;

implementation

{ exports }

function CreateFindSymbol: IDLUIXAnalyzer;
begin
  Result := nil;
end; { CreateFindSymbol }

end.
