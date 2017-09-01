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
//  OutputMessage(Format('DockFormRefresh: EditWindow = %s, DockForm = %s',
//    [EditWindow.Form.Caption, DockForm.Caption]), strEditorNotifierMessages);
end;

procedure TEditorNotifier.DockFormUpdated(const EditWindow: INTAEditWindow;
  DockForm: TDockableForm);
begin
//  OutputMessage(Format('DockFormUpdated: EditWindow = %s, DockForm = %s',
//    [EditWindow.Form.Caption, DockForm.Caption]), strEditorNotifierMessages);
end;

procedure TEditorNotifier.DockFormVisibleChanged(const EditWindow
  : INTAEditWindow; DockForm: TDockableForm);
begin
//  OutputMessage(Format('DockFormVisibleChanged: EditWindow = %s, DockForm = %s',
//    [EditWindow.Form.Caption, DockForm.Caption]), strEditorNotifierMessages);
end;

procedure TEditorNotifier.EditorViewActivated(const EditWindow: INTAEditWindow;
  const EditView: IOTAEditView);
begin
//  OutputMessage(Format('EditorViewActivated: EditWindow = %s, EditView = %s',
//    [EditWindow.Form.Caption, ExtractFileName(EditView.Buffer.FileName)]),
//    strEditorNotifierMessages);
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
//  OutputMessage
//    (Format('WindowCommand: EditWindow = %s, Command = %d, Param = %d',
//    [EditWindow.Form.Caption, Command, Param, strBoolean[Handled]]),
//    strEditorNotifierMessages);
end;

procedure TEditorNotifier.WindowNotification(const EditWindow: INTAEditWindow;
  Operation: TOperation);
const
  strOperation: array [low(TOperation) .. high(TOperation)
    ] of string = ('opInsert', 'opRemove');
begin
//  OutputMessage(Format('WindowNotification: EditWindow = %s, Operation = %s',
//    [EditWindow.Form.Caption, strOperation[Operation]]),
//    strEditorNotifierMessages);
end;

procedure TEditorNotifier.WindowShow(const EditWindow: INTAEditWindow;
  Show, LoadedFromDesktop: Boolean);
begin
//  OutputMessage
//    (Format('WindowShow: EditWindow = %s, Show = %s, LoadedFromDesktop = %s',
//    [EditWindow.Form.Caption, strBoolean[Show], strBoolean[LoadedFromDesktop]]),
//    strEditorNotifierMessages);
end;
{$ENDIF}

end.
