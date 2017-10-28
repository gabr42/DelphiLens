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
  frm := TfrmDLMain.Create(Application);
  try
    frm.ShowModal;
  finally FreeAndNil(frm); end;
end;

end.
