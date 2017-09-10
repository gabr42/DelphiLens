unit ProjectNotifierInterface;

interface

uses
  ToolsApi;

type
  TProjectNotifier = class(TModuleNotifierObject, IOTAModuleNotifier, IOTAProjectNotifier)
  public
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
  System.SysUtils,
  UtilityFunctions,
  DelphiLens.OTAUtils, DelphiLensProxy;

{ TProjectNotifier }

procedure TProjectNotifier.ModuleAdded(const AFileName: string);
begin
  try
    if assigned(DLProxy) then
      DLProxy.ProjectModified;
  except
    on E: Exception do
      Log('TProjectNotifier.ModuleAdded', E);
  end;
end;

procedure TProjectNotifier.ModuleRemoved(const AFileName: string);
begin
  try
    if assigned(DLProxy) then
      DLProxy.ProjectModified;
  except
    on E: Exception do
      Log('TProjectNotifier.ModuleRemoved', E);
  end;
end;

procedure TProjectNotifier.ModuleRenamed(const NewName: string);
begin
  try
    if assigned(DLProxy) then
      DLProxy.ProjectModified;
  except
    on E: Exception do
      Log('TProjectNotifier.ModuleRenamed', E);
  end;
end;

procedure TProjectNotifier.ModuleRenamed(const AOldFileName,
  ANewFileName: string);
begin
  try
    if assigned(DLProxy) then
      DLProxy.ProjectModified;
  except
    on E: Exception do
      Log('TProjectNotifier.ModuleRenamed', E);
  end;
end;

end.
