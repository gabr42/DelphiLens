unit ProjectNotifierInterface;

interface

uses
  ToolsApi,
  Vcl.ExtCtrls;

type
  TProjectNotifier = class(TModuleNotifierObject, IOTAModuleNotifier, IOTAProjectNotifier)
  strict private const
    CPathCheckInterval_sec = 5;
  var
    FProject: IOTAProject;
    FSearchPath: string;
    FConditionals: string;
    FPlatform: string;
    FLibPath: string;
    FTimer: TTimer;
  strict protected
    procedure CheckPaths(Sender: TObject);
  public
    constructor Create(const project: IOTAProject);
    destructor  Destroy; override;
    procedure Destroyed;

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
  Vcl.Forms,
  System.SysUtils,
  UtilityFunctions,
  DelphiLens.OTAUtils, DelphiLensProxy;

{ TProjectNotifier }

procedure TProjectNotifier.CheckPaths(Sender: TObject);
var
  searchPath: string;
  sPlatform: string;
  libPath: string;
  condDefs: string;
begin
  try
    searchPath := GetSearchPath(FProject, True);
    sPlatform := GetActivePlatform(FProject);
    libPath := GetLibraryPath(sPlatform, True);
    condDefs := GetConditionalDefines(FProject);
    if not (SameText(searchPath, FSearchPath)
            and SameText(sPlatform, FPlatform)
            and SameText(condDefs, FConditionals)
            and SameText(libPath, FLibPath)) then
    begin
      FSearchPath := searchPath;
      FPlatform := sPlatform;
      FConditionals := condDefs;
      FLibPath := libPath;
      if assigned(DLProxy) then
        DLProxy.SetProjectConfig(FPlatform, FConditionals, FSearchPath, FLibPath);
    end;
  except
    on E: Exception do
      Log('TProjectNotifier.CheckPaths', E);
  end;
end;

constructor TProjectNotifier.Create(const project: IOTAProject);
begin
  inherited Create;
  FProject := project;
  FSearchPath := GetSearchPath(project, True);
  FPlatform := GetActivePlatform(project);
  FConditionals := GetConditionalDefines(project);
  FLibPath := GetLibraryPath(FPlatform, True);
  FTimer := TTimer.Create(nil);
  FTimer.OnTimer := CheckPaths;
  FTimer.Interval := CPathCheckInterval_sec * 1000;
  FTimer.Enabled := true;
end;

destructor TProjectNotifier.Destroy;
begin
  try
    FreeAndNil(FTimer);
  except
    on E: Exception do
      Log('TProjectNotifier.Destroy', E);
  end;
  inherited;
end;

procedure TProjectNotifier.Destroyed;
begin
  try
    FreeAndNil(FTimer);
  except
    on E: Exception do
      Log('TProjectNotifier.Destroyed', E);
  end;
end;

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
