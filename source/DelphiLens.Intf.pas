unit DelphiLens.Intf;

interface

type
  IDelphiLens = interface ['{66B1B796-CD6B-46AE-B402-9CD0329BC5E3}']
    function  GetConditionalDefines: string;
    function  GetProject: string;
    function  GetSearchPath: string;
    procedure SetConditionalDefines(const value: string);
    procedure SetSearchPath(const value: string);
  //
    procedure Rescan;
    property ConditionalDefines: string read GetConditionalDefines write SetConditionalDefines;
    property Project: string read GetProject;
    property SearchPath: string read GetSearchPath write SetSearchPath;
  end; { IDelphiLens }

implementation

end.
