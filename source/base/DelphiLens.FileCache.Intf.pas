unit DelphiLens.FileCache.Intf;

interface

uses
  Spring.Collections;

type
  IDLFileContent = IList<string>;

  IDLFileCache = interface ['{C750898C-8DD8-4D64-AD5B-B07220C08913}']
    function GetFile(const unitName: string; var fileContent: IDLFileContent): boolean;
    function Load(const unitName, unitPath: string; var fileContent: IDLFileContent): boolean;
  end; { IDLFileCache }

implementation

end.
