unit uIndyPacketServer;

interface

uses
  Classes,SyncObjs,SysUtils,System.Generics.Collections,
  IdGlobal,IdContext,IdBaseComponent,IdComponent,IdCustomTCPServer,IdTCPServer,IdExceptionCore,
  uPacketDefs;

type
  TComms_Event  = procedure (Sender:TObject) of object;
  TComms_Error  = procedure (Sender:TObject;const aMsg:String) of object;
  TComms_Status = procedure (Sender: TObject; const AStatus: TIdStatus) of object;

  type
    tPacketData = record
      DataType:byte;
      Data:tBytes;
    end;



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


  type
     tPacketServer = Class(tObject)
       private
        fCrit:tCriticalSection;
        fServer: TIdTCPServer;
        fIp:string;
        fLastError:string;
        fPort:integer;
        fRecv:integer;
        fSent:integer;
        fBad:integer;
        fCommsError:TComms_Error;

        function  GetConnCount:integer;
        function  GetBad:integer;
        procedure IncBad;
        function  GetSent:integer;
        procedure IncSent;
        function  GetRecv:integer;
        procedure IncRecv;
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
        Destructor Destroy;override;
        procedure  DoError;
        procedure  Start;
        procedure  Stop;
        property OnError:tComms_error read fCommsError write fCommsError;
        property Port:integer read fPort write fPort;
        property IP:string read fIP write fIP;
        property Online:boolean read IsOnline;
        property Connections:integer read GetConnCount;
        property PacketsRecv:integer read GetRecv;
        property PacketsSent:integer read GetSent;
        property PacketsBad:integer read GetBad;

     End;

  var
    PacketSrv:tPacketServer;



implementation


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
       //send outgoing packets
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
   fSent:=0;
   fRecv:=0;
   fBad:=0;
   fServer:=tIdTCPServer.Create(nil);
   fServer.OnConnect:=OnConnect;
   fServer.OnContextCreated:=OnContextCreated;
   fServer.OnDisconnect:=OnDisconnect;
   fServer.OnStatus:=OnStatus;
   fServer.OnException:=OnException;
   fServer.OnExecute:=OnExecute;
end;

Destructor tPacketServer.Destroy;
begin
if fServer.Active then
      fServer.Active:=false;
fCrit.Free;
try
fServer.Free;
finally
Inherited;
end;
end;

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




procedure tPacketServer.OnConnect(AContext: TIdContext);
begin
  AContext.Data:=tPacketContext.Create;
end;

procedure tPacketServer.OnContextCreated(AContext: TIdContext);
begin
//
end;

procedure tPacketServer.OnDisconnect(AContext: TIdContext);
begin
  AContext.Data.Free;
  AContext.Data:=nil;
end;

procedure tPacketServer.OnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
  //
end;

procedure tPacketServer.OnException(AContext: TIdContext; AException: Exception);
begin
  //
  fLastError:=AException.Message;
  TThread.Queue(nil,
        procedure
        begin
          PacketSrv.DoError;
        end);
end;

procedure tPacketServer.DoError;
begin

   if assigned(fCommsError) then fCommsError(nil,fLastError);
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
               end;
         end else
           begin
             //bad buf size
             SetLength(aPacketCxt.fBuff,0);
             SetLength(aBuff,0);
             IncBad;
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
