unit DelphiLensUI.IPC.Intf;

interface

uses
  System.SysUtils;

const
  CDLUIIPCServerName = 'Gp\FDA8909F-3429-4824-A6C4-7196462F130C\DelphiLens\IPC\UI';

type
  IDLUIIPCClient = interface ['{D9CAF801-6F7D-4A57-9A55-A4DEE10546B6}']
    procedure Connect(timeout_ms: integer; var serverFound, connected: boolean);
  end; { IDLUIIPCClient }

  IDLUIIPCServer = interface ['{492A8AD4-9656-43D4-80EE-E9BCD02B3B12}']
    function  GetOnError: TProc<string>;
    procedure SetOnError(const Value: TProc<string>);
  //
    function  Start: string;
    procedure Stop;
    property OnError: TProc<string> read GetOnError write SetOnError;
  end; { IDLUIIPCServer }

implementation

end.
