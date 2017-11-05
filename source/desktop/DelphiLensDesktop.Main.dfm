object frmDLMain: TfrmDLMain
  Left = 0
  Top = 0
  Caption = 'DelphiLens Desktop'
  ClientHeight = 497
  ClientWidth = 764
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    764
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
  object lblWhatIsShowing: TLabel
    Left = 16
    Top = 152
    Width = 39
    Height = 13
    Caption = 'Analysis'
  end
  object lblLine: TLabel
    Left = 160
    Top = 145
    Width = 23
    Height = 13
    Caption = 'Line:'
  end
  object lblCol: TLabel
    Left = 279
    Top = 145
    Width = 39
    Height = 13
    Caption = 'Column:'
  end
  object lblNodeName: TLabel
    Left = 517
    Top = 145
    Width = 53
    Height = 13
    Caption = '<invisible>'
    Visible = False
  end
  object inpProject: TEdit
    Left = 117
    Top = 16
    Width = 551
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 0
    OnChange = inpProjectChange
  end
  object btnSelect: TButton
    Left = 674
    Top = 14
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Select'
    TabOrder = 1
    OnClick = btnSelectClick
  end
  object inpSearchPath: TEdit
    Left = 117
    Top = 47
    Width = 632
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    OnExit = SettingExit
  end
  object inpDefines: TEdit
    Left = 117
    Top = 78
    Width = 632
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
    Top = 168
    Width = 589
    Height = 313
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 11
  end
  object lbFiles: TListBox
    Left = 16
    Top = 168
    Width = 138
    Height = 313
    Anchors = [akLeft, akTop, akBottom]
    ItemHeight = 13
    TabOrder = 10
    OnClick = lbFilesClick
  end
  object btnParsedUnits: TButton
    Left = 279
    Top = 113
    Width = 113
    Height = 25
    Action = actParsedUnits
    TabOrder = 6
  end
  object btnIncludeFiles: TButton
    Left = 398
    Top = 113
    Width = 113
    Height = 25
    Action = actIncludeFiles
    TabOrder = 7
  end
  object btnNotFound: TButton
    Left = 517
    Top = 113
    Width = 113
    Height = 25
    Action = actNotFound
    TabOrder = 8
  end
  object btnProblems: TButton
    Left = 636
    Top = 113
    Width = 113
    Height = 25
    Action = actProblems
    TabOrder = 9
  end
  object btnAnalysis: TButton
    Left = 160
    Top = 113
    Width = 113
    Height = 25
    Action = actAnalysis
    TabOrder = 5
  end
  object inpLine: TSpinEdit
    Left = 194
    Top = 142
    Width = 64
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 12
    Value = 1
  end
  object inpCol: TSpinEdit
    Left = 328
    Top = 142
    Width = 64
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 13
    Value = 1
  end
  object btnFindNode: TButton
    Left = 398
    Top = 142
    Width = 113
    Height = 22
    Action = actFindSyntaxNode
    TabOrder = 14
  end
  object btnShowUI: TButton
    Left = 636
    Top = 140
    Width = 113
    Height = 25
    Caption = 'Show UI'
    TabOrder = 15
    OnClick = btnShowUIClick
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
    object actAnalysis: TAction
      Caption = 'Show analysis'
      OnExecute = actAnalysisExecute
      OnUpdate = EnableResultActions
    end
    object actFindSyntaxNode: TAction
      Caption = 'Find syntax node'
      OnExecute = actFindSyntaxNodeExecute
      OnUpdate = actFindSyntaxNodeUpdate
    end
  end
end
