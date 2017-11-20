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
  UtilityFunctions,
  DelphiLens.OTAUtils,
  DelphiLensProxy;

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
begin
  try
    if assigned(EditView) and assigned(EditView.Buffer) and assigned(DLProxy) then
      DLProxy.FileActivated(EditView.Buffer.FileName);
  except
    on E: Exception do
      Log(lcError, 'TEditorNotifier.EditorViewActivated', E);
  end;
end;

procedure TEditorNotifier.EditorViewModified(const EditWindow: INTAEditWindow;
  const EditView: IOTAEditView);
begin
  try
    if assigned(EditView) and assigned(EditView.Buffer) and assigned(DLProxy) then
      DLProxy.FileModified(EditView.Buffer.FileName);
  except
    on E: Exception do
      Log(lcError, 'TEditorNotifier.EditorViewModified', E);
  end;
end;

procedure TEditorNotifier.WindowActivated(const EditWindow: INTAEditWindow);
begin
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
