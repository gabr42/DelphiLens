unit DelphiLensUI.UIXEngine.Actions;

interface

uses
  System.SysUtils,
  Spring.Collections,
  DelphiLens.UnitInfo,
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIXOpenAnalyzerAction = interface(IDLUIXAction) ['{00E07ADB-97C6-42AA-8865-E1EF8B7274A2}']
    function  GetAnalyzer: IDLUIXAnalyzer;
  //
    property Analyzer: IDLUIXAnalyzer read GetAnalyzer;
  end; { IDLUIXOpenAnalyzerAction }

  TDLUIXUnitBrowserType = (ubtNormal, ubtUses, ubtUsedBy);
  IDLUIXOpenUnitBrowserAction = interface(IDLUIXOpenAnalyzerAction) ['{0741FE6A-E194-4A67-A3BE-4E57AE8B141A}']
    function  GetFilterType: TDLUIXUnitBrowserType;
    function  GetInitialUnit: string;
    procedure SetInitialUnit(const value: string);
  //
    property FilterType: TDLUIXUnitBrowserType read GetFilterType;
    property InitialUnit: string read GetInitialUnit write SetInitialUnit;
  end; { IDLUIXOpenUnitBrowserAction }

  IDLUIXNavigationAction = interface(IDLUIXAction) ['{4370BAEB-860F-42C0-8831-F361289A7AF3}']
    function  GetIsBackNavigation: boolean;
    function  GetLocation: TDLUIXLocation;
    procedure SetLocation(const value: TDLUIXLocation);
  //
    property Location: TDLUIXLocation read GetLocation write SetLocation;
    property IsBackNavigation: boolean read GetIsBackNavigation;
  end; { IDLUIXNavigationAction }

  IDLUIXNamedLocationList = IList<IDLUIXNavigationAction>;

  IDLUIXListNavigationAction = interface(IDLUIXAction) ['{144666AA-1E43-47DB-B725-503C62857843}']
    function  GetLocations: IDLUIXNamedLocationList;
  //                  -
    property Locations: IDLUIXNamedLocationList read GetLocations;
  end; { IDLUIXListNavigationAction }

  TDLUIXLocationQueryByName = reference to function(const name: string;
    var unitName: string; var location: TDLCoordinate): boolean;

  IDLUIXFilteredListAction = interface(IDLUIXAction) ['{A74C5DBB-F0FA-4560-BAF1-41AB5E4E109F}']
    function  GetList: IList<string>;
    function  GetLocationQuery: TDLUIXLocationQueryByName;
    function  GetSelected: string;
    procedure SetLocationQuery(const value: TDLUIXLocationQueryByName);
  //
    function  FilterLocation(const location: TDLUIXLocation): TDLUIXLocation;
    property List: IList<string> read GetList;
    property Selected: string read GetSelected;
    property LocationQuery: TDLUIXLocationQueryByName read GetLocationQuery write SetLocationQuery;
  end; { IDLUIXFilteredListAction }

  TDLUIXSearchProc = reference to function (const searchTerm: string): ICoordinates;

  TDLUIXProgressCallback = reference to procedure (const unitName: string; var abort: boolean);

  TDLUIXGetLineProc = reference to function (const unitName: string; lineNum: integer): string;

  IDLUIXSearchAction = interface(IDLUIXAction) ['{922FC5DA-3781-44AE-94A1-4898D471246C}']
    function  GetGetLine: TDLUIXGetLineProc;
    function  GetInitialSearch: string;
    function  GetProgressCallback: TDLUIXProgressCallback;
    function  GetSearchProc: TDLUIXSearchProc;
    procedure SetProgressCallback(const value: TDLUIXProgressCallback);
  //
    property InitialSearch: string read GetInitialSearch;
    property GetLine: TDLUIXGetLineProc read GetGetLine;
    property ProgressCallback: TDLUIXProgressCallback read GetProgressCallback write SetProgressCallback;
    property SearchProc: TDLUIXSearchProc read GetSearchProc;
  end; { IDLUIXSearchAction }

function  CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
function  CreateOpenUnitBrowserAction(const name: string; const analyzer: IDLUIXAnalyzer;
  const initialUnit: string; const filterType: TDLUIXUnitBrowserType): IDLUIXAction;
function  CreateNavigationAction(const name: string; const location: TDLUIXLocation;
  isBackNavigation: boolean): IDLUIXAction;
function  CreateListNavigationAction(const name: string; const locations: IDLUIXNamedLocationList): IDLUIXAction;
function  CreateFilteredListAction(const name: string; const list: IList<string>;
  const selected: string): IDLUIXAction;
function  CreateSearchAction(const name, searchToken: string;
  const searchProc: TDLUIXSearchProc;
  const progressCallback: TDLUIXProgressCallback;
  const getLineProc: TDLUIXGetLineProc): IDLUIXSearchAction;

implementation

type
  TDLUIXAction = class(TInterfacedObject, IDLUIXAction)
  strict private
    FDefaultAction : IDLUIXAction;
    FManagedActions: IDLUIXManagedActions;
    FName          : string;
  strict protected
    function  GetDefaultAction: IDLUIXAction;
    function  GetName: string;
    function  GetManagedActions: IDLUIXManagedActions;
    procedure SetDefaultAction(const value: IDLUIXAction);
  public
    constructor Create(const name: string);
    property DefaultAction: IDLUIXAction read GetDefaultAction write SetDefaultAction;
    property ManagedActions: IDLUIXManagedActions read GetManagedActions;
    property Name: string read GetName;
  end; { TDLUIXAction}

  TDLUIXOpenAnalyzerAction = class(TDLUIXAction, IDLUIXOpenAnalyzerAction)
  strict private
    FAnalyzer: IDLUIXAnalyzer;
  strict protected
    function  GetAnalyzer: IDLUIXAnalyzer;
  public
    constructor Create(const name: string; const analyzer: IDLUIXAnalyzer);
    property Analyzer: IDLUIXAnalyzer read GetAnalyzer;
  end; { TDLUIXOpenAnalyzerAction }

  TDLUIXOpenUnitBrowserAction = class(TDLUIXOpenAnalyzerAction, IDLUIXOpenUnitBrowserAction)
  strict private
    FFilterType : TDLUIXUnitBrowserType;
    FInitialUnit: string;
  strict protected
    procedure SetInitialUnit(const value: string);
    function  GetFilterType: TDLUIXUnitBrowserType;
    function  GetInitialUnit: string;
  public
    constructor Create(const name: string; const analyzer: IDLUIXAnalyzer;
      const initialUnit: string; const filterType: TDLUIXUnitBrowserType);
    property FilterType: TDLUIXUnitBrowserType read GetFilterType;
    property InitialUnit: string read GetInitialUnit write SetInitialUnit;
  end; { TDLUIXOpenUnitBrowserAction }

  TDLUIXNavigationAction = class(TDLUIXAction, IDLUIXNavigationAction)
  strict private
    FIsBackNavigation: boolean;
    FLocation        : TDLUIXLocation;
  strict protected
    function  GetIsBackNavigation: boolean;
    function  GetLocation: TDLUIXLocation;
    procedure SetLocation(const value: TDLUIXLocation);
  public
    constructor Create(const name: string; const location: TDLUIXLocation;
      isBackNavigation: boolean);
    property Location: TDLUIXLocation read GetLocation write SetLocation;
    property IsBackNavigation: boolean read GetIsBackNavigation;
  end; { TDLUIXNavigationAction }

  TDLUIXListNavigationAction = class(TDLUIXAction, IDLUIXListNavigationAction)
  strict private
    FLocations: IDLUIXNamedLocationList;
  strict protected
    function  GetLocations: IDLUIXNamedLocationList;
  public
    constructor Create(const name: string; locations: IDLUIXNamedLocationList);
    property Locations: IDLUIXNamedLocationList read GetLocations;
  end; { TDLUIXListNavigationAction }

  TDLUIXFilteredListAction = class(TDLUIXAction, IDLUIXFilteredListAction)
  strict private
    FList         : IList<string>;
    FLocationQuery: TDLUIXLocationQueryByName;
    FSelected     : string;
  strict protected
    function  GetLocationQuery: TDLUIXLocationQueryByName;
    procedure SetLocationQuery(const value: TDLUIXLocationQueryByName);
    function  GetList: IList<string>;
    function  GetSelected: string;
  public
    constructor Create(const name: string; const list: IList<string>;
      const selected: string);
    function  FilterLocation(const location: TDLUIXLocation): TDLUIXLocation;
    property List: IList<string> read GetList;
    property LocationQuery: TDLUIXLocationQueryByName read GetLocationQuery write SetLocationQuery;
  end; { TDLUIXFilteredListAction }

  TDLUIXSearchAction = class(TDLUIXAction, IDLUIXSearchAction)
  strict private
    FGetLineProc     : TDLUIXGetLineProc;
    FInitialSearch   : string;
    FProgressCallback: TDLUIXProgressCallback;
    FSearchProc      : TDLUIXSearchProc;
  private
    function  GetGetLine: TDLUIXGetLineProc;
    function  GetInitialSearch: string;
    function  GetProgressCallback: TDLUIXProgressCallback;
    function  GetSearchProc: TDLUIXSearchProc;
    procedure SetProgressCallback(const Value: TDLUIXProgressCallback);
  public
    constructor Create(const name, searchToken: string;
      const searchProc: TDLUIXSearchProc;
      const progressCallback: TDLUIXProgressCallback;
      const getLineProc: TDLUIXGetLineProc);
    property GetLine: TDLUIXGetLineProc read GetGetLine;
    property ProgressCallback: TDLUIXProgressCallback read GetProgressCallback write SetProgressCallback;
    property SearchProc: TDLUIXSearchProc read GetSearchProc;
  end; { TDLUIXSearchAction }

{ exports }

function CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
begin
  Result := TDLUIXOpenAnalyzerAction.Create(name, analyzer);
end; { CreateOpenAnalyzerAction }

function CreateOpenUnitBrowserAction(const name: string; const analyzer: IDLUIXAnalyzer;
  const initialUnit: string; const filterType: TDLUIXUnitBrowserType): IDLUIXAction;
begin
  Result := TDLUIXOpenUnitBrowserAction.Create(name, analyzer, initialUnit, filterType);
end; { CreateOpenUnitBrowserAction }

function CreateNavigationAction(const name: string; const location: TDLUIXLocation;
  isBackNavigation: boolean): IDLUIXAction;
begin
  Result := TDLUIXNavigationAction.Create(name, location, isBackNavigation);
end; { CreateNavigationAction }

function CreateListNavigationAction(const name: string;
  const locations: IDLUIXNamedLocationList): IDLUIXAction;
begin
  Result := TDLUIXListNavigationAction.Create(name, locations);
end; { CreateListNavigationAction }

function CreateFilteredListAction(const name: string;
  const list: IList<string>; const selected: string): IDLUIXAction;
begin
  Result := TDLUIXFilteredListAction.Create(name, list, selected);
end; { CreateFilteredListAction }

function CreateSearchAction(const name, searchToken: string;
  const searchProc: TDLUIXSearchProc;
  const progressCallback: TDLUIXProgressCallback;
  const getLineProc: TDLUIXGetLineProc): IDLUIXSearchAction;
begin
  Result := TDLUIXSearchAction.Create(name, searchToken, searchProc,
              progressCallback, getLineProc);
end; { CreateSearchAction }

{ TDLUIXAction }

constructor TDLUIXAction.Create(const name: string);
begin
  inherited Create;
  FName := name;
  FManagedActions := TCollections.CreateList<TDLUIXManagedAction>;
end; { TDLUIXAction.Create }

function TDLUIXAction.GetDefaultAction: IDLUIXAction;
begin
  Result := FDefaultAction;
end;

function TDLUIXAction.GetManagedActions: IDLUIXManagedActions;
begin
  Result := FManagedActions;
end;

function TDLUIXAction.GetName: string;
begin
  Result := FName;
end; { TDLUIXAction.GetName }

procedure TDLUIXAction.SetDefaultAction(const value: IDLUIXAction);
begin
  FDefaultAction := value;
end; { TDLUIXAction.SetDefaultAction }

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

{ TDLUIXOpenUnitBrowserAction }

constructor TDLUIXOpenUnitBrowserAction.Create(const name: string;
  const analyzer: IDLUIXAnalyzer; const initialUnit: string;
  const filterType: TDLUIXUnitBrowserType);
begin
  inherited Create(name, analyzer);
  FInitialUnit := initialUnit;
  FFilterType := filterType;
end; { TDLUIXOpenUnitBrowserAction.Create }

function TDLUIXOpenUnitBrowserAction.GetFilterType: TDLUIXUnitBrowserType;
begin
  Result := FFilterType;
end; { TDLUIXOpenUnitBrowserAction.GetFilterType }

function TDLUIXOpenUnitBrowserAction.GetInitialUnit: string;
begin
  Result := FInitialUnit;
end; { TDLUIXOpenUnitBrowserAction.GetInitialUnit }

procedure TDLUIXOpenUnitBrowserAction.SetInitialUnit(const value: string);
begin
  FInitialUnit := value;
end; { TDLUIXOpenUnitBrowserAction.SetInitialUnit }

{ TDLUIXNavigationAction }

constructor TDLUIXNavigationAction.Create(const name: string; const location:
  TDLUIXLocation; isBackNavigation: boolean);
begin
  inherited Create(name);
  FLocation := TDLUIXLocation.Create(location);
  FIsBackNavigation := isBackNavigation;
end; { TDLUIXNavigationAction.Create }

function TDLUIXNavigationAction.GetIsBackNavigation: boolean;
begin
  Result := FIsBackNavigation;
end; { TDLUIXNavigationAction.GetIsBackNavigation }

function TDLUIXNavigationAction.GetLocation: TDLUIXLocation;
begin
  Result := FLocation;
end; { TDLUIXNavigationAction.GetLocation }

procedure TDLUIXNavigationAction.SetLocation(const value: TDLUIXLocation);
begin
  FLocation := value;
end; { TDLUIXNavigationAction.SetLocation }

{ TDLUIXListNavigationAction }

constructor TDLUIXListNavigationAction.Create(const name: string; locations:
  IDLUIXNamedLocationList);
begin
  inherited Create(name);
  FLocations := locations;
end; { TDLUIXListNavigationAction.Create }

function TDLUIXListNavigationAction.GetLocations: IDLUIXNamedLocationList;
begin
  Result := FLocations;
end; { TDLUIXListNavigationAction.GetLocations }

{ TDLUIXFilteredListAction }

constructor TDLUIXFilteredListAction.Create(const name: string;
  const list: IList<string>; const selected: string);
begin
  inherited Create(name);
  FList := list;
  FSelected := selected;
end; { TDLUIXFilteredListAction.Create }

function TDLUIXFilteredListAction.FilterLocation(
  const location: TDLUIXLocation): TDLUIXLocation;
var
  loc     : TDLCoordinate;
  unitName: string;
begin
  Result := location;
  if assigned(FLocationQuery) and FLocationQuery(location.UnitName, unitName, loc) then begin
    Result.UnitName := unitName;
    Result.Line := loc.Line;
    Result.Column := loc.Column;
  end;
end; { TDLUIXFilteredListAction.FilterLocation }

function TDLUIXFilteredListAction.GetList: IList<string>;
begin
  Result := FList;
end; { TDLUIXFilteredListAction.GetList }

function TDLUIXFilteredListAction.GetLocationQuery: TDLUIXLocationQueryByName;
begin
  Result := FLocationQuery;
end; { TDLUIXFilteredListAction.GetLocationQuery }

function TDLUIXFilteredListAction.GetSelected: string;
begin
  Result := FSelected;
end; { TDLUIXFilteredListAction.GetSelected }

procedure TDLUIXFilteredListAction.SetLocationQuery(
  const value: TDLUIXLocationQueryByName);
begin
  FLocationQuery := value;
end; { TDLUIXFilteredListAction.SetLocationQuery }

{ TDLUIXSearchAction }

constructor TDLUIXSearchAction.Create(const name, searchToken: string;
      const searchProc: TDLUIXSearchProc;
      const progressCallback: TDLUIXProgressCallback;
      const getLineProc: TDLUIXGetLineProc);
begin
  inherited Create(name);
  FInitialSearch := searchToken;
  FSearchProc := searchProc;
  FProgressCallback := progressCallback;
  FGetLineProc := getLineProc;
end; { TDLUIXSearchAction.Create }

function TDLUIXSearchAction.GetGetLine: TDLUIXGetLineProc;
begin
  Result := FGetLineProc;
end; { TDLUIXSearchAction.GetGetLine }

function TDLUIXSearchAction.GetInitialSearch: string;
begin
  Result := FInitialSearch;
end; { TDLUIXSearchAction.GetInitialSearch }

function TDLUIXSearchAction.GetProgressCallback: TDLUIXProgressCallback;
begin
  Result := FProgressCallback;
end; { TDLUIXSearchAction.GetProgressCallback }

function TDLUIXSearchAction.GetSearchProc: TDLUIXSearchProc;
begin
  Result := FSearchProc;
end; { TDLUIXSearchAction.GetSearchProc }

procedure TDLUIXSearchAction.SetProgressCallback(const value: TDLUIXProgressCallback);
begin
  FProgressCallback := value;
end; { TDLUIXSearchAction.SetProgressCallback }

end.
