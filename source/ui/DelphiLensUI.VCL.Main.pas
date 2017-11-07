unit DelphiLensUI.VCL.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DelphiLensUI.VCL.Form2;

type
  TfrmDLMain = class(TForm)
    btnClose: TButton;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    Form2: TForm1;
  protected
    procedure UpdateShadow;
  public
  end;

procedure DLUIShowForm;

implementation

uses
  VCL.Styles,
  VCL.Themes;

{$R *.dfm}

procedure DLUIShowForm;
var
  frm: TfrmDLMain;
begin
  TStyleManager.TrySetStyle('Cobalt XEMedia', false);
  Application.Title := 'DelphiLens';
  Application.MainFormOnTaskBar := false;
  frm := TfrmDLMain.Create(Application);
  frm.ShowModal;
  FreeAndNil(frm);
  Application.ProcessMessages;
end;

procedure TfrmDLMain.FormCreate(Sender: TObject);
begin
  UpdateShadow;
end;

procedure TfrmDLMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmDLMain.Button1Click(Sender: TObject);
var
  i: Integer;
begin
  for i := 1 to 100 do begin
    Left := Left - 1;
    Application.ProcessMessages;
    Sleep(5);
  end;
end;

procedure TfrmDLMain.UpdateShadow;
var
  pnt: TPoint;
  rgn, rgnCtrl: HRGN;
  i: Integer;
begin
  pnt := ClientToScreen(Point(0, 0));
  rgn := 0;
  for i := 0 to ControlCount - 1 do
    if Controls[i].Tag = 1 then
    begin
      if not (Controls[i] is TWinControl) then Continue;
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
end;

end.
