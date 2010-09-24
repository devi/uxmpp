program dxmpp;

uses
  Forms,
  mainunit in 'mainunit.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
