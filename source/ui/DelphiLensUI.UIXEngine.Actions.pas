unit DelphiLensUI.UIXEngine.Actions;

interface

uses
  Spring.Collections,
  DelphiLensUI.UIXAnalyzer.Intf,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIXOpenAnalyzerAction = interface(IDLUIXAction) ['{00E07ADB-97C6-42AA-8865-E1EF8B7274A2}']
    function  GetAnalyzer: IDLUIXAnalyzer;
  //
    property Analyzer: IDLUIXAnalyzer read GetAnalyzer;
  end; { IDLUIXOpenAnalyzerAction }

  TDLUIXUnitBrowserType = (ubtNormal, ubtUsedIn, ubtUsedBy);
  IDLUIXOpenUnitBrowserAction = interface(IDLUIXOpenAnalyzerAction) ['{0741FE6A-E194-4A67-A3BE-4E57AE8B141A}']
    function  GetFilterType: TDLUIXUnitBrowserType;
    function  GetInitialUnit: string;
  //
    property FilterType: TDLUIXUnitBrowserType read GetFilterType;
    property InitialUnit: string read GetInitialUnit;
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
  //
    property Locations: IDLUIXNamedLocationList read GetLocations;
  end; { IDLUIXListNavigationAction }

  IDLUIXFilteredListAction = interface(IDLUIXAction) ['{A74C5DBB-F0FA-4560-BAF1-41AB5E4E109F}']
    function  GetDefaultAction: IDLUIXAction;
    function  GetList: IList<string>;
    function  GetManagedActions: TDLUIXActions;
    function  GetSelected: string;
    procedure SetDefaultAction(const value: IDLUIXAction);
    procedure SetManagedActions(const value: TDLUIXActions);
  //
    property List: IList<string> read GetList;
    property Selected: string read GetSelected;
    property DefaultAction: IDLUIXAction read GetDefaultAction write SetDefaultAction;
    property ManagedActions: TDLUIXActions read GetManagedActions write SetManagedActions;
  end; { IDLUIXFilteredListAction }

function  CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
function  CreateOpenUnitBrowserAction(const name: string; const analyzer: IDLUIXAnalyzer;
  const initialUnit: string; const filterType: TDLUIXUnitBrowserType): IDLUIXAction;
function  CreateNavigationAction(const name: string; const location: TDLUIXLocation;
  isBackNavigation: boolean): IDLUIXAction;
function  CreateListNavigationAction(const name: string; const locations: IDLUIXNamedLocationList): IDLUIXAction;
function  CreateFilteredListAction(const name: string; const list: IList<string>;
  const selected: string): IDLUIXAction;

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
    function  GetFilterType: TDLUIXUnitBrowserType;
    function  GetInitialUnit: string;
  public
    constructor Create(const name: string; const analyzer: IDLUIXAnalyzer;
      const initialUnit: string; const filterType: TDLUIXUnitBrowserType);
    property FilterType: TDLUIXUnitBrowserType read GetFilterType;
    property InitialUnit: string read GetInitialUnit;
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
    FDefaultAction : IDLUIXAction;
    FList          : IList<string>;
    FManagedActions: TDLUIXActions;
    FSelected      : string;
  strict protected
    function  GetDefaultAction: IDLUIXAction;
    function  GetManagedActions: TDLUIXActions;
    procedure SetDefaultAction(const value: IDLUIXAction);
    procedure SetManagedActions(const value: TDLUIXActions);
    function  GetList: IList<string>;
    function  GetSelected: string;
  public
    constructor Create(const name: string; const list: IList<string>;
      const selected: string);
    property List: IList<string> read GetList;
    property DefaultAction: IDLUIXAction read GetDefaultAction write SetDefaultAction;
    property ManagedActions: TDLUIXActions read GetManagedActions write SetManagedActions;
  end; { TDLUIXFilteredListAction }

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

function TDLUIXFilteredListAction.GetDefaultAction: IDLUIXAction;
begin
  Result := FDefaultAction;
end; { TDLUIXFilteredListAction.GetDefaultAction }

function TDLUIXFilteredListAction.GetList: IList<string>;
begin
  Result := FList;
end; { TDLUIXFilteredListAction.GetList }

function TDLUIXFilteredListAction.GetManagedActions: TDLUIXActions;
begin
  Result := FManagedActions;
end; { TDLUIXFilteredListAction.GetManagedActions }

function TDLUIXFilteredListAction.GetSelected: string;
begin
  Result := FSelected;
end; { TDLUIXFilteredListAction.GetSelected }

procedure TDLUIXFilteredListAction.SetDefaultAction(const value: IDLUIXAction);
begin
  FDefaultAction := value;
end; { TDLUIXFilteredListAction.SetDefaultAction }

procedure TDLUIXFilteredListAction.SetManagedActions(const value: TDLUIXActions);
begin
  FManagedActions := value;
end; { TDLUIXFilteredListAction.SetManagedActions }

end.
