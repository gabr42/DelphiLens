unit InitialiseOTAInterface;

interface

uses
  ToolsAPI;

{$INCLUDE 'CompilerDefinitions.inc'}
procedure Register;

function InitWizard(const BorlandIDEServices: IBorlandIDEServices;
  RegisterProc: TWizardRegisterProc; var Terminate: TWizardTerminateProc): Boolean; stdcall;

exports InitWizard name WizardEntryPoint;

implementation

uses
  SysUtils,
  Forms,
  Windows,
  GpConsole,
//  WizardInterface,
  KeyboardBindingInterface,
  IDENotifierInterface,
  EditorNotifierInterface,
  UtilityFunctions,
  DelphiLens.OTAUtils;

type
  TWizardType = (wtPackageWizard, wtDLLWizard);

const
  iWizardFailState = -1;

var
{$IFDEF D2005}
  VersionInfo: TVersionInfo;
  bmSplashScreen: HBITMAP;
{$ENDIF}
  iWizardIndex: Integer = iWizardFailState;
{$IFDEF D0006}
  iAboutPluginIndex: Integer = iWizardFailState;
{$ENDIF}
  iKeyBindingIndex: Integer = iWizardFailState;
  iIDENotfierIndex: Integer = iWizardFailState;
{$IFDEF D0006}
  iEditorIndex: Integer = iWizardFailState;
{$ENDIF}
{$IFDEF D2005}

const
  strRevision: string = ' abcdefghijklmnopqrstuvwxyz';

resourcestring
  strSplashScreenName = 'DelphiLens Expert %d.%d%s for Embarcadero RAD Studio';
  strSplashScreenBuild = 'Freeware by Primož Gabrijelèiè (Build %d.%d.%d.%d)';
{$ENDIF}

procedure InitialiseWizard(WizardType: TWizardType);//: TWizardTemplate;
var
  Svcs: IOTAServices;
begin
  try
    Svcs := BorlandIDEServices as IOTAServices;
    ToolsAPI.BorlandIDEServices := BorlandIDEServices;
    Application.Handle := Svcs.GetParentHandle;
  {$IFDEF D2005}
    // Aboutbox plugin
    bmSplashScreen := LoadBitmap(hInstance, 'SplashScreenBitMap');
    with VersionInfo do
      iAboutPluginIndex := (BorlandIDEServices as IOTAAboutBoxServices)
        .AddPluginInfo(Format(strSplashScreenName, [iMajor, iMinor,
        Copy(strRevision, iBugFix + 1, 1)]), 'Wizard Description.',
        bmSplashScreen, False, Format(strSplashScreenBuild,
        [iMajor, iMinor, iBugFix, iBuild]), Format('SKU Build %d.%d.%d.%d',
        [iMajor, iMinor, iBugFix, iBuild]));
  {$ENDIF}
    // Create Wizard / Menu Wizard
  //  Result := TWizardTemplate.Create;
  //  if WizardType = wtPackageWizard then
    // Only register main wizard this way if PACKAGE
  //    iWizardIndex := (BorlandIDEServices as IOTAWizardServices)
  //      .AddWizard(Result);
    // Create Keyboard Binding Interface
    iKeyBindingIndex := (BorlandIDEServices as IOTAKeyboardServices)
      .AddKeyboardBinding(TKeybindingTemplate.Create);
    // Create IDE Notifier Interface
    iIDENotfierIndex := (BorlandIDEServices as IOTAServices)
      .AddNotifier(TIDENotifierTemplate.Create);
  {$IFDEF D2005}
    // Create Editor Notifier Interface
    iEditorIndex := (BorlandIDEServices as IOTAEditorServices)
      .AddNotifier(TEditorNotifier.Create);
  {$ENDIF}
  except
    on E: Exception do
      Log(lcError, 'InitialiseWizard', E);
  end;
end;

procedure Register;
begin
  InitialiseWizard(wtPackageWizard);
end;

function InitWizard(const BorlandIDEServices: IBorlandIDEServices;
  RegisterProc: TWizardRegisterProc; var Terminate: TWizardTerminateProc)
  : Boolean; stdcall;
begin
  Result := BorlandIDEServices <> nil;
  if Result then
    {RegisterProc(}InitialiseWizard(wtDLLWizard){)};
end;

initialization
{$IFDEF D2005}
  BuildNumber(VersionInfo);
// Add Splash Screen
bmSplashScreen := LoadBitmap(hInstance, 'SplashScreenBitMap');
with VersionInfo do
  (SplashScreenServices as IOTASplashScreenServices)
    .AddPluginBitmap(Format(strSplashScreenName, [iMajor, iMinor,
    Copy(strRevision, iBugFix + 1, 1)]), bmSplashScreen, False,
    Format(strSplashScreenBuild, [iMajor, iMinor, iBugFix, iBuild]));
{$ENDIF}

finalization
Console.Writeln('Expert shutting down:');
Console.Writeln('  - wizard');
// Remove Wizard Interface
if iWizardIndex > iWizardFailState then
  (BorlandIDEServices as IOTAWizardServices).RemoveWizard(iWizardIndex);
{$IFDEF D2005}
Console.Writeln('  - about');
// Remove Aboutbox Plugin Interface
if iAboutPluginIndex > iWizardFailState then
  (BorlandIDEServices as IOTAAboutBoxServices)
    .RemovePluginInfo(iAboutPluginIndex);
{$ENDIF}
Console.Writeln('  - keyboard');
// Remove Keyboard Binding Interface
if iKeyBindingIndex > iWizardFailState then
  (BorlandIDEServices as IOTAKeyboardServices).RemoveKeyboardBinding
    (iKeyBindingIndex);
Console.Writeln('  - IDE notifier');
// Remove IDE Notifier Interface
if iIDENotfierIndex > iWizardFailState then
  (BorlandIDEServices as IOTAServices).RemoveNotifier(iIDENotfierIndex);
{$IFDEF D2005}
Console.Writeln('  - editor notifier');
// Remove Editor Notifier Interface
if iEditorIndex <> iWizardFailState then
  (BorlandIDEServices as IOTAEditorServices).RemoveNotifier(iEditorIndex);
{$ENDIF}
Console.Writeln('All done!');
end.
