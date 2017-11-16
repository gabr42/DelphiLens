unit KeyboardBindingInterface;

interface

uses
  Messages,
  ToolsAPI,
  Classes,
  Vcl.AppEvnts;

{$INCLUDE CompilerDefinitions.inc}

type
  TKeybindingTemplate = class(TNotifierObject, IOTAKeyboardBinding)
{$IFDEF D2005} strict {$ENDIF} private
{$IFDEF D2005} strict {$ENDIF} protected
    FAppEvents: TApplicationEvents;
    FHotKeyRegistered: boolean;
    FWindow: THandle;
    procedure AppActivated(Sender: TObject);
    procedure AppDeactivated(Sender: TObject);
    procedure RegisterHK;
    procedure UnregisterHK;
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
  Vcl.Forms,
  Menus,
  UtilityFunctions,
  DelphiLens.OTAUtils, DelphiLensProxy;

{ TKeybindingTemplate }

procedure TKeybindingTemplate.AppActivated(Sender: TObject);
begin
  try
    RegisterHK;
  except
    on E: Exception do
      Log('TKeybindingTemplate.AppActivated', E);
  end;
end;

procedure TKeybindingTemplate.AppDeactivated(Sender: TObject);
begin
  try
    UnregisterHK;
  except
    on E: Exception do
      Log('TKeybindingTemplate.AppDeactivated', E);
  end;
end;

procedure TKeybindingTemplate.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
end;

constructor TKeybindingTemplate.Create;
begin
  try
    FWindow := AllocateHWnd(WndProc);
    RegisterHK;
    FAppEvents := TApplicationEvents.Create(Application.MainForm);
    FAppEvents.OnActivate := AppActivated;
    FAppEvents.OnDeactivate := AppDeactivated;
  except
    on E: Exception do
      Log('TKeybindingTemplate.Create', E);
  end;
end;

destructor TKeybindingTemplate.Destroy;
begin
  try
    FreeAndNil(FAppEvents);
    UnregisterHK;
    DeallocateHWnd(FWindow);
    inherited;
  except
    on E: Exception do
      Log('TKeybindingTemplate.Destroy', E);
  end;
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

procedure TKeybindingTemplate.RegisterHK;
begin
  if FHotKeyRegistered then
    Exit;

  if RegisterHotKey(FWindow, 1, MOD_WIN + MOD_ALT, VK_SPACE) then
    FHotKeyRegistered := true
  else
    Log('Failed to register hotkey: ' + SysErrorMessage(GetLastError));
end;

procedure TKeybindingTemplate.UnregisterHK;
begin
  if not FHotKeyRegistered then
    Exit;
  UnregisterHotKey(Fwindow, 1);
  FHotKeyRegistered := false;
end;

procedure TKeybindingTemplate.WndProc(var Message: TMessage);
begin
  try
    if Message.Msg = WM_HOTKEY then begin
       if Message.WParam = 1 then begin
         if assigned(DLProxy) then
           DLProxy.Activate;
         Message.Result := 0;
       end;
    end
    else
      DefWindowProc(FWindow, Message.Msg, Message.wParam, Message.lParam);
  except
    on E: Exception do
      Log('TKeybindingTemplate.WndProc', E);
  end;
end;

end.
