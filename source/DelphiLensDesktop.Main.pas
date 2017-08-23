unit DelphiLensDesktop.Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmDLMain = class(TForm)
    btnRescan     : TButton;
    btnSelect     : TButton;
    dlgOpenProject: TFileOpenDialog;
    inpDefines    : TEdit;
    inpProject    : TEdit;
    inpSearchPath : TEdit;
    lblDefines    : TLabel;
    lblProject    : TLabel;
    lblSearchPath : TLabel;
    procedure btnSelectClick(Sender: TObject);
  private
  public
  end;

var
  frmDLMain: TfrmDLMain;

implementation

{$R *.dfm}

procedure TfrmDLMain.btnSelectClick(Sender: TObject);
begin
  if dlgOpenProject.Execute then
    inpProject.Text := dlgOpenProject.FileName;
end;

end.
