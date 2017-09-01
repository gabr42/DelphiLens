unit DelphiLensProxy;

interface

type
  IDelphiLensProxy = interface ['{1602B867-C10C-4C0C-866E-CE04DFE06224}']
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string);
  end; { IDelphiLensProxy }

var
  DLProxy: IDelphiLensProxy;

implementation

uses
  SysUtils,
  UtilityFunctions,
  DelphiLens;

type
  TDelphiLensProxy = class(TInterfacedObject, IDelphiLensProxy)
  private
  public
    procedure Activate;
    procedure FileActivated(const fileName: string);
    procedure FileModified(const fileName: string);
    procedure ProjectClosed;
    procedure ProjectOpened(const projName: string);
  end; { TDelphiLensProxy }

{ TDelphiLensProxy }

procedure TDelphiLensProxy.Activate;
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.Activate
  except
    on E: Exception do
      OutputMessage(Format('%s in Activate, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.Activate }

procedure TDelphiLensProxy.FileActivated(const fileName: string);
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.FileActivated
  except
    on E: Exception do
      OutputMessage(Format('%s in FileActivated, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.FileActivated }

procedure TDelphiLensProxy.FileModified(const fileName: string);
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.FileModified
  except
    on E: Exception do
      OutputMessage(Format('%s in FileModified, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.FileModified }

procedure TDelphiLensProxy.ProjectClosed;
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.ProjectClosed
  except
    on E: Exception do
      OutputMessage(Format('%s in ProjectClosed, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.ProjectClosed }

procedure TDelphiLensProxy.ProjectOpened(const projName: string);
begin
  try
    // TODO 1 -oPrimoz Gabrijelcic : implement: TDelphiLensProxy.ProjectOpened
  except
    on E: Exception do
      OutputMessage(Format('%s in ProjectOpened, %s', [E.ClassName, E.Message]), 'DelphiLens');
  end;
end; { TDelphiLensProxy.ProjectOpened }

initialization
  DLProxy := TDelphiLensProxy.Create;
finalization
  DLProxy := nil;
end.
