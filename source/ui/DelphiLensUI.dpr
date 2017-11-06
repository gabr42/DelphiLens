library DelphiLensUI;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

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
  DLUIRescanProject;

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
