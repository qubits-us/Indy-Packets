{Main Form for Indy Packet Server

3.4.2022 -q

}


unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,System.Net.Socket,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdTCPServer, IdContext,IdStack,uIndyPacketServer, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.Edit,
  FMX.ScrollBox, FMX.Memo;

type
  TMainFrm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    memLog: TMemo;
    edPort: TEdit;
    Label1: TLabel;
    Button3: TButton;
    Button4: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure OnStatus(sender:tObject;const aStatus:string);
    procedure OnLog(sender:tObject);
    procedure OnError(sender:tObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.fmx}

procedure TMainFrm.Button1Click(Sender: TObject);
begin
if PacketSrv.Online then exit;//nop

PacketSrv.Start;

memLog.Lines.Strings[0]:='Server Active '+PacketSrv.IP;
end;

procedure TMainFrm.Button2Click(Sender: TObject);
begin
if not PacketSrv.Online then exit;//nop

PacketSrv.Stop;
memLog.Lines.Strings[0]:='Server Stopped';
end;

procedure TMainFrm.Button3Click(Sender: TObject);
begin
PacketSrv.DiscoveryEnabled:=true;
end;

procedure TMainFrm.Button4Click(Sender: TObject);
begin
PacketSrv.DiscoveryEnabled:=false;
end;

procedure TMainFrm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
PacketSrv.Stop;
PacketSrv.Free;
end;

procedure TMainFrm.FormCreate(Sender: TObject);
var
IPs:tStrings;
i:integer;
ip:string;

begin
//
ReportMemoryLeaksOnShutDown:=true;
PacketSrv:=tPacketServer.Create;
//Windows - use GStack.LocalAddress seems to give correct ip..
{$IFDEF MSWINDOWS}
PacketSrv.IP:=GStack.LocalAddress;
IPs:=GStack.LocalAddresses;
for I := 0 to IPs.Count-1 do
  memLog.Lines.Insert(0,IPs.Strings[i]);
{$ENDIF}
//Android - GStack doesn't give us what we want..
// pulling ip out of wifimanager when aquiring the multicast lock..
{$IFDEF ANDROID}
ip:=PacketSrv.IP;
memLog.Lines.Insert(0,'Server IP: '+ip);
{$ENDIF}

PacketSrv.Port:=9000;
PacketSrv.ServerName:='SRV1';
PacketSrv.OnState:=OnStatus;
PacketSrv.OnLog:=OnLog;
PacketSrv.OnError:=OnError;
memLog.Lines.Insert(0,'Server Stopped');


end;

procedure TMainFrm.OnStatus(Sender:tObject;const aStatus: string);
begin
  memLog.Lines.Insert(1,'Status Change: '+aStatus);
end;

procedure tMainFrm.OnLog(sender: TObject);
var
aMsg:string;
begin

  aMsg:='Log';
  aMsg:=PacketSrv.PopLog;
  memLog.Lines.Insert(1,aMSg);
end;

procedure tMainFrm.OnError(sender: TObject);
var
aMsg:string;
begin

  aMsg:='Error: '+PacketSrv.PopErrorLog;
  memLog.Lines.Insert(1,aMSg);
end;

end.
