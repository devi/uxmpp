object frmMain: TfrmMain
  Left = 235
  Top = 139
  Width = 589
  Height = 444
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    581
    410)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 32
    Top = 144
    Width = 515
    Height = 241
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Button1: TButton
    Left = 32
    Top = 16
    Width = 75
    Height = 25
    Caption = 'LOGIN'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 128
    Top = 16
    Width = 75
    Height = 25
    Caption = 'LOGOUT'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 256
    Top = 16
    Width = 75
    Height = 25
    Caption = 'JOIN ROOM'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 344
    Top = 16
    Width = 75
    Height = 25
    Caption = 'LEFT ROOM'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 440
    Top = 16
    Width = 75
    Height = 25
    Caption = 'GetRoomList'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 32
    Top = 56
    Width = 113
    Height = 25
    Caption = 'SendPersonalMessage'
    TabOrder = 6
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 384
    Top = 56
    Width = 129
    Height = 25
    Caption = 'SendRoomMessage'
    TabOrder = 7
    OnClick = Button7Click
  end
end
