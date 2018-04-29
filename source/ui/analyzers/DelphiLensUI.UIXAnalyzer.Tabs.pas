unit DelphiLensUI.UIXAnalyzer.Tabs;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

function CreateTabsAnalyzer: IDLUIXAnalyzer;

implementation

uses
  System.SysUtils,
  Spring.Collections,
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXTabsAnalyzer = class(TInterfacedObject, IDLUIXAnalyzer)
  strict private
    FTabNames: IList<string>;
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
begin
  FTabNames := TCollections.CreateList<string>;
  for iTab := Low(context.TabNames) to High(context.TabNames) do
    FTabNames.Add(ExtractFileName(context.TabNames[iTab]));

  filteredList := CreateFilteredListAction('', FTabNames, context.Source.UnitName) as IDLUIXFilteredListAction;
  navigateToTab := CreateNavigationAction('&Open', Default(TDLUIXLocation), false);

  filteredList.ManagedActions.Add(TDLUIXManagedAction.Create(navigateToTab, TDLUIXManagedAction.AnySelected()));
  filteredList.DefaultAction := navigateToTab;

  frame.CreateAction(filteredList);
  frame.CreateAction(navigateToTab, [faoDefault]);
end; { TDLUIXTabsAnalyzer.BuildFrame }

function TDLUIXTabsAnalyzer.CanHandle(const context: IDLUIWorkerContext): boolean;
begin
  Result := (Length(context.TabNames) > 0);
end; { TDLUIXTabsAnalyzer.CanHandle }

end.
