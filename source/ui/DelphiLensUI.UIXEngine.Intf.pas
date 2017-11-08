unit DelphiLensUI.UIXEngine.Intf;

interface

uses
  DelphiLensUI.UIXAnalyzer.Intf;

type
  IDLUIXEngine = interface ['{E263D5F4-6050-46C0-9802-5AAA8D664747}']
    procedure CompleteFrame;
    procedure CreateAction(const analyzerInfo: TDLAnalyzerInfo);
    procedure CreateFrame;
    procedure DestroyFrame;
    procedure ShowFrame;
  end; { IDLUIXEngine }

implementation

end.
