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
    procedure RegProjectNotifier;
    procedure UnregProjectNotifier;
  public
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
var
  edit: IOTAEditor;
  sPlatform: string;
begin
  try
    if NotifyCode = ofnFileClosing then begin
      if ActiveProject = nil then
        if assigned(DLProxy) then
          DLProxy.ProjectClosed;
    end
    else if NotifyCode = ofnActiveProjectChanged then begin
      // get dpr/dpk name
      UnregProjectNotifier;
      FProject := ActiveProject;
      if assigned(FProject) then begin
        FModule := ProjectModule(FProject);
        if assigned(FModule) then begin
          if FModule.ModuleFileCount > 0 then begin
            edit := FModule.ModuleFileEditors[0];
            if assigned(edit) then
              if assigned(DLProxy) then begin
                sPlatform := GetActivePlatform(FProject);
                DLProxy.ProjectOpened(edit.FileName,
                  sPlatform,
                  GetSearchPath(FProject, True),
                  GetLibraryPath(sPlatform, True));
              end;
          end;
        end;
        RegProjectNotifier;
      end;
    end;
  except
    on E: Exception do
      Log('TIDENotifierTemplate.FileNotification', E);
  end;
end;

{$ENDIF}

{$IFDEF D2005}
procedure TIDENotifierTemplate.AfterCompile(const Project: IOTAProject;
  Succeeded, IsCodeInsight: Boolean);
begin
end;
{$ENDIF}

procedure TIDENotifierTemplate.AfterConstruction;
begin
  inherited;
  try
    FProjectNotifier := -1;
    FProject := ActiveProject;
    if assigned(FProject) then
      RegProjectNotifier;
  except
    on E: Exception do
      Log('TIDENotifierTemplate.AfterConstruction', E);
  end;
end;

procedure TIDENotifierTemplate.AfterSave;
begin
end;

procedure TIDENotifierTemplate.BeforeSave;
begin
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
    FProjectNotifierIntf := TProjectNotifier.Create(FProject);
    FProjectNotifier := FProject.AddNotifier(FProjectNotifierIntf);
  except
    on E: Exception do
      Log('TIDENotifierTemplate.RegProjectNotifier', E);
  end;
end;

procedure TIDENotifierTemplate.UnregProjectNotifier;
begin
  try
    if FProjectNotifier >= 0 then begin
      FProject.RemoveNotifier(FProjectNotifier);
      FProjectNotifierIntf := nil;
      FProjectNotifier := -1;
    end;
  except
    on E: Exception do
      Log('TIDENotifierTemplate.UnregProjectNotifier', E);
  end;
end;

initialization
finalization
end.
