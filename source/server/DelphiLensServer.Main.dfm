object frmDelphiLensServer: TfrmDelphiLensServer
  Left = 0
  Top = 0
  Caption = 'DelphiLens Server'
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    635
    299)
  PixelsPerInch = 96
  TextHeight = 13
  object lbLog: TListBox
    Left = 8
    Top = 8
    Width = 619
    Height = 283
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 0
  end
  object IdCmdTCPServer1: TIdCmdTCPServer
    Active = True
    Bindings = <
      item
        IP = '0.0.0.0'
        Port = 8888
      end>
    DefaultPort = 0
    OnConnect = IdCmdTCPServer1Connect
    OnDisconnect = IdCmdTCPServer1Disconnect
    CommandHandlers = <
      item
        CmdDelimiter = ' '
        Command = 'SET'
        Description.Strings = (
          'Sets parameters for currently open project. Possible parameters:'
          ''
          '  SEARCHPATH=search_path'
          '  CONDITIONALS=conditional_symbols')
        Disconnect = False
        Name = 'CmdSet'
        NormalReply.Code = '200'
        ParamDelimiter = '='
        ParseParams = True
        Tag = 0
        OnCommand = CmdSet
      end
      item
        CmdDelimiter = ' '
        Command = 'OPEN'
        Description.Strings = (
          'Opens Delphi project')
        Disconnect = False
        Name = 'CmdOpen'
        NormalReply.Code = '200'
        ParamDelimiter = ' '
        ParseParams = True
        Tag = 0
        OnCommand = CmdOpen
      end
      item
        CmdDelimiter = ' '
        Command = 'SHOW'
        Disconnect = False
        Name = 'CmdShow'
        NormalReply.Code = '200'
        ParamDelimiter = ' '
        ParseParams = True
        Tag = 0
        OnCommand = CmdShow
      end
      item
        CmdDelimiter = ' '
        Command = 'CLOSE'
        Description.Strings = (
          'Closes currently open project')
        Disconnect = False
        Name = 'CmdClose'
        NormalReply.Code = '200'
        ParamDelimiter = ' '
        ParseParams = True
        Tag = 0
        OnCommand = CmdClose
      end
      item
        CmdDelimiter = ' '
        Command = 'QUIT'
        Description.Strings = (
          'Closes TCP/IP connection')
        Disconnect = False
        Name = 'CmdQuit'
        NormalReply.Code = '200'
        ParamDelimiter = ' '
        ParseParams = True
        Tag = 0
        OnCommand = CmdQuit
      end>
    ExceptionReply.Code = '500'
    ExceptionReply.Text.Strings = (
      'Unknown Internal Error')
    Greeting.Code = '200'
    Greeting.Text.Strings = (
      'Welcome')
    HelpReply.Code = '100'
    HelpReply.Text.Strings = (
      'Help follows')
    MaxConnectionReply.Code = '300'
    MaxConnectionReply.Text.Strings = (
      'Too many connections. Try again later.')
    ReplyTexts = <>
    ReplyUnknownCommand.Code = '400'
    ReplyUnknownCommand.Text.Strings = (
      'Unknown Command')
    Left = 544
    Top = 224
  end
end
