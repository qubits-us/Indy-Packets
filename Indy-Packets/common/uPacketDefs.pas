unit uPacketDefs;

interface


const
//Packet Ident - change the values for your prog
Ident_Packet :array[0..15] of byte =(0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7);
//max items in the q before we start dropping
MAX_QUES=101;

CMD_NOP=0;
CMD_JPG=1;


//type used in helper function
type
 TIdentArray = array[0..15] of byte;

//packet header, preceeds all packets..
type
 pPacketHdr=^tPacketHdr;
 tPacketHdr= packed record
  Ident:TIdentArray;//16 bytes
  Command:byte;//1 byte -255 commands
  DataSize:integer;//4 bytes -addional data size after header and not including header..
end;


    //udp discovery packets broadcast from server..
  type
     pDiscoveryPacket=^tDiscoveryPacket;
     tDiscoveryPacket =packed record
       PacketIdent:TIdentArray;
       ServerName :array[0..25] of byte;
       ServerIp   :array[0..13] of byte;
       ServerPort :array[0..13] of byte;
     end;


function CheckPacketIdent(Const AIdent:TIdentArray):boolean;
procedure FillPacketIdent(var aIdent:tIdentArray);
function SwapBytes(Value: LongWord): LongWord;



implementation


//does it match our packet identifier
function CheckPacketIdent(Const AIdent:TIdentArray):boolean;
var
i:integer;
begin
   Result:=true;
     for I := Low(aIdent) to High(AIdent) do
       if AIdent[i]<>Ident_Packet[i] then result:=false;
end;
//fill our identifier
procedure FillPacketIdent(var aIdent:TIdentArray);
var
i:integer;
begin
     for I := Low(AIdent) to High(AIdent) do
        AIdent[i]:=Ident_Packet[i];

end;


function SwapBytes(Value: LongWord): LongWord;
type
  Bytes = packed array[0..3] of Byte;

begin
  Bytes(Result)[0]:= Bytes(Value)[3];
  Bytes(Result)[1]:= Bytes(Value)[2];
  Bytes(Result)[2]:= Bytes(Value)[1];
  Bytes(Result)[3]:= Bytes(Value)[0];
end;



end.
