unit DelphiLens.Intf;

interface

uses
  System.Classes, System.Generics.Collections,
  DelphiAST.ProjectIndexer,
  DelphiLens.UnitInfo, DelphiLens.Cache.Intf, DelphiLens.Analyzers.Intf;

type
  TAnalyzedUnits = class(TList<IDLUnitInfo>)
  public
    function ContainsUnit(const unitName: string): boolean;
    function Find(const unitName: string; var unitInfo: IDLUnitInfo): boolean;
  end; { TAnalyzedUnits }

  TUnitInfo = TProjectIndexer.TUnitInfo;
  TParsedUnits = TProjectIndexer.TParsedUnits;
  TIncludeFiles = TProjectIndexer.TIncludeFiles;
  TProblems = TProjectIndexer.TProblems;

  TCacheStatistics = DelphiLens.Cache.Intf.TCacheStatistics;

  IDLScanResult = interface ['{69592BF1-A9BB-4495-87A8-1081FAB011B3}']
    function  GetAnalysis: TAnalyzedUnits;
    function  GetAnalyzers: IDLAnalyzers;
    function  GetCacheStatistics: TCacheStatistics;
    function  GetIncludeFiles: TIncludeFiles;
    function  GetNotFoundUnits: TStringList;
    function  GetParsedUnits: TParsedUnits;
    function  GetProblems: TProblems;
  //
    procedure ReleaseAnalyzers;
    property Analyzers: IDLAnalyzers read GetAnalyzers;
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

function TAnalyzedUnits.ContainsUnit(const unitName: string): boolean;
var
  uInfo: IDLUnitInfo;
begin
  Result := Find(unitName, uInfo);
end; { TAnalyzedUnits.ContainsUnit }

function TAnalyzedUnits.Find(const unitName: string; var unitInfo: IDLUnitInfo): boolean;
var
  uInfo: IDLUnitInfo;
begin
  Result := false;
  for uInfo in Self do
    if SameText(uInfo.Name, unitName) then begin
      unitInfo := uInfo;
      Exit(true);
    end;
end; { TAnalyzedUnits.Find }

end.
