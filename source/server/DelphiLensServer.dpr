program DelphiLensServer;

uses
  Vcl.Forms,
  DelphiLensServer.Main in 'DelphiLensServer.Main.pas' {frmDelphiLensServer},
  DelphiLensServer.Connection in 'DelphiLensServer.Connection.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDelphiLensServer, frmDelphiLensServer);
  Application.Run;
end.
