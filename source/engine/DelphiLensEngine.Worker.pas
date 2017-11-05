unit DelphiLensEngine.Worker;

interface

type
  TDLEProjectConfig = record
    Platform   : string;
    SearchPath : string;
    LibraryPath: string;
    constructor Create(const APlatform, ASearchPath, ALibraryPath: string);
  end; { TDLEProjectConfig }

  TDelphiLensEngineProject = class
  public
    constructor Create(const projectName: string);
    destructor  Destroy; override;
    procedure FileModified(const fileName: string);
    procedure ProjectModified;
    procedure Rescan;
    procedure SetConfig(const config: TDLEProjectConfig);
  end; { TDelphiLensEngineProject }

implementation

uses
  OtlCommon,
  OtlTaskControl;

type
  TDelphiLensEngineWorker = class(TOmniWorker)
  strict private const
    CTimerRescan         = 1;
    CTimerRescanDelay_ms = 3000;
  var
//    FDelphiLens: IDelphiLens;
//    FScanResult: IDLScanResult;
  strict protected
//    procedure ScheduleRescan;
  public
//    procedure OpenProject(const projectInfo: TOmniValue);
//    procedure CloseProject;
//    procedure ProjectModified;
//    procedure FileModified(const fileModified: TOmniValue);
//    procedure Rescan;
//    procedure SetProjectConfig(const configInfo: TOmniValue);
  end; { TDelphiLensEngineWorker }

{ TDLEProjectConfig }

constructor TDLEProjectConfig.Create(const APlatform, ASearchPath, ALibraryPath: string);
begin
  Platform := APlatform;
  SearchPath := ASearchPath;
  LibraryPath := ALibraryPath;
end; { TDLEProjectConfig.Create }

{ TDelphiLensEngineProject }

constructor TDelphiLensEngineProject.Create(const projectName: string);
begin

end;

destructor TDelphiLensEngineProject.Destroy;
begin

  inherited;
end;

procedure TDelphiLensEngineProject.FileModified(const fileName: string);
begin

end;

procedure TDelphiLensEngineProject.ProjectModified;
begin

end;

procedure TDelphiLensEngineProject.Rescan;
begin

end;

procedure TDelphiLensEngineProject.SetConfig(const config: TDLEProjectConfig);
begin

end;

end.
