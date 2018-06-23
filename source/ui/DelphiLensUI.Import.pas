unit DelphiLensUI.Import;

interface

uses
  DelphiLensUI.Error;

const
  DelphiLensUIDLL = 'DelphiLensUIProxy';

type
  TDLLogger = procedure (projectID: integer; const msg: PChar); stdcall;

function  IsDLUIAvailable: boolean; inline;

procedure DLUISetLogHook(const hook: TDLLogger);
  stdcall; external DelphiLensUIDLL delayed;

function  DLUIOpenProject(const projectName: PChar; var projectID: integer): integer;
  stdcall; external DelphiLensUIDLL delayed;

function  DLUISetProjectConfig(projectID: integer;
            platformName, conditionalDefines, searchPath: PChar): integer;
  stdcall; external DelphiLensUIDLL delayed;

function  DLUIRescanProject(projectID: integer): integer;
  stdcall; external DelphiLensUIDLL delayed;

function  DLUIProjectModified(projectID: integer): integer;
  stdcall; external DelphiLensUIDLL delayed;

function  DLUIFileModified(projectID: integer; fileName: PChar): integer;
  stdcall; external DelphiLensUIDLL delayed;

function  DLUICloseProject(projectID: integer): integer;
  stdcall; external DelphiLensUIDLL delayed;

function  DLUIActivate(monitorNum, projectID: integer; unitName: PChar; line, column: integer;
  tabNames: PChar; var navigateToFile: PChar; var navigateToLine,
  navigateToColumn: integer): integer;
  stdcall; external DelphiLensUIDLL delayed;

function  DLUIGetLastError(projectID: integer; var errorMsg: PChar): integer;
  stdcall; external DelphiLensUIDLL delayed;

var
  GDLUILibraryHandle: THandle;

implementation

uses
  Winapi.Windows;

function IsDLUIAvailable: boolean;
begin
  Result := (GDLUILibraryHandle <> 0);
end; { IsDLUIAvailable }

initialization
  GDLUILibraryHandle := LoadLibrary(DelphiLensUIDLL);
finalization
  if GDLUILibraryHandle <> 0 then begin
    FreeLibrary(GDLUILibraryHandle);
    GDLUILibraryHandle := 0;
  end;
end.
