unit IdNNTPX;

interface

uses Windows, Classes, SysUtils, IdTCPClient, IdGlobal, IdException, IdAssignedNumbers, IdIOHandlerSocket, ConTnrs;

type
  TModeType = (mtStream, mtIHAVE, mtReader);
  TConnectionResult = (crCanPost, crNoPost, crAuthRequired, crTempUnavailable);
  TModeSetResult = (mrCanStream, mrNoStream, mrCanIHAVE, mrNoIHAVE, mrCanPost, mrNoPost);
  TEventNewNewsList = procedure(const AMsgID: string; var ACanContinue: Boolean) of object;
  TEventNewsgroupList = procedure(const ANewsgroup: string; const ALow, AHigh: Cardinal;
		const AType: string; var ACanContinue: Boolean) of object;
  TNewsTransportEvent = procedure (AMsg: TStringList) of object;

  TGetMessageCommand = (gmHeader, gmBody, gmArticle, gmGroup);
  TPipelineState = (psIdle, psFilling, psProcessing);


TPipeLineCommand = class
private
  fArticleNo: Cardinal;
  fStr : string;
  fCommand: TGetMessageCommand;
  fParam : Integer;
  function GetIsGet: boolean;
public
  constructor Create (AArticleNo : Cardinal; const AMsgID : string; ACommand : TGetMessageCommand; AParam : Integer);
  constructor CreateGroupCommand (const AGroupName : string; AParam : Integer);
  property ArticleNo : Cardinal read fArticleNo;
  property Command : TGetMessageCommand read fCommand;
  property Param : Integer read fParam;
  property MsgID : string read fStr;
  property IsGet : boolean read GetIsGet;
end;

  TPipeLineCommandStartEvent = procedure (cmd : TPipelineCommand; var headrs : TStrings; var body : TStream) of object;
  TPipeLineCommandEvent = procedure (cmd : TPipelineCommand) of object;
  TPipeLineCommandAbortEvent = procedure (cmd : TPipelineCommand; startCalled : boolean) of object;

TidNNTPX = class (TIdTCPClient)
private
  FPipelineSize : Integer;
  FPipeLine : TObjectList;
  FPipeLineCmd : string;
  FPipelineState : TPipelineState;
  FlMsgNo: Cardinal;
  flMsgCount: Cardinal;
  FlMsgLow: Cardinal;
  FlMsgHigh: Cardinal;
  fsMsgID: string;
  fGroupOK : boolean;
  fConectionResult: TConnectionResult;
  fModeResult: TModeSetResult;
  FbSetMode: Boolean;
  FNewsAgent: string;
  FOnNewNewsList: TEventNewNewsList;
  FOnNewsgroupList: TEventNewsgroupList;
  FOnNewGroupsList: TEventNewsGroupList;
  fModeType: TModeType;
  fOnSendIHAVE: TNewsTransportEvent;
  fOnSendCheck: TNewsTransportEvent;
  fOnSendTakethis: TNewsTransportEvent;
  FPipelineCommandEndEvent: TPipelineCommandEvent;
  FPipelineCommandStartEvent: TPipelineCommandStartEvent;
  FPipelineCommandAbortEvent: TPipelineCommandAbortEvent;
  fReadLnDelay: Integer;
  function ConvertDateTimeDist(ADate: TDateTime; AGMT: boolean; const ADistributions: string): string;
  function Get(const ACmd: string; const AMsgNo: Cardinal; const AMsgID: string; AHdr : TStrings; ABody : TStream): Boolean;
  function ReceiveHeader(AMsg: TStrings; const ADelim: string = ''): boolean;
  procedure setConnectionResult(const Value: TConnectionResult);
  procedure SetModeResult(const Value: TModeSetResult);
  procedure SetModeType(const Value: TModeType);
  function SetArticle(const ACmd: string; const AMsgNo: Cardinal; const AMsgID: string): Boolean;
  procedure AddPipelineGetCommand (AArticleNo : Cardinal; const AMsgID : string; ACommand : TGetMessageCommand; AParam : Integer);
  procedure AddPipelineGroupCommand (const AGroupName : string; AParam : Integer);
  procedure ProcessPipeline;
  procedure GetInternalResponse;
public
  constructor Create(AOwner: TComponent); override;
  destructor Destroy; override;
  procedure Connect(const ATimeout: Integer = IdTimeoutDefault); override;
  procedure Disconnect; override;
  function GetBody(const AMsgNo: Cardinal; const AMsgID: string; AMsg: TStream): Boolean;
  function GetHeader(const AMsgNo: Cardinal; const AMsgID: string; AMsg: TStrings): Boolean;
  function GetArticle(const AMsgNo: Cardinal; const AMsgID: string; AHdr : TStrings; ABody: TStream): Boolean;

  function ReadLn(ATerminator: string = LF;
      const ATimeout: Integer = IdTimeoutDefault; AMaxLineLength: Integer = -1): string; override;

  procedure BeginPipeline;
  procedure PipelineGetArticle (AMsgNo: Cardinal; const AMsgId : string; AParam : Integer);
  procedure PipelineGetBody (AMsgNo : Cardinal; const AMsgID: string; AParam : Integer);
  procedure PipelineGetHeader (AMsgNo : Cardinal; const AMsgID: string; AParam : Integer);
  procedure PipelineGroup (const groupName : string; AParam : Integer);
  procedure EndPipeline;
  procedure CancelPipeline;

  procedure GetNewsgroupList(AList : TStrings);
  procedure GetNewGroupsList(const ADate: TDateTime; const AGMT: boolean; const ADistributions: string; AList : TStrings);
  procedure GetOverviewFMT(var AResponse: TStringList);
  function SelectArticle(const AMsgNo: Cardinal): Boolean;
  procedure SelectGroup(const AGroup: string);
  function SendCmd(const AOut: string; const AResponse: Array of SmallInt): SmallInt; override;
  function GetResponse(const AAllowedResponses: array of SmallInt): SmallInt; override;
  procedure SendXOVER(const AParam: string; AResponse: TStrings);
  procedure Send (header, msg : TStrings);
  procedure Authenticate;

  property MsgID: string read fsMsgID;
  property MsgNo: Cardinal read FlMsgNo;
  property MsgHigh: Cardinal read FlMsgHigh;
  property MsgLow: Cardinal read FlMsgLow;
  property GreetingResult: TConnectionResult read fConectionResult write setConnectionResult;
  property ModeResult: TModeSetResult read fModeResult write SetModeResult;
  property MsgCount: Cardinal read flMsgCount write flMsgCount;
  property PipelineSize : Integer read fPipelineSize write fPipelineSize;
  property ReadLnDelay : Integer read fReadLnDelay write fReadLnDelay;
published
  property NewsAgent: string read FNewsAgent write FNewsAgent;
  property Mode : TModeType read fModeType write SetModeType default mtReader;
  property Password;
  property Username;
  property SetMode : Boolean read FbSetMode write FbSetMode default True;
  //property OnDisconnect :TserverEvent read fOnDisconnect write fOnDisconnect;
  //property OnConnect: TServerEvent read fOnConnect write fOnConnect;
  property OnSendCheck :TNewsTransportEvent read fOnSendCheck
                                            write fOnSendCheck;
  property OnSendIHAVE: TNewsTransportEvent read fOnSendIHAVE
                                            write fOnSendIHAVE;
  property OnSendTakeThis: TNewsTransportEvent read fOnSendTakethis
                                               write fOnSendTakethis;
  property OnNewsgroupList: TEventNewsgroupList read FOnNewsgroupList
                                                write FOnNewsgroupList;
  property OnNewGroupsList: TEventNewsGroupList read FOnNewGroupsList
                                                write FOnNewGroupsList;
  property PipelineCommandStartEvent : TPipelineCommandStartEvent read FPipelineCommandStartEvent write FPipelineCommandStartEvent;
  property PipelineCommandEndEvent : TPipelineCommandEvent read FPipelineCommandEndEvent write FPipelineCommandEndEvent;
  property PipelineCommandAbortEvent : TPipelineCommandAbortEvent read FPipelineCommandAbortEvent write FPipelineCommandAbortEvent;
  property OnNewNewsList: TEventNewNewsList read FOnNewNewsList
             write FOnNewNewsList;
  property Port default IdPORT_NNTP;

end;

EIdNNTPConnectionRefused = class (EIdProtocolReplyError);

Procedure ParseXOVER(Aline : String; var AArticleIndex : Cardinal;
  var ASubject,
      AFrom : String;
  var ADate : TDateTime;
  var AMsgId,
      AReferences : String;
  var AByteCount,
      ALineCount : Cardinal;
  var AExtraData : String);

procedure ParseNewsGroup(ALine : String; var ANewsGroup : String;
 var AHi, ALo : Cardinal; var AStatus : String; var isNew : boolean);

implementation

uses IdResourceStrings, IdComponent, NewsGlobals, unitSearchString, unitLog;

var
  lastGoodDate : TDateTime = 0;

Procedure ParseXOVER(Aline : String; var AArticleIndex : Cardinal;
  var ASubject,
      AFrom : String;
  var ADate : TDateTime;
  var AMsgId,
      AReferences : String;
  var AByteCount,
      ALineCount : Cardinal;
  var AExtraData : String);

begin
  {Strip backspace and tab junk sequences which occur after a tab separator so they don't throw off any code}
  ALine := StringReplace(ALine,#9#8#9,#9,[rfReplaceAll]);
  {Article Index}
  AArticleIndex := StrToCard ( Fetch( ALine, #9 ) );
  {Subject}
  ASubject := Fetch ( ALine, #9 );
  {From}
  AFrom := Fetch ( ALine, #9 );
  {Date}
  try
    ADate := GMTToLocalDateTime ( Fetch ( Aline, #9 ) );
    lastGoodDate := ADate;
  except
    ADate := LastGoodDate;
  end;
  {Message ID}
  AMsgId := Fetch ( Aline, #9 );
  {References}
  AReferences := Fetch( ALine, #9);
  {Byte Count}
  AByteCount := StrToCard(Fetch(ALine,#9));
  {Line Count}
  ALineCount := StrToCard(Fetch(ALine,#9));
  {Extra data}
  AExtraData := ALine;
end;

Procedure ParseNewsGroup(ALine : String; var ANewsGroup : String;
            var AHi, ALo : Cardinal;
            var AStatus : String; var isNew : boolean);
begin
  isNew := False;
  if ALine <> '' then
  begin
    if ALine [1] = '"' then
    begin
      ANewsGroup := AnsiDequotedStr (ALine, '"');
      Delete (ALine, 1, Length (ANewsGroup) + 2);
      ALine := TrimLeft (Aline);
    end
    else
      ANewsgroup := Fetch(ALine, ' ');
    AHi := StrToCard(Fetch(Aline, ' '));
    ALo := StrToCard(Fetch(ALine, ' '));
    AStatus := (Fetch (ALine, ' '));

    if LowerCase (Trim (ALine)) = '*' then
      isNew := True
  end
end;

{ TidNNTPX }

procedure TidNNTPX.Authenticate;
begin
  inherited SendCmd('AuthInfo User ' + Username, [281, 381]);

  if LastCmdResult.NumericCode <> 281 then
    inherited SendCmd('AuthInfo Pass ' + Password, [281]);
end;

procedure TidNNTPX.Connect(const ATimeout: Integer);
begin
  inherited;
  if IOHandler is TidIOHandlerSocket then
    TidIOHandlerSOcket (IOHandler).UseNagle := False ;
  try
    GetResponse([]);
    // Here lets check to see what condition we are in after being greeted by
    // the server. The application utilizing NNTPWinshoe should check the value
    // of GreetingResult to determine if further action is warranted.

    Greeting.Assign (LastCmdResult);

    case LastCmdResult.NumericCode of
      200: GreetingResult := crCanPost;
      201: GreetingResult := crNoPost;
      400: GreetingResult := crTempUnavailable;
      // This should never happen because the server should immediately close
      // the connection but just in case ....
      // Kudzu: Changed this to an exception, otherwise it produces non-standard usage by the
      // users code
      502: raise EIdNNTPConnectionRefused.CreateError(502,RSNNTPConnectionRefused);
    end;
    // here we call Setmode on the value stored in mode to make sure we can
    // use the mode we have selected
    case mode of
    mtStream: begin
        SendCmd('mode stream');
        if LastCmdResult.NumericCode <> 203 then
          ModeResult := mrNoStream
        else
          ModeResult := mrCanStream;
      end;
    mtReader: begin
         // We should get the same info we got in the greeting
         // result but we set mode to reader anyway since the
         // server may want to do some internal reconfiguration
         // if it knows that a reader has connected
         SendCmd('mode reader');
         if  LastCmdResult.NumericCode <> 200 then
           ModeResult := mrNoPost
         else
           ModeResult := mrCanPost;
       end;
    end;
  except
    Disconnect;
    Raise;
  end;
end;

constructor TidNNTPX.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Mode := mtReader;
  Port := IdPORT_NNTP;
  SetMode := True;
  MaxLineLength := 32768;
  PipelineSize := 1024;
end;

procedure TidNNTPX.Disconnect;
begin
  try
    if Connected then
      WriteLn('Quit');
  finally
    inherited;
  end;
end;

function TidNNTPX.Get(const ACmd: string; const AMsgNo: Cardinal;
  const AMsgID: string;  AHdr : TStrings; ABody: TStream): Boolean;
var
  LContinue: boolean;
begin
  Result := SetArticle(ACmd, AMsgNo, AMsgID);
  if Result then
  begin
    if Assigned (AHdr) then
      AHdr.Clear;
    if AnsiSameText(ACmd, 'HEAD') then
    begin
      if LastCmdResult.NumericCode in [220, 221] then
        ReceiveHeader (AHdr, '.')
    end
    else
    begin
      if LastCmdResult.NumericCode in [220, 221] then
        LContinue := ReceiveHeader (AHdr, '')
      else
        LContinue := True;

      if LContinue and (LastCmdResult.NumericCode in [220, 222]) then
        Capture (ABody, '.')
    end
  end
end;

function TidNNTPX.GetArticle(const AMsgNo: Cardinal; const AMsgID: string;
  AHdr : TStrings; ABody: TStream): Boolean;
begin
  result := Get ('Article', AMsgNo, AMsgID, AHdr, ABody);
end;

function TidNNTPX.GetBody(const AMsgNo: Cardinal; const AMsgID: string;
  AMsg: TStream): Boolean;
begin
  result := Get ('Body', AMsgNo, AMsgID, Nil, AMsg);
end;

function TidNNTPX.GetHeader(const AMsgNo: Cardinal; const AMsgID: string;
  AMsg: TStrings): Boolean;
begin
  Result := Get('Head', AMsgNo, AMsgID, AMsg, Nil);
end;

procedure TidNNTPX.GetNewsgroupList(AList: TStrings);
begin
  SendCmd('List', 215);
  Capture(AList);
end;

procedure TidNNTPX.GetOverviewFMT(var AResponse: TStringList);
begin
  SendCmd('list overview.fmt', 215);
  Capture(AResponse);
end;

function TidNNTPX.ReceiveHeader(AMsg: TStrings;
  const ADelim: string): boolean;
var
  NewLine: String;
begin
  Result := true;
  BeginWork(wmRead);
  try
    repeat
      NewLine := ReadLn;
      if NewLine = ADelim then begin
        break;
      end else if Copy(NewLine, 1, 2) = '..' then
        NewLine := '.'
      else if newLine = '.' then
      begin
        result := false;
        break;
      end;
      if Assigned (AMsg) then
        AMsg.Append(NewLine);
    until False;

    if Assigned (AMsg) then
      FixHeaders (AMsg);
  finally
    EndWork(wmRead);
  end
end;

function TidNNTPX.SelectArticle(const AMsgNo: Cardinal): Boolean;
begin
  Result := SetArticle('Stat', AMsgNo, '');
end;

procedure TidNNTPX.SelectGroup(const AGroup: string);
var
  s: string;
begin
  SendCmd('Group ' + AGroup, [211]);
  s := LastCmdResult.Text [0];
  FlMsgCount := StrToCard(Fetch(s));
  FlMsgLow := StrToCard(Fetch(s));
  FlMsgHigh := StrToCard(Fetch(s));
end;

procedure TidNNTPX.Send(header, msg: TStrings);
var
  i : Integer;
  name, val : string;
begin
  SendCmd('Post', 340);
  BeginWork(wmWrite);
  try
    for i := 0 to header.Count - 1 do
    begin
      name := header.Names [i];
      val := header.Values [name];
      if name <> '' then
        WriteLn (name + ': ' + val);
    end;

    WriteLn;

    for i := 0 to msg.Count - 1 do
      if Copy (msg [i], 1, 1) = '.' then
        WriteLn ('.' + msg [i])
      else
        WriteLn (msg [i]);
  finally
    EndWork (wmWrite)
  end;
  SendCmd('.', 240);
end;

function TidNNTPX.SendCmd(const AOut: string;
  const AResponse: array of SmallInt): SmallInt;
begin
  // NOTE: Responses must be passed as arrays so that the proper inherited SendCmd is called
  // and a stack overflow is not caused.
  Result := inherited SendCmd(AOut, []);
  if (Result = 480) or (Result = 450) then begin
    result := inherited SendCmd('AuthInfo User ' + Username, [281, 381]);

    if result = 381 then
      inherited SendCmd('AuthInfo Pass ' + Password, [281]);
    Result := inherited SendCmd(AOut, AResponse);
  end else begin
    Result := CheckResponse(Result, AResponse);
  end;
end;

procedure TidNNTPX.SendXOVER(const AParam: string; AResponse: TStrings);
begin
  SendCmd('xover ' + AParam, 224);
  Capture(AResponse);
end;

function TidNNTPX.SetArticle(const ACmd: string; const AMsgNo: Cardinal;
  const AMsgID: string): Boolean;
var
  s: string;
begin
  if AMsgNo >= 1 then
    SendCmd(ACmd + ' ' + IntToStr(AMsgNo))
  else if AMsgID <> '' then
    SendCmd(ACmd + ' ' + AMsgID)
  else // Retrieve / Set currently selected atricle
    SendCmd(ACmd);

  if LastCmdResult.NumericCode in [220, 221, 222, 223] then begin
    if AMsgID = '' then begin
      s := LastCmdResult.Text [0];
      flMsgNo := StrToCard(Fetch(s, ' '));
      fsMsgID := s;
    end
    else
      if AMsgNo < 1 then
      begin
        s := LastCmdResult.Text [0];
        flMsgNo := StrToCard(Fetch(s, ' '))
      end;

    Result := True;
  end else if (LastCmdResult.NumericCode = 421) or (LastCmdResult.NumericCode = 422)
   or (LastCmdResult.NumericCode = 423) or (LastCmdResult.NumericCode = 430) then begin
    // 421 no next article in this group
    // 422 no previous article in this group
    // 423 no such article number in this group
    // 430 no such article found
    Result := False;
  end else begin
    raise EidResponseError.Create(LastCmdResult.Text [0]);
  end;
end;

procedure TidNNTPX.setConnectionResult(const Value: TConnectionResult);
begin
  fConectionResult := Value;
end;

procedure TidNNTPX.SetModeResult(const Value: TModeSetResult);
begin
  fModeResult := Value;
end;

procedure TidNNTPX.SetModeType(const Value: TModeType);
begin
  fModeType := Value;
end;

procedure TIdNNTPX.GetNewGroupsList(const ADate: TDateTime; const AGMT: boolean;
 const ADistributions: string; AList : TStrings);
begin
  SendCmd ('NEWGROUPS ' + ConvertDateTimeDist (ADate, AGMT, ADistributions), 231);
  Capture (AList);
end;


function TidNNTPX.ConvertDateTimeDist(ADate: TDateTime; AGMT: boolean;
  const ADistributions: string): string;
begin
  Result := FormatDateTime('yymmdd hhnnss', ADate);
  if AGMT then begin
    Result:= Result + ' GMT';
  end;
  if Length(ADistributions) > 0 then begin
    Result := ' <' + ADistributions + '>';
  end;
end;

(*----------------------------------------------------------------------*
 | TidNNTPX.BeginPipeline                                               |
 |                                                                      |
 | Start pipelining.  This will fail if it's already pipelining         |
 *----------------------------------------------------------------------*)
procedure TidNNTPX.BeginPipeline;
begin
  if fPipelineState = psIdle then
  begin
    fGroupOK := True;
    fPipelineCmd := '';
    if not Assigned (fPipeLine) then
      fPipeLine := TObjectList.Create
    else
      fPipeLine.Clear;

    fPipelineState := psFilling
  end
end;

destructor TidNNTPX.Destroy;
begin
  fPipeLine.Free;

  inherited;
end;

(*----------------------------------------------------------------------*
 | TidNNTPX.EndPipeline                                                 |
 |                                                                      |
 | Send the pipelined commands, and process the results.                |
 *----------------------------------------------------------------------*)
procedure TidNNTPX.EndPipeline;
begin
  if fPipelineState = psFilling then
  try
    ProcessPipeLine
  finally
    fPipeLineState := psIdle;
  end
end;

procedure TidNNTPX.PipelineGetArticle(AMsgNo: Cardinal; const AMsgID : string; AParam : Integer);
begin
  AddPipelineGetCommand (AMsgNo, AMsgID, gmArticle, AParam)
end;

procedure TidNNTPX.PipelineGetBody(AMsgNo: Cardinal; const AMsgID: string; AParam : Integer);
begin
  AddPipelineGetCommand (AmsgNo, AMsgID, gmBody, AParam)
end;

procedure TidNNTPX.PipelineGetHeader(AMsgNo: Cardinal; const AMsgID: string; AParam : Integer);
begin
  AddPipelineGetCommand (AmsgNo, AMsgID, gmheader, AParam)
end;

procedure TidNNTPX.PipelineGroup(const groupName: string; AParam : Integer);
begin
  AddPipelineGroupCommand (groupName, AParam)
end;

procedure TidNNTPX.CancelPipeline;
begin
  try
    fPipelineState := psIdle;
    if Assigned (fPipeLine) then
      fPipeLine.Clear
  except
  end
end;

procedure TidNNTPX.AddPipelineGetCommand(AArticleNo: Cardinal;
  const AMsgID: string; ACommand: TGetMessageCommand; AParam: Integer);
var
  st, str : string;
begin
  if fPipelineState = psFilling then
  begin
    st := '';

    if AArticleNo = 0 then
      str := AMsgID
    else
      str := IntToStr (AArticleNo);

    case ACommand of
      gmHeader : st := 'HEAD';
      gmBody : st := 'BODY';
      gmArticle : st := 'ARTICLE';
    end;

    st := st + ' ' + str + #13#10;

    if Length (fPipelineCmd) + Length (st) > PipelineSize then
      ProcessPipeLine;
    fPipeLine.Add(TPipeLineCommand.Create(AArticleNo, AMsgID, ACommand, AParam));
    fPipelineCmd := fPipelineCmd + st
  end
end;

procedure TidNNTPX.AddPipelineGroupCommand(const AGroupName: string;
  AParam: Integer);
var
  st : string;
begin
  if fPipelineState = psFilling then
  begin
    st := 'GROUP ' + AGroupName + #13#10;

    if Length (fPipelineCmd) + Length (st) > PipelineSize then
      ProcessPipeLine;

    fPipeLine.Add(TPipeLineCommand.CreateGroupCommand (AGroupName, AParam));
    fPipelineCmd := fPipelineCmd + st
  end
end;

procedure TidNNTPX.ProcessPipeline;
//----------------------------------------------------------
// Do a buffer full of NNTP commands
  procedure ProcessNNTPCommand (const cmd : string; startIdx, endIdx : Integer);
  var
    st, str : string;
    pipelineCommand : TPipeLineCommand;
    resp : Integer;
    respOK : boolean;
    header : TStrings;
    body : TStream;
    seCalled, eeCalled : boolean;
    artNo : Integer;
    msgID : string;

    function ValidResponse (const str : string) : boolean;
    begin
      result := (Length (str) > 4) and (str [4] in [' ', #9]);
      if result then
        result := (str [1] in ['0'..'9']) and
                  (str [1] in ['0'..'9']) and
                  (str [1] in ['0'..'9'])
    end;

  begin
    Write (cmd);      // Send the buffer of commands.

                        // Must get a reply for each one
    while startIdx <= endIdx do
    begin
      pipelineCommand := TPipeLineCommand (fPipeLine [startIdx]);

      repeat
        str := ReadLn; //Wait (20);        // Get the reply
        if not ValidResponse (str) then
        begin
          repeat
            str := ReadLn
          until str = '.';

          str := '';
        end
      until str <> '';                          // Version 1.15.7.5 onwards -
                                                // Ignore blank lines before response
      str := StringReplace (str, #9, ' ', [rfReplaceAll]);
      st := str;
      LogMessage (str);

      resp := StrToIntDef (SplitString (' ', str), -1);
      if resp = -1 then
        raise EIdException.Create('Invalid response in pipeline.  ' + st);

                        // Check whether the expected response was received.
      case pipeLineCommand.Command of
        gmHeader  : respOK := resp in [220..223];       // Don't be too pedantic.
        gmBody    : respOK := resp in [220..223];       // There are lots of
        gmArticle : respOK := resp in [220..223];       // weird servers out there!
        gmGroup   :
          begin
            respOK := resp = 211;
            fGroupOK := respOK  // Set flag to say that the last group change
          end                   // failed.  If so, then ignore all message replies
        else                    // until the next successful group change
          respOK := False
      end;

      seCalled := False;
      eeCalled := False;
      header := Nil;
      body := Nil;
      try
        if respOK and fGroupOK then
        begin
          if pipelineCommand.IsGet then
          begin                                 // Check 22x reply matches what we
                                                // expected.
            artNo := StrToIntDef (SplitString (' ', str), -1);
            msgID := SplitString (' ', str);

            if msgID <> '' then                 // Fix for buggy AToZed server.
            begin
              if Copy (msgId, 1, 1) <> '<' then
                msgID := '<' + msgID;

              if Copy (msgId, Length (msgID), 1) <> '>' then
                msgID := msgID + '>'
            end;

                // nb.  Most servers return '0' for the article no if eg.
                //      HEAD <msgID> was requested - so this bit is of limited
                //     usefulness.  For these servers you should fix up the
                //     article no in PipelineCommandEndEvent
            if pipelineCommand.fArticleNo = 0 then
              pipelineCommand.fArticleNo := artNo;

            if pipelineCommand.fStr = '' then
              pipelineCommand.fStr := msgID;
          end
          else
            artNo := 0;

          if Assigned (PipelineCommandStartEvent) then  // Send event to say that the
          begin                                         // command was successfully started

            PipelineCommandStartEvent (pipelineCommand, header, body);
            seCalled := True;                           // Set a flag so we can clear up

            if pipelineCommand.IsGet then
              if (Integer (pipelineCommand.fArticleNo) <> artNo) or
                 (pipelineCommand.fStr <> msgID) then
                 raise EidException.Create(Format ('Pipeline out of sequence %d %d %s %s', [pipelineCommand.fArticleNo, artNo, pipelineCommand.fStr, msgID]));

            if Assigned (header) then                   // Initialize the buffers passed to us
              header.Clear;

            if Assigned (body) then
              body.Size := 0
          end
          else
          begin
            header := nil;
            body := nil
          end
        end;

        if respOK then                        // We *must* get the response text
        case pipelineCommand.Command of
          gmBody : Capture (body, '.');       // nb. Capture works if body is nil -
                                              // it just discards the result which
                                              // is what we want.

          gmHeader :
            ReceiveHeader (header, '.');
          gmArticle : if ReceiveHeader (header, '') then
                        Capture (body, '.')
        end
        else
          if not seCalled and Assigned (PipelineCommandAbortEvent) then
          begin
            PipelineCommandAbortEvent (pipelineCommand, seCalled);
            eeCalled := True
          end;

                                                // If we called the start event we
                                                // *must* call either end event or cancel event
        if seCalled and Assigned (PipelineCommandEndEvent) then
        begin
          PipelineCommandEndEvent (pipelineCommand);
          eeCalled := True
        end;

      except
        if not eeCalled and Assigned (PipelineCommandAbortEvent) then
        try
          PipelineCommandAbortEvent (pipelineCommand, seCalled)
        except
        end;
        raise
      end;

      Inc (startIdx)
    end
  end;

begin
  if fPipelineState = psFilling then
  begin
    fPipelineState := psProcessing;
    try
      processNNTPCommand (fPipelineCmd, 0, fPipeLine.Count - 1)
    finally
      fPipeLine.Clear;
      fPipelineCmd := '';
      fPipelineState := psFilling
    end
  end
end;

function TidNNTPX.GetResponse(
  const AAllowedResponses: array of SmallInt): SmallInt;
begin
  GetInternalResponse;
  Result := CheckResponse(LastCmdResult.NumericCode, AAllowedResponses);
end;

procedure TidNNTPX.GetInternalResponse;
var
  LLine: string;
  LResponse: TStringList;
  LTerm: string;
begin
  LResponse := TStringList.Create; try
    repeat
      LLine := ReadLnWait;
    until LLine <> '';

    LResponse.Add(LLine);
    if Length(LLine) > 3 then begin
      if LLine[4] = '-' then begin // Multi line response coming
        LTerm := Copy(LLine, 1, 3) + ' ';
        {We keep reading lines until we encounter either a line such as "250" or "250 Read"}
        repeat
          LLine := ReadLnWait;
          LResponse.Add(LLine);
        until (Length(LLine) < 4) or (AnsiSameText(Copy(LLine, 1, 4), LTerm));
      end;
    end;
    FLastCmdResult.ParseResponse(LResponse);
  finally FreeAndNil(LResponse); end;
end;

function TidNNTPX.ReadLn(ATerminator: string; const ATimeout: Integer;
  AMaxLineLength: Integer): string;
begin
  result := inherited ReadLn (ATerminator, ATimeout, AMaxLineLength);
  if fReadLnDelay <> 0 then
    Sleep (fReadLnDelay);
end;

{ TPipeLineCommand }

constructor TPipeLineCommand.Create(AArticleNo: Cardinal; const AMsgID : string;
  ACommand: TGetMessageCommand; AParam : Integer);
begin
  fArticleNo := AArticleNo;
  fStr := AMsgID;
  fCommand := ACommand;
  fParam := AParam;
end;

constructor TPipeLineCommand.CreateGroupCommand(const AGroupName: string; AParam : Integer);
begin
  fStr := AGroupName;
  fCommand := gmGroup;
  fParam := AParam
end;

function TPipeLineCommand.GetIsGet: boolean;
begin
  result := fCommand in [gmHeader, gmBody, gmArticle]
end;

end.