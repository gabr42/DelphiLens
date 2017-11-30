unit DelphiLens.UnitInfo.Serializer.Intf;

interface

uses
  System.Classes,
  DelphiLens.UnitInfo;

type
  IDLUnitInfoSerializer = interface ['{1C6EBA83-BD28-42B5-9725-52EF30B8F220}']
    function  Read(stream: TStream; var unitInfo: IDLUnitInfo): boolean;
    procedure Write(const unitInfo: IDLUnitInfo; stream: TStream);
  end; { IDLUnitInfoSerializer }

implementation

end.
