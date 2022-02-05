{  Cross platform packet client demo
    compiled and tested on windows/android
  2.4.2022 -q
  www.qubits.us


  be it harm none, do as ye wish..

}
unit uPacketClientDm;

interface

uses
  System.SysUtils, System.Classes,uClientCommsObj,IdComponent,FMX.Types,uPacketDefs,
  FMX.Graphics;


type
  TComm_Event                 = procedure (Sender:TObject) of object;
  TCommsError_Event           = procedure (Sender:TObject; aMsg:String) of Object;
  TRecvImg_Event              = procedure (Sender:TObject; aImage:tBitmap) of object;





type
  TPacketClientDm = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure CreateComms;
    procedure DestroyComms;
    procedure PacketSent(sender:TObject);
    procedure PacketRecv(sender:tObject);
    procedure ThreadErrorEvent(sender:TObject;const aMsg:String);
    procedure ThreadStatusEvent(sender:tObject;const aStatus:TidStatus);
    procedure PacketAvailable(Sender: TObject);
    procedure ProcessIncoming;
    procedure piRecvJpg;

  private
    { Private declarations }
    fConnected:boolean;
    fConnectEvent:tComm_Event;
    fDisconnectEvent:tComm_Event;
    fRecvEvent:tComm_Event;
    fSendEvent:tComm_Event;
    fCommsError:TCommsError_Event;
    fRecvIm:TRecvImg_Event;


  public
    { Public declarations }
   ClientComms:TClientComms;
   rcvBuff  :Array[0..9999999] of byte;//big ass buffer!!
   rcvCount:integer;

   property  OnConnect:TComm_Event read fConnectEvent write fConnectEvent;
   property  OnDisconnect:TComm_Event read fDisconnectEvent write fDisconnectEvent;
   property  OnRecvPacket:TComm_Event read fRecvEvent write fRecvEvent;
   property  OnSendPacket:TComm_Event read fSendEvent write fSendEvent;
   property  OnRecvImage:TRecvImg_Event read fRecvIm write fRecvIm;
   property  Connected:boolean read fConnected;
  end;

var
  PacketClientDm: TPacketClientDm;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TPacketClientDm.DataModuleCreate(Sender: TObject);
begin
//create
fConnected:=False;
end;

procedure TPacketClientDm.DataModuleDestroy(Sender: TObject);
begin
//destroy
if Assigned(ClientComms) then
begin
 try
  if ClientComms.Connected then
  ClientComms.Disconnect;
 finally
  ClientComms.Free;
 end;
end;

end;

procedure TPacketClientDm.CreateComms;
begin
ClientComms:=tClientComms.Create;
ClientComms.Port:=9000;
ClientComms.Host:='192.168.0.51';
ClientComms.ServerName:='SRV';
ClientComms.OnError:=ThreadErrorEvent;
ClientComms.OnPacketSent:=PacketSent;
ClientComms.OnPacketRecvd:=PacketRecv;
ClientComms.OnStatusChange:=ThreadStatusEvent;
end;

procedure TPacketClientDm.DestroyComms;
begin
if Assigned(ClientComms) then
begin
 try
  if ClientComms.Connected then
  ClientComms.Disconnect;
 finally
  ClientComms.Free

 end;

end;
end;

procedure TPacketClientDm.PacketSent(sender:TObject);
begin
  if Assigned(fSendEvent) then
     fSendEvent(nil);
end;
procedure TPacketClientDm.PacketRecv(sender:tObject);
begin

//process packet
  PacketAvailable(sender);
//notify
  if Assigned(fRecvEvent) then
         fRecvEvent(nil);

end;

procedure TPacketClientDm.ThreadErrorEvent(sender:TObject;const aMsg:String);
begin
    if Assigned(fCommsError) then
          fCommsError(sender,aMsg);
end;

procedure TPacketClientDm.ThreadStatusEvent(sender:tObject;const aStatus:TidStatus);
begin
  //
   if Ord(aStatus) = Ord(hsConnected) then
    begin
     fConnected:=true;
     if Assigned(fConnectEvent) then
         fConnectEvent(nil);
    end;

   if Ord(AStatus) = Ord(hsDisconnected) then
   begin
    //we are disconnected
    fConnected:=False;
   if Assigned(fDisconnectEvent) then
       fDisconnectEvent(nil);
   end;

end;

procedure TPacketClientDm.PacketAvailable(Sender: TObject);
  var
  aPacket:tPacketHdr;
  aBuff:pDataBuff;
begin

           aBuff:=ClientComms.PopPacket;

        if Assigned(aBuff) then
          begin
           //set recv byte count
           rcvCount:=aBuff^.BufferType;
           //move packet into old rec buffer
           Move(aBuff^.DataP[0],RcvBuff[0],Length(aBuff^.DataP));
          end else RcvCount:=0;

       if Assigned(aBuff) then
         begin
           SetLength(aBuff^.DataP,0);
           Dispose(aBuff);//free this, done with it..
          end;

       //see if we got enough for a packet
     if rcvCount>=SizeOf(TPacketHdr) then
        begin
        Move(rcvBuff[0],aPacket,SizeOf(aPacket));
          if CheckPacketIdent(tIdentArray(aPacket.Ident)) then
           begin
              //packets can have extra data.. check for a datasize..
             if rcvCount>=(aPacket.DataSize+SizeOf(aPacket)) then
                begin
                 ProcessIncoming;
                 rcvCount:=0;//reset our count
                 FillChar(rcvBuff,SizeOf(rcvBuff),#0);//reset buffer..
                end;
           end else
              begin
                //invalid header!!
                rcvcount:=0;
                FillChar(rcvBuff,SizeOf(rcvBuff),#0);//reset buffer..
              end;
        end;
end;

procedure TPacketClientDm.ProcessIncoming;
  //process incoming packet
var
  aPacket:tPacketHdr;
begin

     if RcvCount>=SizeOf(TPacketHdr) then
        begin
        Move(rcvBuff,aPacket,SizeOf(aPacket));
          //packets can have extra data.. check for a datasize..
        if RcvCount>=(aPacket.DataSize+SizeOf(aPacket)) then
          begin
            case aPacket.Command of
            CMD_NOP:;//nothing
            CMD_JPG:piRecvJpg;//piRecvJpeg;
            end;
          end;
        end;
end;

//tbitmap is flexible, would load more than just a jpg..
procedure TPacketClientDm.piRecvJpg;
var
aHdr:TPacketHdr;
aStrm:tMemoryStream;
aBitmap:TBitmap;
begin
  //
        aStrm:=tMemoryStream.Create;
        aBitMap:=TBitmap.Create;
   try
        Move(rcvBuff,aHdr,SizeOf(TPacketHdr));
        aStrm.SetSize(aHdr.DataSize);
        aStrm.Write(rcvBuff[SizeOf(TPacketHdr)],aHdr.DataSize);
        aStrm.Position:=0;
        aBitmap.LoadFromStream(aStrm);
        if Assigned(fRecvIm) then
           fRecvIm(self,aBitmap);
   finally
        aStrm.Free;
        aBitmap.Free;
   end;

end;



end.
