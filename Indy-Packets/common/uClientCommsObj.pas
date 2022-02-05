{Indy Packet Client

Created for Inertia -dm

Loving Indy - It's like dropping a farrari motor in my subura..

}


unit uClientCommsObj;

interface

uses Classes,System.SysUtils, System.Generics.Collections, System.SyncObjs,
     IdGlobal, IdTCPClient,IdUdpServer,IdComponent,IdSocketHandle,FMX.Types
{$IFDEF ANDROID},androidapi.JNI.Net,Androidapi.JNIBridge, Androidapi.Jni,
    androidapi.JNI.JavaTypes,androidapi.JNI.Os,FMX.Helpers.Android,Androidapi.Helpers,
     Androidapi.Jni.GraphicsContentViewText {$ENDIF};


type
  TCommsThrd_Event  = procedure (Sender:TObject) of object;
  TCommsThrd_Error  = procedure (Sender:TObject;const aMsg:String) of object;
  TCommsThrd_Status = procedure (Sender: TObject; const AStatus: TIdStatus) of object;

//Packet Ident
const Ident_Packet :array[0..15] of byte =(0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7);
//largest packet
const Max_Packet_Size =1024000;
//max q's before dropping..
const MAX_QUES=101;

//type used in helper function
type TIdentArray =array[0..15] of byte;


//header for each packet..
type
  pPacketHdr=^tPacketHdr;
  tPacketHdr =packed record
      PacketIdent:array[0..15] of byte;//unique identifier..
      Command    :byte;
      DataSize   :integer;//datasize is size of additional data added after header
  end;


    //udp broadcast from server..
  type
     pDiscoveryPacket=^tDiscoveryPacket;
     tDiscoveryPacket =packed record
       PacketIdent:array[0..15] of byte;
       ServerName :array[0..25] of byte;
       ServerIp   :array[0..13] of byte;
       ServerPort :array[0..13] of byte;
     end;





 //data buffers stored in q's
type
   pDataBuff=^TDataBuff;
   TDataBuff=record
     BufferType:integer;
     DataP:array of byte
   end;

   //receives udp broadcast packets, auto configs client comms
   type
      TDiscoveryThread= class(TThread)
        private
            fUdp:TIdUDPServer;
            fLock:TCriticalSection;
            fErrorEvent:TCommsThrd_Error;
            fDiscvRecvEvent:TCommsThrd_Event;
            fPauseEvent:TEvent;
            fDiscvEvent:TEvent;
            fLastError:String;
            fPaused:boolean;
            fPort:integer;
            fSrvName:String;
            fSrvIP:String;
            fSrvPort:Integer;
            fBurp:boolean;
            fDiscvRecvd:integer;
            fBadPackets:integer;
            procedure SetBadRecvd(aValue:integer);
            function  GetBadRecvd:integer;
            procedure IncBadRecvd;
            procedure SetDiscvRecvd(aValue:integer);
            function  GetDiscvRecvd:integer;
            procedure IncDiscvRecvd;
            function  GetBurp:boolean;
            procedure SetBurp(aValue:boolean);
            function  GetPort:integer;
            procedure SetPort(aValue:integer);
            procedure SetPause(const aValue:Boolean);
            function  GetPause:boolean;
            procedure SetServerIp(aValue:String);
            function  GetServerIP:String;
            procedure SetServerPort(aValue:integer);
            function  GetServerPort:integer;
            procedure SetServerName(aValue:String);
            function  GetServerName:String;
            procedure OnUDPRead(AThread: TIdUDPListenerThread;const AData: TIdBytes; ABinding: TIdSocketHandle);
            procedure OnUDPError(AThread: TIdUDPListenerThread; ABinding: TIdSocketHandle;const AMessage: string; const AExceptionClass: TClass);
            function  CheckPacketIdent(Const AIdent:TIdentArray):boolean;
            function  CheckSrvName(const aPacket:TDiscoveryPacket):boolean;
            function  BytesToStr(const aBytes:Array of byte):string;
            procedure Burp;

         protected
             procedure Execute;override;
             procedure DoErrorMsg;
             procedure DoDiscvRecv;
         public
             Constructor Create(aLock:TCriticalSection);
             destructor  Destroy;override;
             property    OnError:TCommsThrd_Error read fErrorEvent write fErrorEvent;
             property    OnDiscovery:TCommsThrd_Event read fDiscvRecvEvent write fDiscvRecvEvent;
             property    Paused:boolean read GetPause write SetPause;
             property    Port:integer read GetPort write SetPort;
             property    ServerPort:integer read GetServerPort;
             property    ServerIP:string read GetServerIP;
             property    ServerName:String read GetServerName write SetServerName;
             property    DoBurp:boolean read GetBurp write SetBurp;
             property    BadPackets:integer read GetBadRecvd;
             property    PacketsReceived:integer read GetDiscvRecvd;
      end;


   //thread for sending data
   type
       TSendingThread= class(TThread)
         private
            fSock:TIDTCPClient;
            fOutQ:TQueue<Pointer>;
            fLock:TCriticalSection;
            fLastError:String;
            fErrorEvent:TCommsThrd_Error;
            fPacketSentEvent:TCommsThrd_Event;
            fPaused:boolean;
            fEvent:TEvent;
            fSent:integer;
            fDropped:integer;
            procedure SetSent(const aValue:integer);
            function  GetSent:integer;
            procedure IncSent;
            procedure SetDropped(const aValue:integer);
            function  GetDropped:integer;
            procedure IncDropped;

            procedure SetPause(const aValue:Boolean);
            function  GetPause:boolean;

         protected
             procedure Execute;override;
             procedure DoErrorMsg;
             procedure DoPacketSent;
             procedure SendPacket;
         public
             Constructor Create(aClient:TIdTCPClient;aQ:TQueue<Pointer>;aLock:TCriticalSection);
             destructor  Destroy;override;
             property    OnError:TCommsThrd_Error read fErrorEvent write fErrorEvent;
             property    OnPacketSent:TCommsThrd_Event read fPacketSentEvent write fPacketSentEvent;
             property    Paused:boolean read GetPause write SetPause;
             property    Dropped:integer read GetDropped;
             property    Sent:integer read GetSent;
       end;

   //thread for receiving data
   type
       TReceivingThread= class(TThread)
         private
            fSock:TIDTCPClient;
            fInQ:TQueue<Pointer>;
            fLock:TCriticalSection;
            fLastError:String;
            fErrorEvent:TCommsThrd_Error;
            fPacketRecvEvent:TCommsThrd_Event;
            fPaused:boolean;
            fEvent:TEvent;
            fDropped:integer;
            fRecvd:integer;
            procedure SetPause(const aValue:boolean);
            function  GetPause:boolean;
            function  CheckPacketIdent(const aPacket:TPacketHdr):boolean;
            function  GetPacketsDropped:integer;
            procedure SetPacketsDropped(const aValue:integer);
            procedure IncPacketsDropped;
            function  GetPacketsRecvd:integer;
            procedure SetPacketsRecvd(const aValue:integer);
            procedure IncPacketsRecvd;

         protected
             procedure Execute;override;
             procedure DoErrorMsg;
             procedure DoPacketRecv;
             procedure RecvPacket(const APacketHdr:TPacketHdr);
         public
             Constructor Create(aClient:TIdTCPClient;aQ:TQueue<Pointer>;aLock:TCriticalSection);
             Destructor  Destroy;override;
             property    OnError:TCommsThrd_Error read fErrorEvent write fErrorEvent;
             property    OnPacketReceived:TCommsThrd_Event read fPacketRecvEvent write fPacketRecvEvent;
             property    Paused:boolean read GetPause write SetPause;
             property    Dropped:integer read GetPacketsDropped;
             property    Received:integer read GetPacketsRecvd;
       end;



type
 TClientComms= class(Tobject)
   private
    fInQue:TQueue<Pointer>;//incoming packets
    fOutQue:TQueue<Pointer>;//outgoing packets
    fLock:TCriticalSection;//crit to protect things
    fOutPacketSentEvent:TCommsThrd_Event;
    fOnPacketRecvdEvent:TCommsThrd_Event;
    fOnDiscvRecvdEvent:TCommsThrd_Event;
    fErrorEvent:TCommsThrd_Error;
    fStatusEvent:TCommsThrd_Status;
    fClientStatus:TIdStatus;
    fClientSock:TIdTCPClient;//our indy client sock
    fPort:integer;//the port
    fHost:String;// the host
    fLastErrorMsg:String;
    fConnected:Boolean;
    fAutoReconnect:boolean;
    fSendThrd:TSendingThread;//sending
    fRecThrd:TReceivingThread;//receiving
    fDiscvThrd:TDiscoveryThread;//discovery
    fOutPacketsDropped:integer;
    {$IFDEF ANDROID}
    fWifiLockEngaged:boolean;
    fWifiManager:JWifiManager;
    fMultiCastLock:JWifiManager_MulticastLock;
    function GetWiFiManager: JWiFiManager;
    procedure GetWifiLock;
    procedure ReleaseWifiLock;
    {$ENDIF}
    procedure SetConnected(aValue:boolean);
    function  GetConnected:boolean;
    procedure SetDropped(aValue:integer);
    function  GetDropped:integer;
    procedure IncDropped;
    function  GetDX:integer;
    function  GetDXbad:integer;
    function  GetRX:integer;
    function  GetTX:integer;
    function  GetRXDropped:integer;
    procedure SetHost(aHost:String);
    function  GetHost:String;
    procedure SetPort(aPort:integer);
    function  GetPort:integer;
    procedure SetServerName(aValue:String);
    function  GetServerName:String;
    procedure SetStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
    procedure SendingError(Sender:TObject;const aMsg:String);
    procedure PacketSent(Sender:TObject);
    procedure ReceivingError(Sender:TObject;const aMsg:String);
    procedure PacketRecvd(Sender:TObject);
    procedure DiscvRecvd(sender:Tobject);
    procedure DiscvError(Sender:TObject;const aMsg:String);

  protected
    function GetInCount:integer;
    function GetOutCount:integer;
    procedure DoDiscvRecvd;
    procedure DoPacketSent;
    procedure DoPacketRecvd;
    procedure DoErrorMsg;
    procedure DoStatusChange;
  public
    constructor Create;
    destructor  Destroy;override;
    procedure   PushPacket(pData:pDataBuff);
    function    PopPacket:pDataBuff;
    procedure   ClearOutQue;
    procedure   ClearInQue;
    procedure   Connect;
    procedure   Disconnect;
    procedure   Discover;
    property    InQCount:integer read GetInCount;
    property    OutQCount:integer read GetOutCount;
    property    OnPacketSent:TCommsThrd_Event read fOutPacketSentEvent write fOutPacketSentEvent;
    property    OnPacketRecvd:TCommsThrd_Event read fOnPacketRecvdEvent write fOnPacketRecvdEvent;
    property    OnDiscoveryRecvd:TCommsThrd_Event read fOnDiscvRecvdEvent write fOnDiscvRecvdEvent;
    property    OnError:TCommsThrd_Error read fErrorEvent write fErrorEvent;
    property    OnStatusChange:TCommsThrd_Status read fStatusEvent write fStatusEvent;
    property    Port:integer read fPort write fPort;
    property    Host:String read GetHost write SetHost;
    property    ServerName:String read GetServerName write SetServerName;
    property    Connected:boolean read GetConnected;
    property    AutoReconnect:boolean read fAutoReconnect write fAutoReconnect;
    property    TXPacketsDropped:integer read GetDropped;
    property    RXPacketsDropped:integer read GetRXDropped;
    property    TXPackets:integer read GetTX;
    property    RXPackets:integer read GetRX;
    property    DXPackets:integer read GetDX;
    property    DXPacketsBad:integer read GetDXbad;
     end;







implementation



{TDiscoveryThread}
constructor TDiscoveryThread.Create(aLock: TCriticalSection);
begin
  fLock:=aLock;
  fPaused:=true;
  fPort:=6000;
  fSrvIP:='';
  fSrvPort:=0;
  fSrvName:='SRV1';
  fBurp:=false;

  fPauseEvent:=tEvent.Create(nil,true, false,'');
  fDiscvEvent:=tEvent.Create(nil,true,false,'');
  try
  fUdp:=TIDUDPServer.Create(nil);
  fUdp.DefaultPort:=fPort;
  FUdp.BroadcastEnabled:=true;
  fUdp.OnUDPRead:=OnUdpRead;
  fUdp.OnUDPException:=OnUdpError;
  fUdp.ThreadedEvent:=true;
  { do i need this??
  fUdp.Bindings.Clear;
  with FUdp.Bindings.Add do
    begin
      IP:='0.0.0.0';
      Port:=6000;
    end;
   }
  finally
    ;
  end;

  inherited Create(false);

end;

//clean house!!
destructor TDiscoveryThread.Destroy;
begin
  //kill the udp socket srvr
  if Assigned(fUdp) then
    begin
     if fUdp.Active then fUdp.Active:=false;
     try
       fUdp.Free;
      finally
       ;
     end;
    end;

  Terminate;//shut down please
  fPauseEvent.SetEvent;//release it..
  FDiscvEvent.SetEvent;//release it..
  //might already be done..
  if not Finished then WaitFor;//no hang ups please gods!!
  fPauseEvent.Free;//bye
  fDiscvEvent.Free;//bye
  fLock:=nil;//remove ref
  inherited;// and everything else..

end;

//excuse me.. :)
procedure TDiscoveryThread.Burp;
var
aPacket:TDiscoveryPacket;
aBuff:TIdBytes;
begin


  //try to broadcast a packet to open things up..
  //not our name se we would ignore it..
   aPacket.PacketIdent[0]:=0;
   aPacket.ServerName[0]:=0;
   aPacket.ServerIp[0]:=0;
   aPacket.ServerPort[0]:=0;
   //take me struct and stuff it into an indy buff..
   SetLength(aBuff,SizeOf(aPacket));
   Move(aPacket,aBuff[0],SizeOf(aPacket));
 try
  fUdp.Broadcast(aBuff,fUdp.DefaultPort);
  except on e:Exception do
    begin
     fLastError:='Burp Error: '+e.Message;
     Synchronize(DoErrorMsg);
    end;
 end;
  SetLength(aBuff,0);//bye



end;

//do we burp out a broadcast packet when active set to true..
//might open things up if stuck.. don't seem to need it..
procedure TDiscoveryThread.SetBurp(aValue: Boolean);
begin
  fLock.Enter;
  try
    fBurp:=aValue;
  finally
  fLock.Leave;

  end;
end;

//get the burp
function TDiscoveryThread.GetBurp:boolean;
begin
fLock.Enter;
try
    result:=fBurp;
finally
fLock.Leave;

end;

end;


//how many discv packets recvs
procedure TDiscoveryThread.SetDiscvRecvd(aValue: Integer);
begin
  fLock.Enter;
  try
    fDiscvRecvd:=aValue;
  finally
  fLock.Leave;

  end;
end;
// get em
function TDiscoveryThread.GetDiscvRecvd;
begin
  fLock.Enter;
  try
    result:=fDiscvRecvd;
  finally
  fLock.Leave;

  end;
end;
// inc em
procedure TDiscoveryThread.IncDiscvRecvd;
begin
  fLock.Enter;
  try
    Inc(fDiscvRecvd);
  finally
  fLock.Leave;

  end;
end;



//how many bad discovery packets received..
procedure TDiscoveryThread.SetBadRecvd(aValue: Integer);
begin
  fLock.Enter;
  try
    fBadPackets:=aValue;
  finally
  fLock.Leave;

  end;
end;
//get em..
function TDiscoveryThread.GetBadRecvd;
begin
  fLock.Enter;
  try
    result:=fBadPackets;
  finally
  fLock.Leave;

  end;
end;
//incrament em.. means plus one.. +1 :)
procedure TDiscoveryThread.IncBadRecvd;
begin
  fLock.Enter;
  try
    Inc(fBadPackets);
  finally
  fLock.Leave;

  end;
end;



// the port we use
procedure TDiscoveryThread.SetPort(aValue: Integer);
begin
  fLock.Enter;
  try
    fPort:=aValue;
  finally
  fLock.Leave;
  end;
end;

//get it..
function TDiscoveryThread.GetPort:integer;
begin
fLock.Enter;
try
   result:=fPort;
finally
fLock.Leave;
end;


end;

//server ip client should connect too..
procedure TDiscoveryThread.SetServerIp(aValue:String);
begin
  fLock.Enter;
  try
    fSrvIp:=aValue;
  finally
  fLock.Leave;

  end;


end;


//get it..
function TDiscoveryThread.GetServerIP:String;
begin
fLock.Enter;
try
  result:=fSrvIP;
finally
fLock.Leave;
end;

end;


//the server port we connect too..
procedure TDiscoveryThread.SetServerPort(aValue: Integer);
begin
  fLock.Enter;
  try
    fSrvPort:=aValue;
  finally
   fLock.Leave;
  end;

end;

//get it
function TDiscoveryThread.GetServerPort;
begin
  fLock.Enter;
  try
    result:=fSrvPort;
  finally
  fLock.Leave;

  end;
end;

//server name we listen for.. set this!! :)
procedure TDiscoveryThread.SetServerName(aValue: string);
begin
  fLock.Enter;
  try
    fSrvName:=aValue;
  finally
   fLock.Leave;
  end;
end;

//get it..
function TDiscoveryThread.GetServerName:string;
begin
fLock.Enter;
try
  result:=fSrvName;
finally
fLock.Leave;
end;

end;

//just chill..
procedure TDiscoveryThread.SetPause(const aValue: Boolean);
begin
  fLock.Enter;
  try
  if (not Terminated) and (fPaused <> aValue) then
  begin
    fPaused := aValue;
    if fPaused then
    begin
      fPauseEvent.ResetEvent;
      fUdp.Active:=false;
      end else
        begin
         fPauseEvent.SetEvent;
         fUdp.Active:=true;
         if DoBurp then Burp;

        end;
  end;

  finally
    fLock.Leave;
  end;

end;

//get it
function TDiscoveryThread.GetPause:boolean;
begin
fLock.Enter;
try
  result:=fPaused;

finally
  fLock.Leave;
end;

end;


// oops!!
procedure TDiscoveryThread.DoErrorMsg;
begin
  if Assigned(fErrorEvent) then
       fErrorEvent(self,fLastError);
end;

//got a discovery packet
procedure TDiscoveryThread.DoDiscvRecv;
begin
    if Assigned(fDiscvRecvEvent) then
       fDiscvRecvEvent(self);
end;



//does it match our packet identifier
function TDiscoveryThread.CheckPacketIdent(Const AIdent:TIdentArray):boolean;
var
i:integer;
begin
   Result:=true;
     for I := Low(aIdent) to High(AIdent) do
       if AIdent[i]<>Ident_Packet[i] then result:=false;
end;


//does it match our server name
function TDiscoveryThread.CheckSrvName(const aPacket:TDiscoveryPacket):boolean;
var
i:integer;
SrvNameBytes:tBytes;
begin
 Result:=true;
  //grab a local copy
   fLock.Enter;
  try
  SrvNameBytes:=BytesOf(fSrvName);
  finally
    fLock.Leave;
  end;
  //check em, quick..
  for I := Low(SrvNameBytes) to High(SrvNameBytes) do
   if i<=High(aPacket.ServerName) then
    if SrvNameBytes[i]<>aPAcket.ServerName[i] then
        result:=false;
end;


//convert from byte array to string, missing me short strings.. :)
function TDiscoveryThread.BytesToStr(const aBytes:Array of byte):string;
var
i:integer;
sBytes:TBytes;
aEncoding:TEncoding;
begin
    aEncoding:=TEncoding.ASCII;
    result:='';
    SetLength(sBytes,High(aBytes));
    Move(aBytes[0],sBytes[0],Length(sBytes));
    result:=aEncoding.GetString(sBytes);
end;



//don't do much in here.. wait for pause or wait for packet received
procedure TDiscoveryThread.Execute;
begin

while not Terminated do
   begin
      try

       if Terminated then exit;
       fPauseEvent.WaitFor(INFINITE);//pause
       if Terminated then exit;
       if Terminated then exit;
       fDiscvEvent.WaitFor(INFINITE);//wait for recvd packet
       if Terminated then exit;
       if not Terminated then Synchronize(DoDiscvRecv);
       if not Terminated then fDiscvEvent.ResetEvent;

      finally
       ;
      end;

   end;

end;

//called from fudp server thread when we get some data..
procedure TDiscoveryThread.OnUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
var
aPacket:TDiscoveryPacket;
begin
    //check size
    if Length(aData) >= SizeOf(aPacket) then
      begin
         //take it..
         Move(aData[0],aPacket,SizeOf(aPacket));
         //check packet idetifier
         if CheckPacketIdent(TIdentArray(aPacket.PacketIdent)) then
          begin
            //is it our srv.. will be many.. :)
           if CheckSrvName(aPacket) then
             begin
             //only if name matches..
             fLock.Enter;
             try
             fSrvIP:=BytesToStr(aPacket.ServerIp);
             fSrvPort:=StrToInt(BytesToStr(aPacket.ServerPort));
             finally
               fLock.Leave;
             end;
             //count it..
             IncDiscvRecvd;
             //trigger discovery event..
             fDiscvEvent.SetEvent;
             end else
               begin
                IncBadRecvd;
                fLastError:='Invalid Server Name';
                Synchronize(DoErrorMsg);

               end;
          end else//not our ident..
            begin
              IncBadRecvd;
              fLastError:='Invalid Packet Ident';
              Synchronize(DoErrorMsg);
            end;
      end;


end;


procedure TDiscoveryThread.OnUDPError(AThread: TIdUDPListenerThread; ABinding: TIdSocketHandle; const AMessage: string; const AExceptionClass: TClass);
begin
   fLastError:=aMessage;
   Synchronize(DoErrorMsg);
end;




{TSendingThread}

constructor TSendingThread.Create(aClient: TIdTCPClient;aQ:TQueue<Pointer>;aLock:TcriticalSection);
begin
  fSock:=aClient;
  fOutQ:=aQ;
  fLock:=aLock;
  fPaused:=true;
  fEvent:=tEvent.Create(nil,true, false,'');
  inherited Create(true);
end;


destructor TSendingThread.Destroy;
begin
  Terminate;
  fEvent.SetEvent;
  if Started then WaitFor;
  fEvent.Free;
  fLock:=nil;
  fSock:=nil;
  fOutQ:=nil;
  inherited;
end;


procedure TSendingThread.SetSent(const aValue: Integer);
begin
  fLock.Enter;
  try
    fSent:=aValue;
  finally
   fLock.Leave;
  end;
end;

function TSendingThread.GetSent:integer;
begin
fLock.Enter;
try
  result:=fSent;
finally
 fLock.Leave;
end;

end;

procedure TSendingThread.IncSent;
begin
  fLock.Enter;
  try
    Inc(fSent);
  finally
  fLock.Leave;
  end;
end;



procedure TSendingThread.SetDropped(const aValue: Integer);
begin
  fLock.Enter;
  try
    fDropped:=aValue;
  finally
   fLock.Leave;
  end;
end;

function TSendingThread.GetDropped:integer;
begin
fLock.Enter;
try
  result:=fDropped;
finally
 fLock.Leave;
end;

end;

procedure TSendingThread.IncDropped;
begin
  fLock.Enter;
  try
    Inc(fDropped);
  finally
  fLock.Leave;
  end;
end;




procedure TSendingThread.SetPause(const aValue: Boolean);
begin
  fLock.Enter;
  try
  if (not Terminated) and (fPaused <> aValue) then
  begin
    fPaused := aValue;
    if fPaused then
      fEvent.ResetEvent
       else
      fEvent.SetEvent;
  end;

  finally
    fLock.Leave;
  end;

end;

function TSendingThread.GetPause:boolean;
begin
fLock.Enter;
try
  result:=fPaused;

finally
  fLock.Leave;
end;

end;








procedure TSendingThread.Execute;
var
qCount:integer;
begin
 //send data from outq
   while not Terminated do
     begin
      try

       if Terminated then exit;
       fEvent.WaitFor(INFINITE);//pause
       if Terminated then exit;

      if fSock.Connected then
       begin


          fLock.Enter;
          try
          qCount:=foutQ.Count;
          finally
          fLock.Leave;
          end;



         if Terminated then  exit;

         //check outgoing q
         if QCount>0 then SendPacket else if not Terminated then SetPause(true);


       end else if not Terminated then setPause(true);




       Except on e:Exception do
        begin
                  fLastError:='ST:'+e.Message;
                 if Assigned(fErrorEvent) then
                     Synchronize(DoErrorMsg);

        end;


      end;//try


     end;//while not terminated
end;


procedure TSendingThread.SendPacket;
var
aPacket:pDataBuff;
aBuff:TIdBytes;
begin
   aPacket:=nil;

   try
   //get the next packet
     fLock.Enter;
     try
     aPacket:=fOutQ.Dequeue;
     finally
     fLock.Leave;
     end;
      //make sure we popped something good..
     if not assigned(aPacket) then
       begin
       fLastError:='ST:Packet not assigned';
       if Assigned(fErrorEvent) then Synchronize(DoErrorMsg);
       IncDropped;//dropping it
       exit;
       end;


           if Length(aPacket^.DataP)>0 then  //no empties allowed
             begin
               //make room..
               SetLength(aBuff,Length(aPacket^.DataP));
               //move packet into buffer
               Move(aPacket^.DataP[0],aBuff[0],Length(aBuff));

               try
               fSock.IOHandler.Write(aBuff);//send it off..
               IncSent;//count it..
               except on e:Exception do
                begin
                  fLastError:='ST:'+e.Message;
                 if Assigned(fErrorEvent) then Synchronize(DoErrorMsg);
                     //clean up..
                    SetLength(aBuff,0);
                    if Assigned(aPacket) then
                     begin
                      setLength(aPacket^.DataP,0);
                      Dispose(aPacket);
                     end;
                    IncDropped;//dropping it..
                    exit;//outta here
                end;
               end;

              if assigned(fPacketSentEvent) then
                Synchronize(DoPacketSent);

                //dispose..
                SetLength(aBuff,0);


             end else
               begin
                  fLastError:='ST:Data array empty.';
                 if Assigned(fErrorEvent) then
                     Synchronize(DoErrorMsg);
                      IncDropped;//dropping it

               end;
       //clean house..
       if Assigned(aPacket) then
        begin
         SetLength(aPacket^.DataP,0);
         Dispose(aPacket);
        end;

   Except on e:Exception do
   begin
                  fLastError:='ST:'+e.Message;
                 if Assigned(fErrorEvent) then
                     Synchronize(DoErrorMsg);
                     IncDropped;//??
       //clean house..
       if Assigned(aPacket) then
        begin
         SetLength(aPacket^.DataP,0);
         Dispose(aPacket);
        end;

   end;

   end;




end;



procedure TSendingThread.DoErrorMsg;
begin
  if Assigned(fErrorEvent) then
       fErrorEvent(self,fLastError);

end;


procedure TSendingThread.DoPacketSent;
begin
    if Assigned(fPacketSentEvent) then
       fPacketSentEvent(self);

end;


{TReceivingThread}


constructor TReceivingThread.Create(aClient: TIdTCPClient;aQ:TQueue<Pointer>;aLock:TcriticalSection);
begin
  fSock:=aClient;
  fInQ:=aQ;
  fLock:=aLock;
  fPaused:=true;
  fLastError:='';
  fDropped:=0;
  fRecvd:=0;
  fEvent:=tEvent.Create(nil,true, false,'');
  inherited Create(true);
end;


destructor TReceivingThread.Destroy;
begin
  Terminate;
  fEvent.SetEvent;
  if Started then WaitFor;
  fEvent.Free;
  fLock:=nil;
  inherited;

end;


procedure TReceivingThread.SetPause(const aValue: Boolean);
begin
fLock.Enter;
 try
  if (not Terminated) and (fPaused <> aValue) then
  begin
    fPaused := aValue;
    if fPaused then
      fEvent.ResetEvent else
      fEvent.SetEvent;
  end;
 finally
    fLock.Leave;
 end;

end;

function TReceivingThread.GetPause:boolean;
begin
fLock.Enter;
try
  result:=fPaused;
finally
 fLock.Leave;
end;

end;

procedure TReceivingThread.IncPacketsDropped;
begin
  fLock.Enter;
  try
    Inc(fDropped);
  finally
  fLock.Leave;

  end;
end;


procedure TReceivingThread.SetPacketsDropped(const aValue: Integer);
begin
  fLock.Enter;
  try
    fDropped:=aValue;
  finally
   fLock.Leave;
  end;
end;

function TReceivingThread.GetPacketsDropped:integer;
begin
fLock.Enter;
try
    result:=fDropped;
finally
fLock.Leave;
end;

end;


procedure TReceivingThread.IncPacketsRecvd;
begin
  fLock.Enter;
  try
    Inc(fRecvd);
  finally
  fLock.Leave;
  end;
end;


procedure TReceivingThread.SetPacketsRecvd(const aValue: Integer);
begin
  fLock.Enter;
  try
    fRecvd:=aValue;
  finally
   fLock.Leave;
  end;
end;

function TReceivingThread.GetPacketsRecvd:integer;
begin
fLock.Enter;
try
    result:=fRecvd;
finally
fLock.Leave;
end;

end;




procedure TReceivingThread.Execute;
var
qCount:integer;
aData:TIdBytes;
aGoodRead:boolean;
APacketHdr:TPacketHdr;
begin
  aGoodRead:=true;//sets length first loop thru
 //send data from outq
   while not Terminated do
     begin
     try

       if Terminated then exit;
       fEvent.WaitFor(INFINITE);//pause
       if Terminated then exit;



      if fSock.Connected then
       begin
         if Terminated then exit;

       if aGoodRead then
        SetLength(aData,SizeOf(TPacketHdr));
         //read in a packet hdr
        aGoodRead:=false;
        try
         fSock.IOHandler.ReadBytes(aData,SizeOf(TPacketHdr),False);
         aGoodRead:=true;
         if Terminated then exit;

        except on e:Exception do
          begin
           //don't raise an error on a read time out, just ignore em..
           if e.Message<>'Read timed out.' then
           begin
           fLastError:='RT:'+e.Message;
           if Assigned(fErrorEvent) then Synchronize(DoErrorMsg);
           end;
          end;
        end;
       if aGoodRead then
        begin
        if Length(aData)=SizeOf(TPacketHdr) then
          begin
            //process the packet..
            move(aData[0],aPacketHdr,SizeOf(TPacketHdr));
            if CheckPacketIdent(aPacketHdr) then
               begin
                 RecvPacket(aPacketHdr);

               end else
                  begin
                   fLastError:='RT:Invalid Hdr Ident Recvd';
                   if Assigned(fErrorEvent) then Synchronize(DoErrorMsg);

                  end;


          end else
             begin
              fLastError:='RT:Invalid Hdr Size Recvd: '+IntToStr(Length(aData));
              if Assigned(fErrorEvent) then Synchronize(DoErrorMsg);

             end;
          SetLength(aData,0);
        end;

       end else if not Terminated then SetPause(true);




       Except on e:Exception do
        begin
                  fLastError:='RT:'+e.Message;
                 if Assigned(fErrorEvent) then
                     Synchronize(DoErrorMsg);

         end;
     end;//try


     end;//while not terminated
end;


function TReceivingThread.CheckPacketIdent(const aPacket: tPacketHdr):boolean;
var
i:integer;
begin
  Result:=true;
   for I := Low(aPacket.PacketIdent) to High(aPAcket.PacketIdent) do
   if aPacket.PacketIdent[i]<> Ident_Packet[i] then result:=false;
end;


procedure TReceivingThread.RecvPacket(const aPacketHdr:TPacketHdr);
var
aPacket:pDataBuff;
aData:TIdBytes;
aSize:integer;
begin

   try
       if Terminated then exit;

       //out of memory maybe
       try
         New(aPacket);//make a new packet buff to be added to the q
       except on e:Exception do
        begin
                  fLastError:='RT:'+e.Message;
                 if Assigned(fErrorEvent) then
                     Synchronize(DoErrorMsg);
                 exit;
        end;
       end;


           if aPacketHdr.DataSize>0 then
             begin
               //need to recv some more

               SetLength(aData,aPacketHdr.DataSize);


                   try
                    fSock.IOHandler.ReadBytes(aData,aPAcketHdr.DataSize,False);
                    if Terminated then exit;

                   except on e:Exception do
                     begin
                      fLastError:='RT:'+e.Message;
                      if Assigned(fErrorEvent) then Synchronize(DoErrorMsg);
                      if assigned(aPacket) then Dispose(aPacket);
                      exit;
                     end;
                   end;

                if Length(aData)=aPAcketHdr.DataSize then
                  begin
                   //calculate total size
                   aPacket^.BufferType:=SizeOf(tPacketHdr)+Length(AData);
                   //make the room
                   SetLength(aPacket^.DataP,APacket^.BufferType);
                   //move in header
                   move(aPacketHdr,aPAcket^.DataP[0],SizeOf(TPacketHdr));
                   //then extra data
                   move(aData[0],aPacket^.DataP[SizeOf(tPacketHdr)],Length(aData));
                      //push to the incoming q .. max is 100
                      fLock.Enter;
                      try
                       if fInQ.Count<MAX_QUES then fInQ.Enqueue(aPacket) else
                         begin
                           //drop it, sorry
                           IncPacketsDropped;
                           SetLength(aPacket^.DataP,0);
                           Dispose(aPacket);
                         end;
                      finally
                       fLock.Leave;
                      end;
                       //free
                      SetLength(aData,0);



                  end else
                     begin
                      fLastError:='RT:Invalid Size Recvd :'+IntToStr(Length(aData))+' Expecting: '+IntToStr(aPacketHdr.DataSize);
                      if Assigned(fErrorEvent) then Synchronize(DoErrorMsg);
                      SetLength(aData,0);
                      if Assigned(aPacket) then Dispose(aPacket);
                      exit;
                     end;



              if assigned(fPacketRecvEvent) then
                Synchronize(DoPacketRecv);


                SetLength(aData,0);


             end else
               begin
                 //just saving the header..

                   //move in header
                   SetLength(aPacket^.DataP,SizeOf(TPacketHdr));
                   move(aPacketHdr,aPAcket^.DataP[0],SizeOf(TPacketHdr));
                   //calc size
                   aPacket^.BufferType:=SizeOf(TPacketHdr);
                     //push to the incoming q
                      fLock.Enter;
                      try
                       if fInQ.Count<MAX_QUES then fInQ.Enqueue(aPacket) else
                         begin
                           //drop it sorry..
                           IncPacketsDropped;
                           SetLength(aPacket^.DataP,0);
                           Dispose(aPacket);
                         end;
                      finally
                       fLock.Leave;
                      end;
                      //free
                      SetLength(aData,0);

                 if assigned(fPacketRecvEvent) then
                   Synchronize(DoPacketRecv);

               end;

   Except on e:Exception do
   begin
                  fLastError:='ST:'+e.Message;
                 if Assigned(fErrorEvent) then
                     Synchronize(DoErrorMsg);
               //free??


   end;

   end;




end;



procedure TReceivingThread.DoErrorMsg;
begin
  if Assigned(fErrorEvent) then
       fErrorEvent(self,fLastError);

end;


procedure TReceivingThread.DoPacketRecv;
begin
    if Assigned(fPacketRecvEvent) then
       fPacketRecvEvent(self);

end;




{TClientComms}




constructor TClientComms.Create;
begin
inherited create;

  fInQue:=TQueue<Pointer>.Create;
  fOutQue:=TQueue<Pointer>.Create;
  fLock:=tCriticalSection.Create;
  fClientSock:=TIdTcpClient.Create(nil);
  fClientSock.Port:=9000;
  fClientSock.Host:='192.168.0.51';
  fClientSock.UseNagle:=false;
  fClientSock.OnStatus:=SetStatus;
  fClientSock.ReadTimeout:=1000;//should be 1sec or 1000ms
  //fClientSock.IOHandler.RecvBufferSize:=MAX_PACKET_SIZE;
  //fClientSock.IOHandler.SendBufferSize:=MAX_PACKET_SIZE;
  fPort:=9000;
  fHost:='192.168.0.51';
  fLastErrorMsg:='';
  fConnected:=false;
  fAutoReconnect:=false;
  {$IFDEF ANDROID}
  fWifiLockEngaged:=false;
  {$ENDIF}
  //create our sending thread
  fSendThrd:=TSendingThread.Create(fClientSock,fOutQue,fLock);
  fSendThrd.OnError:=SendingError;
  fSendThrd.OnPacketSent:=PacketSent;

  //create our receiving thread
  fRecThrd:=TReceivingThread.Create(fClientSock,fInQue,fLock);
  fRecThrd.OnError:=ReceivingError;
  fRecThrd.OnPacketReceived:=PacketRecvd;


  //get wifi lock for android
{$IFDEF ANDROID}
GetWifiLock;
{$ENDIF}




  //create our discovery thread
  fDiscvThrd:=TDiscoveryThread.Create(fLock);
  fDiscvThrd.OnDiscovery:=DiscvRecvd;
  fDiscvThrd.OnError:=DiscvError;



end;

destructor TClientComms.Destroy;
begin

//release the lock
 {$IFDEF ANDROID}
 ReleaseWifiLock;
 {$ENDIF}


   //disconnect client socket
   if fClientSock.Connected then fClientSock.Disconnect;


    //kill sending thread
   if fSendThrd<>nil then
      begin
         fSendThrd.Free;//bye
      end;

   //kill receiving thrad
   if fRecThrd<>nil then
      begin
       fRecThrd.Free;//bye
      end;

   //kill discovery thread
   if fDiscvThrd<>nil then
     begin
       fDiscvThrd.Free;//bye
     end;


   //the q's
   ClearInQue;//empty
   fInQue.Free;//bye
   ClearOutQue;//empty
   fOutQue.Free;//bye


   fClientSock.Free;//bye

   //lastly the crit..
   fLock.Free;//bye

     inherited;

end;





{$IFDEF ANDROID}
//android so tricky dicky..
//do dis so we can hopefuly receive udp broadcast packets..
//which android block by default..
//seems to be working for me, so she stays..
//should i be freeing this dope??

//get the manager in charge of things..
function TClientComms.GetWiFiManager: JWiFiManager;
var
  Obj: JObject;
begin
  result:=nil;
  if fWifiLockEngaged then exit;//don't want another
  //
  Obj := SharedActivityContext.getSystemService(TJContext.JavaClass.WIFI_SERVICE);
  if  Assigned(Obj) then// i know you are..
  Result := TJWiFiManager.Wrap((Obj as ILocalObject).GetObjectID);//that's what i need..
end;

//get the lock, allows for receiving broadcast packets..
procedure TClientComms.GetWifiLock;
begin
 if fWifiLockEngaged then exit;//nothing to do here
try
fWifiManager :=GetWifiManager;
//could a nil, so check her..
  if Assigned(fWifiManager) then
   begin
   fMultiCastLock :=fWifiManager.createMulticastLock(StringToJString('PissMeOff'));
   fMultiCastLock.acquire;
   fWifiLockEngaged:=true;
  end;
 Except on e:Exception do;//holy shits not work again.. :)
 end;//try
end;

//Release the lock when down..
//could do this when ever udp is active??
procedure TClientComms.ReleaseWifiLock;
begin
try
   //check the manager
  if Assigned(fWifiManager) then
   begin
    //check the lock
   If Assigned(fMultiCastLock) then
       if fMultiCastLock.isHeld then //are we still held..
               fMultiCastLock.Release;//bye

  end;
  Except on e:Exception do;//this will never happen right.. :)
  end;// try
end;


{$ENDIF}





//connects client comms..
procedure TClientComms.Connect;
begin
  if fConnected then exit;// already connected..
  try
    fClientSock.ConnectTimeout:=2000;//2 secs or 2000ms
    //copy our ip and port from discovery
    if fDiscvThrd.ServerIP<>'' then
      begin
      Host:=fDiscvThrd.ServerIP;
      Port:=fDiscvThrd.ServerPort;
      end;

    fClientSock.Host:=Host;
    fClientSock.Port:=Port;
    fClientSock.Connect;
    fConnected:=true;
  finally
   ;
  end;


end;


procedure TClientComms.Disconnect;
begin
  if not fConnected then exit;// already not connected..
  try
    fClientSock.Disconnect;
    fConnected:=false;
  finally
   ;
  end;

end;


procedure TClientComms.Discover;
begin
  if fConnected then exit;//already connected


  if fDiscvThrd.Paused then
      fDiscvThrd.Paused:=false;

end;

procedure TClientComms.DiscvError(Sender:TObject;const aMsg:String);
begin
  if Assigned(fErrorEvent) then
       fErrorEvent(self,aMsg);
end;

procedure TClientComms.SendingError(Sender:TObject;const aMsg:String);
begin
  if Assigned(fErrorEvent) then
       fErrorEvent(self,aMsg);
end;

procedure TClientComms.PacketSent(Sender: TObject);
begin

  DoPacketSent;

end;


procedure TClientComms.ReceivingError(Sender:TObject;const aMsg:String);
begin
  if Assigned(fErrorEvent) then
       fErrorEvent(self,aMsg);
end;

procedure TClientComms.PacketRecvd(Sender: TObject);
begin

  DoPacketRecvd;

end;


procedure TClientComms.DiscvRecvd(sender: TObject);
begin
     DoDiscvRecvd;

end;


procedure TClientComms.DoDiscvRecvd;
begin

     //pause discovery thread
     if not fDiscvThrd.Paused then fDiscvThrd.Paused:=true;
     if not Connected then  Connect;



  if Assigned(fOnDiscvRecvdEvent) then
      fOnDiscvRecvdEvent(nil);
end;


procedure TClientComms.SetStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin

   if Ord(aStatus) = Ord(hsConnected) then
    begin
    SetConnected(true);
     //we are connected, start execute
     //unpause em
     if fRecThrd.Paused then fRecThrd.Paused:=false;
     if fSendThrd.Paused then fSendThrd.Paused:=false;
     if not fRecThrd.Started then fRecThrd.Start;
     if not fSendThrd.Started then fSendThrd.Start;
     //pause discovery thread
     if not fDiscvThrd.Paused then fDiscvThrd.Paused:=true;


    end;
   if Ord(AStatus) = Ord(hsDisconnected) then
   begin
    SetConnected(False);

     if not fRecThrd.Paused then fRecThrd.Paused:=true;
     if not fSendThrd.Paused then fSendThrd.Paused:=true;
     //wake up the discovery thread..
     if AutoReconnect then
     if fDiscvThrd.Paused then fDiscvThrd.Paused:=false;



   end;
   //update our local status
   fClientStatus:=aStatus;
     //update main thread of change..
     DoStatusChange;

end;

procedure TClientComms.DoStatusChange;
begin

   if Assigned(fStatusEvent) then
       FStatusEvent(self,fClientStatus);

end;


procedure TClientComms.SetDropped(aValue: integer);
begin
  fLock.Enter;
  try
     fOutPacketsDropped:=aValue;
  finally
  fLock.Leave;

  end;
end;

function TClientComms.GetDropped:integer;
begin
fLock.Enter;
try
  result:=fOutPacketsDropped+fSendThrd.Dropped;
finally
fLock.Leave;

end;

end;

procedure TClientComms.IncDropped;
begin
  fLock.Enter;
  try
    Inc(fOutPacketsDropped);
  finally
    fLock.Leave;
  end;
end;

function TClientComms.GetDX:integer;
begin
fLock.Enter;
try
  result:=fDiscvThrd.PacketsReceived;
finally
fLock.Leave;

end;

end;
function TClientComms.GetDXbad:integer;
begin
fLock.Enter;
try
  result:=fDiscvThrd.BadPackets;
finally
fLock.Leave;

end;

end;

function TClientComms.GetRX:integer;
begin
fLock.Enter;
try
  result:=fRecThrd.Received;
finally
fLock.Leave;

end;

end;

function TClientComms.GetTX:integer;
begin
fLock.Enter;
try
  result:=fSendThrd.Sent;
finally
fLock.Leave;

end;

end;




function TClientComms.GetRXDropped:integer;
begin
fLock.Enter;
try
  result:=fRecThrd.Dropped;
finally
fLock.Leave;

end;

end;

procedure TClientComms.SetConnected(aValue: Boolean);
begin
 fLock.Enter;
  try
    fConnected:=aValue;
  finally
    fLock.Leave;
  end;

end;


function TClientComms.GetConnected:boolean;
begin
 fLock.Enter;
  try
    Result:=fConnected;
  finally
    fLock.Leave;
  end;


end;


procedure TClientComms.SetServerName(aValue: string);
begin
  //protected with crit
  fDiscvThrd.ServerName:=aValue;
end;

function TClientComms.GetServerName:string;
begin
 //protected with crit
result:=fDiscvThrd.ServerName;

end;


procedure TClientComms.SetHost(aHost: string);
begin
 fLock.Enter;
  try
    fHost:=aHost;
  finally
    fLock.Leave;
  end;
end;



function TClientComms.GetHost:String;
begin
 fLock.Enter;
  try
    result:=fHost
  finally
    fLock.Leave;
  end;

end;


procedure TCLientComms.SetPort(aPort: Integer);
begin
  fLock.Enter;
  try
    fPort:=aPort;
  finally
  fLock.Leave;

  end;
end;

function TClientComms.GetPort:integer;
begin
fLock.Enter;
try
  result:=fPort;
finally
fLock.Leave;

end;

end;

procedure TClientComms.DoErrorMsg;
begin
  if Assigned(fErrorEvent) then
       fErrorEvent(self,fLastErrorMsg);
end;

procedure TClientComms.DoPacketRecvd;
begin
  if Assigned(fOnPacketRecvdEvent) then
       fOnPacketRecvdEvent(self);
end;

procedure TClientComms.DoPacketSent;
begin
  if Assigned(fOutPacketSentEvent) then
       fOutPacketSentEvent(self);
end;


function TClientComms.PopPacket:pDataBuff;
var
aObject:TObject;
begin
   fLock.Enter;
   try
   result:=FInQue.Dequeue;
   finally
   fLock.Leave;
   end;
end;


procedure TClientComms.PushPacket(pData: PDataBuff);
begin
  try
  if not Assigned(pData) then exit;//nothing to do

   fLock.Enter;
   try
     if fOutQue.Count<MAX_QUES then
     fOutQue.Enqueue(pData) else
       begin
        //drop the packet
        try
          SetLength(pData^.DataP,0);
          Dispose(pData);
        finally
         ;
        end;
       end;
   finally
   fLock.Leave;
   end;
  //wake up and send!!
  if fSendThrd.Paused then fSendThrd.Paused:=false;


  finally
    ;
  end;
end;


function TClientComms.GetInCount:integer;
begin

    fLock.Enter;
   try
    Result:=fInQue.Count;
  finally
       fLock.Leave;
  end;
end;


function TClientComms.GetOutCount:integer;
begin

  fLock.Enter;
  try
    Result:=fOutQue.Count;
  finally
   fLock.Leave;
  end;

end;

//clean house
procedure TClientComms.ClearOutQue;
var
i:integer;
aData:pDataBuff;
begin

   fLock.Enter;
  try
     for I := 1 to fOutQue.Count do
       begin
         aData:=fOutQue.Dequeue;

         try
           SetLength(aData.DataP,0);
         finally
          ;
         end;
         try
         if Assigned(aData) then Dispose(aData);
         finally
           ;
         end;
       end;
  finally
       fLock.Leave;
  end;
end;


//clean house
procedure TClientComms.ClearInQue;
var
i:integer;
aData:pDataBuff;
begin

   fLock.Enter;
  try
     for I := 1 to fInQue.Count do
       begin
         aData:=fInQue.Dequeue;

         try
           SetLength(aData.DataP,0);
         finally
          ;
         end;

         try
         if Assigned(aData) then Dispose(aData);
         finally
           ;
         end;
       end;
  finally
       fLock.Leave;
  end;
end;



end.
