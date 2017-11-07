unit DelphiLensUI.VCL.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmDLMain = class(TForm)
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
  private
  public
  end;

procedure DLUIShowForm;

implementation

{$R *.dfm}

procedure DLUIShowForm;
var
  frm: TfrmDLMain;
begin
  Application.Title := 'DelphiLens';
  Application.MainFormOnTaskBar := false;
  frm := TfrmDLMain.Create(Application);
  frm.ShowModal;
  FreeAndNil(frm);
  Application.ProcessMessages;
end;

procedure TfrmDLMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
