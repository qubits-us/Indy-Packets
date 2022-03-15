{ Indy Packet Server

 came to life.. 3.12.22 -q


 be it harm none, do as ye wish..


  }
unit uIndyPacketServer;

interface

uses
  Classes,SyncObjs,SysUtils,System.Generics.Collections,
  IdGlobal,IdContext,IdBaseComponent,IdComponent,IdCustomTCPServer,IdTCPServer,IdUdpServer,IdSocketHandle,IdExceptionCore,
  uPacketDefs
  {$IFDEF ANDROID},androidapi.JNI.Net,Androidapi.JNIBridge, Androidapi.Jni,
    androidapi.JNI.JavaTypes,androidapi.JNI.Os,FMX.Helpers.Android,Androidapi.Helpers,
     Androidapi.Jni.GraphicsContentViewText {$ENDIF};

type
  TComms_Event  = procedure (Sender:TObject) of object;
  TComms_Error  = procedure (Sender:TObject;const aMsg:String) of object;
  TComms_Status = procedure (Sender: TObject; const AStatus: String) of object;




//data stored in q's
 type
  tPacketData = record
   DataType:byte;
   Data:tBytes;
 end;






   //sends udp broadcast packets, auto configures clients
   type
      TDiscoveryThread= class(TThread)
        private
            fUdp:TIdUDPServer;
            fLock:TCriticalSection;
            fErrorEvent:TComms_Error;
            fPauseEvent:TEvent;
            fDiscvEvent:TEvent;
            fLastError:String;
            fPaused:boolean;
            fPort:integer;
            fCount:integer;
            fSrvName:String;
            fSrvIP:String;
            fSrvPort:Integer;
            fBurp:boolean;
            fDiscvSent:integer;
            procedure SetDiscvSent(aValue:integer);
            function  GetDiscvSent:integer;
            procedure IncDiscvSent;
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
            procedure OnUDPError(AThread: TIdUDPListenerThread; ABinding: TIdSocketHandle;const AMessage: string; const AExceptionClass: TClass);
            function  CheckPacketIdent(Const AIdent:TIdentArray):boolean;
            function  BytesToStr(const aBytes:Array of byte):string;
            procedure Burp;

         protected
             procedure Execute;override;
             procedure DoErrorMsg;
         public
             Constructor Create(aLock:TCriticalSection);
             destructor  Destroy;override;
             property    OnError:TComms_Error read fErrorEvent write fErrorEvent;
             property    Paused:boolean read GetPause write SetPause;
             property    Port:integer read GetPort write SetPort;
             property    ServerPort:integer read GetServerPort;
             property    ServerIP:string read GetServerIP;
             property    ServerName:String read GetServerName write SetServerName;
             property    DiscvSent:integer read GetDiscvSent;
      end;



  //Packet context object, each connection gets one..
  type
    tPacketContext = Class(tObject)
      private
       fCrit:tCriticalSection;
       fOutQue:tQueue<tPacketData>;
       fBuff:tBytes;
       fHdr:tPacketHdr;
       fSent:integer;
       fDrop:integer;
       fContext:tIdContext;
       function GetDrop:integer;
       procedure IncDrop;
       procedure ZeroSent;
       function  GetSent:integer;
       procedure IncSent;
       function  GetContext:tIdContext;
       function  Pop:tPacketData;
      public
       Constructor Create;
       Destructor  Destroy;override;
       function    GetOutGoing:integer;
       procedure   Process(aContext:tIdContext);
       procedure   Push(aPacket:tPacketData);
       property Context:tIdContext read GetContext;
       property PacketsSent:integer read GetSent;
       property PacketsDrop:integer read GetDrop;
    End;

  // the server object

  type
     tPacketServer = Class(tObject)
       private
        fCrit:tCriticalSection;
        fLogQue:tQueue<string>;
        fErrorQue:tQueue<string>;
        fServer: TIdTCPServer;
        fServerName:String;
        fIp:string;
        fPort:integer;
        fDiscvPort:integer;
        fRecv:integer;
        fSent:integer;
        fBad:integer;
        fDiscoveryEnabled:boolean;
        fCommsError:TComms_event;
        fStatus:tComms_Status;
        fLogEvent:tComms_event;
        fDiscvThrd:TDiscoveryThread;//discovery

    {$IFDEF ANDROID}
        fWifiLockEngaged:boolean;
        fWifiManager:JWifiManager;
        fMultiCastLock:JWifiManager_MulticastLock;
        function GetWiFiManager: JWiFiManager;
        procedure GetWifiLock;
        procedure ReleaseWifiLock;
    {$ENDIF}
        function  GetConnCount:integer;
        function  GetBad:integer;
        procedure IncBad;
        function  GetSent:integer;
        procedure IncSent;
        function  GetRecv:integer;
        procedure IncRecv;
        procedure SetServerName(aValue:string);
        procedure SetDiscovery(aValue:boolean);
        procedure SetDiscoveryPort(aValue:integer);
        procedure Log(aMsg:String);
        procedure LogError(aMsg:String);
        procedure OnConnect(AContext: TIdContext);
        procedure OnContextCreated(AContext: TIdContext);
        procedure OnDisconnect(AContext: TIdContext);
        procedure OnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
        procedure OnException(AContext: TIdContext; AException: Exception);
        procedure OnExecute(AContext: TIdContext);
        function  CheckIdent(aHdr:tPacketHdr):boolean;
        procedure piRecvPacket(aPacket:tPacketContext);
        procedure piRecvNOP(aPacket:tPacketContext);
        function  IsOnline:boolean;



       public
        Constructor Create;
        Destructor  Destroy;override;
        procedure   DoError;
        procedure   DoStatus(aStatus:string);
        procedure   DoLog;
        function    PopLog:string;
        function    PopErrorLog:string;
        procedure   Start;
        procedure   Stop;

        property OnError:tComms_event read fCommsError write fCommsError;
        property OnState:tComms_Status read fStatus write fStatus;
        property OnLog:tComms_event read fLogEvent write fLogEvent;
        property Port:integer read fPort write fPort;
        property DiscvPort:integer read fDiscvPort write SetDiscoveryPort;
        property IP:string read fIP write fIP;
        property Online:boolean read IsOnline;
        property ServerName:String read fServerName write SetServerName;
        property DiscoveryEnabled:boolean read fDiscoveryEnabled write SetDiscovery;
        property Connections:integer read GetConnCount;
        property PacketsRecv:integer read GetRecv;
        property PacketsSent:integer read GetSent;
        property PacketsBad:integer read GetBad;

     End;

   //global server object..
  var
    PacketSrv:tPacketServer;



implementation



{TDiscoveryThread}
constructor TDiscoveryThread.Create(aLock: TCriticalSection);
begin
  fLock:=aLock;
  fPaused:=true;
  fPort:=6001;//port should be one port above what clients listen on..
  fSrvIP:='127.0.0.1';
  fSrvPort:=9000;
  fSrvName:='SRV1';
  fBurp:=false;
  fCount:=0;

  fPauseEvent:=tEvent.Create(nil,true, false,'');
  fDiscvEvent:=tEvent.Create(nil,true,false,'');
  try
  fUdp:=TIDUDPServer.Create(nil);
  fUdp.DefaultPort:=fPort;
  FUdp.BroadcastEnabled:=true;
  fUdp.OnUDPException:=OnUdpError;
  fUdp.ThreadedEvent:=true;
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
aBytes:tBytes;
aBuff:TIdBytes;
begin


  //try to broadcast a discovery packet
   FillPacketIdent(aPacket.PacketIdent);
   //server name
   aBytes:=TEncoding.ANSI.GetBytes(fSrvName);
   if (Length(aBytes)>0) AND (Length(aBytes)<Length(aPAcket.ServerName)) then
   Move(aBytes[0],aPacket.ServerName[0],Length(aBytes)) else
   aPacket.ServerName[0]:=0;
   //server ip
   aBytes:=TEncoding.ANSI.GetBytes(fSrvIP);
   if (Length(aBytes)>0) AND (Length(aBytes)<Length(aPacket.ServerIP)) then
   Move(aBytes[0],aPacket.ServerIP[0],Length(aBytes)) else
   aPacket.ServerIp[0]:=0;
  //server port
   aBytes:=TEncoding.ANSI.GetBytes(IntToStr(fSrvPort));
   if (Length(aBytes)>0) AND (Length(aBytes)<Length(aPacket.ServerPort)) then
   Move(aBytes[0],aPacket.ServerPort[0],Length(aBytes)) else
   aPacket.ServerPort[0]:=0;

  SetLength(aBytes,0);//all done with this..
   //take me struct and stuff it into an indy buff..
   SetLength(aBuff,SizeOf(aPacket));
   Move(aPacket,aBuff[0],SizeOf(aPacket));
 //our broadcast port is 1 less than default..
 try
  fUdp.Broadcast(aBuff,fUdp.DefaultPort-1);
  IncDiscvSent;
  except on e:Exception do
    begin
     fLastError:='Burp Error: '+e.Message;
     Synchronize(DoErrorMsg);
    end;
 end;
  SetLength(aBuff,0);//bye
end;


//how many discv packets recvs
procedure TDiscoveryThread.SetDiscvSent(aValue: Integer);
begin
  fLock.Enter;
  try
    fDiscvSent:=aValue;
  finally
  fLock.Leave;

  end;
end;
// get em
function TDiscoveryThread.GetDiscvSent;
begin
  fLock.Enter;
  try
    result:=fDiscvSent;
  finally
  fLock.Leave;

  end;
end;
// inc em
procedure TDiscoveryThread.IncDiscvSent;
begin
  fLock.Enter;
  try
    Inc(fDiscvSent);
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




//does it match our packet identifier
function TDiscoveryThread.CheckPacketIdent(Const AIdent:TIdentArray):boolean;
var
i:integer;
begin
   Result:=true;
     for I := Low(aIdent) to High(AIdent) do
       if AIdent[i]<>Ident_Packet[i] then result:=false;
end;




//convert from byte array to string, missing me short strings.. :)
function TDiscoveryThread.BytesToStr(const aBytes:Array of byte):string;
begin
    result:='';
    result:=tEncoding.ASCII.GetString(aBytes);
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
       fDiscvEvent.WaitFor(1000);//wait for 1 sec
       inc(fCount);
       if fCount>9 then
         begin
           fCount:=0;
           Burp;
         end;
       if Terminated then exit;
       if not Terminated then fDiscvEvent.ResetEvent;

      finally
       ;
      end;

   end;

end;


procedure TDiscoveryThread.OnUDPError(AThread: TIdUDPListenerThread; ABinding: TIdSocketHandle; const AMessage: string; const AExceptionClass: TClass);
begin
   fLastError:=aMessage;
   Synchronize(DoErrorMsg);
end;




{ Packet Context}




Constructor tPacketContext.Create;
begin
 Inherited;
    SetLength(fBuff,0);
    fSent:=0;
    fCrit:=tCriticalSEction.Create;
    fOutQue:=tQueue<tPacketData>.Create;
end;

Destructor tPacketContext.Destroy;
begin
    SetLength(fBuff,0);
    fOutQue.Free;
    fCrit.Free;
 Inherited;
end;

procedure tPacketContext.Push(aPacket: tPacketData);
begin
   fCrit.Enter;
   try
     if fOutQue.Count<MAX_QUES then
     fOutQue.Enqueue(aPacket) else
       begin
        //drop the packet
        try
          SetLength(aPacket.Data,0);
        finally
         IncDrop;
        end;
       end;
   finally
   fCrit.Leave;
   end;



end;


function tPacketContext.Pop: tPacketData;
begin
   fCrit.Enter;
   try
    if fOutQue.Count>0 then
   result:=FOutQue.Dequeue else
     SetLength(result.Data,0);
   finally
   fCrit.Leave;
   end;

end;

function tPacketContext.GetOutGoing: Integer;
begin
   fCrit.Enter;
   try
   result:=FOutQue.Count
   finally
   fCrit.Leave;
   end;

end;


function tPacketContext.GetDrop: Integer;
begin
     fCrit.Enter;
   try
   result:=fDrop;
   finally
   fCrit.Leave;
   end;

end;

procedure tPacketContext.IncDrop;
begin
     fCrit.Enter;
   try
   Inc(fDrop);
   finally
   fCrit.Leave;
   end;

end;

procedure tPacketContext.ZeroSent;
begin
   fCrit.Enter;
   try
   fSent:=0;
   finally
   fCrit.Leave;
   end;

end;


function tPacketContext.GetSent: Integer;
begin
   fCrit.Enter;
   try
   result:=fSent;
   finally
   fCrit.Leave;
   end;

end;

procedure tPacketContext.IncSent;
begin
   fCrit.Enter;
   try
   Inc(fSent);
   finally
   fCrit.Leave;
   end;

end;



function tPacketContext.GetContext: TIdContext;
begin
  result:=fContext;
end;


procedure tPacketContext.Process(aContext: TIdContext);
var
i,s:integer;
aPack:tPacketData;
aBuff:tIdBytes;
begin
 fContext:=aContext;

   i:=GetOutGoing;
   if i>0 then
     begin
       //send a que'd outgoing packet
       aPack:=Pop;
       s:=Length(aPack.Data);
       if s>0 then
        begin
         //got something to send
         SetLength(aBuff,s);
         Move(aPack.Data[0],aBuff[0],s);
         aContext.Connection.IOHandler.Write(aBuff);
         IncSent;
         SetLength(aBuff,0);
         SetLength(aPack.Data,0);
        end;
     end;

end;



{
 Indy Packet Server

}


Constructor tPacketServer.Create;
begin
  Inherited;
   fCrit:=tCriticalSection.Create;
   fLogQue:=tQueue<string>.Create;
   fErrorQue:=tQueue<string>.Create;
   fSent:=0;
   fRecv:=0;
   fBad:=0;
   fIp:='127.0.0.1';
   fServer:=tIdTCPServer.Create(nil);
   fServer.OnConnect:=OnConnect;
   fServer.OnContextCreated:=OnContextCreated;
   fServer.OnDisconnect:=OnDisconnect;
   fServer.OnStatus:=OnStatus;
   fServer.OnException:=OnException;
   fServer.OnExecute:=OnExecute;

  //create our discovery thread
  fDiscvThrd:=TDiscoveryThread.Create(fCrit);


  {$IFDEF ANDROID}
  fWifiLockEngaged:=false;
  GetWifiLock;
  {$ENDIF}
end;

Destructor tPacketServer.Destroy;
begin
if fServer.Active then
      fServer.Active:=false;

   //kill discovery thread
   if fDiscvThrd<>nil then
     begin
       fDiscvThrd.Free;//bye
     end;

fLogQue.Free;
fErrorQue.Free;
fCrit.Free;

//release the lock
 {$IFDEF ANDROID}
 ReleaseWifiLock;
 {$ENDIF}

 try
  fServer.Free;
   finally
    Inherited;
 end;
end;




{$IFDEF ANDROID}
//get the manager in charge of things..
function tPacketServer.GetWiFiManager: JWiFiManager;
var
  Obj: JObject;
begin
  result:=nil;
  if fWifiLockEngaged then exit;//don't want another
  //
  Obj := SharedActivityContext.getSystemService(TJContext.JavaClass.WIFI_SERVICE);
  if  Assigned(Obj) then
  Result := TJWiFiManager.Wrap((Obj as ILocalObject).GetObjectID);
end;

//get the lock, allows for receiving broadcast packets..
procedure tPacketServer.GetWifiLock;
var
  info: JWiFiInfo;
  ip: string;
  lw:longword;
begin
 if fWifiLockEngaged then exit;//nothing to do here
try
fWifiManager :=GetWifiManager;
//could be a nil, so check..
  if Assigned(fWifiManager) then
   begin
   fMultiCastLock :=fWifiManager.createMulticastLock(StringToJString('IndysAwesome'));
   fMultiCastLock.acquire;
   fWifiLockEngaged:=true;
    info := fWifiManager.getConnectionInfo;
    lw:=info.getIpAddress;
    lw:=SwapBytes(lw);//swap the byte order, backwards on robots..
    ip := MakeUInt32IntoIPv4Address(lw);
    fIp:=ip;//save it
    fDiscvThrd.ServerIP:=fip;//set for our udp discv
  end;
 Except on e:Exception do;
 end;//try
end;

//Release the lock when down..
procedure tPacketServer.ReleaseWifiLock;
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






function tPacketServer.IsOnline: Boolean;
begin
  result:=fServer.Active;
end;

function tPacketServer.GetConnCount: Integer;
begin
   result:=fServer.Contexts.Count;
end;

function tPacketServer.GetBad: Integer;
begin
  fCrit.Enter;
   try
   result:=fBad;
   finally
   fCrit.Leave;
   end;

end;

procedure tPacketServer.IncBad;
begin
  fCrit.Enter;
   try
   Inc(fBad);
   finally
   fCrit.Leave;
   end;

end;


function tPacketServer.GetSent: Integer;
begin
   fCrit.Enter;
   try
   result:=fSent;
   finally
   fCrit.Leave;
   end;

end;

procedure tPacketServer.IncSent;
begin
   fCrit.Enter;
   try
   Inc(fSent);
   finally
   fCrit.Leave;
   end;

end;

function tPacketServer.GetRecv: Integer;
begin
   fCrit.Enter;
   try
   result:=fRecv;
   finally
   fCrit.Leave;
   end;

end;

procedure tPacketServer.IncRecv;
begin
   fCrit.Enter;
   try
   Inc(fRecv);
   finally
   fCrit.Leave;
   end;

end;

procedure tPacketServer.SetServerName(aValue: string);
begin
  fServerName:=aValue;
  fDiscvThrd.ServerName:=fServerName;
end;

//start and stop the discovery thread..
procedure tPacketServer.SetDiscovery(aValue: Boolean);
begin
  if aValue then fDiscvThrd.Paused:=false else
      fDiscvThrd.Paused:=true;
end;

//this will be the port we send out on..
//adding one to it, as we bind one port above..
//this allows running client and server on same cpu..
//server only transmits..
procedure tPacketServer.SetDiscoveryPort(aValue: Integer);
begin
    if aValue<>fDiscvPort then
      begin
      fDiscvPort:=aValue;
      fDiscvThrd.Port:=aValue+1;
      end;
end;


procedure tPacketServer.Log(aMsg:String);
begin

//que up log message
fCrit.Enter;
try
fLogQue.Enqueue(aMsg);
finally
fCrit.Leave;
end;

 //trigger event
  TThread.Queue(nil,
        procedure
        begin
         if Assigned(PacketSrv) then
          PacketSrv.DoLog;
        end);

end;

procedure tPacketServer.LogError(aMsg:String);
begin

//que up log message
fCrit.Enter;
try
fErrorQue.Enqueue(aMsg);
finally
fCrit.Leave;
end;

 //trigger event
  TThread.Queue(nil,
        procedure
        begin
         if Assigned(PacketSrv) then
          PacketSrv.DoError;
        end);

end;



procedure tPacketServer.OnConnect(AContext: TIdContext);
begin
  AContext.Data:=tPacketContext.Create;
  Log('New connection from ip:'+AContext.Binding.PeerIP);
end;

procedure tPacketServer.OnContextCreated(AContext: TIdContext);
begin
//
end;

procedure tPacketServer.OnDisconnect(AContext: TIdContext);
begin
  AContext.Data.Free;
  AContext.Data:=nil;
  Log('Disconnect ip:'+aContext.Binding.PeerIP);
end;

procedure tPacketServer.OnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
//
 DoStatus(aStatusText);
end;

procedure tPacketServer.OnException(AContext: TIdContext; AException: Exception);
begin
  //

  LogError(aException.Message);

end;

procedure tPacketServer.DoError;
begin

   if assigned(fCommsError) then fCommsError(nil);
end;

procedure tPacketServer.DoStatus(aStatus:string);
begin
  if assigned(fStatus) then fStatus(nil,aStatus);
end;

procedure tPacketServer.DoLog;
begin
  if assigned(fLogEvent) then fLogEvent(nil);
end;

function tPacketServer.PopLog: string;
begin
  fCrit.Enter;
  try
   result:='';
   if fLogQue.Count>0 then
     result:=fLogQue.Dequeue;
  finally
   fCrit.Leave;
  end;
end;

function tPacketServer.PopErrorLog: string;
begin
  fCrit.Enter;
  try
   result:='';
   if fErrorQue.Count>0 then
     result:=fErrorQue.Dequeue;
  finally
   fCrit.Leave;
  end;
end;

procedure tPacketServer.OnExecute(AContext: TIdContext);
var
i:integer;
aHdr:tPacketHdr;
aBuff:tIdBytes;
aGoodRead:Boolean;
aPacketCxt:tPacketContext;
begin
 aPacketCxt:=nil;
  //get out packet object, stored in Data
  if Assigned(aContext.Data) then
    aPacketCxt:=TPacketContext(aContext.Data);
if Assigned(aPacketCxt) then
  begin
   //sends an outgoing packet
   aPacketCxt.Process(aContext);
   // context sent an outgoing count it and zero it..
   if aPacketCxt.PacketsSent>0 then
     begin
       IncSent;
       aPacketCxt.ZeroSent;
     end;


    //try to read in a packet header..
   SetLength(aBuff,SizeOf(tPacketHdr));
   aGoodRead:=False;
   aContext.Connection.IOHandler.CheckForDisconnect(true,true);
   i:=aContext.Connection.IOHandler.InputBuffer.Size;

   if i>=SizeOf(tPacketHdr) then
     begin
        try
         aContext.Connection.IOHandler.ReadBytes(aBuff,SizeOf(TPacketHdr),False);
         aGoodRead:=true;
        except on e:EidReadTimeOut do
          begin
          //swallow
          aGoodRead:=false;
          end;
        end;
     end;

   if aGoodRead then
       begin
        if Length(aBuff)=SizeOf(tPacketHdr) then
         begin
           Move(aBuff[0],aHdr,SizeOf(tPacketHdr));
           if CheckIdent(aHdr) then
             begin
               IncRecv;
               //store header in context
               Move(aHdr,aPacketCxt.fHdr,SizeOf(tPacketHdr));
              if aHdr.DataSize>0 then
                begin
                  //need to get more data
                  SetLength(aBuff,aHdr.DataSize);
                  aContext.Connection.IOHandler.ReadBytes(aBuff,aHdr.DataSize,False);
                  if Length(aBuff)=aHdr.DataSize then
                   begin
                   //store extra data in fbuff -context
                    SetLength(aPacketCxt.fBuff,aHdr.DataSize);
                    Move(aBuff[0],aPacketCxt.fBuff[0],aHdr.DataSize);
                    piRecvPacket(aPacketCxt);
                    SetLength(aBuff,0);
                   end else
                     begin
                       //bad size
                       IncBad;
                       SetLength(aPacketCxt.fBuff,0);
                       SetLength(aBuff,0);
                       Log('Bad Data Buffer Size '+aContext.Binding.PeerIP);
                     end;
                end
                  else
                    begin
                      //just a header..
                      SetLength(aPacketCxt.fBuff,0);
                      SetLength(aBuff,0);
                      piRecvPacket(aPacketCxt);
                    end;
             end else
               begin
                 //bad ident
                 SetLength(aPacketCxt.fBuff,0);
                 SetLength(aBuff,0);
                 IncBad;
                 Log('Bad Ident Recvd '+aContext.Binding.PeerIP);
               end;
         end else
           begin
             //bad buf size
             SetLength(aPacketCxt.fBuff,0);
             SetLength(aBuff,0);
             IncBad;
             Log('Bad Header Buffer Size '+aContext.Binding.PeerIP);
           end;
       end;


  end;



end;

function tPacketServer.CheckIdent(aHdr: tPacketHdr): Boolean;
var
i:integer;
begin
  Result:=true;
   for I := Low(aHdr.Ident) to High(aHdr.Ident) do
   if aHdr.Ident[i]<> Ident_Packet[i] then result:=false;
end;

procedure tPacketServer.piRecvPacket(aPacket: tPacketContext);
begin
  //process incoming packets, do a case on the incoming commands
  Log('Processing Packet Command:'+IntToStr(aPacket.fHdr.Command)+' from ip:'+aPacket.Context.Binding.PeerIP);

  case aPacket.fHdr.Command of
  CMD_NOP:piRecvNOP(aPacket);
  end;

end;


procedure tPacketServer.piRecvNOP(aPacket: tPacketContext);
var
aBuff:tIdBytes;
begin
     //server just sends a nop back
     SetLength(aBuff,SizeOf(tPacketHdr));
     Move(aPacket.fHdr,aBuff[0],SizeOf(tPacketHdr));
     aPacket.Context.Connection.IOHandler.Write(aBuff);
     SetLength(aBuff,0);
     IncSent;
end;


procedure tPacketServer.Start;
begin
  //
  fServer.Active:=false;
  fServer.Bindings.Clear;
  fServer.DefaultPort:=fPort;
  fServer.Bindings.Add.IPVersion := Id_IPv4;
  fServer.Active:=true;

end;

procedure tPacketServer.Stop;
begin
  //
  fServer.Active:=false;

end;



end.
