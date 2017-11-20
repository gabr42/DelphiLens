unit IDENotifierInterface;

interface

uses
  ToolsAPI;

{$INCLUDE CompilerDefinitions.inc}

type
  TIDENotifierTemplate = class(TNotifierObject, IOTANotifier,
{$IFDEF D0005} IOTAIDENotifier50, {$ENDIF}
{$IFDEF D2005} IOTAIDENotifier80, {$ENDIF}
    IOTAIDENotifier)
{$IFDEF D2005} strict {$ENDIF} private
{$IFDEF D2005} strict {$ENDIF} protected
    FModule: IOTAModule;
    FProject: IOTAProject;
    FProjectNotifier: integer;
    FProjectNotifierIntf: IOTAProjectNotifier;
    procedure ActiveProjectChanged;
    procedure RegProjectNotifier;
    procedure UnregProjectNotifier;
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    // IOTANotifier
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
{$IFDEF D0005}
    // IOTAIDENotifier
    procedure FileNotification(NotifyCode: TOTAFileNotification;
      const FileName: string; var Cancel: Boolean);
    procedure BeforeCompile(const Project: IOTAProject;
      var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
    // IOTAIDENotifier50
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean;
      var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean);
      overload;
{$ENDIF}
{$IFDEF D2005}
    procedure AfterCompile(const Project: IOTAProject; Succeeded: Boolean;
      IsCodeInsight: Boolean); overload;
{$ENDIF}
  end;

implementation

uses
  SysUtils,
  UtilityFunctions,
  ProjectNotifierInterface,
  DelphiLens.OTAUtils, DelphiLensProxy,
  StrUtils, DSiWin32;

const
  strBoolean: array [False .. True] of string = ('False', 'True');

{$IFDEF D0006}

resourcestring
  strIDENotifierMessages = 'IDE Notifier Messages';
{$ENDIF}

{ TIDENotifierTemplate }

{$IFDEF D0005}

procedure TIDENotifierTemplate.BeforeCompile(const Project: IOTAProject;
  var Cancel: Boolean);
begin
end;

procedure TIDENotifierTemplate.BeforeCompile(const Project: IOTAProject;
  IsCodeInsight: Boolean; var Cancel: Boolean);
begin
end;

procedure TIDENotifierTemplate.AfterCompile(Succeeded: Boolean);
begin
end;

procedure TIDENotifierTemplate.AfterCompile(Succeeded, IsCodeInsight: Boolean);
begin
end;

procedure TIDENotifierTemplate.FileNotification
  (NotifyCode: TOTAFileNotification; const FileName: string;
  var Cancel: Boolean);
begin
  try
    if NotifyCode = ofnActiveProjectChanged then
      ActiveProjectChanged;
  except
    on E: Exception do
      Log(lcError, 'TIDENotifierTemplate.FileNotification', E);
  end;
end;

{$ENDIF}

{$IFDEF D2005}
procedure TIDENotifierTemplate.AfterCompile(const Project: IOTAProject;
  Succeeded, IsCodeInsight: Boolean);
begin
end;
{$ENDIF}

procedure TIDENotifierTemplate.ActiveProjectChanged;
var
  edit: IOTAEditor;
  sPlatform: string;
begin
  Log(lcActiveProject, 'Active project changed');
  UnregProjectNotifier;
  FProject := ActiveProject;
  if not assigned(FProject) then
    Log(lcActiveProject, '... no active project')
  else begin
    FModule := ProjectModule(FProject);
    if not assigned(FModule) then
      Log(lcActiveProject, '... no project module')
    else begin
      if FModule.ModuleFileCount <= 0 then
        Log(lcActiveProject, '... no files in module')
      else begin
        edit := FModule.ModuleFileEditors[0];
        if not assigned(edit) then
          Log(lcActiveProject, '... no editors in module')
        else if assigned(DLProxy) then begin
          sPlatform := GetActivePlatform(FProject);
          DLProxy.ProjectOpened(edit.FileName,
            sPlatform,
            GetConditionalDefines(FProject),
            GetSearchPath(FProject, True),
            GetLibraryPath(sPlatform, True));
        end;
      end;
    end;
    RegProjectNotifier;
  end;
end;

procedure TIDENotifierTemplate.AfterConstruction;
begin
  inherited;
  try
    FProjectNotifier := -1;
    ActiveProjectChanged;
  except
    on E: Exception do
      Log(lcError, 'TIDENotifierTemplate.AfterConstruction', E);
  end;
end;

procedure TIDENotifierTemplate.AfterSave;
begin
end;

procedure TIDENotifierTemplate.BeforeSave;
begin
end;

destructor TIDENotifierTemplate.Destroy;
begin
  UnregProjectNotifier;
  inherited;
end;

procedure TIDENotifierTemplate.Destroyed;
begin
  UnregProjectNotifier;
end;

procedure TIDENotifierTemplate.Modified;
begin
end;

procedure TIDENotifierTemplate.RegProjectNotifier;
begin
  if not assigned(FProject) then
    Exit;

  try
    Log(lcActiveProject, 'Registering project notifier');
    FProjectNotifierIntf := TProjectNotifier.Create(FProject,
      procedure
      begin
        try
          Log(lcActiveProject, 'Removing project notifier');
          FProjectNotifier := -1;
          FProjectNotifierIntf := nil;
          if assigned(DLProxy) then
            DLProxy.ProjectClosed;
        except
          on E: Exception do
            Log(lcError, 'TProjectNotifier CleanupProc', E);
        end;
      end);
    FProjectNotifier := FProject.AddNotifier(FProjectNotifierIntf);
  except
    on E: Exception do begin
      FProjectNotifier := -1;
      FProjectNotifierIntf := nil;
      Log(lcError, 'TIDENotifierTemplate.RegProjectNotifier', E);
    end;
  end;
end;

procedure TIDENotifierTemplate.UnregProjectNotifier;
begin
  try
    if FProjectNotifier >= 0 then begin
      Log(lcActiveProject, 'Removing');
      FProject.RemoveNotifier(FProjectNotifier);
      FProjectNotifierIntf := nil;
      FProjectNotifier := -1;
    end;
  except
    on E: Exception do
      Log(lcError, 'TIDENotifierTemplate.UnregProjectNotifier', E);
  end;
end;

initialization
finalization
end.
