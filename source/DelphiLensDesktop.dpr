program DelphiLensDesktop;

uses
  Vcl.Forms,
  DelphiLensDesktop.Main in 'DelphiLensDesktop.Main.pas' {frmDLMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDLMain, frmDLMain);
  Application.Run;
end.
