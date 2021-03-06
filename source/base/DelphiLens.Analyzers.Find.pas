unit DelphiLens.Analyzers.Find;

interface

uses
  DelphiLens.Intf, DelphiLens.Analyzers.Intf;

function CreateDLFindAnalyzer(const scanResult: IDLScanResult): IDLFindAnalyzer;

implementation

uses
  System.SysUtils, System.StrUtils,
  Spring, Spring.Collections,
  DelphiAST.Consts, DelphiAST.Classes,
  DelphiLens.DelphiASTHelpers, DelphiLens.UnitInfo;

type
  TDLFindAnalyzer = class(TInterfacedObject, IDLFindAnalyzer)
  strict private
    FScanResult: IDLScanResult;
  strict protected
    function  FindIdent(syntaxTree: TSyntaxNode; const ident: string;
                allowSubstring: boolean): Vector<TDLCoordinate>;
  public
    constructor Create(const scanResult: IDLScanResult);
    function  All(const ident: string; options: TDLFindOptions = [];
      progress: TFindProgressProc = nil): ICoordinates;
  end; { TDLUnitAnalyzer }

{ exports }

function CreateDLFindAnalyzer(const scanResult: IDLScanResult): IDLFindAnalyzer;
begin
  Result := TDLFindAnalyzer.Create(scanResult);
end; { CreateDLFindAnalyzer }

{ TDLFindAnalyzer }

constructor TDLFindAnalyzer.Create(const scanResult: IDLScanResult);
begin
  inherited Create;
  FScanResult := scanResult;
end; { TDLFindAnalyzer.Create }

function TDLFindAnalyzer.All(const ident: string; options: TDLFindOptions;
  progress: TFindProgressProc): ICoordinates;
var
  abort          : boolean;
  allowSubstring : boolean;
  unitCoordinates: TDLUnitCoordinates;
  unitInfo       : TUnitInfo;
begin
  Result := TCollections.CreateList<TDLUnitCoordinates>;
  if Trim(ident) = '' then
    Exit;

  allowSubstring := (foAllowSubstring in options);
  abort := false;
  for unitInfo  in FScanResult.ParsedUnits do begin
    if assigned(progress) then
      progress(unitInfo.Name, abort);
    if abort then
      break; //for unitInfo

    if assigned(unitInfo.SyntaxTree) then begin
      unitCoordinates.Coordinates := FindIdent(unitInfo.SyntaxTree, ident, allowSubstring);
      if unitCoordinates.Coordinates.Count > 0 then begin
        unitCoordinates.UnitName := unitInfo.Name;
        Result.Add(unitCoordinates);
      end;
    end;
  end;
end; { TDLFindAnalyzer.All }

function TDLFindAnalyzer.FindIdent(syntaxTree: TSyntaxNode;
  const ident: string; allowSubstring: boolean): Vector<TDLCoordinate>;
var
  coord: IList<TDLCoordinate>;
  name : string;
  node : TSyntaxNode;
begin
  coord := TCollections.CreateList<TDLCoordinate>;
  for node in syntaxTree.All do
    if node.HasAttribute(anName) then begin
      name := node.GetAttribute(anName);
      if SameText(name, ident)
         or (allowSubstring and ContainsText(name, ident))
      then
        coord.Add(TDLCoordinate.Create(node.Line, node.Col));
    end;
  Result := coord.ToArray;
end; { TDLFindAnalyzer.FindIdent }

end.
