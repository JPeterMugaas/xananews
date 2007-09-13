inherited fmPropertyPageFont: TfmPropertyPageFont
  Left = 242
  Top = 200
  HelpType = htKeyword
  HelpKeyword = 'ColoursFonts'
  Caption = 'fmPropertyPageFont'
  ClientHeight = 381
  ClientWidth = 381
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel2: TBevel [0]
    Left = 59
    Top = 311
    Width = 314
    Height = 3
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsTopLine
  end
  object Label6: TLabel [1]
    Left = 11
    Top = 303
    Width = 38
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Preview'
  end
  inherited Panel1: TPanel
    Width = 381
    inherited Bevel1: TBevel
      Width = 381
    end
    inherited stSectionDetails: TLabel
      Width = 369
    end
  end
  object lvFonts: TListView
    Left = 12
    Top = 60
    Width = 237
    Height = 156
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Font Name'
        Width = 114
      end
      item
        Caption = 'Fixed'
        Width = 40
      end
      item
        Caption = 'Truetype'
        Width = 55
      end>
    ColumnClick = False
    GridLines = True
    HideSelection = False
    OwnerData = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnChange = lvFontsChange
    OnData = lvFontsData
  end
  object lvSizes: TListView
    Left = 256
    Top = 60
    Width = 114
    Height = 156
    Anchors = [akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Font Size (pts)'
        Width = 90
      end>
    ColumnClick = False
    GridLines = True
    HideSelection = False
    OwnerData = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    ViewStyle = vsReport
    OnChange = lvSizesChange
    OnData = lvSizesData
  end
  object gbFontEffects: TGroupBox
    Left = 12
    Top = 229
    Width = 149
    Height = 66
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Font Effects'
    TabOrder = 3
    object cbBold: TCheckBox
      Left = 12
      Top = 16
      Width = 61
      Height = 17
      Caption = '&Bold'
      TabOrder = 0
      OnClick = cbBoldClick
    end
    object cbUnderline: TCheckBox
      Tag = 2
      Left = 77
      Top = 16
      Width = 68
      Height = 17
      Caption = '&Underline'
      TabOrder = 1
      OnClick = cbBoldClick
    end
    object cbStrikeout: TCheckBox
      Tag = 3
      Left = 77
      Top = 36
      Width = 68
      Height = 17
      Caption = '&Strikeout'
      TabOrder = 3
      OnClick = cbBoldClick
    end
    object cbItalic: TCheckBox
      Tag = 1
      Left = 12
      Top = 36
      Width = 61
      Height = 17
      Caption = '&Italic'
      TabOrder = 2
      OnClick = cbBoldClick
    end
  end
  object rePreview: TRichEdit
    Left = 12
    Top = 318
    Width = 359
    Height = 54
    Anchors = [akLeft, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Lines.Strings = (
      'TASK: Shoot yourself in the foot.'
      ''
      'C: You shoot yourself in the foot.'
      ''
      
        'C++: You accidentally create a dozen instances of yourself and s' +
        'hoot '
      'them all in the foot. Providing emergency medical assistance is '
      'impossible '
      
        'since you can'#39't tell which are bitwise copies and which are just' +
        ' pointing '
      'at '
      'others and saying,"That'#39's me, over there."'
      ''
      
        'FORTRAN: You shoot yourself in each toe until you run out of toe' +
        's, '
      'then '
      
        'you read in the next foot and repeat. If you run out of bullets,' +
        ' you '
      
        'continue with the attempts to shoot yourself anyway because you ' +
        'have '
      'no exception-handling capability.'
      ''
      'Pascal: The compiler won'#39't let you shoot yourself in the foot.'
      ''
      
        'Ada: After correctly packing your foot, you attempt to concurren' +
        'tly load '
      
        'the gun, pull the trigger, scream, and shoot yourself in the foo' +
        't. When '
      
        'you try, however, you discover you can'#39't because your foot is of' +
        ' the '
      'wrong type.'
      ''
      'COBOL: Using a COLT 45 HANDGUN, AIM gun at LEG.FOOT, THEN '
      'place '
      'ARM.HAND.FINGER on HANDGUN.TRIGGER and SQUEEZE. '
      'THEN return '
      'HANDGUN to HOLSTER. CHECK whether shoelace needs to be re-'
      'tied.'
      ''
      
        'LISP: You shoot yourself in the appendage which holds the gun wi' +
        'th '
      'which '
      
        'you shoot yourself in the appendage which holds the gun with whi' +
        'ch '
      'you '
      
        'shoot yourself in the appendage which holds the gun with which y' +
        'ou '
      'shoot '
      
        'yourself in the appendage which holds the gun with which you sho' +
        'ot '
      
        'yourself in the appendage which holds the gun with which you sho' +
        'ot '
      'yourself in the appendage which holds...'
      ''
      'FORTH: Foot in yourself shoot.'
      ''
      
        'Prolog: You tell your program that you want to be shot in the fo' +
        'ot. The '
      
        'program figures out how to do it, but the syntax doesn'#39't permit ' +
        'it to '
      'explain it to you.'
      ''
      
        'BASIC: Shoot yourself in the foot with a water pistol. On large ' +
        'systems, '
      'continue until entire lower body is waterlogged.'
      ''
      
        'Visual Basic: You'#39'll really only appear to have shot yourself in' +
        ' the foot, '
      'but '
      'you'#39'll have had so much fun doing it that you won'#39't care.'
      ''
      
        'HyperTalk: Put the first bullet of gun into foot left of leg of ' +
        'you. Answer '
      'the result.'
      ''
      
        'Motif: You spend days writing a UIL description of your foot, th' +
        'e bullet, '
      'its '
      
        'trajectory, and the intricate scrollwork onthe ivory handles of ' +
        'the gun. '
      
        'When you finally get around to pulling the trigger, the gun jams' +
        '.'
      ''
      
        'APL: You shoot yourself in the foot, then spend all day figuring' +
        ' out how '
      'to '
      'do it in fewer characters.'
      ''
      
        'SNOBOL: If you succeed, shoot yourself in the left foot. If you ' +
        'fail, '
      'shoot '
      'yourself in the right foot.'
      ''
      
        'Unix:% ls foot.c foot.h foot.o toe.c toe.o % rm * .o rm:.o no su' +
        'ch file or '
      'directory % ls %'
      ''
      'Concurrent Euclid: You shoot yourself in somebody else'#39's foot.'
      ''
      '370 JCL: You send your foot down to MIS and include a 400-page '
      
        'document explaining exactly how you want it to be shot. Three ye' +
        'ars '
      'later, your foot comes back deep-fried.'
      ''
      
        'Paradox: Not only can you shoot yourself in the foot, your users' +
        ' can, '
      'too.'
      ''
      
        'Access: You try to point the gun at your foot, but it shoots hol' +
        'es in all '
      'your Borland distribution diskettes instead.'
      ''
      
        'Revelation: You'#39're sure you'#39're going to be able to shoot yoursel' +
        'f in the '
      
        'foot, just as soon as you figure out what all these nifty little' +
        ' bullet-'
      'thingies '
      'are for.'
      ''
      
        'Assembler: You try to shoot yourself in the foot, only to discov' +
        'er you '
      
        'must first invent the gun, the bullet, the trigger, and your foo' +
        't.'
      ''
      
        'Modula2: After realizing that you can'#39't actually accomplish anyt' +
        'hing in '
      'this '
      'language, you shoot yourself in the head.'
      ''
      'Anon')
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object gbFontColors: TGroupBox
    Left = 168
    Top = 229
    Width = 209
    Height = 66
    Anchors = [akRight, akBottom]
    Caption = 'Font &Colours:'
    TabOrder = 4
    object Label5: TLabel
      Left = 12
      Top = 38
      Width = 58
      Height = 13
      Caption = '&Background'
    end
    object clrBackground: TColorBox
      Left = 80
      Top = 35
      Width = 121
      Height = 22
      Style = [cbStandardColors, cbExtendedColors, cbSystemColors, cbCustomColor, cbPrettyNames]
      ItemHeight = 16
      TabOrder = 0
      OnChange = clrBackgroundChange
    end
  end
end