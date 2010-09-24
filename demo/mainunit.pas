unit mainunit;

interface

uses
  SysUtils, Classes, Controls, Forms, StdCtrls, 
  uxmpp,synacode,synautil;

type
  TfrmMain = class(TForm)
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

  public
    procedure Tulis(log:string);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
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
  xmpp.Host := 'gmail.com';
  xmpp.Port := '5222';
  xmpp.JabberID := 'my_gmail_id@gmail.com';
  xmpp.Password := 'password';
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

end.
