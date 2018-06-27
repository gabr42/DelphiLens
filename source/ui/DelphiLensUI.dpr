program DelphiLensUI;

{$R 'bitmaps.res' '..\res\bitmaps.rc'}

uses
  Vcl.Forms,
  DelphiLensUI.Main in 'DelphiLensUI.Main.pas' {frmMainHidden};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.ShowMainForm := false;
  Application.CreateForm(TfrmMainHidden, frmMainHidden);
  Application.Run;
end.
