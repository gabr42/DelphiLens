unit DelphiLens.Intf;

interface

uses
  System.Classes, System.Generics.Collections,
  DelphiAST.ProjectIndexer,
  DelphiLens.UnitInfo,
  DelphiLens.Cache.Intf;

type
  TAnalyzedUnits = class(TList<TDLUnitInfo>)
  public
    function Find(const unitName: string; var unitInfo: TDLUnitInfo): boolean;
  end; { TAnalyzedUnits }

  TParsedUnits = TProjectIndexer.TParsedUnits;
  TIncludeFiles = TProjectIndexer.TIncludeFiles;
  TProblems = TProjectIndexer.TProblems;

  TCacheStatistics = DelphiLens.Cache.Intf.TCacheStatistics;

  IDLScanResult = interface ['{69592BF1-A9BB-4495-87A8-1081FAB011B3}']
    function  GetAnalysis: TAnalyzedUnits;
    function  GetCacheStatistics: TCacheStatistics;
    function  GetIncludeFiles: TIncludeFiles;
    function  GetNotFoundUnits: TStringList;
    function  GetParsedUnits: TParsedUnits;
    function  GetProblems: TProblems;
  //
    property Analysis: TAnalyzedUnits read GetAnalysis;
    property CacheStatistics: TCacheStatistics read GetCacheStatistics;
    property ParsedUnits: TParsedUnits read GetParsedUnits;
    property IncludeFiles: TIncludeFiles read GetIncludeFiles;
    property Problems: TProblems read GetProblems;
    property NotFoundUnits: TStringList read GetNotFoundUnits;
  end; { IDLScanResult }

  IDelphiLens = interface ['{66B1B796-CD6B-46AE-B402-9CD0329BC5E3}']
    function  GetConditionalDefines: string;
    function  GetProject: string;
    function  GetSearchPath: string;
    procedure SetConditionalDefines(const value: string);
    procedure SetSearchPath(const value: string);
  //
    function Rescan: IDLScanResult;
    property ConditionalDefines: string read GetConditionalDefines write SetConditionalDefines;
    property Project: string read GetProject;
    property SearchPath: string read GetSearchPath write SetSearchPath;
  end; { IDelphiLens }

implementation

uses
  System.SysUtils;

function TAnalyzedUnits.Find(const unitName: string; var unitInfo: TDLUnitInfo): boolean;
var
  iUnit: integer;
begin
  Result := false;
  for iUnit := 0 to Count - 1 do
    if SameText(Items[iUnit].Name, unitName) then begin
      unitInfo := Items[iUnit];
      Exit(true);
    end;
end; { TAnalyzedUnits.Find }

end.
