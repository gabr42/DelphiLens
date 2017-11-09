unit DelphiLensUI.UIXEngine.VCLFloating;

interface

uses
  DelphiLensUI.UIXEngine.Intf;

function CreateUIXEngine: IDLUIXEngine;

implementation

uses
  Winapi.Windows,
  System.Types, System.SysUtils, System.Classes,
  Spring, Spring.Collections,
  Vcl.StdCtrls, Vcl.Controls, Vcl.Forms, Vcl.Styles, Vcl.Themes,
  DelphiLensUI.UIXAnalyzer.Intf;

type
  TVCLFloatingForm = class(TForm)
  protected
    procedure ExitOnEscape(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    procedure UpdateMask;
  end; { TVCLFloatingForm }

  TDLUIXVCLFloatingFrame = class(TManagedInterfacedObject, IDLUIXFrame)
  strict private const
    CDefaultButtonWidth  = 201;
    CDefaultButtonHeight =  81;
    CDefaultSpacing      =  15;
  var
    [Managed(false)] FActionMap: IDictionary<TObject, IDLUIXAction>;
    [Managed(false)] FForm     : TVCLFloatingForm;
  var
    FOnAction: TDLUIXFrameAction;
    FParent  : IDLUIXFrame;
  strict protected
    procedure ForwardAction(Sender: TObject);
    function  GetOnAction: TDLUIXFrameAction;
    procedure SetOnAction(const value: TDLUIXFrameAction);
  public
    constructor Create(const parentFrame: IDLUIXFrame);
    procedure CreateAction(const action: IDLUIXAction);
    procedure Show;
    property OnAction: TDLUIXFrameAction read GetOnAction write SetOnAction;
  end; { TDLUIXVCLFloatingFrame }

  TDLUIXVCLFloatingEngine = class(TInterfacedObject, IDLUIXEngine)
  public
    procedure CompleteFrame(const frame: IDLUIXFrame);
    function  CreateFrame(const parentFrame: IDLUIXFrame): IDLUIXFrame;
    procedure DestroyFrame(var frame: IDLUIXFrame);
    procedure ShowFrame(const frame: IDLUIXFrame);
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
  FActionMap := TCollections.CreateDictionary<TObject, IDLUIXAction>;
  FParent := parentFrame;
  FForm := TVCLFloatingForm.CreateNew(Application);
  FForm.BorderStyle := bsNone;
  FForm.Position := poScreenCenter;
  FForm.ClientWidth := CDefaultButtonWidth;
  FForm.ClientHeight := 0;
  FForm.AlphaBlend := true;
  FForm.AlphaBlendValue := 192;
  FForm.KeyPreview := true;
  FForm.OnKeyDown := FForm.ExitOnEscape;
end; { TDLUIXVCLFloatingFrame.Create }

procedure TDLUIXVCLFloatingFrame.CreateAction(const action: IDLUIXAction);
var
  button: TButton;
begin
  if FForm.ClientHeight = 0 then
    FForm.ClientHeight := CDefaultButtonHeight
  else
    FForm.ClientHeight := FForm.ClientHeight + CDefaultButtonHeight + CDefaultSpacing;

  button := TButton.Create(FForm);
  button.Parent := FForm;
  button.Width := CDefaultButtonWidth;
  button.Height := CDefaultButtonHeight;
  button.Left := 0;
  button.Top := FForm.ClientHeight - CDefaultButtonHeight;
  button.Caption := action.Name + ' >';
  button.OnClick := ForwardAction;

  FActionMap.Add(button, action);
end; { TDLUIXVCLFloatingFrame.CreateAction }

procedure TDLUIXVCLFloatingFrame.ForwardAction(Sender: TObject);
begin
  if assigned(OnAction) then
    OnAction(Self, FActionMap[Sender]);
end; { TDLUIXVCLFloatingFrame.ForwardAction }

function TDLUIXVCLFloatingFrame.GetOnAction: TDLUIXFrameAction;
begin
  Result := FOnAction;
end; { TDLUIXVCLFloatingFrame.GetOnAction }

procedure TDLUIXVCLFloatingFrame.SetOnAction(const value: TDLUIXFrameAction);
begin
  FOnAction := value;
end; { TDLUIXVCLFloatingFrame.SetOnAction }

procedure TDLUIXVCLFloatingFrame.Show;
begin
  FForm.UpdateMask;
  FForm.ShowModal;
end; { TDLUIXVCLFloatingFrame.Show }

{ TDLUIXVCLFloatingEngine }

procedure TDLUIXVCLFloatingEngine.CompleteFrame(const frame: IDLUIXFrame);
begin
  // do nothing
end; { TDLUIXVCLFloatingEngine.CompleteFrame }

function TDLUIXVCLFloatingEngine.CreateFrame(const parentFrame: IDLUIXFrame): IDLUIXFrame;
begin
  Result := TDLUIXVCLFloatingFrame.Create(parentFrame);
end; { TDLUIXVCLFloatingEngine.CreateFrame }

procedure TDLUIXVCLFloatingEngine.DestroyFrame(var frame: IDLUIXFrame);
begin
  frame := nil;
end; { TDLUIXVCLFloatingEngine.DestroyFrame }

procedure TDLUIXVCLFloatingEngine.ShowFrame(const frame: IDLUIXFrame);
begin
  TStyleManager.TrySetStyle('Cobalt XEMedia', false);
  Application.Title := 'DelphiLens';
  Application.MainFormOnTaskBar := false;
  frame.Show;
end; { TDLUIXVCLFloatingEngine.ShowFrame }

end.
