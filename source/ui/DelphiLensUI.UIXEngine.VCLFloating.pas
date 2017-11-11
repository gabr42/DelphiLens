unit DelphiLensUI.UIXEngine.VCLFloating;

interface

uses
  DelphiLensUI.UIXEngine.Intf;

function CreateUIXEngine: IDLUIXEngine;

implementation

uses
  Winapi.Windows,
  System.Types, System.SysUtils, System.Classes,
  Vcl.StdCtrls, Vcl.Controls, Vcl.Forms, Vcl.Styles, Vcl.Themes,
  Spring, Spring.Collections,
  GpStuff, GpEasing,
  DelphiLensUI.UIXAnalyzer.Intf, DelphiLensUI.UIXEngine.Actions;

type
  TVCLFloatingForm = class(TForm)
  protected
    procedure ExitOnEscape(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    procedure UpdateMask;
  end; { TVCLFloatingForm }

  IDLUIXVCLFloatingFrame = interface ['{43127F61-07EE-466F-BAB2-E39B811AFB2F}']
    function GetBounds_Screen(const action: IDLUIXAction): TRect;
  end; { IDLUIXVCLFloatingFrame }

  TDLUIXVCLFloatingFrame = class(TManagedInterfacedObject, IDLUIXFrame,
                                                           IDLUIXVCLFloatingFrame)
  strict private const
    CAlphaBlendActive    = 192;
    CAlphaBlendInactive  =  64;
    CButtonWidth         = 201;
    CButtonHeight        =  81;
    CButtonSpacing       =  15;
    CFrameSpacing        =  15;
  var
    [Managed(false)] FGUIToActionMap: IDictionary<TObject, IDLUIXAction>;
    [Managed(false)] FActionToGUIMap: IDictionary<IDLUIXAction, TObject>;
    [Managed(false)] FForm          : TVCLFloatingForm;
  var
    FEasing  : IEasing;
    FOnAction: TDLUIXFrameAction;
    FParent  : IDLUIXFrame;
  strict protected
    procedure ForwardAction(Sender: TObject);
    function  GetOnAction: TDLUIXFrameAction;
    procedure SetOnAction(const value: TDLUIXFrameAction);
  public
    constructor Create(const parentFrame: IDLUIXFrame);
    // IDLUIXVCLFloatingFrame
    function  GetBounds_Screen(const action: IDLUIXAction): TRect;
    // IDLUIXFrame
    procedure Close;
    procedure CreateAction(const action: IDLUIXAction);
    procedure MarkActive(isActive: boolean);
    procedure Show(const parentAction: IDLUIXAction);
    property OnAction: TDLUIXFrameAction read GetOnAction write SetOnAction;
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

procedure TVCLFloatingForm.ExitOnEscape(Sender: TObject; var Key: Word; Shift:
  TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end; { TVCLFloatingForm.ExitOnEscape }

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
  FGUIToActionMap := TCollections.CreateDictionary<TObject, IDLUIXAction>;
  FActionToGUIMAP := TCollections.CreateDictionary<IDLUIXAction, TObject>;
  FParent := parentFrame;
  FForm := TVCLFloatingForm.CreateNew(Application);
  FForm.BorderStyle := bsNone;
  FForm.ClientWidth := CButtonWidth;
  FForm.ClientHeight := 0;
  FForm.AlphaBlend := true;
  FForm.KeyPreview := true;
  FForm.AlphaBlendValue := CAlphaBlendActive;
  FForm.OnKeyDown := FForm.ExitOnEscape;
end; { TDLUIXVCLFloatingFrame.Create }

procedure TDLUIXVCLFloatingFrame.Close;
begin
  FForm.Close;
end; { TDLUIXVCLFloatingFrame.Close }

procedure TDLUIXVCLFloatingFrame.CreateAction(const action: IDLUIXAction);
var
  button      : TButton;
  openAnalyzer: IDLUIXOpenAnalyzerAction;
begin
  if FForm.ClientHeight = 0 then
    FForm.ClientHeight := CButtonHeight
  else
    FForm.ClientHeight := FForm.ClientHeight + CButtonHeight + CButtonSpacing;

  button := TButton.Create(FForm);
  button.Parent := FForm;
  button.Width := CButtonWidth;
  button.Height := CButtonHeight;
  button.Left := 0;
  button.Top := FForm.ClientHeight - CButtonHeight;
  if Supports(action, IDLUIXOpenAnalyzerAction, openAnalyzer) then
    button.Caption := action.Name + ' >'
  else
    button.Caption := action.Name;
  button.OnClick := ForwardAction;

  FGUIToActionMap.Add(button, action);
  FActionToGUIMap.Add(action, button);
end; { TDLUIXVCLFloatingFrame.CreateAction }

procedure TDLUIXVCLFloatingFrame.ForwardAction(Sender: TObject);
begin
  if assigned(OnAction) then
    OnAction(Self, FGUIToActionMap[Sender]);
end; { TDLUIXVCLFloatingFrame.ForwardAction }

function TDLUIXVCLFloatingFrame.GetBounds_Screen(const action: IDLUIXAction): TRect;
var
  control: TObject;
begin
  if not (FActionToGUIMap.TryGetValue(action, control)
          and (control is TControl))
  then
    Result := TRect.Empty
  else begin
    Result := TControl(control).BoundsRect;
    Result.TopLeft := FForm.ClientToScreen(Result.TopLeft);
    Result.BottomRight := FForm.ClientToScreen(Result.BottomRight);
  end;
end; { TDLUIXVCLFloatingFrame.GetBounds_Screen }

function TDLUIXVCLFloatingFrame.GetOnAction: TDLUIXFrameAction;
begin
  Result := FOnAction;
end; { TDLUIXVCLFloatingFrame.GetOnAction }

procedure TDLUIXVCLFloatingFrame.MarkActive(isActive: boolean);
var
  newAlphaBlend: integer;
begin
  newAlphaBlend := IFF(isActive, CAlphaBlendActive, CAlphaBlendInactive);
  FEasing := Easing.InOutCubic(FForm.AlphaBlendValue, newAlphaBlend, 500, 10,
    procedure (value: integer)
    begin
      if not (csDestroying in FForm.ComponentState) then
        FForm.AlphaBlendValue := value;
    end);
end; { TDLUIXVCLFloatingFrame.MarkActive }

procedure TDLUIXVCLFloatingFrame.SetOnAction(const value: TDLUIXFrameAction);
begin
  FOnAction := value;
end; { TDLUIXVCLFloatingFrame.SetOnAction }

procedure TDLUIXVCLFloatingFrame.Show(const parentAction: IDLUIXAction);
var
  rect: TRect;
begin
  if not assigned(FParent) then
    FForm.Position := poScreenCenter
  else begin
    FForm.Position := poDesigned;
    rect := (FParent as IDLUIXVCLFloatingFrame).GetBounds_Screen(parentAction);
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
  TStyleManager.TrySetStyle('Cobalt XEMedia', false);
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
