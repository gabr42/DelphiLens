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

{$R *.fmx}

procedure DLUIShowForm;
var
  frm: TfrmDLMain;
begin
//  Application.Initialize;
//  Application.CreateForm(TfrmDLMain, frm);
//  Application.Run;

  frm := TfrmDLMain.Create(Application);
  try
    frm.ShowModal;
//    frm.Release;
//    Application.Terminate;
  finally FreeAndNil(frm); end;
  Application.ProcessMessages;
end;

procedure TfrmDLMain.btnCloseClick(Sender: TObject);
begin
//  Application.Terminate;
  Close;
end;

end.
