object frmDLMain: TfrmDLMain
  Left = 0
  Top = 0
  Caption = 'DelphiLens Desktop'
  ClientHeight = 497
  ClientWidth = 625
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    625
    497)
  PixelsPerInch = 96
  TextHeight = 13
  object lblProject: TLabel
    Left = 16
    Top = 19
    Width = 38
    Height = 13
    Caption = 'Project:'
    FocusControl = inpProject
  end
  object lblSearchPath: TLabel
    Left = 16
    Top = 50
    Width = 58
    Height = 13
    Caption = 'Search path'
    FocusControl = inpSearchPath
  end
  object lblDefines: TLabel
    Left = 16
    Top = 81
    Width = 95
    Height = 13
    Caption = 'Conditional defines:'
    FocusControl = inpDefines
  end
  object inpProject: TEdit
    Left = 117
    Top = 16
    Width = 412
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 1
  end
  object btnSelect: TButton
    Left = 535
    Top = 14
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Select'
    TabOrder = 0
    OnClick = btnSelectClick
  end
  object inpSearchPath: TEdit
    Left = 117
    Top = 47
    Width = 493
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
  end
  object inpDefines: TEdit
    Left = 117
    Top = 78
    Width = 493
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
  end
  object btnRescan: TButton
    Left = 24
    Top = 112
    Width = 75
    Height = 25
    Caption = 'Rescan'
    TabOrder = 4
  end
  object dlgOpenProject: TFileOpenDialog
    DefaultExtension = '.dpr'
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Delphi project'
        FileMask = '*.dpr'
      end
      item
        DisplayName = 'Delphi file'
        FileMask = '*.pas'
      end
      item
        DisplayName = 'Any file'
        FileMask = '*.*'
      end>
    Options = []
    Left = 24
    Top = 448
  end
end
