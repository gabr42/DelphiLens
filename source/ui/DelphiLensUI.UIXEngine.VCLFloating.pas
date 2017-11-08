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
  DelphiLensUI.UIXAnalyzer.Intf;

type
  TVCLFloatingForm = class(TForm)
  strict protected
    procedure FormCreate(Sender: TObject);
    procedure UpdateMask;
  public
    constructor Create(AOwner: TComponent); override;
  end; { TVCLFloatingForm }

  TDLUIXVCLFloatingEngine = class(TInterfacedObject, IDLUIXEngine)
  strict private const
    CDefaultButtonWidth  = 201;
    CDefaultButtonHeight =  81;
    CDefaultSpacing      =  15;
  var
    FForm: TVCLFloatingForm;
  public
    procedure CompleteFrame;
    procedure CreateAction(const analyzerInfo: TDLAnalyzerInfo);
    procedure CreateFrame;
    procedure DestroyFrame;
    procedure ShowFrame;
  end; { TDLUIXVCLFloatingEngine }

{ exports }

function CreateUIXEngine: IDLUIXEngine;
begin
  Result := TDLUIXVCLFloatingEngine.Create;
end; { CreateUIXEngine }

{ TDLUIXVCLFloatingEngine }

procedure TDLUIXVCLFloatingEngine.CompleteFrame;
begin
  // do nothing
end; { TDLUIXVCLFloatingEngine.CompleteFrame }

procedure TDLUIXVCLFloatingEngine.CreateAction(const analyzerInfo: TDLAnalyzerInfo);
var
  button: TButton;
begin
  if FForm.ClientHeight = 0 then
    FForm.ClientHeight := CDefaultButtonHeight
  else
    FForm.ClientHeight := FForm.ClientHeight + CDefaultButtonHeight + CDefaultSpacing;

  button := TButton.Create(FForm);
  button.Parent := FForm;
  button.Left := 0;
  button.Top := FForm.ClientHeight - CDefaultButtonHeight;
end; { TDLUIXVCLFloatingEngine.CreateAction }

procedure TDLUIXVCLFloatingEngine.CreateFrame;
begin
  FForm := TVCLFloatingForm.CreateNew(Application);
  FForm.BorderStyle := bsNone;
  FForm.Position := poScreenCenter;
  FForm.ClientWidth := CDefaultButtonWidth;
  FForm.ClientHeight := 0;
end; { TDLUIXVCLFloatingEngine.CreateFrame }

procedure TDLUIXVCLFloatingEngine.DestroyFrame;
begin
  FreeAndNil(FForm);
end; { TDLUIXVCLFloatingEngine.DestroyFrame }

procedure TDLUIXVCLFloatingEngine.ShowFrame;
begin
  TStyleManager.TrySetStyle('Cobalt XEMedia', false);
  Application.Title := 'DelphiLens';
  Application.MainFormOnTaskBar := false;
  FForm.ShowModal;
end; { TDLUIXVCLFloatingEngine.ShowFrame }

{ TVCLFloatingForm }

constructor TVCLFloatingForm.Create(AOwner: TComponent);
begin
  inherited;
  OnCreate := FormCreate;
end;

procedure TVCLFloatingForm.FormCreate(Sender: TObject);
begin
  UpdateMask;
end;

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

end.
