unit DelphiLensUI.Main;

interface

uses
  DelphiLens.Intf;

procedure DLUIShowUI(const projectInfo: IDLScanResult; const fileName: string;
  line, column: integer);

implementation

uses
  System.SysUtils,
  DelphiLensUI.UIXEngine.Intf,
  DelphiLensUI.UIXEngine.VCLFloating;

type
  TDLUserInterface = class
  strict private
    FColumn     : integer;
    FFileName   : string;
    FLine       : integer;
    FProjectInfo: IDLScanResult;
    FUIXEngine  : IDLUIXEngine;
  public
    constructor Create(const uixEngine: IDLUIXEngine);
    procedure Activate;
    procedure Build(const projectInfo: IDLScanResult; const fileName: string;
      const line, column: integer);
    procedure Teardown;
  end; { TDLUserInterface }

{ exports }

procedure DLUIShowUI(const projectInfo: IDLScanResult; const fileName: string;
  line, column: integer);
var
  ui: TDLUserInterface;
begin
  ui := TDLUserInterface.Create(CreateUIXEngine);
  try
    ui.Build(projectInfo, fileName, line, column);
    try
      ui.Activate;
    finally ui.Teardown; end;
  finally FreeAndNil(ui); end;
end; { DLUIShowUI }

{ TDLUserInterface }

constructor TDLUserInterface.Create(const uixEngine: IDLUIXEngine);
begin
  inherited Create;
  FUIXEngine := uixEngine;
end; { TDLUserInterface.Create }

procedure TDLUserInterface.Activate;
begin
  // TODO 1 -oPrimoz Gabrijelcic : implement: TDLUserInterface.Activate
end; { TDLUserInterface.Activate }

procedure TDLUserInterface.Build(const projectInfo: IDLScanResult;
  const fileName: string; const line, column: integer);
begin
  FProjectInfo := projectInfo;
  FFileName := fileName;
  FLine := line;
  FColumn := column;
  // TODO 1 -oPrimoz Gabrijelcic : implement: TDLUserInterface.Build
end; { TDLUserInterface.Build }

procedure TDLUserInterface.Teardown;
begin
  // TODO 1 -oPrimoz Gabrijelcic : implement: TDLUserInterface.Teardown
end; { TDLUserInterface.Teardown }

end.
