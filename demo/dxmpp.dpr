program dxmpp;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses

{$IFDEF FPC}
{$IFDEF LINUX}
   cthreads,
{$ENDIF}
{$ENDIF}

{$IFNDEF FPC}
{$ELSE}
  Interfaces,
{$ENDIF}
  Forms,
  mainunit in 'mainunit.pas' {frmMain};

//{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
