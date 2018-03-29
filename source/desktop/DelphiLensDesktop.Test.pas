unit DelphiLensDesktop.Test;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Themes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.ImageList,
  Vcl.ImgList, Vcl.Buttons,
  GpVCL.OwnerDrawBitBtn;

type
  TfrmTest = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ImageList1: TImageList;
    BitBtn1: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    procedure DrawBitBtn(button: TOwnerDrawBitBtn; canvas: TCanvas; drawRect: TRect;
  buttonState: TThemedButton);
  public
    { Public declarations }
  end;

var
  frmTest: TfrmTest;

implementation

uses
  GpVCL;

{$R *.dfm}

procedure TfrmTest.Button2Click(Sender: TObject);
begin
  BitBtn1.Enabled := not BitBtn1.Enabled;
end;

procedure TfrmTest.DrawBitBtn(button: TOwnerDrawBitBtn; canvas: TCanvas;
  drawRect: TRect; buttonState: TThemedButton);
begin
  ImageList1.Draw(canvas, drawRect.Left + 8,
    drawRect.Top + (drawRect.Height - ImageList1.Height) div 2,
    0, dsNormal, itImage, button.Enabled);

  drawRect.Left := drawRect.Left + 8 + ImageList1.Width + 8;
  button.DrawText(button.Caption, drawRect, DT_NOCLIP or DT_LEFT or DT_VCENTER or DT_SINGLELINE)
end;

procedure TfrmTest.FormShow(Sender: TObject);
var
  button: TButton;
begin
  BitBtn1.OnOwnerDraw := DrawBitBtn;

  for button in EnumControls<TButton> do
    SetWindowLong(button.Handle, GWL_STYLE, GetWindowLong(button.Handle, GWL_STYLE) OR BS_LEFT);
end;

end.
