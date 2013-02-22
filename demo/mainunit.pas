unit mainunit;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, Controls, Forms, StdCtrls, 
  uxmpp,synacode,synautil;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    xmpp:TXmpp;
    procedure DoOnError(Sender:TObject;Value:string);
    procedure DoOnLoggin(Sender:TObject);
    procedure DoOnLogout(Sender:TObject);
    procedure DoOnDebugXML(Sender:TObject;Value:string);
    procedure DoOnMsg(Sender:TObject;From,MsgText,MsgHTML:string;
      TimeStamp:TDateTime;MsgType:TMessageType);
    procedure DoOnJoinedRoom(Sender:TObject;JID:string);
    procedure DoOnLeftRoom(Sender:TObject;JID:string);
    procedure DoOnRoster(Sender:TObject;JID,Name,Subscription,Group:string);
    procedure DoOnPresence(Sender: TObject; presence_type_, jid_, resource_, status_, photo_: string);
    procedure DoOnIqVcard(Sender:TObject; from_, to_, fn_, photo_type_, photo_bin_ : string);

  public
    procedure Tulis(log:string);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  //some ui related staff
  Edit1.Text:= 'user@serv.er';
  Edit2.Text:= '';
  Edit2.EchoMode:= emPassword;
  Edit3.Text:='5222';
  Label1.Caption:= 'Username';
  Label1.Width:= 230;
  Label2.Caption:= 'Password';
  Label2.Width:= 230;


  //xmpp
  xmpp := TXmpp.Create;
  xmpp.OnError := DoOnError;
  xmpp.OnDebugXML := DoOnDebugXML;
  xmpp.OnMessage := DoOnMsg;
  xmpp.OnUserJoinedRoom := DoOnJoinedRoom;
  xmpp.OnUserLeftRoom := DoOnLeftRoom;
  xmpp.OnLogin := DoOnLoggin;
  xmpp.OnLogout := DoOnLogout;
  xmpp.OnRoomList := DoOnDebugXML;
  xmpp.OnRoster := DoOnRoster;

  xmpp.OnIqVcard:= DoOnIqVcard;
  xmpp.OnPresence:= DoOnPresence;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  xmpp.Free;
end;

procedure TfrmMain.Tulis(log:string);
begin
  Memo1.Lines.Add(log);
end;

procedure TfrmMain.DoOnDebugXML(Sender: TObject; Value: string);
begin
  Tulis(Value);
end;

procedure TfrmMain.DoOnError(Sender: TObject; Value: string);
begin
  Tulis('ERROR: '+Value);
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  Edit1.Text := synautil.TrimSPLeft(Edit1.Text);
  Edit1.Text := synautil.TrimSPRight(Edit1.Text);
  xmpp.Host := synautil.SeparateRight(Edit1.Text, '@');
  xmpp.Port := Edit3.Text;
  xmpp.JabberID := Edit1.Text;
  xmpp.Password := Edit2.Text;
  xmpp.Login;
end;

procedure TfrmMain.Button2Click(Sender: TObject);
begin
  xmpp.Logout;
end;

procedure TfrmMain.Button3Click(Sender: TObject);
begin
  xmpp.JoinRoom('testroom');
end;

procedure TfrmMain.Button4Click(Sender: TObject);
begin
  xmpp.LeaveRoom;
end;

procedure TfrmMain.DoOnMsg(Sender: TObject; From, MsgText, MsgHTML: string;
  TimeStamp:TDateTime;MsgType: TMessageType);
var s:string;  
begin
  case MsgType of
  mtRoom: s := 'ROOM MSG: ';
  mtPersonal: s := 'PERSONAL MSG: ';
  end;
  Tulis(s + From+'('+DateTimeToStr(TimeStamp)+'): '+MsgText);
end;

procedure TfrmMain.DoOnJoinedRoom(Sender: TObject; JID: string);
begin
  Tulis(JID+' has joined the room');
end;

procedure TfrmMain.DoOnLeftRoom(Sender: TObject; JID: string);
begin
  Tulis(JID+' has left the room');
end;

procedure TfrmMain.DoOnLoggin(Sender: TObject);
begin
  Tulis('Logged in to '+xmpp.Host);
end;

procedure TfrmMain.DoOnLogout(Sender: TObject);
begin
  Tulis('Logged out');
end;

procedure TfrmMain.Button5Click(Sender: TObject);
begin
  xmpp.GetRoomList;
end;

procedure TfrmMain.Button7Click(Sender: TObject);
begin
  xmpp.SendRoomMessage('webeks');
end;

procedure TfrmMain.Button6Click(Sender: TObject);
begin
  xmpp.SendPersonalMessage('tester2@devitha-desktop','webeks');
end;

procedure TfrmMain.DoOnRoster(Sender: TObject; JID, Name, Subscription,
  Group: string);
begin
  Tulis(JID+':'+Name+':'+Subscription+':'+Group);
end;

procedure TfrmMain.DoOnIqVcard(Sender:TObject; from_, to_, fn_, photo_type_, photo_bin_ : string);
begin
    Tulis('Entered DoOnIqVcard');
    Tulis('from: ' + from_);
    Tulis('to: ' + to_);
    Tulis('photo type: ' + photo_type_);
    Tulis('photo binary: ' + photo_bin_);
    Tulis('Exited DoOnIqVcard');
end;

procedure TfrmMain.DoOnPresence(Sender: TObject; presence_type_, jid_, resource_, status_, photo_: string);
   begin
     Tulis('Entered DoOnPresence');
     Tulis('presence type is ' + presence_type_);
     Tulis('jid is ' + jid_);
     Tulis('resource is ' + resource_);
     Tulis('status is ' + status_);
     Tulis('photo is ' + photo_);
     Tulis('Exited DoOnPresence');
   end;
end.
