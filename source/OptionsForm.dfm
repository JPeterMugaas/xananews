inherited fmOptions: TfmOptions
  Left = 189
  Top = 224
  HelpType = htKeyword
  HelpKeyword = 'Options'
  Caption = 'XanaNews Options'
  ExplicitWidth = 320
  ExplicitHeight = 240
  PixelsPerInch = 96
  TextHeight = 13
  inherited Splitter1: TSplitter
    Left = 185
    ExplicitLeft = 185
  end
  inherited pnlOptions: TPanel
    Left = 189
    Width = 374
    ExplicitLeft = 189
    ExplicitWidth = 374
    inherited Bevel1: TBevel
      Width = 374
      ExplicitWidth = 374
    end
  end
  inherited vstSections: TVirtualStringTree
    Width = 185
    ExplicitWidth = 185
  end
  inherited pnlButtons: TPanel
    object Button1: TButton [0]
      Left = 0
      Top = 10
      Width = 145
      Height = 25
      Caption = 'Set as Default Newsreader'
      TabOrder = 0
      OnClick = Button1Click
    end
    inherited btnOK: TButton
      TabOrder = 1
    end
    inherited btnCancel: TButton
      TabOrder = 2
    end
    inherited btnApply: TButton
      TabOrder = 3
    end
    inherited btnHelp: TButton
      TabOrder = 4
    end
  end
  inherited PersistentPosition1: TPersistentPosition
    SubKey = 'Position\Options'
    Left = 160
  end
  inherited PopupMenu1: TPopupMenu
    Left = 192
  end
end