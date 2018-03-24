unit DelphiLensUI.UIXEngine.VCLFloating;

interface

uses
  DelphiLensUI.UIXEngine.Intf;

//TODO: Also overlap location list
//TODO: Lists should change width according to the item
//TODO: Nicer buttons with icons ... Derive from TBitBtn and reimplement CN_DRAWITEM?

function CreateUIXEngine: IDLUIXEngine;

implementation

uses
  Winapi.Windows, Winapi.Messages,
  System.Types, System.RTTI, System.SysUtils, System.StrUtils, System.Classes, System.Math,
  System.RegularExpressions,
  Vcl.StdCtrls, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.WinXCtrls,
  Spring, Spring.Collections, Spring.Reflection,
  GpStuff, GpEasing, GpVCL,
  DelphiLens.UnitInfo,
  DelphiLensUI.UIXAnalyzer.Intf, DelphiLensUI.UIXAnalyzer.Attributes,
  DelphiLensUI.UIXEngine.Actions;

type
  TDLUIXListBoxWrapper = class(TListBox)
  protected
    function  GetItemIndex: integer; override;
    procedure SelectAndMakeVisible(const value: integer);
    procedure SetItemIndex(const value: integer); overload; override;
  end; { TDLUIXListBoxWrapper }

  TVCLFloatingForm = class(TForm)
  strict private
    FOnBackSpace: TProc;
  protected
    procedure HandleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    procedure UpdateMask;
    property OnBackSpace: TProc read FOnBackSpace write FOnBackSpace;
  end; { TVCLFloatingForm }

  IDLUIXVCLFloatingFrame = interface ['{43127F61-07EE-466F-BAB2-E39B811AFB2F}']
    function  GetBounds_Screen(const action: IDLUIXAction): TRect;
  end; { IDLUIXVCLFloatingFrame }

  IDLUIXVCLListStorage = interface ['{90F471EC-DC29-4D4A-B87C-91DC61414BCF}']
    function  GetContent: IList<string>;
    function  GetListBox: TListBox;
    function  GetSearchBox: TSearchBox;
    function  GetSearchTimer: TTimer;
  //
    property Content: IList<string> read GetContent;
    property ListBox: TListBox read GetListBox;
    property SearchBox: TSearchBox read GetSearchBox;
    property SearchTimer: TTimer read GetSearchTimer;
  end; { IDLUIXVCLListStorage }

  TDLUIXVCLListStorage = class(TInterfacedObject, IDLUIXVCLListStorage)
  strict private
    FContent  : IList<string>;
    FListBox  : TListBox;
    FSearchBox: TSearchBox;
    FTimer    : TTimer;
  strict protected
    function  GetContent: IList<string>;
    function  GetListBox: TListBox;
    function  GetSearchBox: TSearchBox;
    function  GetSearchTimer: TTimer;
  public
    constructor Create(AListBox: TListBox; ASearchBox: TSearchBox; ATimer: TTimer);
    property Content: IList<string> read GetContent;
    property ListBox: TListBox read GetListBox;
    property SearchBox: TSearchBox read GetSearchBox;
    property SearchTimer: TTimer read GetSearchTimer;
  end; { IDLUIXVCLListStorage }

  TDLUIXVCLFloatingFrame = class(TManagedInterfacedObject, IDLUIXFrame,
                                                           IDLUIXVCLFloatingFrame)
  strict private const
    CAlphaBlendActive         = 255;
    CAlphaBlendInactive       =  64;
    CButtonHeight             =  81;
    CButtonHeight2nd          =  53;
    CButtonHeightSmall        =  33;
    CButtonSpacing            =  15;
    CButtonSpacingSmall       =   7;
    CButtonWidth              = 201;
    CColumnSpacing            =  15;
    CFilteredListWidth        = 201;
    CFilteredListHeight       = 313;
    CFrameSpacing             =  21;
    CInactiveFrameOverlap     =  21;
    CListButtonHeight         =  25;
    CListButtonSpacing        =   3;
    CListButtonWidth          = 254;
    CSearchBoxHeight          =  21;
    CSearchToListBoxSeparator =   1;
  var
    [Managed(false)] FActionMap: IBidiDictionary<TObject, IDLUIXAction>;
    [Managed(false)] FForm     : TVCLFloatingForm;
    [Managed(false)] FListMap  : IDictionary<TComponent, IDLUIXVCLListStorage>;
  var
    FColumnTop     : integer;
    FColumnLeft    : integer;
    FEasing        : IEasing;
    FEasingPos     : IEasing;
    FForceNewColumn: boolean;
    FHistoryButton : TButton;
    FOnAction      : TDLUIXFrameAction;
    FOnShowProc    : IQueue<TProc>;
    FOriginalLeft  : Nullable<integer>;
    FParent        : IDLUIXFrame;
    FPrevOptions   : TDLUIXFrameActionOptions;
    FTargetLeft    : Nullable<integer>;
  strict protected
    procedure ApplyOptions(control: TControl; options: TDLUIXFrameActionOptions);
    function  BuildButton(const action: IDLUIXAction; options: TDLUIXFrameActionOptions): TRect;
    function  BuildFilteredList(const filteredList: IDLUIXFilteredListAction;
      options: TDLUIXFrameActionOptions): TRect;
    function  BuildList(const listNavigation: IDLUIXListNavigationAction;
      options: TDLUIXFrameActionOptions): TRect;
    function  CollectNames(listBox: TListBox): string;
    procedure EaseAlphaBlend(start, stop: integer);
    procedure EaseLeft(start, stop: integer);
    procedure EnableActions(const actions: IDLUIXManagedActions; numSelected: integer);
    procedure FilterListBox(Sender: TObject);
    procedure ForwardAction(Sender: TObject);
    function  GetOnAction: TDLUIXFrameAction;
    function  GetParent: IDLUIXFrame;
    function  GetParentRect(const action: IDLUIXAction = nil): TRect;
    procedure HandleListBoxClick(Sender: TObject);
    procedure HandleListBoxDblClick(Sender: TObject);
    procedure HandleListBoxData(control: TWinControl; index: integer;
      var data: string);
    function  HandleListBoxDataFind(control: TWinControl; findString: string): integer;
    procedure HandleListBoxKeyDown(Sender: TObject; var key: word;
      shift: TShiftState);
    procedure HandleSearchBoxKeyDown(Sender: TObject; var key: word;
      shift: TShiftState);
    procedure HandleSearchBoxTimer(Sender: TObject);
    function  IsHistoryAnalyzer(const analyzer: IDLUIXAnalyzer): boolean;
    procedure NewColumn;
    function  NumItems(listBox: TListBox): integer;
    procedure PrepareNewColumn;
    procedure QueueOnShow(proc: TProc);
    procedure SetLocationAndOpen(listBox: TListBox; doOpen: boolean);
    procedure SetOnAction(const value: TDLUIXFrameAction);
    procedure UpdateClientSize(const rect: TRect);
  public
    constructor Create(const parentFrame: IDLUIXFrame);
    // IDLUIXVCLFloatingFrame
    function  GetBounds_Screen(const action: IDLUIXAction): TRect;
    // IDLUIXFrame
    procedure Close;
    procedure CreateAction(const action: IDLUIXAction;
      options: TDLUIXFrameActionOptions = []);
    function  IsEmpty: boolean;
    procedure MarkActive(isActive: boolean);
    procedure Show(const parentAction: IDLUIXAction);
    property OnAction: TDLUIXFrameAction read GetOnAction write SetOnAction;
    property Parent: IDLUIXFrame read GetParent;
  end; { TDLUIXVCLFloatingFrame }

  TDLUIXVCLFloatingEngine = class(TInterfacedObject, IDLUIXEngine)
  public
    constructor Create;
    function  CreateFrame(const parentFrame: IDLUIXFrame): IDLUIXFrame;
    procedure DestroyFrame(var frame: IDLUIXFrame);
  end; { TDLUIXVCLFloatingEngine }

{ exports }

function CreateUIXEngine: IDLUIXEngine;
begin
  Result := TDLUIXVCLFloatingEngine.Create;
end; { CreateUIXEngine }

{ TDLUIXListBoxWrapper }

function TDLUIXListBoxWrapper.GetItemIndex: integer;
begin
  if not MultiSelect then
    Result := inherited GetItemIndex
  else begin
    for Result := 0 to Count - 1 do
      if Selected[Result] then
        Exit;
    Result := -1;
  end;
end; { TDLUIXListBoxWrapper.GetItemIndex }

procedure TDLUIXListBoxWrapper.SelectAndMakeVisible(const value: integer);
begin
  ItemIndex := value;
  SendMessage(Handle, LB_SETCARETINDEX, ItemIndex, 0);
end; { TDLUIXListBoxWrapper.SelectAndMakeVisible }

procedure TDLUIXListBoxWrapper.SetItemIndex(const value: integer);
var
  i: integer;
begin
  if not MultiSelect then
    inherited SetItemIndex(value)
  else
    for i := 0 to Count - 1 do
      Selected[i] := (i = value);
end; { TDLUIXListBoxWrapper.SetItemIndex }

{ TVCLFloatingForm }

constructor TVCLFloatingForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  inherited;
  OnKeyDown := HandleKeyDown;
end; { TVCLFloatingForm.CreateNew }

procedure TVCLFloatingForm.HandleKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close
  else if Key = VK_BACK then
    if assigned(OnBackSpace) then
      OnBackSpace();
end; { TVCLFloatingForm.HandleKeyDown }

procedure TVCLFloatingForm.UpdateMask;
var
  pnt: TPoint;
  rgn, rgnCtrl: HRGN;
  i: Integer;
begin
  pnt := ClientToScreen(Point(0, 0));
  rgn := 0;
  for i := 0 to ControlCount - 1 do begin
    if not (Controls[i] is TWinControl) then
      continue;
    with Controls[i] do
      rgnCtrl := CreateRectRgn(Left, Top, Left+Width, Top+Height);
    if rgn = 0 then
      rgn := rgnCtrl
    else begin
      CombineRgn(rgn, rgn, rgnCtrl, RGN_OR);
      DeleteObject(rgnCtrl);
    end;
  end;
  if rgn <> 0 then begin
    SetWindowRgn(Handle, rgn, true);
    DeleteObject(rgn);
  end;
end; { TVCLFloatingForm.UpdateMask }

{ TDLUIXVCLFloatingFrame }

constructor TDLUIXVCLFloatingFrame.Create(const parentFrame: IDLUIXFrame);
begin
  inherited Create;
  FActionMap := TCollections.CreateBidiDictionary<TObject, IDLUIXAction>;
  FListMap := TCollections.CreateDictionary<TComponent, IDLUIXVCLListStorage>;
  FOnShowProc := TCollections.CreateQueue<TProc>;
  FParent := parentFrame;
  FForm := TVCLFloatingForm.CreateNew(Application);
  FForm.BorderStyle := bsNone;
  FForm.ClientWidth := 0;
  FForm.ClientHeight := 0;
  FForm.AlphaBlend := true;
  FForm.KeyPreview := true;
  FForm.AlphaBlendValue := CAlphaBlendActive;
  FForm.OnBackSpace :=
    procedure
    begin
      if assigned(FHistoryButton) then
        FHistoryButton.OnClick(FHistoryButton);
    end;
end; { TDLUIXVCLFloatingFrame.Create }

procedure TDLUIXVCLFloatingFrame.ApplyOptions(control: TControl;
  options: TDLUIXFrameActionOptions);
begin
  control.Enabled := not (faoDisabled in options);
  if (control is TButton) and (faoDefault in options) then
    TButton(control).Default := true;
end; { TDLUIXVCLFloatingFrame.ApplyOptions }

function TDLUIXVCLFloatingFrame.BuildButton(const action: IDLUIXAction;
  options: TDLUIXFrameActionOptions): TRect;
var
  button      : TButton;
  openAnalyzer: IDLUIXOpenAnalyzerAction;
begin
  button := TButton.Create(FForm);
  button.Parent := FForm;
  button.Width := CButtonWidth;
  button.Height := IFF(faoSmall in options, CButtonHeightSmall,
                     IFF(assigned(FParent), CButtonHeight2nd, CButtonHeight));
  button.Left := FColumnLeft;
  button.Top := FColumnTop + IFF(FColumnTop = 0, 0,
    IFF((faoSmall in options) and (faoSmall in FPrevOptions), CButtonSpacingSmall, CButtonSpacing));

  if not assigned(FParent) then
    button.Font.Size := 11;

  if Supports(action, IDLUIXOpenAnalyzerAction, openAnalyzer) then begin
    if not IsHistoryAnalyzer(openAnalyzer.Analyzer) then
      button.Caption := action.Name + ' >'
    else begin
      button.Caption := '< ' + action.Name;
      FHistoryButton := button;
    end;
  end
  else
    button.Caption := action.Name;
  button.OnClick := ForwardAction;

  ApplyOptions(button, options);
  FActionMap.Add(button, action);

  Result := button.BoundsRect;
end; { TDLUIXVCLFloatingFrame.BuildButton }

function TDLUIXVCLFloatingFrame.BuildFilteredList(
  const filteredList: IDLUIXFilteredListAction;
  options: TDLUIXFrameActionOptions): TRect;
var
  listBox    : TDLUIXListBoxWrapper;
  listBoxData: IDLUIXVCLListStorage;
  searchBox  : TSearchBox;
  searchTimer: TTimer;
begin
  searchBox := TSearchBox.Create(FForm);
  searchBox.Parent := FForm;
  searchBox.Width := CFilteredListWidth;
  searchBox.Height := CSearchBoxHeight;
  searchBox.Left := FColumnLeft;
  searchBox.Top := FColumnTop + 1;
  searchBox.OnKeyDown := HandleSearchBoxKeyDown;
  searchBox.OnInvokeSearch := FilterListBox;
  ApplyOptions(searchBox, options);

  listBox := TDLUIXListBoxWrapper.Create(FForm);
  listBox.Parent := FForm;
  listBox.Width := searchBox.Width;
  listBox.Height := CFilteredListHeight;
  listBox.Left := FColumnLeft;
  listBox.Top := searchBox.BoundsRect.Bottom + CSearchToListBoxSeparator;
  listBox.Style := lbVirtual;
  listBox.MultiSelect := true;
  listBox.OnClick := HandleListBoxClick;
  listBox.OnDblClick := HandleListBoxDblClick;
  listBox.OnKeyDown := HandleListBoxKeyDown;
  listBox.OnData := HandleListBoxData;
  listBox.OnDataFind := HandleListBoxDataFind;
  ApplyOptions(listBox, options);

  searchTimer := TTimer.Create(FForm);
  searchTimer.Enabled := false;
  searchTimer.Interval := 250;
  searchTimer.OnTimer := HandleSearchBoxTimer;

  listBoxData := TDLUIXVCLListStorage.Create(listBox, searchBox, searchTimer);
  FListMap.Add(listBox, listBoxData);
  FListMap.Add(searchBox, listBoxData);
  FListMap.Add(searchTimer, listBoxData);

  FActionMap.Add(searchBox, filteredList);

  FilterListBox(searchBox);
  listBox.SelectAndMakeVisible(listBox.Items.IndexOf(filteredList.Selected));

  Result.TopLeft := searchBox.BoundsRect.TopLeft;
  Result.BottomRight := listBox.BoundsRect.BottomRight;
  NewColumn;

  QueueOnShow(
    procedure
    begin
      SetLocationAndOpen(listBox, false);
      EnableActions(filteredList.ManagedActions, listBox.SelCount);
    end);
end; { TDLUIXVCLFloatingFrame.BuildFilteredList }

function TDLUIXVCLFloatingFrame.BuildList(
  const listNavigation: IDLUIXListNavigationAction;
  options: TDLUIXFrameActionOptions): TRect;
var
  button    : TButton;
  hasHotkey : TRegEx;
  hotkey    : string;
  navigation: IDLUIXNavigationAction;
  nextTop   : integer;
begin
  Result.TopLeft := Point(FColumnLeft, FColumnTop);
  nextTop := FColumnTop;
  button := nil;

  hotkey := '1';

  hasHotkey := TRegEx.Create('&[^&]');
  for navigation in listNavigation.Locations do
    if hasHotkey.IsMatch(navigation.Name) then begin
      hotkey := '';
      break; //for
    end;

  for navigation in listNavigation.Locations do begin
    button := TButton.Create(FForm);
    button.Parent := FForm;
    button.Width := CListButtonWidth;
    button.Height := CListButtonHeight;
    button.Left := FColumnLeft;
    button.Top := nextTop;
    button.Caption := '  ' + IFF(hotkey = '', '  ', '&' + hotkey + ' ') + navigation.Name;
    button.OnClick := ForwardAction;
    ApplyOptions(button, options);

    FActionMap.Add(button, navigation);

    nextTop := button.Top + button.Height + CListButtonSpacing;
    if hotkey = '9' then
      hotkey := ''
    else if hotkey <> '' then
      hotkey := Chr(Ord(hotkey[1]) + 1);
  end; //for namedLocation

  if assigned(button) then
    Result.BottomRight := button.BoundsRect.BottomRight
  else
    Result := TRect.Empty;
end; { TDLUIXVCLFloatingFrame.BuildList }

procedure TDLUIXVCLFloatingFrame.Close;
begin
  FForm.Close;
end; { TDLUIXVCLFloatingFrame.Close }

function TDLUIXVCLFloatingFrame.CollectNames(listBox: TListBox): string;
var
  i       : integer;
  selected: IList<string>;
begin
  selected := TCollections.CreateList<string>;
  for i := 0 to listBox.Count - 1 do
    if listBox.Selected[i] then
      selected.Add(listBox.Items[i]);
  Result := string.Join(#13, selected.ToArray);
end; { TDLUIXVCLFloatingFrame.CollectNames }

procedure TDLUIXVCLFloatingFrame.CreateAction(const action: IDLUIXAction;
  options: TDLUIXFrameActionOptions);
var
  filterList : IDLUIXFilteredListAction;
  historyList: IDLUIXListNavigationAction;
begin
  PrepareNewColumn;
  if Supports(action, IDLUIXListNavigationAction, historyList) then
    UpdateClientSize(BuildList(historyList, options))
  else if Supports(action, IDLUIXFilteredListAction, filterList) then
    UpdateClientSize(BuildFilteredList(filterList, options))
  else
    UpdateClientSize(BuildButton(action, options));
  FPrevOptions := options;
end; { TDLUIXVCLFloatingFrame.CreateAction }

procedure TDLUIXVCLFloatingFrame.EaseAlphaBlend(start, stop: integer);
begin
  FEasing := Easing.InOutCubic(start, stop, 500, 10,
    procedure (value: integer)
    begin
      if not (csDestroying in FForm.ComponentState) then
        FForm.AlphaBlendValue := value;
    end);
end; { TDLUIXVCLFloatingFrame.EaseAlphaBlend }

procedure TDLUIXVCLFloatingFrame.EaseLeft(start, stop: integer);
begin
  FTargetLeft := stop;
  FEasingPos := Easing.InOutCubic(start, stop, 500, 10,
    procedure (value: integer)
    begin
      if not (csDestroying in FForm.ComponentState) then
        FForm.Left := value;
    end);
end; { TDLUIXVCLFloatingFrame.EaseLeft }

procedure TDLUIXVCLFloatingFrame.EnableActions(const actions: IDLUIXManagedActions;
  numSelected: integer);
var
  action : TDLUIXManagedAction;
  control: TObject;
begin
  for action in actions do
    if FActionMap.TryGetKey(action.Action, control) then
      (control as TControl).Enabled := action.Test(numSelected);
end; { TDLUIXVCLFloatingFrame.EnableActions }

procedure TDLUIXVCLFloatingFrame.FilterListBox(Sender: TObject);
var
  content      : IList<string>;
  filteredList : IDLUIXFilteredListAction;
  listBox      : TListBox;
  matchesSearch: TPredicate<string>;
  searchBox    : TSearchBox;
  searchFilter : string;
  selected     : string;
begin
  searchBox := Sender as TSearchBox;
  filteredList := FActionMap.Value[searchBox] as IDLUIXFilteredListAction;
  searchFilter := searchBox.Text;
  listBox := FListMap[searchBox].ListBox;

  listBox.Items.BeginUpdate;
  try
    if listBox.ItemIndex < 0 then
      selected := ''
    else
      selected := listBox.Items[listBox.ItemIndex];

    content := FListMap[listBox].Content;
    content.Clear;

    if searchFilter = '' then
      content.AddRange(filteredList.List)
    else begin
      matchesSearch :=
        function (const s: string): boolean
        begin
          Result := ContainsText(s, searchFilter);
        end;
      content.AddRange(filteredList.List.Where(matchesSearch));
    end;

    listBox.Count := content.Count;

    if selected <> '' then
      listBox.ItemIndex := listBox.Items.IndexOf(selected);
    if (listBox.ItemIndex < 0) and (listBox.Items.Count > 0) then
      listBox.ItemIndex := 0;

    EnableActions(filteredList.ManagedActions, listBox.SelCount);

    listBox.OnClick(listBox);
  finally listBox.Items.EndUpdate; end;
end; { TDLUIXVCLFloatingFrame.FilterListBox }

procedure TDLUIXVCLFloatingFrame.ForwardAction(Sender: TObject);
begin
  if assigned(OnAction) then
    OnAction(Self, FActionMap.Value[Sender]);
end; { TDLUIXVCLFloatingFrame.ForwardAction }

function TDLUIXVCLFloatingFrame.GetBounds_Screen(const action: IDLUIXAction): TRect;
var
  control: TObject;
begin
  if action = nil then
    Exit(FForm.BoundsRect);

  control := FActionMap.Key[action];
  if not (control is TControl) then
    Exit(TRect.Empty);

  Result := TControl(control).BoundsRect;
  Result.TopLeft := FForm.ClientToScreen(Result.TopLeft);
  Result.BottomRight := FForm.ClientToScreen(Result.BottomRight);

  if FTargetLeft.HasValue then
    Result.Offset(FTargetLeft.Value - Result.Left, 0);
end; { TDLUIXVCLFloatingFrame.GetBounds_Screen }

function TDLUIXVCLFloatingFrame.GetOnAction: TDLUIXFrameAction;
begin
  Result := FOnAction;
end; { TDLUIXVCLFloatingFrame.GetOnAction }

function TDLUIXVCLFloatingFrame.GetParent: IDLUIXFrame;
begin
  Result := FParent;
end; { TDLUIXVCLFloatingFrame.GetParent }

function TDLUIXVCLFloatingFrame.GetParentRect(const action: IDLUIXAction): TRect;
begin
  Result := (FParent as IDLUIXVCLFloatingFrame).GetBounds_Screen(action);
end; { TDLUIXVCLFloatingFrame.GetParentRect }

procedure TDLUIXVCLFloatingFrame.HandleListBoxClick(Sender: TObject);
var
  filteredList: IDLUIXFilteredListAction;
  listBox     : TListBox;
begin
  listBox := (Sender as TListBox);
  filteredList := (FActionMap.Value[FListMap[listBox].SearchBox] as IDLUIXFilteredListAction);
  EnableActions(filteredList.ManagedActions, listBox.SelCount);
  SetLocationAndOpen(listBox, false);
end; { TDLUIXVCLFloatingFrame.HandleListBoxClick }

procedure TDLUIXVCLFloatingFrame.HandleListBoxData(control: TWinControl; index: integer;
  var data: string);
begin
  data := FListMap[control].Content[index];
end; { TDLUIXVCLFloatingFrame.HandleListBoxData }

function TDLUIXVCLFloatingFrame.HandleListBoxDataFind(control: TWinControl;
  findString: string): integer;
begin
  Result := FListMap[control].Content.IndexOf(findString);
end; { TDLUIXVCLFloatingFrame.HandleListBoxDataFind }

procedure TDLUIXVCLFloatingFrame.HandleListBoxDblClick(Sender: TObject);
var
  filteredList: IDLUIXFilteredListAction;
  listBox     : TListBox;
begin
  listBox := (Sender as TListBox);
  filteredList := (FActionMap.Value[FListMap[listBox].SearchBox] as IDLUIXFilteredListAction);
  EnableActions(filteredList.ManagedActions, listBox.SelCount);
  SetLocationAndOpen(listBox, true);
end; { TDLUIXVCLFloatingFrame.HandleListBoxDblClick }

procedure TDLUIXVCLFloatingFrame.HandleListBoxKeyDown(Sender: TObject;
  var key: word; shift: TShiftState);
begin
  if key = VK_RETURN then begin
    SetLocationAndOpen(Sender as TListBox, true);
    key := 0;
  end;
end; { TDLUIXVCLFloatingFrame.HandleListBoxKeyDown }

procedure TDLUIXVCLFloatingFrame.HandleSearchBoxKeyDown(Sender: TObject;
  var key: word; shift: TShiftState);
var
  listBox: TDLUIXListBoxWrapper;
  timer  : TTimer;
begin
  if (key = VK_UP) or (key = VK_DOWN)
     or (key = VK_HOME) or (key = VK_END)
     or (key = VK_PRIOR) or (key = VK_NEXT) then
  begin
    listBox := FListMap[Sender as TSearchBox].ListBox as TDLUIXListBoxWrapper;
    if key = VK_UP then
      listBox.SelectAndMakeVisible(Max(listBox.ItemIndex - 1, 0))
    else if key = VK_DOWN then
      listBox.SelectAndMakeVisible(Min(listBox.ItemIndex + 1, listBox.Items.Count - 1))
    else if key = VK_HOME then
      listBox.SelectAndMakeVisible(0)
    else if key = VK_END then
      listBox.SelectAndMakeVisible(listBox.Items.Count - 1)
    else if key = VK_PRIOR then
      listBox.SelectAndMakeVisible(Max(listBox.ItemIndex - NumItems(listBox), 0))
    else if key = VK_NEXT then
      listBox.SelectAndMakeVisible(Min(listBox.ItemIndex + NumItems(listBox), listBox.Items.Count - 1));
    listBox.OnClick(listBox);
    key := 0;
  end
  else if key = VK_RETURN then begin
    SetLocationAndOpen(FListMap[Sender as TSearchBox].ListBox, true);
    key := 0;
  end
  else begin
    timer := FListMap[Sender as TSearchBox].SearchTimer;
    timer.Enabled := false;
    timer.Enabled := true;
  end;
end; { TDLUIXVCLFloatingFrame.HandleSearchBoxKeyDown }

procedure TDLUIXVCLFloatingFrame.HandleSearchBoxTimer(Sender: TObject);
begin
  (Sender as TTimer).Enabled := false;
  FilterListBox(FListMap[TTimer(Sender)].SearchBox);
end; { TDLUIXVCLFloatingFrame.HandleSearchBoxTimer }

function TDLUIXVCLFloatingFrame.IsEmpty: boolean;
begin
  Result := (FForm.ClientHeight = 0);
end; { TDLUIXVCLFloatingFrame.IsEmpty }

function TDLUIXVCLFloatingFrame.IsHistoryAnalyzer(const analyzer: IDLUIXAnalyzer):
  boolean;
begin
  Result := TType.GetType((analyzer as TObject).ClassType).HasCustomAttribute<TBackNavigationAttribute>;
end; { TDLUIXVCLFloatingFrame.IsHistoryAnalyzer }

procedure TDLUIXVCLFloatingFrame.MarkActive(isActive: boolean);
begin
  EaseAlphaBlend(FForm.AlphaBlendValue, IFF(isActive, CAlphaBlendActive, CAlphaBlendInactive));

  if assigned(FParent) then begin
    if not isActive then begin
      FOriginalLeft := FForm.Left;
      EaseLeft(FForm.Left, GetParentRect.Left + CInactiveFrameOverlap);
    end
    else if FOriginalLeft.HasValue then begin
      EaseLeft(FForm.Left, FOriginalLeft);
      FOriginalLeft := nil;
    end;
  end;
end; { TDLUIXVCLFloatingFrame.MarkActive }

procedure TDLUIXVCLFloatingFrame.NewColumn;
begin
  FForceNewColumn := true;
end; { TDLUIXVCLFloatingFrame.NewColumn }

function TDLUIXVCLFloatingFrame.NumItems(listBox: TListBox): integer;
begin
  Result := Trunc(listBox.ClientHeight /  listBox.ItemHeight);
end; { TDLUIXVCLFloatingFrame.NumItems }

procedure TDLUIXVCLFloatingFrame.PrepareNewColumn;
begin
  if not FForceNewColumn then
    Exit;

  FColumnLeft := FForm.ClientWidth + CColumnSpacing;
  FColumnTop := 0;
  FForceNewColumn := false;
end; { TDLUIXVCLFloatingFrame.PrepareNewColumn }

procedure TDLUIXVCLFloatingFrame.QueueOnShow(proc: TProc);
begin
  FOnShowProc.Enqueue(proc);
end; { TDLUIXVCLFloatingFrame.QueueOnShow }

procedure TDLUIXVCLFloatingFrame.SetLocationAndOpen(listBox: TListBox; doOpen: boolean);
var
  action           : TDLUIXManagedAction;
  filterAction     : IDLUIXFilteredListAction;
  navigationAction : IDLUIXNavigationAction;
  unitBrowserAction: IDLUIXOpenUnitBrowserAction;
  unitName         : string;
begin
  if listBox.ItemIndex < 0 then
    unitName := ''
  else if listBox.SelCount = 1 then
    unitName := listBox.Items[listBox.ItemIndex]
  else
    unitName := CollectNames(listBox);

  filterAction := FActionMap.Value[FListMap[listBox].SearchBox] as IDLUIXFilteredListAction;

  for action in filterAction.ManagedActions do
    if Supports(action.Action, IDLUIXOpenUnitBrowserAction, unitBrowserAction) then
      unitBrowserAction.InitialUnit := unitName;

  if assigned(filterAction.DefaultAction)
     and Supports(filterAction.DefaultAction, IDLUIXNavigationAction, navigationAction)
  then begin
    navigationAction.Location := filterAction.FilterLocation(
      TDLUIXLocation.Create('', unitName, TDLCoordinate.Invalid));

    if doOpen then
      OnAction(Self, navigationAction);
  end;
end; { TDLUIXVCLFloatingFrame.SetLocationAndOpen }

procedure TDLUIXVCLFloatingFrame.SetOnAction(const value: TDLUIXFrameAction);
begin
  FOnAction := value;
end; { TDLUIXVCLFloatingFrame.SetOnAction }

procedure TDLUIXVCLFloatingFrame.Show(const parentAction: IDLUIXAction);
var
  analyzerAction: IDLUIXOpenAnalyzerAction;
  isBack        : boolean;
  proc          : TProc;
  rect          : TRect;
  button: TButton;
begin
  if not assigned(FParent) then
    FForm.Position := poScreenCenter
  else begin
    FForm.Position := poDesigned;
    rect := (FParent as IDLUIXVCLFloatingFrame).GetBounds_Screen(parentAction);
    isBack := false;
    if Supports(parentAction, IDLUIXOpenAnalyzerAction, analyzerAction) then
      isBack := TType.GetType((analyzerAction.Analyzer as TObject).ClassType).HasCustomAttribute<TBackNavigationAttribute>;

    if isBack then
      FForm.Left := rect.Left - CFrameSpacing - FForm.Width
    else
      FForm.Left := rect.Left + CFrameSpacing;
    FForm.Top := rect.Top + (rect.Height - FForm.Height) div 2;
  end;
  for proc in FOnShowProc do
    proc();
  FForm.UpdateMask;

  for button in FForm.EnumControls<TButton> do
    if string(button.Caption).StartsWith('  ') then
      SetWindowLong(button.Handle, GWL_STYLE, GetWindowLong(button.Handle, GWL_STYLE) OR BS_LEFT);

  FForm.ShowModal;
end; { TDLUIXVCLFloatingFrame.Show }

procedure TDLUIXVCLFloatingFrame.UpdateClientSize(const rect: TRect);
begin
  FForm.ClientWidth  := Max(FForm.ClientWidth,  rect.Right);
  FForm.ClientHeight := Max(FForm.ClientHeight, rect.Bottom);
  FColumnTop := Max(FColumnTop, rect.Bottom);
end; { TDLUIXVCLFloatingFrame.UpdateClientSize }

{ TDLUIXVCLFloatingEngine }

constructor TDLUIXVCLFloatingEngine.Create;
begin
  inherited;
  Application.Title := 'DelphiLens';
  Application.MainFormOnTaskBar := false;
end; { TDLUIXVCLFloatingEngine.Create }

function TDLUIXVCLFloatingEngine.CreateFrame(const parentFrame: IDLUIXFrame): IDLUIXFrame;
begin
  Result := TDLUIXVCLFloatingFrame.Create(parentFrame);
end; { TDLUIXVCLFloatingEngine.CreateFrame }

procedure TDLUIXVCLFloatingEngine.DestroyFrame(var frame: IDLUIXFrame);
begin
  frame := nil;
end; { TDLUIXVCLFloatingEngine.DestroyFrame }

{ TDLUIXVCLListStorage }

constructor TDLUIXVCLListStorage.Create(AListBox: TListBox; ASearchBox: TSearchBox;
  ATimer: TTimer);
begin
  inherited Create;
  FContent := TCollections.CreateList<string>;
  FListBox := AListBox;
  FSearchBox := ASearchBox;
  FTimer := ATimer;
end; { TDLUIXVCLListStorage.Create }

function TDLUIXVCLListStorage.GetContent: IList<string>;
begin
  Result := FContent;
end; { TDLUIXVCLListStorage.GetContent }

function TDLUIXVCLListStorage.GetListBox: TListBox;
begin
  Result := FListBox;
end; { TDLUIXVCLListStorage.GetListBox }

function TDLUIXVCLListStorage.GetSearchBox: TSearchBox;
begin
  Result := FSearchBox;
end; { TDLUIXVCLListStorage.GetSearchBox }

function TDLUIXVCLListStorage.GetSearchTimer: TTimer;
begin
  Result := FTimer;
end; { TDLUIXVCLListStorage.GetSearchTimer }

end.
