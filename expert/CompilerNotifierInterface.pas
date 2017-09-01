unit CompilerNotifierInterface;

interface

uses
  ToolsAPI;

{$INCLUDE CompilerDefinitions.inc}
{$IFDEF D2010}

type
  TCompilerNotifier = class(TNotifierObject, IOTACompileNotifier)
  strict private
  strict protected
    procedure ProjectCompileStarted(const Project: IOTAProject;
      Mode: TOTACompileMode);
    procedure ProjectCompileFinished(const Project: IOTAProject;
      Result: TOTACompileResult);
    procedure ProjectGroupCompileStarted(Mode: TOTACompileMode);
    procedure ProjectGroupCompileFinished(Result: TOTACompileResult);
  public
  end;
{$ENDIF}

implementation

uses
  SysUtils,
  UtilityFunctions;

{$IFDEF D2010}

const
  strCompileMode: array [low(TOTACompileMode) .. high(TOTACompileMode)
    ] of string = ('Make', 'Build', 'Check', 'Make Unit');
  strCompileResult: array [low(TOTACompileResult) .. high(TOTACompileResult)
    ] of string = ('Failed', 'Succeeded', 'Background');

resourcestring
  strCompilerNotifierMessages = 'Compiler Notifier Messages';

procedure TCompilerNotifier.ProjectCompileStarted(const Project: IOTAProject;
  Mode: TOTACompileMode);
begin
  // OutputMessage(Format('ProjectCompileStarted: Project = %s, Mode = %s', [
  // ExtractFilename(Project.FileName), strCompileMode[Mode]]),
  // strCompilerNotifierMessages);
end;

procedure TCompilerNotifier.ProjectCompileFinished(const Project: IOTAProject;
  Result: TOTACompileResult);
begin
//  OutputMessage(Format('ProjectCompileFinished: Project = %s, Result = %s',
//    [ExtractFileName(Project.FileName), strCompileResult[Result]]),
//    strCompilerNotifierMessages);
end;

procedure TCompilerNotifier.ProjectGroupCompileStarted(Mode: TOTACompileMode);
begin
//  OutputMessage(Format('ProjectGroupCompileStarted: Mode = %s',
//    [strCompileMode[Mode]]), strCompilerNotifierMessages);
end;

procedure TCompilerNotifier.ProjectGroupCompileFinished
  (Result: TOTACompileResult);
begin
//  OutputMessage(Format('ProjectGroupCompileFinished: Mode = %s',
//    [strCompileResult[Result]]), strCompilerNotifierMessages);
end;
{$ENDIF}

end.
