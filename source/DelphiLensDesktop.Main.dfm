object frmDLMain: TfrmDLMain
  Left = 0
  Top = 0
  Caption = 'DelphiLens Desktop'
  ClientHeight = 497
  ClientWidth = 645
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    645
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
    Width = 432
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 1
    OnChange = inpProjectChange
  end
  object btnSelect: TButton
    Left = 555
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
    Width = 513
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    OnExit = SettingExit
  end
  object inpDefines: TEdit
    Left = 117
    Top = 78
    Width = 513
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    OnExit = SettingExit
  end
  object btnRescan: TButton
    Left = 16
    Top = 113
    Width = 138
    Height = 25
    Caption = 'Rescan'
    TabOrder = 4
    OnClick = btnRescanClick
  end
  object outLog: TMemo
    Left = 160
    Top = 152
    Width = 470
    Height = 329
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 5
  end
  object lbFiles: TListBox
    Left = 16
    Top = 152
    Width = 138
    Height = 329
    Anchors = [akLeft, akTop, akBottom]
    ItemHeight = 13
    TabOrder = 6
  end
  object btnParsedUnits: TButton
    Left = 160
    Top = 113
    Width = 113
    Height = 25
    Action = actParsedUnits
    TabOrder = 7
  end
  object btnIncludeFiles: TButton
    Left = 279
    Top = 113
    Width = 113
    Height = 25
    Action = actIncludeFiles
    TabOrder = 8
  end
  object btnNotFound: TButton
    Left = 398
    Top = 113
    Width = 113
    Height = 25
    Action = actNotFound
    TabOrder = 9
  end
  object btnProblems: TButton
    Left = 517
    Top = 113
    Width = 113
    Height = 25
    Action = actProblems
    TabOrder = 10
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
    Left = 560
    Top = 232
  end
  object ActionList: TActionList
    Left = 560
    Top = 168
    object actParsedUnits: TAction
      Caption = 'Show parsed units'
      OnExecute = actParsedUnitsExecute
      OnUpdate = EnableResultActions
    end
    object actIncludeFiles: TAction
      Caption = 'Show include files'
      OnExecute = actIncludeFilesExecute
      OnUpdate = EnableResultActions
    end
    object actNotFound: TAction
      Caption = 'Show missing files'
      OnExecute = actNotFoundExecute
      OnUpdate = EnableResultActions
    end
    object actProblems: TAction
      Caption = 'Show problems'
      OnExecute = actProblemsExecute
      OnUpdate = EnableResultActions
    end
  end
end
