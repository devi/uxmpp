//
// simple xmpp implementation
//
// credits: exodus, synapse and libxmlparser
//
// contact: devi[dot]mandiri[at]gmail[dot]com
//
// tested with openfire, ejabberd and googletalk

unit uxmpp;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

// uncomment this line to debug xml line by line...
{$DEFINE DEBUG_XML}

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  Classes, SysUtils, tcpsynapse, xmltag, ExtCtrls;

type
  TMessageType  = (mtRoom,mtPersonal);

  TChatMessageEvent = procedure(Sender:TObject;
                                From:string;
                                MsgText:string;
                                MsgHTML:string;
                                TimeStamp:TDateTime;
                                MsgType:TMessageType) of object;

{
  TOfflineMessageEvent = procedure(Sender:TObject;
                                   From:string;
                                   MsgText:string;
                                   MsgHTML:string;
                                   TimeStamp:TDateTime) of object;
}
  TErrorEvent   = procedure(Sender:TObject;ErrMsg:string) of object;
  TRoomPresence = procedure(Sender:TObject;JID:string) of object;
  TRoomListEvent= procedure(Sender:TObject;RoomName:string) of object;
  TRosterEvent  = procedure(Sender:TObject;JID,Name,Subscription,Group:string) of object;

  TPresenceEvent= procedure(Sender:TObject;Presence_Type,JID,Resource,Status,Photo : string) of object;
  TIqVcardEvent = procedure(Sender:TObject; from_, to_, fn_, photo_type_, photo_bin_ : string) of object;

  TXmpp=class
  private
    FSocket:TTCPClient;
    FHost,FPort,
    FUser,FPass,
    FResource,FCurServer,
    FRoomName:string;
    {$IFDEF DEBUG_XML}
    FOnDebugXML:TTCPEvent;
    {$ENDIF}
    FAuthd,
    FSessAuth,
    FPresenceSet,
    FMD5,FCramMD5,
    FPLAIN:Boolean;
    FRoot,FRootTag,
    FBuff,FSessID,
    FJID,FConference:string;
    FMD5Step,FCramMD5Step,
    FMYID,FMSGID:integer;
    FParser:TXMLTagParser;

    FOnError:TErrorEvent;
    FOnLogin,
    FOnLogout:TNotifyEvent;

    FOnChat:TChatMessageEvent;
//    FOnOfflineMsg:TOfflineMessageEvent;
    FOnRoster:TRosterEvent;

    FOnJoinedRoom,
    FOnLeftRoom:TRoomPresence;

    FOnPresence : TPresenceEvent;
    FOnIqVcard  : TIqVcardEvent;

    FRoomRoster:TStringList;
    FTimer:TTimer;
    FOnRoomList:TRoomListEvent;

    FCurrentID:string; // just test

    procedure DoOnConnected(Sender:TObject);
    procedure DoOnDisconnected(Sender:TObject);
    procedure DoOnDebugXML(Sender:TObject; Value:String);
    procedure DoOnError(Sender:TObject; Value:string);
    procedure DoAfterUpgradedToSSL(Sender:TObject);
    procedure DoOnSSLFailed(Sender:TObject;Value:string);

    procedure SetDefaultVal;
    procedure DoError(ErrMsg:string); // zzz...
    procedure SendXMPPHeader(AHost:string);
    function  GetFullTag(AData:string):string;
    procedure ProsesData(AData:string);
    procedure ParseTags(AData:string);
    procedure ProsesTags(tag:TXMLTag);
    procedure ParsingFeatures(tag:TXMLTag);
    procedure ParsingIQ(tag:TXMLTag);
    procedure IQBeforeLoggedIn(tag: TXMLTag);
    procedure ParsingPresence(tag:TXMLTag);
    procedure ParsingMessage(tag:TXMLTag);
    procedure BindingResource;
    procedure BindingSession;

    procedure SendAuth(AuthMethod:string);

    procedure SendMD5Auth;
    procedure SendMD5Response(tag:TXMLTag);
    procedure SendCramMD5Auth;
    procedure SendCramMD5Response(tag:TXMLTag);
    procedure SendPLAINAuth;

    // hmm.... a "command callback" or "signal listener"... what d'u think ?
    function  GenerateID:string;

    function  GetJID:string;
    function  GenerateMSGID:string;

    procedure AddToRosterRoom(JID:string);
    function  IsInRosterRoom(JID:string):Boolean;
    procedure RemoveFromRosterRoom(JID:string);
    function  GetRosterRoomJID(JID:string):string;

    procedure DoOnTimer(Sender:TObject);
    procedure SendCommand(XML:string);
    procedure SendChatMessage(ToJID,MsgText,MsgHtml:string;MsgType:TMessageType);

    procedure ParsingIQRoster(tag:TXMLTag);
  public
    constructor Create;
    destructor Destroy;override;

    procedure Login;
    procedure Logout;

    procedure SendRoomMessage(MsgText:string);
    procedure SendPersonalMessage(ToJID,MsgText:string);

    procedure JoinRoom(RoomName:string);
    procedure LeaveRoom;
    procedure GetRoomList;

  published
    property JabberID:string read FUser write FUser;
    property Password:string read FPass write FPass;
    property Resource:string read FResource write FResource;

    property Host:string read FHost write FHost;
    property Port:string read FPort write FPort;

    property OnLogin:TNotifyEvent read FOnLogin write FOnLogin;
    property OnLogout:TNotifyEvent read FOnLogout write FOnLogout;

    {$IFDEF DEBUG_XML}
    property OnDebugXML:TTCPEvent read FOnDebugXML write FOnDebugXML;
    {$ENDIF}

    property OnError:TErrorEvent read FOnError write FOnError;
    property OnMessage:TChatMessageEvent read FOnChat write FOnChat;

//    property OnOfflineMessage:TOfflineMessageEvent read FOnOfflineMsg write FOnOfflineMsg;

    property OnUserJoinedRoom:TRoomPresence read FOnJoinedRoom write FOnJoinedRoom;
    property OnUserLeftRoom:TRoomPresence read FOnLeftRoom write FOnLeftRoom;

    property OnRoomList:TRoomListEvent read FOnRoomList write FOnRoomList;

    property OnRoster:TRosterEvent read FOnRoster write FOnRoster;

    property OnPresence: TPresenceEvent read FOnPresence write FOnPresence;
    property OnIqVcard : TIqVcardEvent       read FOnIqVcard write FOnIqVcard;
  end;
  

implementation

uses
  xmppconst,
  saslauth,
  synautil;

{ TXmpp }

constructor TXmpp.Create;
begin
  inherited;
  FUser := '';
  FPass := '';
  FResource := 'Home';
  FRootTag := 'stream:stream';
  FParser := TXMLTagParser.Create;
  FRoomRoster := TStringList.Create;

  FSocket := TTCPClient.Create;
  FSocket.OnConnected := DoOnConnected;
  FSocket.OnDisconnected := DoOnDisconnected;
  FSocket.OnData := DoOnDebugXML;
  FSocket.OnError := DoOnError;
  FSocket.OnAfterUpgradedToSSL := DoAfterUpgradedToSSL;
  FSocket.OnSSLFailed := DoOnSSLFailed;

  FTimer := TTimer.Create(nil);
  FTimer.Interval := 1000 * 60;
  FTimer.OnTimer := DoOnTimer;
  FTimer.Enabled := False;

end;

destructor TXmpp.Destroy;
begin
  Logout;
  FTimer.Free;
  FRoomRoster.Free;
  FParser.Clear;
  FParser.Free;
  FSocket.Free;
  inherited;
end;

procedure TXmpp.SetDefaultVal;
begin
  FAuthd := False;
  FSessAuth := False;
  FRoot := '';
  FCurServer:= '';
  FBuff := '';
  FSessID := '';
  FRoomName := '';
  FJID := '';
  FConference := '';
  FMD5Step := 0;
  FCramMD5Step := 0;
  FMYID := 0;
  FMSGID := 0;
  FMD5 := False;
  FCramMD5 := False;
  FPLAIN := False;
  FPresenceSet := False;
end;

procedure TXmpp.Login;
begin
  if FSocket.IsConnected then
    Exit;

  if (Pos('gmail.com',FHost)>0) or
    (Pos('google.com',FHost)>0) or 
    (Pos('googlemail.com', FHost) > 0) then
  begin
    FHost := 'talk.google.com';
    FUser := SeparateLeft(FUser,'@');
    FUser := FUser + '@' + 'gmail.com';
  end;

  FSocket.Host := FHost;
  FSocket.Port := FPort;
  FSocket.Connect;
end;

procedure TXmpp.Logout;
begin
  if FAuthd then begin
    SendCommand('<presence type="unavailable"/>');
    SendCommand('</stream:stream>');
  end else
  FSocket.Disconnect;
end;

procedure TXmpp.DoOnConnected(Sender:TObject);
begin
  SetDefaultVal;
  FRoomRoster.Clear;
  SendCommand('<?xml version="1.0"?>');
  if FHost='talk.google.com' then
    SendXMPPHeader('gmail.com')
  else
    SendXMPPHeader(FHost);
end;

procedure TXmpp.DoOnDebugXML(Sender: TObject; Value:string);
begin
  if Pos('<',Value)>0 then
  begin
{$IFDEF DEBUG_XML}
    if Assigned(OnDebugXML) then
      FOnDebugXML(Self,'<= '+Value);
{$ENDIF}
    if (Value<>('</'+FRootTag+'>')) then
      ProsesData(Value)
    else
      Logout;
  end;
end;

procedure TXmpp.DoOnDisconnected(Sender:TObject);
begin
  SetDefaultVal;
  if Assigned(OnLogout) then
    FOnLogout(Self);
end;

procedure TXmpp.DoOnError(Sender:TObject;Value:string);
begin
  DoError(Value);
end;

procedure TXmpp.DoAfterUpgradedToSSL(Sender:TObject);
begin
  SendXMPPHeader(FCurServer);
end;

procedure TXmpp.DoOnSSLFailed(Sender:TObject;Value:string);
begin
  // what TODO ?
  DoError('SSL connection failed!');
end;

procedure TXmpp.SendCommand(XML: string);
begin
  if not FSocket.IsConnected then
    Exit;
  FSocket.SendData(XML);
  {$IFDEF DEBUG_XML}
  if Assigned(OnDebugXML) then
    FOnDebugXML(Self,'=> '+XML);
  {$ENDIF}
end;

procedure TXmpp.SendXMPPHeader(AHost:string);
begin
  SendCommand('<stream:stream to="'+AHost+'"  xmlns="jabber:client"'+
       ' xmlns:stream="http://etherx.jabber.org/streams"  version="1.0">');
end;

procedure TXmpp.DoError(ErrMsg: string);
begin
  if Assigned(OnError) then
    FOnError(Self,ErrMsg)
  else
  raise EXMLStream.Create(ErrMsg);
end;

// exodus
function TXmpp.GetFullTag(AData: string): string;
    function RPos(find_data, in_data: string): cardinal;
    var
        lastpos, newpos: cardinal;
        mybuff: string;
        origlen: cardinal;
    begin
        lastpos := 0;
        newpos := 0;
        origlen := Length(AData);
        repeat
            mybuff := Copy(in_data, lastpos + 1, origlen-newpos);
            newpos := pos(find_data, mybuff);
            if (newpos > 0) then begin
                lastpos := lastpos + newpos;
            end;
        until (newpos <= 0);

        Result := lastpos;
    end;
var
    sbuff, r, stag, etag, tmps: string;
    p, ls, le, e, l, ps, pe, ws, sp, tb, cr, nl, i: longint;
    _counter:integer;
begin
    Result := '';
    _counter := 0;
    sbuff := AData;
    l := Length(sbuff);

    if (Trim(sbuff)) = '' then exit;

    p := Pos('<', sbuff);
    if p <= 0 then
    begin
      DoError('Not a valid XML data!');
      Exit;
    end;

    tmps := Copy(sbuff, p, l - p + 1);
    e := Pos('>', tmps);
    i := Pos('/>', tmps);

    if ((e = 0) and (i = 0)) then exit;

    if FRoot = '' then begin
        sp := Pos(' ', tmps);
        tb := Pos(#09, tmps);
        cr := Pos(#10, tmps);
        nl := Pos(#13, tmps);

        ws := sp;
        if (tb > 0) then ws := Min(ws,tb);
        if (cr > 0) then ws := Min(ws,cr);
        if (nl > 0) then ws := Min(ws,nl);

        if ((i > 0) and (i < ws)) then
            FRoot := Trim(Copy(sbuff, p + 1, i - 2))
        else if (e < ws) then
            FRoot := Trim(Copy(sbuff, p + 1, e - 2))
        else
            FRoot := Trim(Copy(sbuff, p + 1, ws - 2));

        if  (FRoot = '?xml') or
            (FRoot = '!ENTITY') or
            (FRoot = '!--') or
            (FRoot = '!ATTLIST') or
            (FRoot = FRootTag) then begin
            r := Copy(sbuff, p, e);
            FRoot := '';
            FBuff := Copy(sbuff, p + e , l - e - p + 1);
            Result := r;
            exit;
        end;
    end;

    if (e = (i + 1)) then begin
        r := Copy(sbuff, p, e);
        FRoot := '';
        FBuff := Copy(sbuff, p + e, l - e - p + 1);
    end
    else begin
        i := p;
        stag := '<' + FRoot;
        etag := '</' + FRoot + '>';
        ls := length(stag);
        le := length(etag);
        r := '';
        repeat
            tmps := Copy(sbuff, i, l - i + 1);
            ps := Pos(stag, tmps);

            if (ps > 0) then begin
                _counter := _counter + 1;
                i := i + ps + ls - 1;
            end;

            tmps := Copy(sbuff, i, l - i + 1);
            pe := RPos(etag, tmps);
            if ((pe > 0) and ((ps > 0) and (pe > ps)) ) then begin
                _counter := _counter - 1;
                i := i + pe + le - 1;
                if (_counter <= 0) then begin
                    r := Copy(sbuff, p, i - p);
                    FRoot := '';
                    FBuff := Copy(sbuff, i, l - i + 1);
                    break;
                end;
            end;
        until ((pe <= 0) or (ps <= 0) or (tmps = ''));
    end;
    result := r;
end;

procedure TXmpp.ProsesData(AData: string);
var
  cp_buff: string;
  fc,frag: string;
begin
  cp_buff := AData;
  cp_buff := FBuff + AData;
  FBuff := cp_buff;

  repeat
    frag := GetFullTag(FBuff);
    if (frag <> '') then
    begin
      fc := frag[2];
      if (fc <> '?') and (fc <> '!') then
        ParseTags(frag);
      FRoot := '';
    end;
  until ((frag = '') or (FBuff = ''));
end;

procedure TXmpp.ParseTags(AData: string);
var
  c_tag: TXMLTag;
begin
  FParser.ParseString(AData, FRootTag);
//  repeat
    c_tag := FParser.PopTag;
    if (c_tag <> nil) then
    begin
      ProsesTags(c_tag);
      c_tag.Free;
    end;
//  until (c_tag = nil);
end;

procedure TXmpp.ProsesTags(tag: TXMLTag);
var s:string;
begin
  if tag.Name='stream:error' then
  begin
    if tag.ChildCount>0 then
      s := tag.ChildTags[0].Name;
    DoError('XML stream error '+s);
  end else
  if tag.Name=FRootTag then
  begin
    FSessID := tag.GetAttribute('id');
    FCurServer := tag.GetAttribute('from');
  end else
  if tag.Name='stream:features' then
  begin
    ParsingFeatures(tag);
  end else
  if tag.Name='proceed' then
  begin
    // start ssl connection..
    FSocket.DoOpenSSL;
  end else
  if tag.Name='challenge' then
  begin
    if FMD5 then begin
      if FMD5Step=0 then
        SendMD5Response(tag)
      else
        SendCommand('<response xmlns="'+XMLNS_SASL+'"/>');
    end else
    if FCramMD5 then begin
      if FCramMD5Step=0 then
        SendCramMD5Response(tag)
      else
        SendCommand('<response xmlns="'+XMLNS_SASL+'"/>');
    end;
  end else
  if tag.Name='success' then
  begin
    FAuthd := True;
    SendXMPPHeader(FCurServer);
  end else
  if tag.Name='failure' then
  begin
    // phew..
    if FMD5 then begin
      FMD5 := False;
      if FCramMD5 then
        SendCramMD5Auth
      else
      if FPLAIN then
        SendPLAINAuth;
    end else
    if FCramMD5 then begin
      FCramMD5 := False;
      if FPLAIN then
        SendPLAINAuth;
    end else
    if FPLAIN then
      FPLAIN := False;


    if (not FMD5) and (not FCramMD5) and
      (not FPLAIN) then
    begin
      if tag.ChildCount>0 then
        s := tag.ChildTags[0].Name;

      DoError('Failure: '+s);
      Logout;
    end;

  end else
  
  // stanzas
  if tag.Name='iq' then
  begin
    ParsingIQ(tag);
  end else
  if tag.Name='presence' then
  begin
    ParsingPresence(tag);
  end else
  if tag.Name='message' then
  begin
    ParsingMessage(tag);
  end;
end;

procedure TXmpp.ParsingFeatures(tag: TXMLTag);
var
  x:TXMLTag;
  tl:TXMLTagList;
  st:TStringList;
  i:integer;
begin
  if FAuthd and (not FSessAuth) then
  begin
    BindingResource;
  end else
  if (not FAuthd) and (not FSessAuth) then
  begin
    if tag.TagExists('starttls') then
    begin
      SendCommand('<starttls xmlns="'+XMLNS_TLS+'"/>');
      Exit;
    end;

    if tag.TagExists('mechanisms') then
    begin
      x := tag.GetFirstTag('mechanisms');
      tl := x.ChildTags;
      st := TStringList.Create;
      try
        for i:=0 to tl.Count-1 do
          st.Add(tl[i].Data);
        FMD5 := (st.IndexOf('DIGEST-MD5')<>-1);
        FCramMD5 := (st.IndexOf('CRAM-MD5')<>-1); 
        FPLAIN:= (st.IndexOf('PLAIN')<>-1);
      finally
        st.Free;
        tl.Free;
      end;
    end;

    if tag.TagExists('compression') then
    begin
      // TODO
    end;

    // what a mess... 
    if FMD5 then
      SendMD5Auth
    else
    if FCramMD5 then
      SendCramMD5Auth
    else
    if FPLAIN then
      SendPLAINAuth
    else
      DoError('SASL authentication failed!');

  end; // not FSessAuth

end;

procedure TXmpp.BindingResource;
var
  x,p:TXMLTag;
begin
  x := TXMLTag.Create('iq');
  try
    x.SetAttribute('type','set');
    x.SetAttribute('id',GenerateID);
    p := x.AddTagNS('bind',XMLNS_BIND);
    p.AddBasicTag('resource',FResource);
    SendCommand(x.XML);
  finally
    x.Free;
  end;
end;

procedure TXmpp.BindingSession;
var s:string;
begin
  s := '<iq type="set" id="'+GenerateID+'"><session xmlns="'+XMLNS_SESS+'"/></iq>';
  SendCommand(s);
end;

procedure TXmpp.SendAuth(AuthMethod:string);
begin
  SendCommand('<auth xmlns="'+XMLNS_SASL+'" mechanism="'+AuthMethod+'" xmlns:ga="'+
    XMLNS_GOOG+'" ga:client-uses-full-bind-result="true"></auth>');
end;

procedure TXmpp.SendMD5Auth;
begin
  SendAuth('DIGEST-MD5');
//  SendCommand('<auth xmlns="'+XMLNS_SASL+'" mechanism="DIGEST-MD5" xmlns:ga=""/>');
end;

procedure TXmpp.SendMD5Response(tag: TXMLTag);
var
  c,resp,s:string;
begin
  c := tag.Data;
  if c<>'' then begin
    s := '<response xmlns="'+XMLNS_SASL+'">';
    resp := SASLDigestMD5(c,FUser,FPass,FCurServer);
    s := s + resp+'</response>';
    FMD5Step := 1;
    SendCommand(s);
  end else
    DoError('SASL/DIGEST-MD5 authentication failed!');
end;

procedure TXmpp.SendCramMD5Auth;
begin
  SendAuth('CRAM-MD5');
//  SendCommand('<auth xmlns="'+XMLNS_SASL+'" mechanism="CRAM-MD5"/>');
end;

procedure TXmpp.SendCramMD5Response(tag: TXMLTag);
var
  c,resp,s:string;
begin
  c := tag.Data;
  if c<>'' then begin
    s := '<response xmlns="'+XMLNS_SASL+'">';
    resp := SASLCramMD5(c,FUser,FPass);
    s := s + resp+'</response>';
    FCramMD5Step := 1;
    SendCommand(s);
  end else
    DoError('SASL/CRAM-MD5 authentication failed!');
end;

procedure TXmpp.SendPLAINAuth;
var
  s,buf:string;
begin
  buf := SASLPlain(FUser,FPass);
  // googletalk
  // <auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'
  // xmlns:ga='http://www.google.com/talk/protocol/auth' ga:client-uses-full-bind-result='true'>bla..bla..</auth>
  s := '<auth xmlns="'+XMLNS_SASL+'" mechanism="PLAIN" xmlns:ga="'+
    XMLNS_GOOG+'" ga:client-uses-full-bind-result="true">'+buf+'</auth>';
  SendCommand(s);
end;

function TXmpp.GenerateID: string;
begin
  Inc(FMYID);
  FCurrentID := Format('%8.8d', [FMYID]);
  Result := FCurrentID;
end;

function TXmpp.GetJID: string;
begin
  Result := SeparateLeft(FJID,'/');
end;

procedure TXmpp.IQBeforeLoggedIn(tag: TXMLTag);
var p:TXMLTag;
begin
  if tag.TagExists('bind') then
  begin
    p := tag.GetFirstTag('bind');
    FJID := p.GetBasicText('jid');
    BindingSession;
  end else
//  if tag.TagExists('session') then
  begin
    FSessAuth := True;
    //<iq type='get' id='purple2fd60f4d' to='ichthus-desktop'>
    //<query xmlns='http://jabber.org/protocol/disco#items'/></iq>
    SendCommand('<iq type="get" id="'+GenerateID+'" to="'+FCurServer+'">'+
        '<query xmlns="'+XMLNS_DISCO+'#items"/></iq>');
    SendCommand('<iq type="get" id="'+GenerateID+'" to="'+FCurServer+'">'+
        '<query xmlns="'+XMLNS_DISCO+'#info"/></iq>');
  end;
end;

procedure TXmpp.ParsingIQ(tag: TXMLTag);
var
  ty,iqid,iqfr,
  iqty,iqvar,
  trid:string;
  q,qi:TXMLTag;
  i:integer;

  server_name, server_type, from_, to_, fn_, photo_type_, photo_bin_ : string;
  vc0, vc1, vc2, vc3, vc4 : TXMLTag;

begin
  trid := tag.GetAttribute('id');
  ty := tag.GetAttribute('type');

  if (trid = 'vc2') and (ty = 'result') then begin // got vcard of the contact

        from_ := tag.GetAttribute('from');
        to_   := tag.GetAttribute('to');

        vc0 := tag.GetFirstTag('vCard');
        if (vc0<>nil) then begin
           vc1 := vc0.GetFirstTag('FN');
           if (vc1<>nil) then begin
             fn_ := vc1.Data;
             vc2 := vc0.GetFirstTag('PHOTO');
             if vc2 <> nil then begin
                vc3 := vc2.GetFirstTag('TYPE');
                if vc3 <> nil then begin
                   photo_type_ := vc3.Data;
                   vc4 := vc2.GetFirstTag('BINVAL');
                   if vc4 <> nil then begin
                      photo_bin_ := vc4.Data;
                   end;
                end;
             end; //photo
           end; //fn
        end;
        vc0.Free;
        vc1.Free;
        vc2.Free;
        vc3.Free;
        if Assigned(FOnIqVcard) then begin

          FOnIqVcard (Self, from_, to_, fn_, photo_type_, photo_bin_) ;

        end;
     exit
  end;  //vcard






  if (ty='result') then
  begin
    if (not FSessAuth) then
    begin
      IQBeforeLoggedIn(tag);
      Exit; //
    end;

    iqfr := tag.GetAttribute('from');
    q := tag.GetFirstTag('query');
    if (q<>nil) then begin
      if (q.Namespace=XMLNS_DISCO+'#items') then
      begin
        for i:=0 to q.ChildCount-1 do
        begin
          qi := q.ChildTags.Tags[i];
          if (qi.Name='item') then  begin
          //<iq type='get' id='purple2fd60f4f' to='conference.ichthus-desktop'>
          //<query xmlns='http://jabber.org/protocol/disco#info'/></iq>
            iqid := qi.GetAttribute('jid');
            if (iqid<>'') then
            begin
              if (iqfr=FCurServer) then begin
                SendCommand('<iq type="get" id="'+GenerateID+'" to="'+iqid+'">'+
                  '<query xmlns="'+XMLNS_DISCO+'#info"/></iq>');
              end else
              if (iqfr=FConference) then begin
                if Assigned(OnRoomList) then
                  FOnRoomList(Self,TrimSPRight(SeparateLeft(qi.GetAttribute('name'),'(')));
              end; // room list

            end;
          end;
        end;
      end else // disco#items

      if (q.Namespace=XMLNS_DISCO+'#info') then
      begin
        for i:=0 to q.ChildCount-1 do
        begin
          qi := q.ChildTags.Tags[i];
          if (qi.Name='identity') then
          begin
            iqid := qi.GetAttribute('category');
            iqty := qi.GetAttribute('type');

            // jabber chat room
            if (iqid='conference') and (iqty='text') then
            begin
              FConference := iqfr;
              // assume "Anyone can create a chat room" for now :p
              
            end else // conference
            if (iqid='server') then
            begin
              // servername, servertype
              server_name := qi.GetAttribute('name');
              server_type := qi.GetAttribute('type');
            end else // server
            if (iqid='pubsub') then
            begin
              //
            end; // pubsub
          end else // qi.name
          if (qi.Name='feature') then
          begin
            // TODO
            iqvar := qi.GetAttribute('var');
            // activating keepalive..
            if (iqvar='urn:xmpp:ping') then
            begin
              FTimer.Enabled := True;
            end else
            if (iqvar=XMLNS_ROSTER) then
            begin
              //SendCommand('<iq type="get" id="'+GenerateID+'"><query xmlns="'+XMLNS_ROSTER+'"/></iq>');
            end;
          end;
        end; // loop

      end else // disco#info

      if (q.Namespace=XMLNS_ROSTER) then
      begin

        ParsingIQRoster(q);  

        // set presence
        if not FPresenceSet then
        begin
          FPresenceSet := True;
          //SendCommand('<presence></presence>');
           SendCommand('<presence xml:lang="en"><show>chat</show><status></status></presence>'); 
          if Assigned(OnLogin) then FOnLogin(Self);
        end;


      end; // roster                

      if not FPresenceSet then
        if FCurrentID=trid then
          SendCommand('<iq type="get" id="'+GenerateID+'"><query xmlns="'+XMLNS_ROSTER+'"/></iq>');

    end; // q<>nil

  end;
end;

// exodus
function JabberToDateTime(datestr: string): TDateTime;
var
    rdate: TDateTime;
    ys, ms, ds, ts: string;
    yw, mw, dw: Word;
begin
    // Converts assumed UTC time to local.
    // translate date from 20000110T19:54:00 to proper format..
    ys := Copy(Datestr, 1, 4);
    ms := Copy(Datestr, 5, 2);
    ds := Copy(Datestr, 7, 2);
    ts := Copy(Datestr, 10, 8);

    try
        yw := StrToInt(ys);
        mw := StrToInt(ms);
        dw := StrToInt(ds);

        if (TryEncodeDate(yw, mw, dw, rdate)) then begin
            rdate := rdate + StrToTime(ts);
            Result := rdate - TimeZoneBias(); // Convert to local time
        end
        else
            Result := Now();
    except
        Result := Now;
    end;
end;

function RightStr(AText: String; ACount: Integer): string;
begin
  Result := Copy(AText, Length(AText) + 1 - ACount, ACount);
end;

function LeftStr(AText: String; ACount: Integer): String;
begin
  Result := Copy(AText, 1, ACount);
end;

function IncHour(const AValue: TDateTime;
  const ANumberOfHours: Int64): TDateTime;
begin
  Result := ((AValue * HoursPerDay) + ANumberOfHours) / HoursPerDay;
end;

function IncMinute(const AValue: TDateTime;
  const ANumberOfMinutes: Int64): TDateTime;
begin
  Result := ((AValue * MinsPerDay) + ANumberOfMinutes) / MinsPerDay;
end;
// exodus
function XEP82DateTimeToDateTime(datestr: string): TDateTime;
var
    rdate: TDateTime;
    ys, ms, ds, ts: string;
    yw, mw, dw: Word;
    tzd: string;
    tzd_hs: string;
    tzd_ms: string;
    tzd_hw: word;
    tzd_mw: word;
begin
    // Converts UTC or TZD time to Local Time
    // translate date from 2008-06-11T10:10:23.102Z (2008-06-11T10:10:23.102-06:00) or to properformat
    Result := Now();

    datestr := Trim(datestr);
    if (Length(datestr) = 0) then exit;

    ys := Copy(datestr, 1, 4);
    ms := Copy(datestr, 6, 2);
    ds := Copy(datestr, 9, 2);
    ts := Copy(datestr, 12, 8);

    if (RightStr(datestr, 1) = 'Z') then
    begin
        // Is UTC
        try
            yw := StrToInt(ys);
            mw := StrToInt(ms);
            dw := StrToInt(ds);

            if (TryEncodeDate(yw, mw, dw, rdate)) then begin
                rdate := rdate + StrToTime(ts);
                Result := rdate - TimeZoneBias(); // Convert to local time
            end
            else
                Result := Now();
        except
            Result := Now;
        end;
    end
    else begin
        // Is not UTC so convert to UTC
        tzd := Copy(datestr, Length(datestr) - 5, 6);
        tzd_hs := Copy(tzd, 2, 2);
        tzd_ms := Copy(tzd, 5, 2);

        try
            yw := StrToInt(ys);
            mw := StrToInt(ms);
            dw := StrToInt(ds);
            tzd_hw := StrToInt(tzd_hs);
            tzd_mw := StrToInt(tzd_ms);

            if (TryEncodeDate(yw, mw, dw, rdate)) then
            begin
                rdate := rdate + StrToTime(ts);
                // modify time for TZD offset.
                if (LeftStr(tzd, 1) = '+') then
                begin
                    // Time is greater then UTC so subtract time
                    rdate := IncHour(rdate, (-1 * tzd_hw));
                    rdate := IncMinute(rdate, (-1 * tzd_mw));
                end
                else begin
                    // Time is less then UTC so add time
                    rdate := IncHour(rdate, tzd_hw);
                    rdate := IncMinute(rdate, tzd_mw);
                end;

                // Now that we have UTC, change ot local
                Result := rdate - TimeZoneBias();
            end
            else begin
                Result := Now();
            end;
        except
            Result := Now();
        end;
    end;

end;

procedure TXmpp.ParsingMessage(tag: TXMLTag);
var
  p,x,d:TXMLTag;
  mf,mt,mb,mh,
  fr,ty,_ts:string;
  _time:TDateTime;
begin
  _time := Now;
  mt := tag.GetAttribute('to');
  if Pos(mt,FJID)=0 then
    Exit;

  ty := tag.GetAttribute('type');
  fr := tag.GetAttribute('from');

  p := tag.GetFirstTag('body');
  if (p<>nil) then
    mb := p.Data;
  x := tag.GetFirstTag('html');
  if (x<>nil) then
    mh := x.XML;

  // room chat message
  if (ty='groupchat') then //and (Pos(FRoomName,fr)>0) then
  begin
    mf := SeparateRight(fr,'/');
    if mf=fr then Exit;
    mf := GetRosterRoomJID(mf);
    if p<>nil then
      if Assigned(OnMessage) then
        FOnChat(Self,mf,mb,mh,_time,mtRoom);
  end else
// personal chat message
  if (ty='chat') then
  begin
    if p=nil then Exit;

    d := nil;
    if tag.TagExists('x') then
      d := tag.GetFirstTag('x')
    else
    if tag.TagExists('delay') then
      d := tag.GetFirstTag('delay');

    if (d<>nil) then begin
      _ts := tag.GetAttribute('stamp');
      if (d.Namespace=XMLNS_DELAY) or (d.Namespace=XMLNS_DELAY_203) then
        _time := XEP82DateTimeToDateTime(_ts) //JabberToDateTime(_ts)
    end;
    if Assigned(OnMessage) then
      FOnChat(Self,fr,mb,mh,_time,mtPersonal);
  end;

{
  if tag.TagExists('body') and
    (tag.GetAttribute('type')='chat') then
  begin

    x := tag.GetFirstTag('x');
    if (x<>nil) and (x.Namespace=XMLNS_EVENT) then
      FMsgComposing := x.TagExists('composing');

    mt := tag.GetAttribute('to');
    if Pos(GetJID,mt)>0 then
    begin
      mf := tag.GetAttribute('from');
      dt := tag.GetFirstTag('body').Data;
      p :=  tag.GetFirstTag('html');
      mh := p.XML;

      if Assigned(OnMessage) then
        FOnChat(Self,mf,dt,mh);
    end;
  end;
}  
end;

{ later...
function DecodeShowDisplayValue(show: string): string;
begin
    if (show = '') then
      result := 'Available'
    else if (show = 'chat') then
      result := 'Free to Chat'
    else if (show = 'away') then
      result := 'Away'
    else if (show = 'xa') then
      result := 'Extended Away'
    else if (show = 'dnd') then
      result := 'Do not Disturb'
    else
      result := show;
end;
}

procedure TXmpp.ParsingPresence(tag: TXMLTag);
var
  p,x:TXMLTag;
  pf,pty,
  pid:string;

  status_tag, x_tag, photo_tag : TXMLTag;
  presence_type_, tmp_, jid_, resource_, status_, photo_ : string;

begin
  pf := tag.GetAttribute('from');
  pty:= tag.GetAttribute('type');

  if pty='error' then
    Exit;

  // room presence
  if Pos(FRoomName,pf)>0 then
  begin
    //s := SeparateRight(pf,'/');
    //if (s<>FUser) then
    //begin
      p := tag.GetFirstTag('x');
      if (p<>nil) then begin
        x := p.GetFirstTag('item');
        if (x<>nil) then begin
          pid := x.GetAttribute('jid');
          if pty='unavailable' then
          begin
            if Pos(pid,FJID)>0 then
              FRoomName := '';

            RemoveFromRosterRoom(pid);
          end else
          begin
            //if Pos(pid,FJID)=0 then
              AddToRosterRoom(pid);
          end;
        end;
      end;// p<>nil
    //end;
  end else
  begin

     if Assigned(FOnPresence) then begin
        presence_type_ := pty;
        jid_ := '';
        resource_ := '';
        status_ := '';
        photo_ := '';
        tmp_ := tag.GetAttribute('from');
        jid_ := synautil.SeparateLeft(tmp_, '/');
        resource_ := synautil.SeparateRight(tmp_, '/');
        status_tag := tag.GetFirstTag('status');
        if (status_tag <> nil) then begin
           status_ := status_tag.Data
        end;
        x_tag := tag.GetFirstTag('x');
        if (x_tag<>nil) then begin
           photo_tag := x_tag.GetFirstTag('photo');
           if (photo_tag<>nil) then begin
              photo_ := photo_tag.Data;
           end;
        end;
        //status_tag.Free;
        //x_tag.Free;
        //photo_tag.Free;
        FOnPresence (Self, presence_type_, jid_, resource_, status_, photo_) ;
     end;


  end;
end;

function TXmpp.IsInRosterRoom(JID: string): Boolean;
var i:integer;
begin
  Result := False;
  for i:=0 to FRoomRoster.Count-1 do begin
    if (FRoomRoster[i]=JID) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure TXmpp.RemoveFromRosterRoom(JID: string);
var i:integer;
begin
  if not IsInRosterRoom(JID) then
    Exit;
  for i:=0 to FRoomRoster.Count-1 do
  begin
    if (FRoomRoster[i]=JID) then
    begin
      FRoomRoster.Delete(i);
      Break;
    end;
  end;
  if Assigned(OnUserLeftRoom) then
    FOnLeftRoom(Self,JID);
end;

procedure TXmpp.JoinRoom(RoomName: string);
begin
  if (not FSessAuth) or (RoomName='') then
    Exit;

  // only one room
  if (FRoomName<>'') then begin
    DoError('Only one room/session');
    Exit;
  end;                               

  FRoomName := SeparateLeft(RoomName,'@');
  FRoomName := FRoomName+'@'+FConference;

  SendCommand('<presence from="'+GetJID+'" to="'+
    FRoomName+'/'+FUser+'"/>');
end;

procedure TXmpp.AddToRosterRoom(JID: string);
begin
  if not IsInRosterRoom(JID) then
  begin
    FRoomRoster.Add(JID);
    if Assigned(OnUserJoinedRoom) then
      FOnJoinedRoom(Self,JID);
  end;
end;

function TXmpp.GetRosterRoomJID(JID: string): string;
var i:integer;
begin
  Result := '';
  for i:=0 to FRoomRoster.Count-1 do begin
    if (SeparateLeft(FRoomRoster[i],'@')=JID) then
    begin
      Result := FRoomRoster[i];
      Break;
    end;
  end;
end;

procedure TXmpp.LeaveRoom;
begin
  if FRoomName='' then
    Exit;
  SendCommand('<presence to="'+FRoomName+'/'+FUser+'" type="unavailable"/>');
end;

procedure TXmpp.DoOnTimer(Sender: TObject);
begin
  FTimer.Enabled := False;
  if not FSessAuth then
    Exit;
  //<iq type='get' id='purplef5537fcf'><ping xmlns='urn:xmpp:ping'/></iq>
  SendCommand('<iq type="get" id="'+GenerateID+'"><ping xmlns="urn:xmpp:ping"/></iq>');
  FTimer.Enabled := True;
end;

procedure TXmpp.GetRoomList;
begin
  if (FConference='') then
    Exit;
  SendCommand('<iq type="get" id="'+GenerateID+'" to="'+FConference+'">'+
    '<query xmlns="'+XMLNS_DISCO+'#items"/></iq>');
end;

function TXmpp.GenerateMSGID: string;
begin
  Inc(FMSGID);
  Result := 'msg'+Format('%5.5d', [FMSGID]);
end;

procedure TXmpp.SendChatMessage(ToJID, MsgText, MsgHtml: string;
  MsgType: TMessageType);
var s:string;
    x,b,h:TXMLtag;
begin
  if (not FSessAuth) then
    Exit;

  x := TXMLTag.Create('message');
  try
    x.SetAttribute('from',FJID);
    x.SetAttribute('id',GenerateMSGID);
    x.SetAttribute('to',ToJID);

    case MsgType of
      mtRoom:     x.SetAttribute('type','groupchat');
      mtPersonal: x.SetAttribute('type','chat');
    end;

    b := x.AddTag('body');
    b.AddCData(MsgText);
    h := x.AddTagNS('html',XML_XHTMLIM);
    h.AddTagNS('body',XML_XHTML);
    h.AddCData(MsgHtml);
    s := x.XML;
  finally
    x.Free;
  end;
  SendCommand(s);
end;

procedure TXmpp.SendPersonalMessage(ToJID, MsgText: string);
begin
  SendChatMessage(ToJID,MsgText,MsgText,mtPersonal);
end;

procedure TXmpp.SendRoomMessage(MsgText: string);
begin
  if FRoomName='' then
    Exit; // ignore silently
  SendChatMessage(FRoomName,MsgText,MsgText,mtRoom);
end;

procedure TXmpp.ParsingIQRoster(tag:TXMLTag);
var
  _jid,_name,_subscription,_group:string;
  i:integer;
  x:TXMLTag;
begin
  for i:=0 to tag.ChildTags.Count-1 do begin
    x := tag.ChildTags[i];
    _jid := x.GetAttribute('jid');
    _name:= x.GetAttribute('name');
    _subscription := x.GetAttribute('subscription');
    _group := x.GetBasicText('group');

    if Assigned(OnRoster) then
      FOnRoster(Self,_jid,_name,_subscription,_group);
  end;
end;

end.
