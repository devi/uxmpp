//
// xmpp sasl authentication
//
// credits: exodus, synapse
//
// contact: devi[dot]mandiri[at]gmail[dot]com
//

unit saslauth;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, synacode, synautil;

function Min(const A, B: Integer): Integer;
function SASLPlain(AUser,APass:string):string;
function SASLDigestMD5(AChallenge,AUser,APass,AHost:string):string;
function SASLCramMD5(AChallenge,AUser,APass:string):string;

implementation

function Min(const A, B: Integer): Integer;
begin
  if A < B then
    Result := A
  else
    Result := B;
end;

function SASLPlain(AUser,APass:string):string;
begin
  Result := #$00 + AUser + #$00 + APass;
  Result := EncodeBase64(Result);
end;

function MyRandom(size:integer):string;
var
  RndBuffer:String;
  i:integer;
begin
  Randomize;
  RndBuffer :=StringOfChar(chr(0),size);
  for i := 0 to size do begin
    RndBuffer[i] := chr(Random(256));
  end;
  SetLength(RndBuffer,size);
  Result := RndBuffer;
end;

procedure ParseNameValues(AStrings:TStringlist;AStr:string);
var
    i: integer;
    q: boolean;
    n,v: Widestring;
    ns, vs: integer;
begin
    ns := 1;
    vs := 1;
    q := false;
    for i := 0 to Length(AStr) - 1 do begin
        if (not q) then begin
            if (AStr[i] = ',') then begin
                if (v = '') then
                    v := Copy(AStr, vs, i - vs);
                AStrings.Add(n);
                AStrings.Values[n] := v;
                ns := i + 1;
                n := '';
                v := '';
            end
            else if (AStr[i] = '"') then begin
                q := true;
                vs := i + 1;
            end
            else if (AStr[i] = '=') then begin
                n := Copy(AStr, ns, i - ns);
                vs := i + 1;
            end;
        end
        else if (AStr[i] = '"') then begin
            v := Copy(AStr, vs, i - vs);
            q := false;
        end;
    end;
end;

// exodus modified
function SASLDigestMD5(AChallenge,AUser,APass,AHost:string):string;
var
  c,e,uri,resp,a2,p1,p2,
  _realm,_nonce,_cnonce,
  _user,_pass,_host,
  dig,nc:string;
  pairs:TStringList;
begin
  c := DecodeBase64(AChallenge);

  _user := AUser;
  _pass := APass;
  _host := AHost;

  pairs := TStringList.Create;
  try
    ParseNameValues(pairs,c);
    if (pairs.IndexOf('realm')<>-1) then
      _realm := pairs.Values['realm']
    else
      _realm := AHost;
    _nonce := pairs.Values['nonce'];
  finally
    pairs.Free;
  end;

  e := MyRandom(64); // i'll fix this later ;)
  e := EncodeBase64(e);
  _cnonce := LowerCase(StrToHex(MD5(e)));

  uri:= 'xmpp/' + _host;
  nc := '00000001';

  resp := 'username="' + _user + '",';
  resp := resp + 'realm="' + _realm + '",';
  resp := resp + 'nonce="' + _nonce + '",';
  resp := resp + 'cnonce="' + _cnonce + '",';
  resp := resp + 'nc=' + nc + ',';
  resp := resp + 'qop=auth,';
  resp := resp + 'digest-uri="' + uri + '",';

  e := MD5(_user + ':' + _realm + ':' + _pass)
      + ':' + _nonce + ':' + _cnonce;
  p1 := LowerCase(StrToHex(MD5(e)));

  a2 := 'AUTHENTICATE:' + uri;
  p2 := LowerCase(StrToHex(MD5(a2)));

  e := p1 + ':' + _nonce + ':' + nc + ':' +
      _cnonce + ':auth:' + p2;
  dig := LowerCase(StrToHex(MD5(e)));

  resp := resp + 'response=' + dig + ',';
  resp := resp + 'charset=utf-8';

  Result := EncodeBase64(resp);
end;

// rfc2195
function SASLCramMD5(AChallenge,AUser,APass:string):string;
var
  s,c:string;
begin
  c := DecodeBase64(AChallenge);
  s := StrToHex(HMAC_MD5(c,APass));
  Result := EncodeBase64(AUser + ' ' + s);
end;

end.

