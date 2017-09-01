unit EditorNotifierInterface;

interface

{$INCLUDE CompilerDefinitions.inc}

uses
  ToolsAPI,
{$IFDEF D0006}
  DockForm,
{$ENDIF}
  Classes;

{$IFDEF D2005}

type
  TEditorNotifier = class(TNotifierObject, INTAEditServicesNotifier)
  strict private
  strict protected
  public
    procedure WindowShow(const EditWindow: INTAEditWindow;
      Show, LoadedFromDesktop: Boolean);
    procedure WindowNotification(const EditWindow: INTAEditWindow;
      Operation: TOperation);
    procedure WindowActivated(const EditWindow: INTAEditWindow);
    procedure WindowCommand(const EditWindow: INTAEditWindow;
      Command, Param: Integer; var Handled: Boolean);
    procedure EditorViewActivated(const EditWindow: INTAEditWindow;
      const EditView: IOTAEditView);
    procedure EditorViewModified(const EditWindow: INTAEditWindow;
      const EditView: IOTAEditView);
    procedure DockFormVisibleChanged(const EditWindow: INTAEditWindow;
      DockForm: TDockableForm);
    procedure DockFormUpdated(const EditWindow: INTAEditWindow;
      DockForm: TDockableForm);
    procedure DockFormRefresh(const EditWindow: INTAEditWindow;
      DockForm: TDockableForm);
  end;
{$ENDIF}

implementation

uses
  SysUtils,
  UtilityFunctions;

{$IFDEF D2005}
{ TEditorNotifier }

const
  strEditorNotifierMessages = 'Editor Notifier Messages';
  strBoolean: array [False .. True] of string = ('False', 'True');

procedure TEditorNotifier.DockFormRefresh(const EditWindow: INTAEditWindow;
  DockForm: TDockableForm);
begin
end;

procedure TEditorNotifier.DockFormUpdated(const EditWindow: INTAEditWindow;
  DockForm: TDockableForm);
begin
end;

procedure TEditorNotifier.DockFormVisibleChanged(const EditWindow: INTAEditWindow;
  DockForm: TDockableForm);
begin
end;

procedure TEditorNotifier.EditorViewActivated(const EditWindow: INTAEditWindow;
  const EditView: IOTAEditView);
var
  view: IOTAEditView;
begin
//  view := EditView.Buffer.TopView;
//  if assigned(view) then begin
//    OutputMessage(Format('EditorViewActivated: EditWindow = %s, EditView = %s',
//      [EditWindow.Form.Caption, ExtractFileName(EditView.Buffer.FileName)]),
//      strEditorNotifierMessages);
//    OutputMessage('EditorViewActivated: ' + view.Buffer.FileName, strEditorNotifierMessages)
//  end;
end;

procedure TEditorNotifier.EditorViewModified(const EditWindow: INTAEditWindow;
  const EditView: IOTAEditView);
begin
//  OutputMessage(Format('EditorViewModified: EditWindow = %s, EditView = %s',
//    [EditWindow.Form.Caption, ExtractFileName(EditView.Buffer.FileName)]),
//    strEditorNotifierMessages);
end;

procedure TEditorNotifier.WindowActivated(const EditWindow: INTAEditWindow);
begin
//  OutputMessage(Format('WindowActivated: EditWindow = %s',
//    [EditWindow.Form.Caption]), strEditorNotifierMessages);
end;

procedure TEditorNotifier.WindowCommand(const EditWindow: INTAEditWindow;
  Command, Param: Integer; var Handled: Boolean);
begin
end;

procedure TEditorNotifier.WindowNotification(const EditWindow: INTAEditWindow;
  Operation: TOperation);
begin
end;

procedure TEditorNotifier.WindowShow(const EditWindow: INTAEditWindow;
  Show, LoadedFromDesktop: Boolean);
begin
end;
{$ENDIF}

end.
