{Main Form for Indy Packet Server

3.4.2022 -q

}


unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
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
end;

procedure TMainFrm.Button2Click(Sender: TObject);
begin
PacketSrv.Stop;
end;

procedure TMainFrm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
PacketSrv.Stop;
PacketSrv.Free;
end;

procedure TMainFrm.FormCreate(Sender: TObject);
begin
//
ReportMemoryLeaksOnShutDown:=true;
PacketSrv:=tPacketServer.Create;
PacketSrv.IP:=GStack.LocalAddress;
PacketSrv.Port:=9000;

end;

end.
