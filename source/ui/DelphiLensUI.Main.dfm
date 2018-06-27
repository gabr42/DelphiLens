object frmMainHidden: TfrmMainHidden
  Left = 0
  Top = 0
  Caption = 'Hidden main form'
  ClientHeight = 336
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object tmrInitialWait: TTimer
    Interval = 10000
    OnTimer = tmrInitialWaitTimer
    Left = 24
    Top = 24
  end
end
