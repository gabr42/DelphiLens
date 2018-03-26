program DelphiLensDesktop;

uses
  FastMM4,
  Vcl.Forms,
  DelphiLensDesktop.Main in 'DelphiLensDesktop.Main.pas' {frmDLMain},
  DelphiLensDesktop.Test in 'DelphiLensDesktop.Test.pas' {frmTest};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDLMain, frmDLMain);
  Application.CreateForm(TfrmTest, frmTest);
  Application.Run;
end.
