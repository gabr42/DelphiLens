program DelphiLensUITest;

uses
  Vcl.Forms,
  DelphiLensUITest.Main in 'DelphiLensUITest.Main.pas' {frmDLUITestMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDLUITestMain, frmDLUITestMain);
  Application.Run;
end.
