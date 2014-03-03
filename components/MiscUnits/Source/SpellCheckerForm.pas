unit SpellCheckerForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, cmpCWSpellChecker, cmpCWRichEdit,
  cmpPersistentPosition, unitExSettings;

type
  TfmSpellChecker = class(TForm)
    Label1: TLabel;
    lblSuggestions: TLabel;
    btnChange: TButton;
    btnChangeAll: TButton;
    btnSkipAll: TButton;
    btnSkip: TButton;
    btnAdd: TButton;
    btnCancel: TButton;
    btnFinish: TButton;
    reText: TExRichEdit;
    lvSuggestions: TListView;
    PersistentPosition1: TPersistentPosition;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSkipClick(Sender: TObject);
    procedure btnChangeClick(Sender: TObject);
    procedure btnChangeAllClick(Sender: TObject);
    procedure lvSuggestionsDblClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnSkipAllClick(Sender: TObject);
    procedure PersistentPosition1GetSettingsClass(Owner: TObject; var SettingsClass: TExSettingsClass);
    procedure PersistentPosition1GetSettingsFile(Owner: TObject; var fileName: string);
  private
    fChecker: TCWSpellChecker;
    fText: WideString;
    fBadWord: WideString;
    fBadSS: Integer;
    fIgnoreWords: TStringList;
    fSS, fSE: Integer;
    fQuoteChars: string;
    FSettingsFilename: string;
    FSettingsClass: TExSettingsClass;
    procedure ErrorFoundAt(ss, se: Integer; suggestions: TStrings);
    procedure NextWord;
    function GetChangedWord: WideString;
  protected
    procedure UpdateActions; override;
  public
    destructor Destroy; override;
    procedure Initialize(checker: TCWSpellChecker; ss, se: Integer; suggestions: TStrings);
    property QuoteChars: string read fQuoteChars write fQuoteChars;
    property SettingsClass: TExSettingsClass read FSettingsClass write FSettingsClass;
    property SettingsFilename: string read FSettingsFilename write FSettingsFilename;
  end;

var
  fmSpellChecker: TfmSpellChecker;

implementation

uses
  unitCharsetMap;

{$R *.dfm}

{ TfmSpellChecker }

procedure TfmSpellChecker.Initialize(checker: TCWSpellChecker; ss, se: Integer;
  suggestions: TStrings);
begin
  fChecker := checker;
  fText := fChecker.ExRichEdit.Text;
  reText.CodePage := fChecker.ExRichEdit.CodePage;
  reText.Text := fText;
  fChecker.ExRichEdit.SetRawSelection(ss, se);
  fSS := ss;
  fSE := se;
  reText.SetRawSelection(ss, se);
  fBadWord := fChecker.ExRichEdit.SelText;

  ErrorFoundAt(ss, se, suggestions);
end;

procedure TfmSpellChecker.FormDestroy(Sender: TObject);
begin
  fmSpellChecker := nil;
end;

procedure TfmSpellChecker.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfmSpellChecker.ErrorFoundAt(ss, se: Integer; suggestions: TStrings);
var
  i: Integer;
begin
  fBadSS := ss;

  lvSuggestions.Items.BeginUpdate;
  try
    lvSuggestions.Items.Clear;
    for i := 0 to suggestions.Count - 1 do
      with lvSuggestions.Items.Add do
        Caption := suggestions[i];
  finally
    lvSuggestions.Items.EndUpdate;
  end;

  if lvSuggestions.Items.Count > 0 then
  begin
    lvSuggestions.ItemFocused := lvSuggestions.Items[0];
    lvSuggestions.Selected    := lvSuggestions.Items[0];
    ActiveControl := lvSuggestions;

    btnFinish.Default := False;
    btnChange.Default := True;
  end;
end;

procedure TfmSpellChecker.UpdateActions;
var
  errorFound: Boolean;
  canChange: Boolean;
begin
  errorFound := fBadWord <> '';

  if errorFound then
  begin
    btnSkip.Enabled := True;
    btnSkipAll.Enabled := True;
    canChange := (lvSuggestions.ItemIndex <> -1) or (reText.Text <> fText);
    btnChange.Enabled := canChange;
    btnChangeAll.Enabled := canChange;
  end
  else
  begin
    btnSkip.Enabled := False;
    btnSkipAll.Enabled := False;
    btnChange.Enabled := False;
    btnChangeAll.Enabled := False;
  end;
end;

procedure TfmSpellChecker.btnSkipClick(Sender: TObject);
begin
  NextWord;
end;

procedure TfmSpellChecker.NextWord;
var
  ss, se: Integer;
  suggestions: TStrings;
  ok: Boolean;
begin
  repeat
    reText.GetRawSelection(ss, se);

    suggestions := TStringList.Create;
    try
      ok := fChecker.Check(fText, se + 1, ss, se, suggestions);
      if not ok then
      begin
        fChecker.ExRichEdit.SetRawSelection(ss, se);
        reText.SetRawSelection(ss, se);
        fBadWord := fChecker.ExRichEdit.SelText;
        if not Assigned(fIgnoreWords) or
          (fIgnoreWords.IndexOf(fBadWord) = -1) then
        begin
          ErrorFoundAt(ss, se, suggestions);
          Break;
        end;
      end
      else
      begin
        ModalResult := mrOK;
        Break;
      end;
    finally
      suggestions.Free;
    end;
  until False;
end;

procedure TfmSpellChecker.PersistentPosition1GetSettingsClass(Owner: TObject;
  var SettingsClass: TExSettingsClass);
begin
  SettingsClass := FSettingsClass;
end;

procedure TfmSpellChecker.PersistentPosition1GetSettingsFile(Owner: TObject;
  var fileName: string);
begin
  fileName := FSettingsFilename;
end;

procedure TfmSpellChecker.btnChangeClick(Sender: TObject);
begin
  if reText.Text <> fText then
  begin
    fText := reText.Text;
    fChecker.ExRichEdit.Text := fText
  end
  else
  begin
    fChecker.ExRichEdit.SelText := lvSuggestions.Selected.Caption;
    fText := fChecker.ExRichEdit.Text;
    reText.SelText := lvSuggestions.Selected.Caption;
  end;
  NextWord;
end;

procedure TfmSpellChecker.btnChangeAllClick(Sender: TObject);
var
  ss: Integer;
  newWord: string;
begin
  if reText.Text <> fText then
    newWord := GetChangedWord
  else
    newWord := lvSuggestions.Selected.Caption;

  ss := fBadSS - 1;

  fText := Copy(fText, 1, ss) + StringReplace(Copy(fText, ss + 1, MaxInt),
    fBadWord, newWord, [rfReplaceAll, rfIgnoreCase]);
  fChecker.ExRichEdit.Text := fText;
  reText.Text := fText;

  reText.SetRawSelection(ss + 1, ss + 1 + Length(newWord));

  NextWord;
end;

procedure TfmSpellChecker.lvSuggestionsDblClick(Sender: TObject);
begin
  btnChangeClick(nil);
end;

function TfmSpellChecker.GetChangedWord: WideString;
var
  changedText: WideString;
  p, l, ew: Integer;
  ch: WideChar;
begin
  changedText := reText.Text;
  l := Length(changedText);
  p := fBadSS;

  ew := -1;

  while p < l do
  begin
    ch := changedText[p];

    if IsWideCharAlNum(ch) or (word(ch) = word('''')) then
      ew := p
    else
      Break;

    Inc(p);
  end;

  if ew = -1 then
    Result := ''
  else
    Result := Copy(changedText, fBadSS, ew - fBadSS + 1);
end;

procedure TfmSpellChecker.btnAddClick(Sender: TObject);
begin
  fChecker.Add(fBadWord);
  NextWord;
end;

destructor TfmSpellChecker.Destroy;
begin
  fIgnoreWords.Free;

  inherited Destroy;
end;

procedure TfmSpellChecker.btnSkipAllClick(Sender: TObject);
begin
  if not Assigned(fIgnoreWords) then
  begin
    fIgnoreWords := TStringList.Create;
    fIgnoreWords.CaseSensitive := False;
  end;
  fIgnoreWords.Add(fBadWord);
  NextWord;
end;

procedure TfmSpellChecker.FormShow(Sender: TObject);
begin
  reText.SetRawSelection(fSS, fSE);
end;

end.
