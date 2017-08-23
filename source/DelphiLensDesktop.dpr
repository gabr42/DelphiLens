program DelphiLensDesktop;

uses
  Vcl.Forms,
  DelphiLensDesktop.Main in 'DelphiLensDesktop.Main.pas' {frmDLMain},
  DelphiLens.Intf in 'DelphiLens.Intf.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDLMain, frmDLMain);
  Application.Run;
end.
