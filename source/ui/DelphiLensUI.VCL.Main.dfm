object frmDLMain: TfrmDLMain
  Left = 0
  Top = 0
  AlphaBlend = True
  AlphaBlendValue = 192
  BorderStyle = bsNone
  Caption = 'Delphi Lens'
  ClientHeight = 375
  ClientWidth = 651
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Tag = 1
    Left = 40
    Top = 32
    Width = 201
    Height = 81
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
end
