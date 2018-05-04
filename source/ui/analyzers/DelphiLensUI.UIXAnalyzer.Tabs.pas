unit DelphiLensUI.UIXAnalyzer.Tabs;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateTabsAnalyzer: IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,  System.Generics.Defaults,
  Spring.Collections,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXTabsAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private
    FTabNames: IList<string>;
    FTabPaths: IList<string>;
  public
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame;
      const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { TDLUIXTabsAnalyzer }

{ exports }

function CreateTabsAnalyzer: IDLUIXAnalyzer;
begin
  Result := TDLUIXTabsAnalyzer.Create;
end; { CreateTabsAnalyzer }

{ TDLUIXTabsAnalyzer }

procedure TDLUIXTabsAnalyzer.BuildFrame(const action: IDLUIXAction;
  const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
var
  filteredList : IDLUIXFilteredListAction;
  iTab         : integer;
  navigateToTab: IDLUIXAction;
  sPath        : string;
  sTab         : string;
begin
  FTabPaths := TCollections.CreateList<string>;
  for sTab in context.TabNames do
    FTabPaths.Add(sTab);

  // terribly inefficient but a) it is called rarely and b) FTabPaths will be really short
  FTabPaths.Sort(
    TComparer<string>.Construct(
      function (const left, right: string): integer
      begin
        Result := CompareText(ExtractFileName(left), ExtractFileName(right));
      end));

  FTabNames := TCollections.CreateList<string>;
  for sPath in FTabPaths do
    FTabNames.Add(ExtractFileName(sPath));

  filteredList := CreateFilteredListAction('', FTabNames, context.Source.UnitName) as IDLUIXFilteredListAction;
  navigateToTab := CreateNavigationAction('&Open', Default(TDLUIXLocation), false);

  filteredList.ManagedActions.Add(TDLUIXManagedAction.Create(navigateToTab, TDLUIXManagedAction.AnySelected()));
  filteredList.DefaultAction := navigateToTab;

  filteredList.FileNameIdxQuery :=
    function (itemIdx: integer; var fileName: string): boolean
    begin
      Result := (itemIdx >= 0) and (itemIdx < FTabPaths.Count);
      if Result then
        fileName := FTabPaths[itemIdx];
    end;

  frame.CreateAction(filteredList);
  frame.CreateAction(navigateToTab, [faoDefault]);
end; { TDLUIXTabsAnalyzer.BuildFrame }

function TDLUIXTabsAnalyzer.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (Length(context.TabNames) > 0);
end; { TDLUIXTabsAnalyzer.CanHandle }

end.
