unit DelphiLensDesktop.Test;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Themes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.ImageList,
  Vcl.ImgList, Vcl.Buttons,
  GpVCL.OwnerDrawBitBtn;

type
  TfrmTest = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
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
  Vcl.Imaging.PNGImage,
  GpVCL;

{$R *.dfm}

procedure TfrmTest.Button2Click(Sender: TObject);
begin
  BitBtn1.Enabled := not BitBtn1.Enabled;
end;

procedure TfrmTest.DrawBitBtn(button: TOwnerDrawBitBtn; canvas: TCanvas;
  drawRect: TRect; buttonState: TThemedButton);

  function ResourceName(tag: integer): string;
  begin
    case tag of
      1: Result := 'IDD_ANGLE_RIGHT_16';
      2: Result := 'IDD_ANGLE_LEFT_16';
      3: Result := 'IDD_SHARE_16';
      else raise Exception.Create('Unexpected tag!');
    end;
  end;

var
  png : TPngImage;
  imgX: integer;
begin
  png := TPngImage.Create;
  try
    png.LoadFromResourceName(HInstance, ResourceName(Abs(button.Tag)));
    if button.Tag < 0 then
      imgX := drawRect.Left + 8
    else
      imgX := drawRect.Right - 8 - png.Width;
    canvas.Draw(imgX, drawRect.Top + (drawRect.Height - png.Height) div 2, png);

    drawRect.Left := drawRect.Left + 16;
    if button.Height > 53 then
      drawRect.Left := drawRect.Left + png.Width;

    drawRect.Bottom := drawRect.Bottom - 2; // looks better
    button.DrawText(button.Caption, drawRect, DT_NOCLIP or DT_LEFT or DT_VCENTER or DT_SINGLELINE)
  finally FreeAndNil(png); end;
end;

procedure TfrmTest.FormShow(Sender: TObject);
var
  bitbtn: TBitBtn;
begin
  for bitbtn in EnumControls<TBitBtn> do
    bitbtn.OnOwnerDraw := DrawBitBtn;
end;

end.
