unit DelphiLensUI.UIXEngine.VCLFloating;

interface

uses
  DelphiLensUI.UIXEngine.Intf;

//TODO: Treat backspace as hotkey for "History"
//TODO: Don't add to history if current location = new location
//TODO: Lists should change width according to the item
//TODO: Nicer buttons ...

function CreateUIXEngine: IDLUIXEngine;

implementation

uses
  Winapi.Windows,
  System.Types, System.RTTI, System.SysUtils, System.Classes, System.Math,
  Vcl.StdCtrls, Vcl.Controls, Vcl.Forms,
  Spring, Spring.Collections, Spring.Reflection,
  GpStuff, GpEasing,
  DelphiLensUI.UIXAnalyzer.Intf, DelphiLensUI.UIXAnalyzer.Attributes,
  DelphiLensUI.UIXEngine.Actions;

type
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
    function GetBounds_Screen(const action: IDLUIXAction): TRect;
  end; { IDLUIXVCLFloatingFrame }

  TDLUIXVCLFloatingFrame = class(TManagedInterfacedObject, IDLUIXFrame,
                                                           IDLUIXVCLFloatingFrame)
  strict private const
    CAlphaBlendActive     = 255;
    CAlphaBlendInactive   =  64;
    CButtonHeight         =  81;
    CButtonSpacing        =  15;
    CButtonWidth          = 201;
    CFrameSpacing         =  15;
    CInactiveFrameOverlap = 21;
    CListButtonHeight     =  25;
    CListButtonSpacing    =   3;
    CListButtonWidth      = 254;
  var
    [Managed(false)] FActionMap: IBidiDictionary<TObject, IDLUIXAction>;
    [Managed(false)] FForm     : TVCLFloatingForm;
  var
    FEasing       : IEasing;
    FEasingPos    : IEasing;
    FHistoryButton: TButton;
    FOnAction     : TDLUIXFrameAction;
    FOriginalLeft : Nullable<integer>;
    FParent       : IDLUIXFrame;
    FTargetLeft   : Nullable<integer>;
  strict protected
    function  BuildButton(const action: IDLUIXAction): integer;
    function  BuildList(const listNavigation: IDLUIXListNavigationAction): integer;
    procedure EaseAlphaBlend(start, stop: integer);
    procedure EaseLeft(start, stop: integer);
    procedure ForwardAction(Sender: TObject);
    function  GetOnAction: TDLUIXFrameAction;
    function  GetParent: IDLUIXFrame;
    function  GetParentRect(const action: IDLUIXAction = nil): TRect;
    function  IsHistoryAnalyzer(const analyzer: IDLUIXAnalyzer): boolean;
    procedure SetOnAction(const value: TDLUIXFrameAction);
  public
    constructor Create(const parentFrame: IDLUIXFrame);
    // IDLUIXVCLFloatingFrame
    function  GetBounds_Screen(const action: IDLUIXAction): TRect;
    // IDLUIXFrame
    procedure Close;
    procedure CreateAction(const action: IDLUIXAction);
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

{ TVCLFloatingForm }

constructor TVCLFloatingForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  inherited;
  OnKeyDown := HandleKeyDown;
end;

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
  FParent := parentFrame;
  FForm := TVCLFloatingForm.CreateNew(Application);
  FForm.BorderStyle := bsNone;
  FForm.ClientWidth := CButtonWidth;
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

function TDLUIXVCLFloatingFrame.BuildButton(const action: IDLUIXAction): integer;
var
  button      : TButton;
  openAnalyzer: IDLUIXOpenAnalyzerAction;
begin
  button := TButton.Create(FForm);
  button.Parent := FForm;
  button.Width := CButtonWidth;
  button.Height := CButtonHeight;
  button.Left := 0;
  button.Top := FForm.ClientHeight + IFF(FForm.ClientHeight = 0, 0, CButtonSpacing);

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

  FActionMap.Add(button, action);

  Result := button.BoundsRect.Bottom;
end; { TDLUIXVCLFloatingFrame.BuildButton }

function TDLUIXVCLFloatingFrame.BuildList(const listNavigation:
  IDLUIXListNavigationAction): integer;
var
  button    : TButton;
  hotkey    : string;
  navigation: IDLUIXNavigationAction;
  nextTop   : integer;
begin
  nextTop := 0;
  Result := 0;
  button := nil;

  hotkey := '1';
  for navigation in listNavigation.Locations do begin
    button := TButton.Create(FForm);
    button.Parent := FForm;
    button.Width := CListButtonWidth;
    button.Height := CListButtonHeight;
    button.Left := 0;
    button.Top := nextTop;
    button.Caption := IFF(hotkey = '', '  ', '&' + hotkey + ' ') + navigation.Name;
    button.OnClick := ForwardAction;

    FForm.Width := Max(FForm.Width, button.Width);

    FActionMap.Add(button, navigation);

    nextTop := button.Top + button.Height + CListButtonSpacing;
    if hotkey = '9' then
      hotkey := ''
    else if hotkey <> '' then
      hotkey := Chr(Ord(hotkey[1]) + 1);
  end; //for namedLocation

  if assigned(button) then
    Result := button.BoundsRect.Bottom;
end; { TDLUIXVCLFloatingFrame.BuildList }

procedure TDLUIXVCLFloatingFrame.Close;
begin
  FForm.Close;
end; { TDLUIXVCLFloatingFrame.Close }

procedure TDLUIXVCLFloatingFrame.CreateAction(const action: IDLUIXAction);
var
  historyList: IDLUIXListNavigationAction;
begin
  if Supports(action, IDLUIXListNavigationAction, historyList) then
    FForm.ClientHeight := Max(FForm.ClientHeight, BuildList(historyList))
  else
    FForm.ClientHeight := Max(FForm.ClientHeight, BuildButton(action));
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

procedure TDLUIXVCLFloatingFrame.SetOnAction(const value: TDLUIXFrameAction);
begin
  FOnAction := value;
end; { TDLUIXVCLFloatingFrame.SetOnAction }

procedure TDLUIXVCLFloatingFrame.Show(const parentAction: IDLUIXAction);
var
  analyzerAction: IDLUIXOpenAnalyzerAction;
  isBack        : boolean;
  rect          : TRect;
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
      FForm.Left := rect.Right + CFrameSpacing;
    FForm.Top := rect.Top + (rect.Height - FForm.Height) div 2;
  end;
  FForm.UpdateMask;
  FForm.ShowModal;
end; { TDLUIXVCLFloatingFrame.Show }

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

end.
