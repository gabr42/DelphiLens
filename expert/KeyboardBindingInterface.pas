unit KeyboardBindingInterface;

interface

uses
  Messages,
  ToolsAPI,
  Classes;

{$INCLUDE CompilerDefinitions.inc}

type
  TKeybindingTemplate = class(TNotifierObject, IOTAKeyboardBinding)
{$IFDEF D2005} strict {$ENDIF} private
    FWindow: THandle;
{$IFDEF D2005} strict {$ENDIF} protected
    procedure WndProc(var Message: TMessage);
  public
    constructor Create;
    destructor Destroy; override;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
  end;

implementation

uses
  Windows,
  SysUtils,
  Dialogs,
  Menus,
  UtilityFunctions,
  DelphiLensProxy;

{ TKeybindingTemplate }

procedure TKeybindingTemplate.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
end;

constructor TKeybindingTemplate.Create;
begin
  FWindow := AllocateHWnd(WndProc);
  { TODO :
This doesn't work well if >1 Delphi is using this wizard.
Add keyboard shortcut configuration. }
  if not RegisterHotKey(FWindow, 1, MOD_WIN + MOD_ALT , VK_SPACE) then
    OutputMessage('Failed to register hotkey: ' + SysErrorMessage(GetLastError), 'DelphiLens');
end;

destructor TKeybindingTemplate.Destroy;
begin
  UnregisterHotKey(Fwindow, 1);
  DeallocateHWnd(FWindow);
  inherited;
end;

function TKeybindingTemplate.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TKeybindingTemplate.GetDisplayName: string;
begin
  Result := 'DelphiLens Keybindings';
end;

function TKeybindingTemplate.GetName: string;
begin
  Result := 'DelphiLens Keyboard Bindings';
end;

procedure TKeybindingTemplate.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_HOTKEY then begin
     if Message.WParam = 1 then begin
       if assigned(DLProxy) then
         DLProxy.Activate;
       Message.Result := 0;
     end;
  end
  else
    DefWindowProc(FWindow, Message.Msg, Message.wParam, Message.lParam);
end;

end.
