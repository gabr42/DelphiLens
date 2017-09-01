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
  public
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
  UtilityFunctions;

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
//  OutputMessage(Format('BeforeCompile: Project: %s, Cancel = %s',
//    [ExtractFileName(Project.FileName), strBoolean[Cancel]])
//{$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

procedure TIDENotifierTemplate.BeforeCompile(const Project: IOTAProject;
  IsCodeInsight: Boolean; var Cancel: Boolean);
begin
//  OutputMessage
//    (Format('BeforeCompile: Project: %s, IsCodeInsight = %s, Cancel = %s',
//    [ExtractFileName(Project.FileName), strBoolean[IsCodeInsight],
//    strBoolean[Cancel]])
//{$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

procedure TIDENotifierTemplate.AfterCompile(Succeeded: Boolean);
begin
//  OutputMessage(Format('AfterCompile: Succeeded=  %s', [strBoolean[Succeeded]])
//{$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

procedure TIDENotifierTemplate.AfterCompile(Succeeded, IsCodeInsight: Boolean);
begin
//  OutputMessage(Format('AfterCompile: Succeeded=  %s, IsCodeInsight = %s',
//    [strBoolean[Succeeded], strBoolean[IsCodeInsight]])
//{$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

procedure TIDENotifierTemplate.FileNotification
  (NotifyCode: TOTAFileNotification; const FileName: string;
  var Cancel: Boolean);
//const
//  strNotifyCode: array [low(TOTAFileNotification) .. high(TOTAFileNotification)
//    ] of string = ('ofnFileOpening', 'ofnFileOpened', 'ofnFileClosing',
//    'ofnDefaultDesktopLoad', 'ofnDefaultDesktopSave', 'ofnProjectDesktopLoad',
//    'ofnProjectDesktopSave', 'ofnPackageInstalled', 'ofnPackageUninstalled'
//    {$IFDEF D0007}, 'ofnActiveProjectChanged' {$ENDIF} {$IFDEF DXE80},
//    // Dont have XE8 to check this so
//    'ofnProjectOpenedFromTemplate' {$ENDIF}            // may need to be changed to DXE100
//    );
begin
//  OutputMessage
//    (Format('FileNotification: NotifyCode = %s, FileName = %s, Cancel = %s',
//    [strNotifyCode[NotifyCode], ExtractFileName(FileName), strBoolean[Cancel]])
//{$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

{$ENDIF}
{$IFDEF D2005}

procedure TIDENotifierTemplate.AfterCompile(const Project: IOTAProject;
  Succeeded, IsCodeInsight: Boolean);
begin
//  OutputMessage
//    (Format('AfterCompile: Project: %s, Succeeded=  %s, IsCodeInsight = %s',
//    [ExtractFileName(Project.FileName), strBoolean[Succeeded],
//    strBoolean[IsCodeInsight]]), strIDENotifierMessages);
end;
{$ENDIF}

procedure TIDENotifierTemplate.AfterSave;
begin
//  OutputMessage('AfterSave' {$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

procedure TIDENotifierTemplate.BeforeSave;
begin
//  OutputMessage('BeforeSave' {$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

procedure TIDENotifierTemplate.Destroyed;
begin
//  ClearMessages([cmCompiler .. cmTool]);
//  OutputMessage('Destroyed' {$IFDEF D0006}, strIDENotifierMessages {$ENDIF});
end;

procedure TIDENotifierTemplate.Modified;
begin
//  OutputMessage('Modified' {$IFDEF D0006} , strIDENotifierMessages {$ENDIF});
end;

initialization
finalization
end.
