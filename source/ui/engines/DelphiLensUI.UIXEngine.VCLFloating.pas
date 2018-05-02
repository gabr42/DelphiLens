unit DelphiLensUI.UIXEngine.VCLFloating;

interface

uses
  DelphiLensUI.UIXEngine.Intf;

//TODO: Also overlap history location list
//TODO: Lists should change width according to the item
//TODO: Nicer buttons with icons ... Derive from TBitBtn and reimplement CN_DRAWITEM?

function CreateUIXEngine: IDLUIXEngine;

implementation

uses
  Winapi.Windows, Winapi.Messages,
  System.Types, System.RTTI, System.SysUtils, System.StrUtils, System.Classes, System.Math,
  System.RegularExpressions,
  Vcl.StdCtrls, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.WinXCtrls, Vcl.Buttons,
  Vcl.Themes, Vcl.Graphics, Vcl.Imaging.Pngimage,
  VirtualTrees,
  Spring, Spring.Collections, Spring.Reflection,
  GpStuff, GpEasing, GpVCL, GpVCL.OwnerDrawBitBtn,
  DelphiLens.UnitInfo, DelphiLens.FileCache.Intf, DelphiLens.FileCache,
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
    function  GetContentIdx: IList<integer>;
    function  GetListBox: TListBox;
    function  GetSearchBox: TSearchBox;
    function  GetSearchTimer: TTimer;
  //
    property Content: IList<string> read GetContent;
    property ContentIdx: IList<integer> read GetContentIdx;
    property ListBox: TListBox read GetListBox;
    property SearchBox: TSearchBox read GetSearchBox;
    property SearchTimer: TTimer read GetSearchTimer;
  end; { IDLUIXVCLListStorage }

  TDLUIXVCLListStorage = class(TInterfacedObject, IDLUIXVCLListStorage)
  strict private
    FContent   : IList<string>;
    FContentIdx: IList<integer>;
    FListBox   : TListBox;
    FSearchBox : TSearchBox;
    FTimer     : TTimer;
  strict protected
    function  GetContent: IList<string>;
    function  GetContentIdx: IList<integer>;
    function  GetListBox: TListBox;
    function  GetSearchBox: TSearchBox;
    function  GetSearchTimer: TTimer;
  public
    constructor Create(AListBox: TListBox; ASearchBox: TSearchBox; ATimer: TTimer);
    property Content: IList<string> read GetContent;
    property ContentIdx: IList<integer> read GetContentIdx;
    property ListBox: TListBox read GetListBox;
    property SearchBox: TSearchBox read GetSearchBox;
    property SearchTimer: TTimer read GetSearchTimer;
  end; { TDLUIXVCLListStorage }

  IDLUIXVCLTreeStorage = interface ['{990B7DE6-6222-4D62-A646-3727F70788E9}']
    function  GetCoordinates: ICoordinates;
    function  GetSearchBox: TSearchBox;
    function  GetSearchTimer: TTimer;
    function  GetVirtualTree: TVirtualStringTree;
    procedure SetCoordinates(const value: ICoordinates);
  //
    property Coordinates: ICoordinates read GetCoordinates write SetCoordinates;
    property SearchBox: TSearchBox read GetSearchBox;
    property SearchTimer: TTimer read GetSearchTimer;
    property VirtualTree: TVirtualStringTree read GetVirtualTree;
  end; { TDLUIXVCLTreeStorage }

  TDLUIXVCLTreeStorage = class(TInterfacedObject, IDLUIXVCLTreeStorage)
  strict private
    FCoordinates: ICoordinates;
    FSearchBox  : TSearchBox;
    FTimer      : TTimer;
    FVirtualTree: TVirtualStringTree;
  strict protected
    function  GetCoordinates: ICoordinates;
    procedure SetCoordinates(const value: ICoordinates);
    function  GetSearchBox: TSearchBox;
    function  GetSearchTimer: TTimer;
    function  GetVirtualTree: TVirtualStringTree;
  public
    constructor Create(AVirtualTree: TVirtualStringTree; ASearchBox: TSearchBox; ATimer: TTimer);
    property Coordinates: ICoordinates read GetCoordinates write SetCoordinates;
    property SearchBox: TSearchBox read GetSearchBox;
    property SearchTimer: TTimer read GetSearchTimer;
    property VirtualTree: TVirtualStringTree read GetVirtualTree;
  end; { TDLUIXVCLTreeStorage }

  TDLUIXVCLFloatingFrame = class(TManagedInterfacedObject, IDLUIXFrame,
                                                           IDLUIXVCLFloatingFrame)
  strict private const
    CAlphaBlendActive         = 255;
    CAlphaBlendInactive       =  64;
    CButtonFontSize           =  13;
    CButtonFontSizeSmall      =  11;
    CButtonHeight             =  81;
    CButtonHeight2nd          =  53;
    CButtonHeightSmall        =  33;
    CButtonSpacing            =  15;
    CButtonSpacingSmall       =   7;
    CButtonWidth              = 201;
    CColumnSpacing            =  15;
    CFilteredListHeight       = 313;
    CFilteredListWidth        = 201;
    CFrameSpacing             =  21;
    CInactiveFrameOverlap     =  21;
    CListButtonHeight         =  25;
    CListButtonSpacing        =   3;
    CListButtonWidth          = 254;
    CLocationTreeHeight       = CFilteredListHeight;
    CLocationTreeWidth        = 2 * CFilteredListWidth;
    CSearchBoxHeight          =  21;
    CSearchToListBoxSeparator =   1;
    CResourceImageAngleLeft   = 'IDD_ANGLE_LEFT';
    CResourceImageAngleRight  = 'IDD_ANGLE_RIGHT';
    CResourceImageShare       = 'IDD_SHARE';
  type
    TButtonDrawInfo = record
      ResourceName  : string;
      PositionRight : boolean;
      TextLeftOffset: integer;
      constructor Create(const AResourceName: string; APositionRight: boolean;
        ATextLeftOffset: integer);
    end; { TButtonDrawInfo }
  var
    [Managed(false)] FActionMap : IBidiDictionary<TObject, IDLUIXAction>;
    [Managed(false)] FButtonDraw: IDictionary<TBitBtn, TButtonDrawInfo>;
    [Managed(false)] FForm      : TVCLFloatingForm;
    [Managed(false)] FListMap   : IDictionary<TComponent, IDLUIXVCLListStorage>;
    [Managed(false)] FTreeMap   : IDictionary<TComponent, IDLUIXVCLTreeStorage>;
  var
    FCaptionPanel  : TPanel;
    FColumnTop     : integer;
    FColumnLeft    : integer;
    FEasing        : IEasing;
    FEasingPos     : IEasing;
    FFileCache     : IDLFileCache;
    FForceNewColumn: boolean;
    FHistoryButton : TBitBtn;
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
    function  BuildSearch(const search: IDLUIXSearchAction;
      options: TDLUIXFrameActionOptions): TRect;
    function  BuildList(const listNavigation: IDLUIXListNavigationAction;
      options: TDLUIXFrameActionOptions): TRect;
    function  CollectNames(listBox: TListBox): string;
    procedure DoSearch(const treeData: IDLUIXVCLTreeStorage; const searchTerm: string);
    procedure DrawCustomButton(button: TOwnerDrawBitBtn; canvas: TCanvas;
      drawRect: TRect; buttonState: TThemedButton);
    procedure EaseAlphaBlend(start, stop: integer);
    procedure EaseLeft(start, stop: integer);
    procedure EnableActions(const actions: IDLUIXManagedActions; numSelected: integer);
    procedure FilterListBox(Sender: TObject);
    procedure ForwardAction(Sender: TObject);
    function  GetCaption: string;
    function  GetFileCache: IDLFileCache;
    function  GetOnAction: TDLUIXFrameAction;
    function  GetParent: IDLUIXFrame;
    function  GetParentRect(const action: IDLUIXAction = nil): TRect;
    procedure GetSearchNodeText(Sender: TBaseVirtualTree; node: PVirtualNode;
      column: TColumnIndex; textType: TVSTTextType; var cellText: string);
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
    procedure HandleVTFocusChanged(Sender: TBaseVirtualTree; node: PVirtualNode;
      column: TColumnIndex);
    procedure InitSearchNode(Sender: TBaseVirtualTree; parentNode, node: PVirtualNode;
      var initialStates: TVirtualNodeInitStates);
    procedure InitSearchNodeChildren(Sender: TBaseVirtualTree;
      node: PVirtualNode; var childCount: cardinal);
    function  IsHistoryAnalyzer(const analyzer: IDLUIXAnalyzer): boolean;
    function  MakeRes(const resourceName: string): string;
    procedure NewColumn;
    function  NumItems(listBox: TListBox): integer;
    procedure PrepareNewColumn;
    function  ResourceSize: integer;
    procedure QueueOnShow(proc: TProc);
    procedure SetCaption(const value: string);
    procedure SetLocationAndOpen(listBox: TListBox; doOpen: boolean);
    procedure SetOnAction(const value: TDLUIXFrameAction);
    procedure StartSearch(Sender: TObject);
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
    procedure Show(monitorNum: integer; const parentAction: IDLUIXAction);
    property Caption: string read GetCaption write SetCaption;
    property FileCache: IDLFileCache read GetFileCache;
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

{ TDLUIXVCLFloatingFrame.TButtonDrawInfo }

constructor TDLUIXVCLFloatingFrame.TButtonDrawInfo.Create(const AResourceName: string;
  APositionRight: boolean; ATextLeftOffset: integer);
begin
  ResourceName := AResourceName;
  PositionRight := APositionRight;
  TextLeftOffset := ATextLeftOffset;
end; { TDLUIXVCLFloatingFrame.TButtonDrawInfo.Create }

{ TDLUIXVCLFloatingFrame }

constructor TDLUIXVCLFloatingFrame.Create(const parentFrame: IDLUIXFrame);
begin
  inherited Create;
  FActionMap := TCollections.CreateBidiDictionary<TObject, IDLUIXAction>;
  FListMap := TCollections.CreateDictionary<TComponent, IDLUIXVCLListStorage>;
  FTreeMap := TCollections.CreateDictionary<TComponent, IDLUIXVCLTreeStorage>;
  FButtonDraw := TCollections.CreateDictionary<TBitBtn, TButtonDrawInfo>;
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
  if (control is TBitBtn) and (faoDefault in options) then
    TBitBtn(control).Default := true;
end; { TDLUIXVCLFloatingFrame.ApplyOptions }

function TDLUIXVCLFloatingFrame.BuildButton(const action: IDLUIXAction;
  options: TDLUIXFrameActionOptions): TRect;
var
  button          : TBitBtn;
  navigateAnalyzer: IDLUIXNavigationAction;
  openAnalyzer    : IDLUIXOpenAnalyzerAction;
begin
  button := TBitBtn.Create(FForm);
  button.Parent := FForm;
  button.Width := CButtonWidth;
  button.Height := IFF(faoSmall in options, CButtonHeightSmall,
                     IFF(assigned(FParent), CButtonHeight2nd, CButtonHeight));
  button.Left := FColumnLeft;
  button.Top := FColumnTop + IFF(FColumnTop = 0, 0,
    IFF((faoSmall in options) and (faoSmall in FPrevOptions), CButtonSpacingSmall, CButtonSpacing));
  button.Caption := action.Name;
  if not assigned(FParent) then
    button.Font.Size := CButtonFontSize
  else
    button.Font.Size := CButtonFontSizeSmall;

  if Supports(action, IDLUIXOpenAnalyzerAction, openAnalyzer) then begin
    if not IsHistoryAnalyzer(openAnalyzer.Analyzer) then
      FButtonDraw.AddOrSetValue(button,
        TButtonDrawInfo.Create(MakeRes(CResourceImageAngleRight),
          true, IFF(button.Height = CButtonHeight, ResourceSize, 0)))
    else begin
      FButtonDraw.AddOrSetValue(button,
        TButtonDrawInfo.Create(MakeRes(CResourceImageAngleLeft),
          false, IFF(button.Height = CButtonHeight, ResourceSize, 0)));
      FHistoryButton := button;
    end;
  end
  else if Supports(action, IDLUIXNavigationAction, navigateAnalyzer) then
    FButtonDraw.AddOrSetValue(button,
      TButtonDrawInfo.Create(MakeRes(CResourceImageShare),
        true, IFF(button.Height = CButtonHeight, ResourceSize, 0)))
  else
    FButtonDraw.AddOrSetValue(button,
      TButtonDrawInfo.Create('', true, IFF(button.Height = CButtonHeight, ResourceSize, 0)));

  button.OnClick := ForwardAction;
  button.OnOwnerDraw := DrawCustomButton;

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
  button    : TBitBtn;
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
    button := TBitBtn.Create(FForm);
    button.Parent := FForm;
    button.Width := CListButtonWidth;
    button.Height := CListButtonHeight;
    button.Left := FColumnLeft;
    button.Top := nextTop;
    button.Caption := '  ' + IFF(hotkey = '', '  ', '&' + hotkey + ' ') + navigation.Name;
    button.OnClick := ForwardAction;
    button.OnOwnerDraw := DrawCustomButton;
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

function TDLUIXVCLFloatingFrame.BuildSearch(const search: IDLUIXSearchAction;
  options: TDLUIXFrameActionOptions): TRect;
var
  searchBox  : TSearchBox;
  searchTimer: TTimer;
  treeData   : TDLUIXVCLTreeStorage;
  vt         : TVirtualStringTree;
begin
  search.ProgressCallback :=
    procedure (const unitName: string; var abort: boolean)
    begin
      Application.ProcessMessages;
    end;

  searchBox := TSearchBox.Create(FForm);
  searchBox.Parent := FForm;
  searchBox.Width := CLocationTreeWidth;
  searchBox.Height := CSearchBoxHeight;
  searchBox.Left := FColumnLeft;
  searchBox.Top := FColumnTop + 1;
  searchBox.OnKeyDown := HandleSearchBoxKeyDown;
  searchBox.OnInvokeSearch := StartSearch;

  vt := TVirtualStringTree.Create(FForm);
  vt.Parent := FForm;
  vt.Width := searchBox.Width;
  vt.Height := CLocationTreeHeight;
  vt.Left := searchBox.Left;
  vt.Top := searchBox.BoundsRect.Bottom + CSearchToListBoxSeparator;
  vt.OnFocusChanged := HandleVTFocusChanged;

  searchTimer := TTimer.Create(FForm);
  searchTimer.Enabled := false;
  searchTimer.Interval := 500;
  searchTimer.OnTimer := HandleSearchBoxTimer;

  treeData := TDLUIXVCLTreeStorage.Create(vt, searchBox, searchTimer);
  FTreeMap.Add(vt, treeData);
  FTreeMap.Add(searchBox, treeData);
  FTreeMap.Add(searchTimer, treeData);

  FActionMap.Add(searchBox, search);

  vt.Tag := NativeUInt(pointer(treeData));

  searchBox.Text := search.InitialSearch;

//  FilterListBox(searchBox);
//  listBox.SelectAndMakeVisible(listBox.Items.IndexOf(filteredList.Selected));

  Result.TopLeft := searchBox.BoundsRect.TopLeft;
  Result.BottomRight := vt.BoundsRect.BottomRight;
  NewColumn;

  QueueOnShow(
    procedure
    begin
      DoSearch(treeData, searchBox.Text);
    end);
end; { TDLUIXVCLFloatingFrame.BuildSearch }

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
  search     : IDLUIXSearchAction;
begin
  PrepareNewColumn;
  if Supports(action, IDLUIXListNavigationAction, historyList) then
    UpdateClientSize(BuildList(historyList, options))
  else if Supports(action, IDLUIXFilteredListAction, filterList) then
    UpdateClientSize(BuildFilteredList(filterList, options))
  else if Supports(action, IDLUIXSearchAction, search) then
    UpdateClientSize(BuildSearch(search, options))
  else
    UpdateClientSize(BuildButton(action, options));
  FPrevOptions := options;
end; { TDLUIXVCLFloatingFrame.CreateAction }

procedure TDLUIXVCLFloatingFrame.DoSearch(const treeData: IDLUIXVCLTreeStorage;
  const searchTerm: string);
var
  vt: TVirtualStringTree;
begin
  treeData.Coordinates := (FActionMap[treeData.SearchBox] as IDLUIXSearchAction).SearchProc(searchTerm);
  vt := treeData.VirtualTree;
  vt.BeginUpdate;
  try
    vt.Clear;
    vt.OnInitNode := InitSearchNode;
    vt.OnInitChildren := InitSearchNodeChildren;
    vt.OnGetText := GetSearchNodeText;
    vt.NodeDataSize := SizeOf(IInterface);
    vt.RootNodeCount := treeData.Coordinates.Count;
  finally vt.EndUpdate; end;
  HandleVTFocusChanged(vt, vt.FocusedNode, -1);
end; { TDLUIXVCLFloatingFrame.DoSearch }

procedure TDLUIXVCLFloatingFrame.DrawCustomButton(button: TOwnerDrawBitBtn;
  canvas: TCanvas; drawRect: TRect; buttonState: TThemedButton);
var
  drawInfo: TButtonDrawInfo;
  imgX    : integer;
  png     : TPngImage;
begin
  if not FButtonDraw.TryGetValue(TBitBtn(button), drawInfo) then
    drawInfo := TButtonDrawInfo.Create('', true, 0);

  if drawInfo.ResourceName <> '' then begin
    png := TPngImage.Create;
    try
      png.LoadFromResourceName(HInstance, drawInfo.ResourceName);
      if drawInfo.PositionRight then begin
        imgX := drawRect.Right - ResourceSize - png.Width;
        if png.Width > ResourceSize then
          imgX := imgX + ResourceSize div 2;
      end
      else
        imgX := drawRect.Left + ResourceSize;
      canvas.Draw(imgX, drawRect.Top + (drawRect.Height - png.Height) div 2, png);
    finally FreeAndNil(png); end;
  end;

  drawRect.Left := drawRect.Left + ResourceSize + drawInfo.TextLeftOffset;
  drawRect.Bottom := drawRect.Bottom - 2; // looks better
  button.DrawText(button.Caption, drawRect, DT_NOCLIP or DT_LEFT or DT_VCENTER or DT_SINGLELINE)
end; { TDLUIXVCLFloatingFrame.DrawCustomButton }

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
  contentIdx   : IList<integer>;
  filteredList : IDLUIXFilteredListAction;
  iItem        : integer;
  listBox      : TListBox;
  list         : IList<string>;
  listStorage  : IDLUIXVCLListStorage;
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

    listStorage := FListMap[listBox];
    content := listStorage.Content;
    contentIdx := listStorage.ContentIdx;
    content.Clear;
    contentIdx.Clear;

    list := filteredList.List;

    if searchFilter = '' then
      content.AddRange(list)
    else 
      for iItem := 0 to list.Count - 1 do begin
        if ContainsText(list[iItem], searchFilter) then begin
          content.Add(list[iItem]);
          contentIdx.Add(iItem);
        end;
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

function TDLUIXVCLFloatingFrame.GetCaption: string;
begin
  if assigned(FCaptionPanel) then
    Result := FCaptionPanel.Caption
  else
    Result := '';
end; { TDLUIXVCLFloatingFrame.GetCaption }

function TDLUIXVCLFloatingFrame.GetFileCache: IDLFileCache;
begin
  if assigned(Parent) then
    Result := Parent.FileCache
  else begin
    if not assigned(FFileCache) then
      FFileCache := CreateFileCache;
    Result := FFileCache;
  end;
end; { TDLUIXVCLFloatingFrame.GetFileCache }

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

procedure TDLUIXVCLFloatingFrame.GetSearchNodeText(Sender: TBaseVirtualTree;
  node: PVirtualNode; column: TColumnIndex; textType: TVSTTextType;
  var cellText: string);
var
  treeData: TDLUIXVCLTreeStorage;
begin
  if textType = ttStatic then begin
    cellText := '';
    Exit;
  end;

  treeData := TDLUIXVCLTreeStorage(Sender.Tag);
  if node.Parent = Sender.RootNode then
    cellText := treeData.Coordinates[node.Index].UnitName
  else
    cellText := (FActionMap[treeData.SearchBox] as IDLUIXSearchAction).GetLine(
      treeData.Coordinates[node.Parent.Index].UnitName,
      treeData.Coordinates[node.Parent.Index].Coordinates[node.Index].Line);
end; { TDLUIXVCLFloatingFrame.GetSearchNodeText }

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
  listBox    : TDLUIXListBoxWrapper;
  listBoxData: IDLUIXVCLListStorage;
  timer      : TTimer;
  treeData   : IDLUIXVCLTreeStorage;
begin
  if not FListMap.TryGetValue(Sender as TComponent, listBoxData) then
    listBoxData := nil;
  if not FTreeMap.TryGetValue(Sender as TComponent, treeData) then
    treeData := nil;

  if (key = VK_UP) or (key = VK_DOWN)
     or (key = VK_HOME) or (key = VK_END)
     or (key = VK_PRIOR) or (key = VK_NEXT) then
  begin
    if assigned(listBoxData) then begin
      listBox := listBoxData.ListBox as TDLUIXListBoxWrapper;
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
    end;
  end
  else if key = VK_RETURN then begin
    if assigned(listBoxData) then begin
      SetLocationAndOpen(listBoxData.ListBox, true);
      key := 0;
    end;
  end
  else begin
    timer := nil;
    if assigned(listBoxData) then
      timer := listBoxData.SearchTimer;
    if assigned(treeData) then
      timer := treeData.SearchTimer;
    if assigned(timer) then begin
      timer.Enabled := false;
      timer.Enabled := true;
    end;
  end;
end; { TDLUIXVCLFloatingFrame.HandleSearchBoxKeyDown }

procedure TDLUIXVCLFloatingFrame.HandleSearchBoxTimer(Sender: TObject);
var
  listBoxData: IDLUIXVCLListStorage;
  treeData   : IDLUIXVCLTreeStorage;
begin
  (Sender as TTimer).Enabled := false;
  if FListMap.TryGetValue(Sender as TComponent, listBoxData) then
    FilterListBox(listBoxData.SearchBox)
  else if FTreeMap.TryGetValue(TComponent(Sender), treeData) then
    DoSearch(treeData, treeData.SearchBox.Text);
end; { TDLUIXVCLFloatingFrame.HandleSearchBoxTimer }

procedure TDLUIXVCLFloatingFrame.HandleVTFocusChanged(Sender: TBaseVirtualTree;
  node: PVirtualNode; column: TColumnIndex);
var
  navigationAction: IDLUIXNavigationAction;
  searchAction    : IDLUIXSearchAction;
  treeData        : TDLUIXVCLTreeStorage;
  unitName        : string;
begin
  treeData := TDLUIXVCLTreeStorage(Sender.Tag);
  searchAction := (FActionMap[treeData.SearchBox] as IDLUIXSearchAction);

  if not (assigned(searchAction.DefaultAction)
          and Supports(searchAction.DefaultAction, IDLUIXNavigationAction, navigationAction))
  then
    navigationAction := nil;

  if not assigned(node) then
    EnableActions(searchAction.ManagedActions, 0)
  else begin
    EnableActions(searchAction.ManagedActions, 1);
    if assigned(navigationAction) then
      if node.Parent = Sender.RootNode then
        navigationAction.Location := TDLUIXLocation.Create('',
          treeData.Coordinates[node.Index].UnitName, TDLCoordinate.Invalid)
      else
        navigationAction.Location := TDLUIXLocation.Create('',
          treeData.Coordinates[node.Parent.Index].UnitName,
          treeData.Coordinates[node.Parent.Index].Coordinates[node.Index]);
  end;
end; { TDLUIXVCLFloatingFrame.HandleVTFocusChanged }

procedure TDLUIXVCLFloatingFrame.InitSearchNode(Sender: TBaseVirtualTree;
  parentNode, node: PVirtualNode; var initialStates: TVirtualNodeInitStates);
begin
  if not assigned(parentNode) then
    initialStates := [ivsHasChildren]
  else
    initialStates := [];
end; { TDLUIXVCLFloatingFrame.InitSearchNode }

procedure TDLUIXVCLFloatingFrame.InitSearchNodeChildren(
  Sender: TBaseVirtualTree; node: PVirtualNode; var childCount: cardinal);
var
  treeData: TDLUIXVCLTreeStorage;
begin
  if node.Parent <> Sender.RootNode then
    childCount := 0
  else begin
    treeData := TDLUIXVCLTreeStorage(Sender.Tag);
    childCount := treeData.Coordinates[node.Index].Coordinates.Count;
  end;
end; { TDLUIXVCLFloatingFrame.InitSearchNodeChildren }

function TDLUIXVCLFloatingFrame.IsEmpty: boolean;
begin
  Result := (FForm.ClientHeight = 0);
end; { TDLUIXVCLFloatingFrame.IsEmpty }

function TDLUIXVCLFloatingFrame.IsHistoryAnalyzer(const analyzer: IDLUIXAnalyzer):
  boolean;
begin
  Result := TType.GetType((analyzer as TObject).ClassType).HasCustomAttribute<TBackNavigationAttribute>;
end; { TDLUIXVCLFloatingFrame.IsHistoryAnalyzer }

function TDLUIXVCLFloatingFrame.MakeRes(const resourceName: string): string;
begin
  Result := Format('%s_%d', [resourceName, ResourceSize]);
end; { TDLUIXVCLFloatingFrame.MakeRes }

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

function TDLUIXVCLFloatingFrame.ResourceSize: integer;
begin
  //TODO: Make DPI-dependent
  Result := 16;
end; { TDLUIXVCLFloatingFrame.ResourceSize }

procedure TDLUIXVCLFloatingFrame.SetCaption(const value: string);
begin
  Exit; //Caption panel is currently disabled
  if not assigned(FCaptionPanel) then begin
    FCaptionPanel := TPanel.Create(FForm);
    FCaptionPanel.Parent := FForm;
    FCaptionPanel.Width := CButtonWidth;
    FCaptionPanel.Height := CButtonHeightSmall;
    FCaptionPanel.Font.Size := CButtonFontSizeSmall;
    FCaptionPanel.Left := FColumnLeft;
    FCaptionPanel.Top := FColumnTop;
    FCaptionPanel.BevelOuter := bvNone;
    UpdateClientSize(FCaptionPanel.BoundsRect);
  end;
  FCaptionPanel.Caption := value;
end; { TDLUIXVCLFloatingFrame.SetCaption }

procedure TDLUIXVCLFloatingFrame.SetLocationAndOpen(listBox: TListBox; doOpen: boolean);
var
  action           : TDLUIXManagedAction;
  filterAction     : IDLUIXFilteredListAction;
  itemIdx          : integer;
  listStorage      : IDLUIXVCLListStorage;
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

  listStorage := FListMap[listBox];
  filterAction := FActionMap.Value[listStorage.SearchBox] as IDLUIXFilteredListAction;

  for action in filterAction.ManagedActions do
    if Supports(action.Action, IDLUIXOpenUnitBrowserAction, unitBrowserAction) then
      unitBrowserAction.InitialUnit := unitName;

  if assigned(filterAction.DefaultAction)
     and Supports(filterAction.DefaultAction, IDLUIXNavigationAction, navigationAction)
  then begin
    itemIdx := listBox.ItemIndex;
    if (itemIdx >= 0) and (itemIdx < listStorage.ContentIdx.Count) then
      itemIdx := listStorage.ContentIdx[itemIdx];

    navigationAction.Location := filterAction.FilterLocation(itemIdx,
      TDLUIXLocation.Create('', unitName, TDLCoordinate.Invalid));

    if doOpen then
      OnAction(Self, navigationAction);
  end;
end; { TDLUIXVCLFloatingFrame.SetLocationAndOpen }

procedure TDLUIXVCLFloatingFrame.SetOnAction(const value: TDLUIXFrameAction);
begin
  FOnAction := value;
end; { TDLUIXVCLFloatingFrame.SetOnAction }

procedure TDLUIXVCLFloatingFrame.Show(monitorNum: integer; const parentAction: IDLUIXAction);
var
  analyzerAction: IDLUIXOpenAnalyzerAction;
  isBack        : boolean;
  proc          : TProc;
  rect          : TRect;
begin
  FForm.Position := poDesigned;
  if not assigned(FParent) then begin
    rect := Screen.Monitors[monitorNum].BoundsRect;
    FForm.Left := rect.Left + (rect.Width - FForm.Width) div 2;
    FForm.Top := rect.Top + (rect.Height - FForm.Height) div 2;
  end
  else begin
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

  FForm.ShowModal;
end; { TDLUIXVCLFloatingFrame.Show }

procedure TDLUIXVCLFloatingFrame.StartSearch(Sender: TObject);
var
  treeData: IDLUIXVCLTreeStorage;
begin
  if FTreeMap.TryGetValue(TComponent(Sender), treeData) then
    DoSearch(treeData, treeData.SearchBox.Text);
end; { TDLUIXVCLFloatingFrame.StartSearch }

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
  FContentIdx := TCollections.CreateList<integer>;
  FListBox := AListBox;
  FSearchBox := ASearchBox;
  FTimer := ATimer;
end; { TDLUIXVCLListStorage.Create }

function TDLUIXVCLListStorage.GetContent: IList<string>;
begin
  Result := FContent;
end; { TDLUIXVCLListStorage.GetContent }

function TDLUIXVCLListStorage.GetContentIdx: IList<integer>;
begin
  Result := FContentIdx;
end; { TDLUIXVCLListStorage.GetContentIdx }

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

{ TDLUIXVCLTreeStorage }

constructor TDLUIXVCLTreeStorage.Create(AVirtualTree: TVirtualStringTree;
  ASearchBox: TSearchBox; ATimer: TTimer);
begin
  inherited Create;
  FVirtualTree := AVirtualTree;
  FSearchBox := ASearchBox;
  FTimer := ATimer;
end; { TDLUIXVCLTreeStorage.Create }

function TDLUIXVCLTreeStorage.GetCoordinates: ICoordinates;
begin
  Result := FCoordinates;
end; { TDLUIXVCLTreeStorage.GetCoordinates }

function TDLUIXVCLTreeStorage.GetSearchBox: TSearchBox;
begin
  Result := FSearchBox;
end; { TDLUIXVCLTreeStorage.GetSearchBox }

function TDLUIXVCLTreeStorage.GetSearchTimer: TTimer;
begin
  Result := FTimer;
end; { TDLUIXVCLTreeStorage.GetSearchTimer }

function TDLUIXVCLTreeStorage.GetVirtualTree: TVirtualStringTree;
begin
  Result := FVirtualTree;
end; { TDLUIXVCLTreeStorage.GetVirtualTree }

procedure TDLUIXVCLTreeStorage.SetCoordinates(const value: ICoordinates);
begin
  FCoordinates := value;
end; { TDLUIXVCLTreeStorage.SetCoordinates }

end.
