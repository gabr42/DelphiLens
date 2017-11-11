unit GpEasing;

interface

uses
  System.SysUtils;

type
  Easing = class
    class procedure Linear(start, stop: integer; duration_ms, tick_ms: integer; updater: TProc<integer>); static;
  end; { Easing }

implementation

uses
  Vcl.ExtCtrls,
  DSiWin32;

type
  TEasing = class
  strict private
    FDuration_ms: integer;
    FStartValue : integer;
    FStopValue  : integer;
    FTick_ms    : integer;
    FStart_ms   : int64;
    FTimer      : TTimer;
    FUpdater    : TProc<integer>;
  strict protected
    procedure StartTimer;
    procedure UpdateValue(sender: TObject);
  public
    destructor Destroy; override;
    procedure Linear;
    property Duration_ms: integer read FDuration_ms write FDuration_ms;
    property StartValue: integer read FStartValue write FStartValue;
    property StopValue: integer read FStopValue write FStopValue;
    property Tick_ms: integer read FTick_ms write FTick_ms;
    property Updater: TProc<integer> read FUpdater write FUpdater;
  end; { TEasing }

{ Easing }

class procedure Easing.Linear(start, stop, duration_ms, tick_ms: integer;
  updater: TProc<integer>);
var
  easing: TEasing;
begin
  easing := TEasing.Create; // will be destroyed in its own timer
  easing.StartValue := start;
  easing.StopValue := stop;
  easing.Duration_ms := duration_ms;
  easing.Tick_ms := tick_ms;
  easing.Updater := updater;
  easing.Linear;
end; { Easing }

{ TEasing }

destructor TEasing.Destroy;
begin
  FreeAndNil(FTimer);
  updater(StopValue);
  inherited;
end; { TEasing }

procedure TEasing.Linear;
begin
  StartTimer;
end; { TEasing.Linear }

procedure TEasing.StartTimer;
begin
  FTimer := TTimer.Create(nil);
  FTimer.Interval := Tick_ms;
  FTimer.OnTimer := UpdateValue;
  FStart_ms := DSiTimeGetTime64;
end; { TEasing.StartTimer }

procedure TEasing.UpdateValue(sender: TObject);
var
  delta_ms: int64;
  newValue: integer;
begin
  delta_ms := DSiElapsedTime64(FStart_ms);

  if delta_ms >= Duration_ms then
    newValue := StopValue
  else
    newValue := FStartValue + Round((FStopValue - FStartValue) / Duration_ms * delta_ms);

  if newValue = StopValue then
    Destroy
  else
    updater(newValue);
end; { TEasing.UpdateValue }

end.
