unit DelphiLensUI.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TfrmDLMain = class(TForm)
    btnClose: TButton;
    StyleBook1: TStyleBook;
    procedure btnCloseClick(Sender: TObject);
  private
  public
  end;

var
  frmDLMain: TfrmDLMain;

procedure DLUIShowForm;

implementation

uses
  Winapi.Windows,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ;

{$R *.fmx}

procedure DLUIShowForm;
var
  frm: TfrmDLMain;
  i: Integer;
begin
  Application.Initialize;
  frm := TfrmDLMain.Create(Application);
  frm.ShowModal;
//  frm.Release;
  frm.Free;
  Application.Terminate;
end;

procedure TfrmDLMain.btnCloseClick(Sender: TObject);
begin
//  Application.Terminate;
//  ModalResult := mrOK;
  Close;
end;

end.
