unit DelphiLensDesktop.Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DelphiLens.Intf;

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
    outLog        : TMemo;
    procedure btnRescanClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure inpProjectChange(Sender: TObject);
    procedure SettingExit(Sender: TObject);
  private const
    CSettingsKey = '\SOFTWARE\Gp\DelphiLens\DelphiLensDesktop';
    CSettingsProject            = 'Project';
    CSettingsSearchPath         = 'SearchPath';
    CSettingsConditionalDefines = 'ConditionalDefines';
  var
    FDelphiLens: IDelphiLens;
    FLoading: boolean;
  protected
    procedure LoadSettings;
    procedure SaveSettings;
  public
  end;

var
  frmDLMain: TfrmDLMain;

implementation

uses
  DSiWin32,
  GpVCL,
  DelphiLens;

{$R *.dfm}

procedure TfrmDLMain.btnRescanClick(Sender: TObject);
begin
  if not assigned(FDelphiLens) then
    FDelphiLens := CreateDelphiLens(inpProject.Text);
  FDelphiLens.SearchPath := inpSearchPath.Text;
  FDelphiLens.ConditionalDefines := inpDefines.Text;
  with AutoRestoreCursor(crHourGlass) do begin
    FDelphiLens.Rescan;
    outLog.Text := Format('Scanned files: %d'#13#10'Cached files: %d',
      [FDelphiLens.Cache.Statistics.NumScanned, FDelphiLens.Cache.Statistics.NumCached]);
  end;
end;

procedure TfrmDLMain.FormCreate(Sender: TObject);
begin
  LoadSettings;
end;

procedure TfrmDLMain.btnSelectClick(Sender: TObject);
begin
  if dlgOpenProject.Execute then begin
    inpProject.Text := dlgOpenProject.FileName;
    FDelphiLens := nil;
  end;
end;

procedure TfrmDLMain.inpProjectChange(Sender: TObject);
begin
  SaveSettings;
end;

procedure TfrmDLMain.LoadSettings;
begin
  FLoading := true;
  inpProject.Text := DSiReadRegistry(CSettingsKey, CSettingsProject, '');
  inpSearchPath.Text := DSiReadRegistry(CSettingsKey, CSettingsSearchPath, '');
  inpDefines.Text := DSiReadRegistry(CSettingsKey, CSettingsConditionalDefines, '');
  FLoading := false;
end;

procedure TfrmDLMain.SaveSettings;
begin
  if FLoading then
    Exit;

  DSiWriteRegistry(CSettingsKey, CSettingsProject, inpProject.Text);
  DSiWriteRegistry(CSettingsKey, CSettingsSearchPath, inpSearchPath.Text);
  DSiWriteRegistry(CSettingsKey, CSettingsConditionalDefines, inpDefines.Text);
end;

procedure TfrmDLMain.SettingExit(Sender: TObject);
begin
  SaveSettings;
end;

end.
