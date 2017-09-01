unit KeyboardBindingInterface;

interface

uses
  ToolsAPI,
  Classes;

{$INCLUDE CompilerDefinitions.inc}

type
  TKeybindingTemplate = class(TNotifierObject, IOTAKeyboardBinding)
{$IFDEF D2005} strict {$ENDIF} private
{$IFDEF D2005} strict {$ENDIF} protected
    procedure AddBreakPoint(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
  public
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
  end;

implementation

uses
  SysUtils,
  Dialogs,
  Menus,
  UtilityFunctions;

{ TKeybindingTemplate }

procedure TKeybindingTemplate.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
//  BindingServices.AddKeyBinding([TextToShortcut('Ctrl+Shift+F8')],
//    AddBreakPoint, nil);
//  BindingServices.AddKeyBinding([TextToShortcut('Ctrl+Alt+F8')],
//    AddBreakPoint, nil);
end;

procedure TKeybindingTemplate.AddBreakPoint(const Context: IOTAKeyContext;
  KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
//var
//  i: Integer;
//  DS: IOTADebuggerServices;
//  MS: IOTAModuleServices;
//  strFileName: string;
//  Source: IOTASourceEditor;
//  CP: TOTAEditPos;
//  BP: IOTABreakpoint;
begin
//  MS := BorlandIDEServices as IOTAModuleServices;
//  Source := SourceEditor(MS.CurrentModule);
//  strFileName := Source.FileName;
//  CP := Source.EditViews[0].CursorPos;
//  DS := BorlandIDEServices as IOTADebuggerServices;
//  BP := nil;
//  for i := 0 to DS.SourceBkptCount - 1 do
//    if (DS.SourceBkpts[i].LineNumber = CP.Line) and
//      (AnsiCompareFileName(DS.SourceBkpts[i].FileName, strFileName) = 0) then
//      BP := DS.SourceBkpts[i];;
//  if BP = nil then
//    BP := DS.NewSourceBreakpoint(strFileName, CP.Line, nil);
//  if KeyCode = TextToShortcut('Ctrl+Shift+F8') then
//    BP.Edit(True)
//  else if KeyCode = TextToShortcut('Ctrl+Alt+F8') then
//    BP.Enabled := not BP.Enabled;
//  BindingResult := krHandled;
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

end.
