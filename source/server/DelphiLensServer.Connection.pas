unit DelphiLensServer.Connection;

interface

uses
  DelphiLens.Intf;

type
  TConnectionData = class
  strict private
    FConditionals: string;
    FDelphiLens  : IDelphiLens;
    FScanResult  : IDLScanResult;
    FSearchPath  : string;
  public
    property Conditionals: string read FConditionals write FConditionals;
    property DelphiLens: IDelphiLens read FDelphiLens write FDelphiLens;
    property ScanResult: IDLScanResult read FScanResult write FScanResult;
    property SearchPath: string read FSearchPath write FSearchPath;
  end; { TConnectionData }

implementation

end.
