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
  DelphiLensProxy;

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
begin
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
      OutputMessage('Active project: ' + FProject.FileName, 'DelphiLens');
      RegProjectNotifier;
      FModule := ProjectModule(FProject);
      if assigned(FModule) then begin
        if FModule.ModuleFileCount > 0 then begin
          edit := FModule.ModuleFileEditors[0];
          if assigned(edit) then
            if assigned(DLProxy) then
              DLProxy.ProjectOpened(edit.FileName);
        end;
      end;
    end;
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
  Exit;
  FProjectNotifier := -1;
  try
{ TODO : Sometimes crashes if this is executed in constructor. Do it via timer? }
//    FProject := ActiveProject;
//    if assigned(FProject) then
//      RegProjectNotifier;
  except
    on E: Exception do
      OutputMessage('Exception in TIDENotifierTemplate.AfterConstruction: ' + E.Message, 'DelphiLens');
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

  FProjectNotifier := FProject.AddNotifier(TProjectNotifier.Create());
end;

procedure TIDENotifierTemplate.UnregProjectNotifier;
begin
  if FProjectNotifier >= 0 then begin
    FProject.RemoveNotifier(FProjectNotifier);
    FProjectNotifier := -1;
  end;
end;

initialization
finalization
end.
