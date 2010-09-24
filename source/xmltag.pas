//
// xml parser
//
// credits: exodus, libxmlparser
//
// contact: devi[dot]mandiri[at]gmail[dot]com
//

unit xmltag;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, libxmlparser;

type
  TXMLNode=class;

  EXMLStream = class(Exception);

  XMLNodeType = (xml_Node, xml_Tag, xml_Attribute, xml_CDATA);

  TXMLNode = class
  private
    fName: String;
    ftype: XMLNodeType;
  public
    constructor Create; virtual;
    property Name:string read fName write fName;
    property NodeType: XMLNodeType read ftype write ftype;
    function IsTag: boolean;
    function XML: string; virtual;
  end;

  TXMLCData = class(TXMLNode)
  private
    FData: string;
    procedure Set_Text(Value:string);
  public
    constructor Create; overload; override;
    constructor Create(content: string); reintroduce; overload;
    destructor Destroy; override;

    function XML: string; override;
    property Data: string read FData write Set_Text;
  end;

  TXMLTag = class;

  TXMLNodeList = class(TObjectList)
  end;

  TXMLTagList = class(TList)
    private
        function GetTag(index: integer): TXMLTag;
    public
        property Tags[index: integer]: TXMLTag read GetTag; default;
  end;

  TXMLTag = class(TXMLNode)
  private
    FChildren: TXMLNodeList;
    FAttrList:TAttrList;
    FXMLBuff,FNameSpace:string;
  public
    pTag:TXMLTag;
    constructor Create; overload; override;
    constructor Create(ATagName: string); reintroduce; overload; virtual;
    constructor Create(ATag: TXMLTag); reintroduce; overload; virtual;
    constructor Create(ATagName,ACDATA: string); reintroduce; overload; virtual;
    destructor Destroy;override;

    function  XML:string;override;

    function  AddTag(ATagName: string): TXMLTag; overload;
    function  AddTag(AChildTag: TXMLTag): TXMLTag; overload;
    function  AddTagNS(ATagName: string; AXmlns: string): TXMLTag;
    function  AddBasicTag(ATagName, ACData: string): TXMLTag;
    procedure AssignTag(const ATag: TXMLTag);
    function  AddCData(AContent: String): TXMLCData;
    procedure SetAttribute(AName,AValue:string);
    function  GetAttribute(AName:string):string;
    procedure RemoveAttribute(ATagName: string);
    procedure RemoveTag(node: TXMLTag);
    function  GetFirstTag(ATagName: string): TXMLTag;
    function  GetBasicText(ATagName: string): String;
    function  TagExists(ATagName: string): boolean;

    function  ChildCount: integer;
    function  ChildTags: TXMLTagList;
    procedure ClearTags;
    procedure ClearCData;
    function  Data: String;
    function  Namespace(children: boolean = false): String;

    property Nodes: TXMLNodeList read FChildren;
    property Attributes:TAttrList read FAttrList;
  end;

  TXMLTagParser=class
  private
    FParser:TXmlParser;
    FList:TList;
    function ProcessTag(curtag: TXMLTag): TXMLTag;
  public
    constructor Create;
    destructor Destroy;override;
    procedure ParseString(buff: string; stream_tag: string='');
    function  PopTag: TXMLTag;
    function  Count: integer;
    procedure Clear;
  end;

implementation

function HTML_EscapeChars(txt: string; DoAPOS: boolean; DoQUOT: boolean): string;
var
  tmps: string;
  i: integer;
begin
  tmps := '';
  for i := 1 to length(txt) do
  begin
    if txt[i] = '&' then tmps := tmps + '&amp;'
    else if (txt[i] = Chr(39)) and (DoAPOS) then tmps := tmps + '&apos;'
    else if (txt[i] = '"') and (doQUOT) then tmps := tmps + '&quot;'
    else if txt[i] = '<' then tmps := tmps + '&lt;'
    else if txt[i] = '>' then tmps := tmps + '&gt;'
    else tmps := tmps + txt[i];
  end;
  Result := tmps;
end;

function XML_EscapeChars(txt: string): string;
begin
  Result := HTML_EscapeChars(txt, true, true);
end;

{ TXMLNode }

constructor TXMLNode.Create;
begin
  inherited;
  fName := '';
  ftype := xml_Node;
end;

function TXMLNode.IsTag: boolean;
begin
  Result := (ftype=xml_Tag);
end;

function TXMLNode.XML: string;
begin
//
end;


{ TXMLCData }

constructor TXMLCData.Create;
begin
  inherited;
  Name := '#TEXT';
  NodeType := xml_CDATA;
  FData := '';
end;

constructor TXMLCData.Create(content: string);
begin
  Create;
  FData := content;
end;

destructor TXMLCData.Destroy;
begin
  inherited Destroy;
end;

procedure TXMLCData.Set_Text(Value: string);
var
  p1: integer;
  tmps: string;
begin
  tmps := Value;
  p1 := Pos('<![CDATA[', Uppercase(tmps));
  if p1 > 0 then begin
    Delete(tmps, p1, 9);
    p1 := Pos(']]>', tmps);
    if p1 > 0 then
      Delete(tmps, p1, 3);
    Name := '#CDATA';
  end else
    tmps := tmps;

  FData := tmps;
end;

function TXMLCData.XML: string;
var
  tmps: string;
begin
  if Name = '#CDATA' then
    tmps := '<![CDATA[ ' + fData + ' ]]>'
  else
    tmps := XML_EscapeChars(fData);

  Result := tmps;
end;

{ TXMLTagList }

function TXMLTagList.GetTag(index: integer): TXMLTag;
begin
  if (index >= 0) and (index < Count) then
    Result := TXMLTag(Items[index])
  else
    Result := nil;
end;

{ TXMLTag }

constructor TXMLTag.Create;
begin
  inherited;
  NodeType := xml_tag;
  (*$IFDEF HAS_CONTNRS_UNIT *)
  FChildren := TXMLNodeList.Create(True);
  (*$ELSE*)
  FChildren := TXMLNodeList.Create;
  (*$ENDIF*)
  FAttrList := TAttrList.Create;
  pTag := nil;
  FXMLBuff := '';
end;

destructor TXMLTag.Destroy;
begin
  FAttrList.Clear;
  FAttrList.Free;
  FChildren.Clear;
  FChildren.Free;
  inherited Destroy;
end;

constructor TXMLTag.Create(ATagName: string);
begin
  Create;
  Name := ATagName;
end;

constructor TXMLTag.Create(ATag: TXMLTag);
begin
  Create;
  Self.AssignTag(ATag);
end;

constructor TXMLTag.Create(ATagName, ACDATA: string);
begin
  Create(ATagName);
  Self.AddCData(ACDATA);
end;

procedure TXMLTag.AssignTag(const ATag: TXMLTag);
var
    i: integer;
    c: TXMLTag;
    tags: TXMLNodeList;
    n: TXMLNode;
begin
  Self.Name := ATag.Name;
  tags := ATag.Nodes;

  for i := 0 to tags.Count - 1 do
  begin
    n := TXMLNode(tags[i]);
    if (n.NodeType = xml_Tag) then
    begin
      c := Self.AddTag(TXMLTag(n).Name);
      c.AssignTag(TXMLTag(n));
    end else
    if (n.NodeType = xml_CDATA) then
    begin
      Self.AddCData(TXMLCData(n).Data)
    end;
  end;

  FXMLBuff := ATag.FXMLBuff;
end;

function TXMLTag.AddTag(ATagName: string): TXMLTag;
var
  t: TXMLTag;
begin
  t := TXMLTag.Create;
  t.Name := ATagName;
  t.pTag := Self;
  FChildren.Add(t);
  Result := t;
end;

function TXMLTag.AddTag(AChildTag: TXMLTag): TXMLTag;
begin
  FChildren.Add(AChildTag);
  Result := AChildTag;
end;

function TXMLTag.XML: string;
var
  i: integer;
  x: String;
begin
  x := '<' + Self.Name;
  for i := 0 to FAttrList.Count - 1 do
    x := x + ' ' + FAttrList.Name(i) + '="' +
            XML_EscapeChars(FAttrList.Value(i)) + '"';

  if ((FChildren.Count = 0) and (FXMLBuff = '')) then
    x := x + '/>'
  else begin
    x := x + '>';
    for i := 0 to FChildren.Count - 1 do
      x := x + TXMLNode(FChildren[i]).XML;
      x := x + FXMLBuff;
      x := x + '</' + Self.name + '>';
  end;
  Result := x;
end;

function TXMLTag.ChildCount: integer;
begin
  Result := FChildren.Count;
end;

function TXMLTag.ChildTags: TXMLTagList;
var
  t: TXMLTagList;
  n: TXMLNode;
  i: integer;
begin
  t := TXMLTagList.Create();
  for i:=0 to FChildren.Count-1 do
  begin
    n := TXMLNode(FChildren[i]);
    if (n.IsTag) then
      t.Add(TXMLTag(n));
  end;
  Result := t;
end;

function TXMLTag.GetAttribute(AName: string): string;
var
  a: TNvpNode;
begin
  Result := '';
  a := FAttrList.Node(AName);
  if a<>nil then
    Result := a.Value;
end;

procedure TXMLTag.SetAttribute(AName, AValue: string);
var
  a: TNvpNode;
begin
  a := FAttrList.Node(AName);
  if a = nil then begin
    a := TAttr.Create(AName, AValue);
    FAttrList.Add(a);
  end else
    a.Value := AValue;
end;

procedure TXMLTag.RemoveAttribute(ATagName: string);
var
  a: TNvpNode;
begin
  a := FAttrList.Node(ATagName);
  if (a <> nil) then begin
    FAttrList.Remove(a);
  end;
end;

function TXMLTag.AddCData(AContent: String): TXMLCData;
var
  c: TXMLCData;
begin
  c := TXMLCData.Create(AContent);
  FChildren.Add(c);
  Result := c;
end;

procedure TXMLTag.ClearCData;
var
  i: integer;
  n: TXMLNode;
begin
  for i:= (FChildren.Count - 1) downto 0 do
  begin
    n := TXMLNode(FChildren[i]);
    if n is TXMLCDATA then
      FChildren.Delete(i);
  end;
end;

procedure TXMLTag.ClearTags;
var
  i: integer;
  n: TXMLNode;
begin
  for i:=(FChildren.Count-1) downto 0 do
  begin
    n := TXMLNode(FChildren[i]);
    if n is TXMLTag then
      FChildren.Delete(i);
  end;
end;

procedure TXMLTag.RemoveTag(node: TXMLTag);
var
  i: integer;
begin
  i := FChildren.IndexOf(node);
  if (i >= 0) then
    FChildren.Delete(i);
end;

function TXMLTag.AddBasicTag(ATagName, ACData: string): TXMLTag;
var
  t: TXMLTag;
begin
  t := AddTag(ATagName);
  t.pTag := Self;
  t.AddCData(ACData);
  Result := t;
end;

function TXMLTag.AddTagNS(ATagName, AXmlns: string): TXMLTag;
begin
  Result := AddTag(ATagName);
  Result.SetAttribute('xmlns', AXmlns);
end;

function TXMLTag.Data: string;
var
  i: integer;
  n: TXMLNode;
begin
  Result := '';
  for i:=0 to FChildren.Count - 1 do
  begin
    n := TXMLNode(FChildren[i]);
    if (n.NodeType = xml_CDATA) then
    begin
      Result := Result + TXMLCData(n).Data + ' ';
      Break;
    end;
  end;
  if Result <> '' then Result := Trim(Result);
end;

function TXMLTag.GetBasicText(ATagName: string): String;
var
  t: TXMLTag;
begin
  t := self.GetFirstTag(ATagName);
  if (t <> nil) then
    Result := t.Data
  else
    Result := '';
end;

function TXMLTag.GetFirstTag(ATagName: string): TXMLTag;
var
  sname: string;
  i: integer;
  n: TXMLNode;
begin
  Result := nil;
  sname := Trim(ATagName);
  assert(Fchildren <> nil);
  for i := 0 to FChildren.Count - 1 do
  begin
    n := TXMLNode(FChildren[i]);
    if ((n.IsTag) and (CompareStr(sname, n.name)=0)) then
    begin
      Result := TXMLTag(n);
      exit;
    end;
  end;
end;

function TXMLTag.Namespace(children: boolean): string;
var
  n:  TXMLNode;
  i:  integer;
begin
  if FNameSpace = '' then
  begin
    if (not children) then
      FNameSpace := Self.GetAttribute('xmlns');
    if FNameSpace='' then
    begin
      for i := 0 to FChildren.Count - 1 do
      begin
        n := TXMLNode(FChildren[i]);
        if (n.NodeType = xml_Tag) then
        begin
          FNameSpace := TXMLTag(n).GetAttribute('xmlns');
          if FNameSpace<>'' then
            break;
        end;
      end;
    end;
  end;
  Result := FNameSpace;
end;

function TXMLTag.TagExists(ATagName: string): boolean;
begin
  Result := (GetFirstTag(ATagName) <> nil);
end;

{ TXMLTagParser }

procedure TXMLTagParser.Clear;
begin
  FList.Clear;
end;

function TXMLTagParser.Count: integer;
begin
  Result := FList.Count;
end;

constructor TXMLTagParser.Create;
begin
  inherited;
  FParser := TXmlParser.Create;
  FParser.Normalize := False;
  FList := TList.Create;
end;

destructor TXMLTagParser.Destroy;
begin
  FParser.Clear;
  FParser.Free;
  FList.Free;
  inherited;
end;

procedure TXMLTagParser.ParseString(buff, stream_tag: string);
var
  tmp:string;
  curtag:TXMLTag;
  i:integer;
begin
  FParser.Clear;
  FParser.LoadFromBuffer(PChar(buff));
  FParser.StartScan;
  FParser.Normalize := False;
  curtag := nil;
  while FParser.Scan do begin
    case FParser.CurPartType of
      ptStartTag,
      ptEmptyTag:
          begin
            if (FParser.CurFinal[0]<>'>') then
            begin
              tmp := string(FParser.CurStart);
            end else
            begin
              if curtag=nil then
                curtag := TXMLTag.Create(Trim(FParser.CurName))
              else
                curtag := curtag.AddTag(Trim(FParser.CurName));

              for i:=0 to FParser.CurAttr.Count-1 do
                curtag.SetAttribute(FParser.CurAttr.Name(i),FParser.CurAttr.Value(i));

              if FParser.CurPartType=ptEmptyTag then
                curtag := ProcessTag(curtag);

              if FParser.CurName=stream_tag then
                curtag := ProcessTag(curtag);

            end;
          end;
      ptContent,
      ptCData:
          begin
            if curtag <> nil then
            begin
              tmp := Trim(FParser.CurContent);
              if tmp <> '' then
                curtag.AddCData(FParser.CurContent);
            end;
          end;
      ptEndTag:
          begin
            if curtag<>nil then
              curtag := ProcessTag(curtag);
          end;
    end;
  end;
end;

function TXMLTagParser.PopTag: TXMLTag;
begin
  if FList.Count > 0 then
  begin
    Result := TXMLTag(FList[0]);
    FList.Delete(0);
  end else
    Result := nil;
end;

function TXMLTagParser.ProcessTag(curtag: TXMLTag): TXMLTag;
begin
  if curtag = nil then
    Result := nil
  else
  if (curtag.pTag = nil) then
  begin
    FList.Add(curtag);
    Result := nil;
  end else
  begin
    Result := curtag.pTag;
  end;
end;

end.

