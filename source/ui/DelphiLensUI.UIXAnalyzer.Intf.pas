unit DelphiLensUI.UIXAnalyzer.Intf;

interface

uses
  DelphiLensUI.WorkerContext,
  DelphiLensUI.UIXEngine.Intf;

type
  IDLUIXAnalyzer = interface ['{CB412130-697D-4486-B2B6-153E5BDF4E4A}']
    procedure BuildFrame(const action: IDLUIXAction; const frame: IDLUIXFrame; const context: IDLUIWorkerContext);
    function  CanHandle(const context: IDLUIWorkerContext): boolean;
  end; { IDLUIXAnalyzer }

implementation

 end.
