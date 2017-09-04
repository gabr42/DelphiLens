library DelphiLensExpert;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

{$R *.res}

{Generate by DGH OTA Wizard}
uses
  DelphiLensProxy in 'DelphiLensProxy.pas',
  InitialiseOTAInterface in 'InitialiseOTAInterface.pas',
  UtilityFunctions in 'UtilityFunctions.pas',
//  WizardInterface in 'WizardInterface.pas',
  EditorNotifierInterface in 'EditorNotifierInterface.pas',
  IDENotifierInterface in 'IDENotifierInterface.pas',
  KeyboardBindingInterface in 'KeyboardBindingInterface.pas';

begin
end.
