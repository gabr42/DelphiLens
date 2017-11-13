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

  IDLUIXNavigationAction = interface(IDLUIXAction) ['{4370BAEB-860F-42C0-8831-F361289A7AF3}']
    function  GetIsBackNavigation: boolean;
    function  GetLocation: TDLUIXLocation;
  //
    property Location: TDLUIXLocation read GetLocation;
    property IsBackNavigation: boolean read GetIsBackNavigation;
  end; { IDLUIXNavigationAction }

  IDLUIXNamedLocationList = IList<IDLUIXNavigationAction>;

  IDLUIXListNavigationAction = interface(IDLUIXAction) ['{144666AA-1E43-47DB-B725-503C62857843}']
    function  GetLocations: IDLUIXNamedLocationList;
  //
    property Locations: IDLUIXNamedLocationList read GetLocations;
  end; { IDLUIXListNavigationAction }

function  CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
function  CreateNavigationAction(const name: string; const location: TDLUIXLocation;
  isBackNavigation: boolean): IDLUIXAction;
function  CreateListNavigationAction(const name: string; const locations: IDLUIXNamedLocationList): IDLUIXAction;

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

  TDLUIXNavigationAction = class(TDLUIXAction, IDLUIXNavigationAction)
  strict private
    FIsBackNavigation: boolean;
    FLocation        : TDLUIXLocation;
  strict protected
    function  GetIsBackNavigation: boolean;
    function  GetLocation: TDLUIXLocation;
  public
    constructor Create(const name: string; const location: TDLUIXLocation;
      isBackNavigation: boolean);
    property Location: TDLUIXLocation read GetLocation;
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

{ exports }

function CreateOpenAnalyzerAction(const name: string; const analyzer: IDLUIXAnalyzer): IDLUIXAction;
begin
  Result := TDLUIXOpenAnalyzerAction.Create(name, analyzer);
end; { CreateOpenAnalyzerAction }

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

end.
