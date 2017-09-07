unit ProjectNotifierInterface;

interface

uses
  ToolsApi;

type
  TProjectNotifier = class(TModuleNotifierObject, IOTAModuleNotifier, IOTAProjectNotifier)
  public
    constructor Create;
    destructor Destroy; override;

    { IOTAModuleNotifier }

    { User has renamed the module }
    procedure ModuleRenamed(const NewName: string); overload;

    { IOTAProjectNotifier }

    { This notifier will be called when a file/module is added to the project }
    procedure ModuleAdded(const AFileName: string);

    { This notifier will be called when a file/module is removed from the project }
    procedure ModuleRemoved(const AFileName: string);

    { This notifier will be called when a file/module is renamed in the project }
    procedure ModuleRenamed(const AOldFileName, ANewFileName: string); overload;
  end;

implementation

uses
  UtilityFunctions,
  DelphiLensProxy;

{ TProjectNotifier }

constructor TProjectNotifier.Create;
begin
//  OutputMessage('TProjectNotifier created', 'DelphiLens');
  inherited Create;
end;

destructor TProjectNotifier.Destroy;
begin
//  OutputMessage('TProjectNotifier destroyed', 'DelphiLens');
  inherited;
end;

procedure TProjectNotifier.ModuleAdded(const AFileName: string);
begin
  if assigned(DLProxy) then
    DLProxy.ProjectModified;
end;

procedure TProjectNotifier.ModuleRemoved(const AFileName: string);
begin
  if assigned(DLProxy) then
    DLProxy.ProjectModified;
end;

procedure TProjectNotifier.ModuleRenamed(const NewName: string);
begin
  if assigned(DLProxy) then
    DLProxy.ProjectModified;
end;

procedure TProjectNotifier.ModuleRenamed(const AOldFileName,
  ANewFileName: string);
begin
  if assigned(DLProxy) then
    DLProxy.ProjectModified;
end;

end.
