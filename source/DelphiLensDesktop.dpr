program DelphiLensDesktop;

uses
  Vcl.Forms,
  DelphiLensDesktop.Main in 'DelphiLensDesktop.Main.pas' {frmDLMain},
  DelphiLens.DelphiASTHelpers in 'DelphiLens.DelphiASTHelpers.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDLMain, frmDLMain);
  Application.Run;
end.
