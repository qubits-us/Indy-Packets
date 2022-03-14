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
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure OnStatus(sender:tObject;const aStatus:string);
    procedure OnLog(sender:tObject);
    procedure OnError(sender:tObject);
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
PacketSrv.Start;

memLog.Lines.Strings[0]:='Server Active '+PacketSrv.IP;
//memLog.Lines.Insert(0,'Server Active '+PacketSrv.IP);
end;

procedure TMainFrm.Button2Click(Sender: TObject);
begin
PacketSrv.Stop;
memLog.Lines.Strings[0]:='Server Stopped';
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
//Android - GStack doesn't give us what we want..

{$IFDEF WINDOWS}
PacketSrv.IP:=GStack.LocalAddress;
IPs:=GStack.LocalAddresses;
for I := 0 to IPs.Count-1 do
  memLog.Lines.Insert(0,IPs.Strings[i]);
{$ENDIF}

{$IFDEF ANDROID}
ip:=PacketSrv.IP;
memLog.Lines.Insert(0,'Server IP: '+ip);
{$ENDIF}

PacketSrv.Port:=9000;
PacketSrv.OnState:=OnStatus;
PacketSrv.OnLog:=OnLog;
PacketSrv.OnError:=OnError;
memLog.Lines.Insert(0,'Server Stopped');


end;

procedure TMainFrm.OnStatus(Sender:tObject;const aStatus: string);
begin
  memLog.Lines.Insert(1,aStatus);
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
