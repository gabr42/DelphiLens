unit WizardInterface;

interface

uses
  ToolsAPI,
  Menus,
  ExtCtrls;

{$INCLUDE CompilerDefinitions.inc}

type
  TWizardTemplate = class(TNotifierObject, IOTAWizard, IOTAMenuWizard)
{$IFDEF D2005} strict {$ENDIF} private
{$IFDEF D2005} strict {$ENDIF} protected
  public
    constructor Create;
    destructor Destroy; override;
    // IOTAWizard
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    // IOTAMenuWizard
    function GetMenuText: string;
  end;

implementation

{ TWizardTemplate }

constructor TWizardTemplate.Create;
begin
end;

destructor TWizardTemplate.Destroy;
begin
end;

procedure TWizardTemplate.Execute;
begin
  // Write your code here to be executed when the Menu Item under Help is selected.
end;

function TWizardTemplate.GetIDString: string;
begin
  Result := 'DelphiLensExpert';
end;

function TWizardTemplate.GetMenuText: string;
begin
  Result := 'DelphiLens';
end;

function TWizardTemplate.GetName: string;
begin
  Result := 'DelphiLens Expert';
end;

function TWizardTemplate.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

end.
