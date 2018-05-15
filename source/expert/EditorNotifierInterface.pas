unit EditorNotifierInterface;

interface

{$INCLUDE CompilerDefinitions.inc}

uses
  SysUtils,
  ToolsAPI,
{$IFDEF D0006}
  DockForm,
{$ENDIF}
{$IFDEF D2005}
  Generics.Collections,
{$ENDIF}
  Classes;

{$IFDEF D2005}

type
  TEditorModuleNotifier = class(TModuleNotifierObject, IOTAModuleNotifier)
  var
    FModule: IOTAModule;
    FCleanupProc: TProc;
    FAfterSaveProc: TProc;
  public
    constructor Create(const module: IOTAModule; cleanupProc, afterSaveProc: TProc);
    procedure Destroyed;

    { IOTAModuleNotifier }

    procedure AfterSave; reintroduce;
  end;

  TEditorNotifierItem = TPair<integer,IOTAModuleNotifier>;

  TEditorNotifier = class(TNotifierObject, INTAEditServicesNotifier)
  strict private
    FModuleNotifiers: TDictionary<IOTAModule, TEditorNotifierItem>;
  strict protected
    procedure RegisterModuleNotifier(const module: IOTAModule);
  public
    constructor Create;
    destructor Destroy; override;
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
  UtilityFunctions,
  DelphiLens.OTAUtils,
  DelphiLensProxy;

{$IFDEF D2005}
{ TEditorNotifier }

const
  strEditorNotifierMessages = 'Editor Notifier Messages';
  strBoolean: array [False .. True] of string = ('False', 'True');

constructor TEditorNotifier.Create;
begin
  inherited Create;
  FModuleNotifiers := TDictionary<IOTAModule, TEditorNotifierItem>.Create;
end;

destructor TEditorNotifier.Destroy;
var
  kv: TPair<IOTAModule,TEditorNotifierItem>;
begin
  for kv in FModuleNotifiers do
    kv.Key.RemoveNotifier(kv.Value.Key);
  FreeAndNil(FModuleNotifiers);
  inherited;
end;

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
    if assigned(EditView) and assigned(EditView.Buffer) then begin
      if assigned(EditView.Buffer.Module) then
        RegisterModuleNotifier(EditView.Buffer.Module);
      if assigned(DLProxy) then
        DLProxy.FileActivated(EditView.Buffer.FileName);
    end;
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

procedure TEditorNotifier.RegisterModuleNotifier(const module: IOTAModule);
var
  notifier: IOTAModuleNotifier;
  notifierIdx: integer;
begin
  if not FModuleNotifiers.ContainsKey(module) then begin
    notifier := TEditorModuleNotifier.Create(module,
      procedure
      var
        item: TEditorNotifierItem;
      begin
        if FModuleNotifiers.TryGetValue(module, item) then
          module.RemoveNotifier(item.Key);
        FModuleNotifiers.Remove(module);
      end,
      procedure
      begin
        if assigned(DLProxy) then
          DLProxy.FileSaved(module.FileName);
      end);
    notifierIdx := module.AddNotifier(notifier);
    FModuleNotifiers.Add(module, TEditorNotifierItem.Create(notifierIdx, notifier));
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

{ TEditorModuleNotifier }

constructor TEditorModuleNotifier.Create(const module: IOTAModule;
  cleanupProc, afterSaveProc: TProc);
begin
  inherited Create;
  FModule := module;
  FAfterSaveProc := afterSaveProc;
  FCleanupProc := cleanupProc;
end;

procedure TEditorModuleNotifier.AfterSave;
begin
  if assigned(FAfterSaveProc) then
    FAfterSaveProc();
end;

procedure TEditorModuleNotifier.Destroyed;
begin
  try
    if assigned(FCleanupProc) then begin
      FCleanupProc();
      FCleanupProc := nil;
    end;
  except
    on E: Exception do
      Log(lcError, 'TEditorModuleNotifier.Destroyed', E);
  end;
end;

end.
