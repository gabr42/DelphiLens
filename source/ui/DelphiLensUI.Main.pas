unit DelphiLensUI.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  DelphiLensUI.IPC.Intf;

type
  TfrmMainHidden = class(TForm)
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    FIPCServer: IDLUIIPCServer;
  public
  end;

var
  frmMainHidden: TfrmMainHidden;

implementation

uses
  DelphiLensUI.IPC.Server;

{$R *.dfm}

procedure TfrmMainHidden.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if assigned(FIPCServer) then begin
    FIPCServer.Stop;
    FIPCServer := nil;
  end;
  CanClose := true;
end;

procedure TfrmMainHidden.FormCreate(Sender: TObject);
var
  err: string;
begin
  FIPCServer := CreateIPCServer;
  FIPCServer.OnError :=
    procedure (msg: string)
    begin
      ShowMessage('IPC Server error: ' + msg);
    end;
  err := FIPCServer.Start;
  if err <> '' then begin
    ShowMessage('Failed to start IPC server!'#13#10#13#10 + err + #13#10#13#10'This application will now close.');
    Application.Terminate;
  end;
end;

end.
