unit DelphiLensUI.Import;

interface

uses
  DelphiLensUI.Error;

const
  DelphiLensUIDLL = 'DelphiLensUI';

  function  IsDLUIAvailable: boolean;

  function  DLUIOpenProject(const projectName: PChar; var projectID: integer): integer; stdcall;
    external DelphiLensUIDLL delayed;

  function  DLUISetProjectConfig(projectID: integer; platform,
              searchPath, libraryPath: PChar): integer; stdcall;
    external DelphiLensUIDLL delayed;

  function  DLUIRescanProject(projectID: integer): integer; stdcall;
    external DelphiLensUIDLL delayed;

  function  DLUIProjectModified(projectID: integer): integer; stdcall;
    external DelphiLensUIDLL delayed;

  function  DLUIFileModified(projectID: integer; const fileName: PChar): integer; stdcall;
    external DelphiLensUIDLL delayed;

  function  DLUICloseProject(projectID: integer): integer; stdcall;
    external DelphiLensUIDLL delayed;

  function  DLUIGetLastError(projectID: integer; var errorMsg: PChar): integer; stdcall;
    external DelphiLensUIDLL delayed;

implementation

uses
  Winapi.Windows;

var
  GDLUILibraryHandle: THandle;

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
