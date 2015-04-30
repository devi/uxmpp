object frmMain: TfrmMain
  Left = 235
  Height = 444
  Top = 139
  Width = 589
  ClientHeight = 444
  ClientWidth = 589
  Color = clBtnFace
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  Position = poScreenCenter
  LCLVersion = '1.0.1.3'
  object Memo1: TMemo
    Left = 32
    Height = 241
    Top = 192
    Width = 515
    Anchors = [akTop, akLeft, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Button1: TButton
    Left = 32
    Height = 25
    Top = 80
    Width = 75
    Caption = 'LOGIN'
    OnClick = Button1Click
    TabOrder = 1
  end
  object Button2: TButton
    Left = 128
    Height = 25
    Top = 80
    Width = 75
    Caption = 'LOGOUT'
    OnClick = Button2Click
    TabOrder = 2
  end
  object Button3: TButton
    Left = 224
    Height = 25
    Top = 80
    Width = 75
    Caption = 'JOIN ROOM'
    OnClick = Button3Click
    TabOrder = 3
  end
  object Button4: TButton
    Left = 328
    Height = 25
    Top = 80
    Width = 75
    Caption = 'LEFT ROOM'
    OnClick = Button4Click
    TabOrder = 4
  end
  object Button5: TButton
    Left = 440
    Height = 25
    Top = 80
    Width = 75
    Caption = 'GetRoomList'
    OnClick = Button5Click
    TabOrder = 5
  end
  object Button6: TButton
    Left = 32
    Height = 25
    Top = 136
    Width = 113
    Caption = 'SendPersonalMessage'
    OnClick = Button6Click
    TabOrder = 6
  end
  object Button7: TButton
    Left = 386
    Height = 25
    Top = 136
    Width = 129
    Caption = 'SendRoomMessage'
    OnClick = Button7Click
    TabOrder = 7
  end
  object Edit1: TEdit
    Left = 32
    Height = 21
    Top = 40
    Width = 171
    TabOrder = 8
  end
  object Edit2: TEdit
    Left = 232
    Height = 21
    Top = 40
    Width = 200
    TabOrder = 9
  end
  object Label1: TLabel
    Left = 32
    Height = 14
    Top = 16
    Width = 38
    Caption = 'Label1'
    ParentColor = False
  end
  object Label2: TLabel
    Left = 232
    Height = 14
    Top = 16
    Width = 38
    Caption = 'Label2'
    ParentColor = False
  end
  object Edit3: TEdit
    Left = 448
    Height = 21
    Top = 40
    Width = 80
    TabOrder = 10
    Text = 'Edit3'
  end
end
