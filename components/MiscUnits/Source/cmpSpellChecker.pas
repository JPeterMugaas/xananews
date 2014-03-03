(*======================================================================*
 | cmpSpellChecker                                                      |
 |                                                                      |
 | ISpell spell checker component.                                      |
 |                                                                      |
 | The contents of this file are subject to the Mozilla Public License  |
 | Version 1.1 (the "License"); you may not use this file except in     |
 | compliance with the License. You may obtain a copy of the License    |
 | at http://www.mozilla.org/MPL/                                       |
 |                                                                      |
 | Software distributed under the License is distributed on an "AS IS"  |
 | basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See  |
 | the License for the specific language governing rights and           |
 | limitations under the License.                                       |
 |                                                                      |
 | Copyright � Colin Wilson 2003  All Rights Reserved                   |
 |                                                                      |
 | Version  Date        By    Description                               |
 | -------  ----------  ----  ------------------------------------------|
 | 1.0      13/02/2003  CPWW  Original                                  |
 *======================================================================*)

unit cmpSpellChecker;

interface

uses
  Windows, SysUtils, Classes, Contnrs, StrUtils;

type
  // ==============================================================
  // TSpeller class
  //
  // Class for controlling ISpell.exe

  TSpeller = class
  private
    fCodePage: Integer;
    pi: TProcessInformation;
    fHInputWrite, fHErrorRead, fHOutputRead: THandle;
  public
    constructor Create(const APath, ACmd: string; ACodePage: Integer);
    destructor Destroy; override;
    procedure SpellCommand(const cmd: AnsiString);
    function GetResponse: string;
    function GetCheckResponse: string;
    property CodePage: Integer read fCodePage;
  end;

  // ==============================================================
  // TISpellLanguage class
  //
  // Class used in fISpellLanguages object list.  Contains the details
  // of the supported language variants

  TISpellLanguage = class
  private
    fCmd: string;
    fPath: string;
    fCodePage: Integer;
    fLang: Integer;
    fName: string;
  public
    constructor Create(const APath, AName: string; ACodePage, ALang: Integer; const ACmd: string);

    property CodePage: Integer read fCodePage;
    property cmd: string read fCmd;    // Cmd to send to ISpell.exe
    property Lang: Integer read fLang; // Language ID
    property name: string read fName;
    property Path: string read fPath;
  end;

  // ==============================================================
  // TSpellChecker class
  //
  // Class for checking words or strings against the ISpell
  // dictionary

  TSpellChecker = class(TComponent)
  private
    fLanguageIdx: Integer;
    fSpeller: TSpeller;
    fQuoteChars: string;
    procedure SetLanguageIdx(const Value: Integer);
    procedure Initialize;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    class function LanguageCount: Integer;
    class function Language(idx: Integer): TISpellLanguage;

    function CheckWord(const ws: WideString; suggestions: TStrings = nil): Boolean;
    function Check(const ws: WideString; startPos: Integer; var selStart, selEnd: Integer;
      suggestions: TStrings = nil; SkipFirstLine: Boolean = False): Boolean;
    procedure Add(const Word: WideString);
    property LanguageIdx: Integer read fLanguageIdx write SetLanguageIdx default - 1;
    property QuoteChars: string read fQuoteChars write fQuoteChars;
  end;

  EISpell = class(Exception)
  end;

procedure InitISpell(const APath: string);

function DefaultISpellLanguage(): Integer;

implementation

uses
  ActiveX, iniFiles, unitCharsetMap, unitSearchString, Registry;

var
  gDefaultISpellLanguage: Integer = -1;
  gISpellInitialized: Boolean = False;
  gISpellLanguages: TObjectList = nil;
  gCoInitialize: Boolean = False;

{ TSpellChecker }

(*----------------------------------------------------------------------*
 | procedure TSpellChecker.Add                                          |
 |                                                                      |
 | Add a word to the ISpell dictionary                                  |
 |                                                                      |
 | Parameters:                                                          |
 |   const word: WideString             The word to add                 |
 *----------------------------------------------------------------------*)
procedure TSpellChecker.Add(const word: WideString);
begin
  if not Assigned(fSpeller) then
    Initialize;
  if Assigned(fSpeller) then
    fSpeller.SpellCommand('*' + WideStringToAnsiString(word, fSpeller.CodePage));
end;

(*----------------------------------------------------------------------*
 | function TSpellChecker.Check                                         |
 |                                                                      |
 | Check the words in a string.  Return false on the first misspelt     |
 | word, or True if there aren't any misspelt words.                    |
 |                                                                      |
 | If it returns false, also fill in the selStart and selEnd variables  |
 | to indicate the (1-based) position and length of the misspelt        |
 | word, and fil in the optional list of suggestions.                   |
 |                                                                      |
 | Parameters:                                                          |
 |   const ws: WideString;      The string of words to check            |
 |   var startPos: Integer;     The starting position for the search    |
 |   var selStart : Integer     Returns position of first misspelling   |
 |   var selEnd : Integer;      Returns the end position of the "       |
 |   suggestions : TStrings     Optional list of suggestions filled in  |
 |                              when there is a misspelling.            |
 *----------------------------------------------------------------------*)
function TSpellChecker.Check(const ws: WideString; startPos: Integer; var selStart,
  selEnd: Integer; suggestions: TStrings; SkipFirstLine: Boolean): Boolean;
var
  l, p, lp: Integer;
  sw, ew: Integer;
  ch: WideChar;
  InQuoteLine: Boolean;

  // --------------------------------------------------------------
  // Check the individual word at sw..ew
  function DoCheck: Boolean;
  begin
    if sw <> -1 then
    begin
      Result := CheckWord(Copy(ws, sw, ew - sw + 1), suggestions);
      if not Result then
      begin
        selStart := sw;
        selEnd := ew;
      end;
      sw := -1;
    end
    else
      Result := True;
  end;

  function IsUrl: Boolean;
  begin
    Result := False;
    // Is it a start of an url?  If so, skip the rest till a whitespace is found.
    if ((l - p) >= 2) and (ch = ':') and (ws[p+1] = '/') and (ws[p+2] = '/')  then
    begin
      Result := True;
      while (p <= l) and not (ch in [#$D, #$A, ' ']) do
      begin
        Inc(p);
        ch := ws[p];
      end;
    end;
  end;

begin
  l := Length(ws);
  if l = 0 then
  begin
    Result := True;
    Exit;
  end;

  sw := -1;
  ew := -1;
  p := startPos;

  // Skip first line if requested - eg. to climb over
  // quote header, etc.
  if SkipFirstLine then
  begin
    ch := ' ';
    while (p <= l) do
    begin
      ch := ws[p];
      if (ch = #$A) or (ch = #$D) then
        Break
      else
        Inc(p);
    end;

    while (p <= l) and ((ch = #$A) or (ch = #$D)) do
    begin
      Inc(p);
      ch := ws[p];
    end;
  end;

  Result := True;

  InQuoteLine := False;
  lp := p;

  // If the StartPos wasn't at the beginning, detect
  // whether we're in the middle of a quote line.

  while (lp > 1) do
  begin
    ch := ws[lp - 1];
    if (ch = #$D) or (ch = #$A) then
    begin
      InQuoteLine := Pos(ws[lp], QuoteChars) > 0;
      Break;
    end
    else
      Dec(lp);
  end;

  // Find each word
  while Result and (p <= l) do
  begin
    ch := ws[p];

    // Keep track of 'start of line' so we can
    // detect quoted lines and signatures.
    if (ch = #$D) or (ch = #$A) then
      lp := 0
    else
      if lp = 1 then
      begin
        InQuoteLine := Pos(ch, QuoteChars) > 0;
        if ((l - p) >= 4) and (ch = '-') and (ws[p+1] = '-') and (ws[p+2] = ' ') and (ws[p+3] = #$D) and (ws[p+4] = #$A) then
        begin
          Result := True;
          Exit;
        end;
      end;

    if IsWideCharAlNum(ch) or (Word(ch) = Word('''')) then
    begin
      if sw = -1 then
        sw := p;
      ew := p;
    end
    else
      if sw <> -1 then
        if not InQuoteLine and not IsUrl then
          Result := DoCheck // End of word found.  Check it.
        else
          sw := -1;
    Inc(p);
    Inc(lp);
  end;
  if Result and (sw <> -1) and not InQuoteLine then
    Result := DoCheck; // Check final word
end;

(*----------------------------------------------------------------------*
 | function TSpellChecker.CheckWord                                     |
 |                                                                      |
 | Check an individual word                                             |
 |                                                                      |
 | Parameters:                                                          |
 |   const ws: WideString               The word to check               |
 |   suggestions: TStrings              Optional suggestions returned   |
 |                                      if the word was misspelt        |
 |                                                                      |
 | The function returns False if the word was misspelt                  |
 *----------------------------------------------------------------------*)
function TSpellChecker.CheckWord(const ws: WideString;
  suggestions: TStrings): Boolean;
var
  resp: string;
begin
  if not Assigned(fSpeller) then
    Initialize;

  if Assigned(fSpeller) then
  begin                         // Send word to ispell.exe
    fSpeller.SpellCommand(WideStringToAnsiString(ws, fSpeller.CodePage));
    resp := fSpeller.GetResponse;
    Result := resp = '';        // If blank line received the word was
                                // spelt OK.
    if Assigned(suggestions) then
    begin
      suggestions.BeginUpdate;
      suggestions.Clear;
      try
        if not Result then
        begin                   // Misspelt word.  Parse the suggestions
          SplitString(':', resp);

          while resp <> '' do
            suggestions.Add(SplitString(',', resp));
        end;
      finally
        suggestions.EndUpdate;
      end;
    end;
  end
  else
    Result := True;
end;

constructor TSpellChecker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fLanguageIdx := -1;
end;

destructor TSpellChecker.Destroy;
begin
  fSpeller.Free;
  inherited Destroy;
end;

procedure TSpellChecker.Initialize;
begin
  if fLanguageIdx = -1 then        // If not language was specified...
    fLanguageIdx := gDefaultISpellLanguage;

  FreeAndNil(fSpeller);
  if (fLanguageIdx >= 0) and Assigned(gISpellLanguages) and (fLanguageIdx < gISpellLanguages.Count) then
    with TISpellLanguage(gISpellLanguages[fLanguageIdx]) do
      fSpeller := TSpeller.Create(Path, cmd, CodePage);
end;

class function TSpellChecker.Language(idx: Integer): TISpellLanguage;
begin
  if (idx >= 0) and (idx < gISpellLanguages.Count) then
    Result := TISpellLanguage(gISpellLanguages[idx])
  else
    Result := nil;
end;

class function TSpellChecker.LanguageCount: Integer;
begin
  if Assigned(gISpellLanguages) then
    Result := gISpellLanguages.Count
  else
    Result := 0;
end;

procedure TSpellChecker.SetLanguageIdx(const Value: Integer);
begin
  if fLanguageIdx <> Value then
  begin
    fLanguageIdx := Value;
    if not(csDesigning in ComponentState) then
      Initialize;
  end;
end;

{ TISpellLanguage }

(*----------------------------------------------------------------------*
 | constructor TISpellLanguage.Create                                   |
 |                                                                      |
 | Constructor for TISpellLanguage                                      |
 |                                                                      |
 | Parameters:                                                          |
 |   const APath,               // Initial values of fields             |
 |   const AName: string;                                               |
 |   ACodePage,                                                         |
 |   ALang: Integer;                                                    |
 |   const ACmd: string                                                 |
 *----------------------------------------------------------------------*)
constructor TISpellLanguage.Create(const APath, AName: string; ACodePage, ALang: Integer;
  const ACmd: string);
begin
  fPath := APath;
  fName := AName;
  fCodePage := ACodePage;
  fLang := ALang;
  fCmd := ACmd;
end;

procedure CreateSTDHandles(const sa: TSecurityAttributes; var hInputRead, hInputWrite, hOutputRead,
  hOutputWrite, hErrorRead, hErrorWrite: THandle);
var
  hOutputReadTmp: THandle;
  hInputWriteTmp: THandle;
  hErrorReadTmp: THandle;
begin
  hOutputReadTmp := 0;
  hInputWriteTmp := 0;
  hErrorReadTmp := 0;
  hInputRead := 0;
  hInputWrite := 0;
  hOutputRead := 0;
  hOutputWrite := 0;
  hErrorRead := 0;
  hErrorWrite := 0;

  try
    if not CreatePipe(hOutputReadTmp, hOutputWrite, @sa, 0) then
      RaiseLastOSError;

    if not CreatePipe(hErrorReadTmp, hErrorWrite, @sa, 0) then
      RaiseLastOSError;

    if not CreatePipe(hInputRead, hInputWriteTmp, @sa, 0) then
      RaiseLastOSError;

    if not DuplicateHandle(GetCurrentProcess, hOutputReadTmp, GetCurrentProcess, @hOutputRead, 0, False, DUPLICATE_SAME_ACCESS) then
      RaiseLastOSError;

    if not DuplicateHandle(GetCurrentProcess, hErrorReadTmp, GetCurrentProcess, @hErrorRead, 0, False, DUPLICATE_SAME_ACCESS) then
      RaiseLastOSError;

    if not DuplicateHandle(GetCurrentProcess, hInputWriteTmp, GetCurrentProcess, @hInputWrite, 0, False, DUPLICATE_SAME_ACCESS) then
      RaiseLastOSError;

    CloseHandle(hOutputReadTmp); hOutputReadTmp := 0;
    CloseHandle(hInputWriteTmp); hInputWriteTmp := 0;
    CloseHandle(hErrorReadTmp);  hErrorReadTmp := 0;

  except
    if hOutputReadTmp  <> 0 then CloseHandle(hOutputReadTmp);
    if hInputWriteTmp  <> 0 then CloseHandle(hInputWriteTmp);
    if hErrorReadTmp   <> 0 then CloseHandle(hErrorReadTmp);
    if hInputRead      <> 0 then CloseHandle(hInputRead);    hInputRead := 0;

    if hInputWrite     <> 0 then CloseHandle(hInputWrite);   hInputWrite := 0;
    if hOutputRead     <> 0 then CloseHandle(hOutputRead);   hOutputRead := 0;
    if hOutputWrite    <> 0 then CloseHandle(hOutputWrite);  hOutputWrite := 0;
    if hErrorRead      <> 0 then CloseHandle(hErrorRead);    hErrorRead := 0;
    if hErrorWrite     <> 0 then CloseHandle(hErrorWrite);   hErrorWrite := 0;

    raise;
  end;
end;

{ TSpeller }

(*----------------------------------------------------------------------*
 | constructor TSpeller.Create                                          |
 |                                                                      |
 | Create the ISpell.exe controller class.  Run ISpell with input       |
 | output and error pipes.                                              |
 |                                                                      |
 | Parameters:                                                          |
 |   const APath,                                                       |
 |   ACmd: string;                                                      |
 |   ACodePage : Integer                                                |
 *----------------------------------------------------------------------*)
constructor TSpeller.Create(const APath, ACmd: string; ACodePage: Integer);
var
  si: TStartupInfo;
  buf: string;
  hInputRead, hOutputWrite, hErrorWrite: THandle;
  sa: TSecurityAttributes;
begin
  fCodePage := ACodePage;
  SetEnvironmentVariable('HOME', PChar(APath));

  sa.nLength := SizeOf(TSecurityAttributes);
  sa.lpSecurityDescriptor := nil;
  sa.bInheritHandle := True;

  FillChar(pi, SizeOf(pi), 0);
  FillChar(si, SizeOf(si), 0);

  CreateStdHandles(sa, hInputRead, fHInputWrite, fHOutputRead, hOutputWrite, fHErrorRead, hErrorWrite);

  try
    si.cb := SizeOf(si);
    si.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    si.hStdOutput := hOutputWrite;
    si.hStdInput := hInputRead;
    si.hStdError := hErrorWrite;
    si.wShowWindow := SW_HIDE;

    if not CreateProcess(nil, PChar(ACmd), @sa, @sa, True, 0, nil, nil, si, pi) then
      RaiseLastOSError;
  finally
    CloseHandle(hOutputWrite);
    CloseHandle(hInputRead);
    CloseHandle(hErrorWrite);
  end;

  buf := GetCheckResponse;
  SpellCommand('!');
end;

destructor TSpeller.Destroy;
begin
  if pi.hProcess <> 0 then
  begin
    SpellCommand(^Z); // Send Ctrl-Z to ISpell to terminate it
    WaitForSingleObject(pi.hProcess, 1000); // Wait for it to finish
  end;

  try
    if pi.hThread <> 0 then CloseHandle(pi.hThread);
    if pi.hProcess <> 0 then CloseHandle(pi.hProcess);
    if fHInputWrite <> 0 then CloseHandle(fHInputWrite);
    if fHErrorRead <> 0 then CloseHandle(fHErrorRead);
    if fHOutputRead <> 0 then CloseHandle(fHOutputRead);
  except
    on E: Exception do
      TerminateProcess(pi.hProcess, 0);
  end;
  inherited Destroy;
end;

(*----------------------------------------------------------------------*
 | function TSpeller.GetCheckResponse                                   |
 |                                                                      |
 | Get a response.  If the response was on stderr, raise an exception   |
 *----------------------------------------------------------------------*)
function TSpeller.GetCheckResponse: string;
var
  l: DWORD;

  // ReadPipe
  //
  // Read from a pipe.  If there's nothing in the pipe return an empty string
  function ReadPipe(pipeHandle: THandle; var s: string): Boolean;
  var
    avail: DWORD;
  begin
    if not PeekNamedPipe(pipeHandle, nil, 0, nil, @avail, nil) then
      RaiseLastOSError;

    if avail > 0 then
    begin
      SetLength(s, avail + 512);

      if not ReadFile(pipeHandle, s[1], avail + 512, avail, nil) then
        RaiseLastOSError;

      SetLength(s, avail);
      Result := True;
    end
    else
      Result := False;
  end;

begin { GetCheckResponse }
  l := 20;
  Sleep(100);
  repeat
    { Try stdout first }
    if ReadPipe(fHOutputRead, Result) then
      break;

    { Try stderr }
    if ReadPipe(fHErrorRead, Result) then
      raise EISpell.Create(Result);

    Sleep(100);
    Dec(l);
  until l = 0;

  if l = 0 then
    Result := ''; // raise EISpell.Create ('Timeout in ISpell');

  Result := Trim(Result);
end;

function TSpeller.GetResponse: string;
var
  ansi: AnsiString;
  avail: DWORD;
begin
  Result := '';

  SetLength(ansi, 2048);
  if ReadFile(fHOutputRead, ansi[1], 2048, avail, nil) then
  begin
    SetString(Result, PAnsiChar(ansi), avail);
    Result := Trim(Result);
  end
  else
    RaiseLastOSError;
end;

procedure TSpeller.SpellCommand(const cmd: AnsiString);
var
  n: DWORD;
begin
  WriteFile(fHInputWrite, (cmd + #13#10)[1], Length(cmd) + 2, n, nil);
end;

procedure InitISpell(const APath: string);
var
  reg: TRegistry;
  ISpellPath, ISpellRoot, s, name, cmd: string;
  f: TSearchRec;
  flags: LongWord;
  sections: TStrings;
  i: Integer;
  sectionLanguage: Integer;

  function GetISpellPathFromRegistry: string;
  begin
    flags := KEY_READ;
    {$ifdef CPUX64}
      flags := flags or KEY_WOW64_32KEY;
    {$endif}
    reg := TRegistry.Create(flags);
    try
      reg.RootKey := HKEY_LOCAL_MACHINE;
      if reg.OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ispell.exe', False) then
        Result := reg.ReadString('Path')
      else
        Result := '';
    finally
      reg.Free;
    end;
  end;

  function SpellerForLocale(locale: Integer): Integer;
  var
    i: Integer;
  begin
    Result := -1;

    for i := 0 to gISpellLanguages.Count - 1 do
      if TISpellLanguage(gISpellLanguages[i]).Lang = locale then
      begin
        Result := i;
        Break;
      end;
  end;

begin
  if not gCoInitialize then
    if CoInitialize(nil) = S_OK then
      gCoInitialize := True;

  ISpellPath := ExpandFileName(APath);
  if not ((Length(Trim(ISpellPath)) <> 0) and (DirectoryExists(ISpellPath))) then
    ISpellPath := GetISpellPathFromRegistry;

  ISpellRoot := ExtractFilePath(ISpellPath);
  ISpellPath := IncludeTrailingPathDelimiter(ISpellPath);

  if DirectoryExists(ISpellPath) then
  begin

    if FindFirst(ISpellPath + '*.*', faDirectory, f) = 0 then
    begin
      if not Assigned(gISpellLanguages) then
        gISpellLanguages := TObjectList.Create
      else
        gISpellLanguages.Clear;

      try
        sections := TStringList.Create;
        try
          // Enumerate the subdirectories of the ISpell
          // directory.  Each one will containe a language
          repeat
            if ((f.Attr and faDirectory) <> 0) and (Copy(f.name, 1, 1) <> '.') then
              with TInIFile.Create(ISpellPath + f.name + '\ISpell.ini') do
                try
                  ReadSections(sections);
                  sectionLanguage := 1033;
                  for i := 0 to sections.Count - 1 do
                  begin
                    // Read the language settings from the .INI file
                    // in the language directory
                    s := sections[i];
                    if s = '' then
                      name := f.name
                    else
                      name := s;

                    cmd := ReadString(s, 'Cmd', '');
                    cmd := StringReplace(cmd, '%UniRed%', ISpellRoot, [rfReplaceAll, rfIgnoreCase]);

                    sectionLanguage := ReadInteger(s, 'LangNo', sectionLanguage);

                    gISpellLanguages.Add(TISpellLanguage.Create(
                      ExcludeTrailingPathDelimiter(ISpellPath),
                      name,
                      MIMECharsetNameToCodePage(ReadString(s, 'Charset', 'us-ascii')),
                      sectionLanguage,
                      cmd));
                  end;
                finally
                  Free;
                end;
          until FindNext(f) <> 0;
        finally
          sections.Free;
        end;
      finally
        FindClose(f);
      end;
    end;
  end;

  if Assigned(gISpellLanguages) then
  begin
    if gDefaultISpellLanguage = -1 then
      gDefaultISpellLanguage := SpellerForLocale(GetThreadLocale);

    if gDefaultISpellLanguage = -1 then
      gDefaultISpellLanguage := SpellerForLocale(GetUserDefaultLCID);

    if gDefaultISpellLanguage = -1 then
      gDefaultISpellLanguage := SpellerForLocale(GetSystemDefaultLCID);

    if gDefaultISpellLanguage = -1 then
      gDefaultISpellLanguage := SpellerForLocale(1033); // US English

    if (gDefaultISpellLanguage = -1) and (gISpellLanguages.Count > 0) then
      gDefaultISpellLanguage := 0;
  end;
  gISpellInitialized := True;
end;

function DefaultISpellLanguage(): Integer;
begin
  if not gISpellInitialized then
    InitISpell('');
  Result := gDefaultISpellLanguage;
end;

initialization

finalization
  gISpellLanguages.Free;
  if gCoInitialize then
    CoUninitialize;
end.
