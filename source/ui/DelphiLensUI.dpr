library DelphiLensUI;

{$R *.dres}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  DelphiLensUI.DLLExports;

{$R *.res}

exports
  DLUIOpenProject,
  DLUICloseProject,
  DLUIProjectModified,
  DLUIFileModified,
  DLUISetProjectConfig,
  DLUIRescanProject,
  DLUIActivate;

var
  SaveDllProc: TDLLProc;

procedure LibExit(reason: integer);
begin
  if Reason = DLL_PROCESS_DETACH then
    DLUIFinalize;

  if assigned(SaveDllProc) then
    SaveDllProc(reason);	// call saved entry point procedure
end; { LibExit }

begin
  DLUIInitialize;
  SaveDllProc := DllProc; // save exit procedure chain
  DllProc := @LibExit;	  // install LibExit exit procedure
end.
