{Main Scene for Indy Packet Client Test-
 Based off of the borg scene..

 created 2.4.2022 -q
 www.qubits.us

 be it harm none, do as ye wishes..


}
unit uSceneMain;

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.UIConsts,
  FMX.Types, FMX.Controls, FMX.Forms3D, FMX.Types3D, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, System.Math.Vectors, FMX.Ani, FMX.Controls3D,FMX.Surfaces,
  FMX.MaterialSources, FMX.Objects3D, FMX.Effects, FMX.Filter.Effects,FMX.Layers3D,
  FMX.Objects,uDlg3dCtrls,uNumPadDlg,uIPChangeDlg,uClientCommsObj;


  type
    TDlgMainScene= class(TDummy)
      private
       fConnected:boolean;
       fDlgUp:boolean;
       fIm:TImage3d;
       fTxt:TText3d;
       fPort:String;
       fIp:String;
       fCmd:Byte;
       fBtnIp:TDlgInputButton;
       fBtnPort:tDlgInputButton;
       fBtnCmd:TDlgInputButton;
       fBtnConnect:TDlgButton;
       fBtnDisconnect:tDlgButton;
       fBtnSend:tDlgButton;
       fBtnClose:tDlgButton;
       fBtnDuration:TDlgInputButton;
       fDuration:integer;
       fBtnSpin:TDlgInputButton;
       fBorg:TCube;
       fWebTxt:TText3d;
       fDownx:single;
       bDownx:single;
       fCloseOnce:boolean;
       fBorgSpin:TFLoatAnimation;
       fCloseEvent:TDlgDoneClick_Event;
       fCleanedUp:boolean;
       fNumPad:TDlgNumPad;
       fIPNumPad:TDlgIPNumPad;
      protected
       procedure OnConnect(sender:tObject);
       procedure OnDisconnect(sender:tObject);
       procedure Connect(sender:tObject);
       procedure Disconnect(sender:tObject);
       procedure Send(sender:tObject);
       procedure SendNOP;
       procedure SendJPG;
       procedure GetIp(sender:tObject);
       procedure GetIpDone(sender:tObject);
       procedure GetIpCancel(sender:tObject);
       procedure GetPort(sender:tObject);
       procedure GetPortDone(sender:tObject;Selected:integer);
       procedure GetPortCancel(sender:tObject);
       procedure TogCMD(sender:tObject);
       procedure TogSpin(sender:tObject);
       procedure DoClose(sender:tObject);
       procedure ChangeIm(sender:tObject; aBitmap:TBitmap);
       procedure DurationDone(sender:tobject;Selected:integer);
       procedure DurationClick(sender:tObject);
       procedure BorgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single; RayPos,
                               RayDir: TVector3D);
       procedure BorgMouseup(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single; RayPos,
                               RayDir: TVector3D);


      public
       Constructor Create(Sender: TComponent;aWidth,aHeight,aX,aY:single);Reintroduce;
       Destructor Destroy;override;
       procedure  CleanUp;
       property  OnClose:TDlgDoneClick_Event read fCloseEvent write fCloseEvent;
       property CleanedUp:boolean read fCleanedUp;
    end;



implementation

uses dmMaterials,uPacketClientDm,uPacketDefs;



Constructor TDlgMainScene.Create(Sender: TComponent;aWidth,aHeight,aX,aY:single);
var
aGap:Single;
aBtnWidth,aBtnHeight:single;
newx,newy:single;

begin
  //create
  Inherited Create(nil);
  fCleanedUp:=false;
  fDlgUp:=False;
  fConnected:=False;
  fNumPad:=nil;
  fIPNumPad:=nil;
  fDuration:=50;
  //set our cam first always!!!
  Projection:=TProjection.Screen;
  Parent:=TForm3d(sender);
  HitTest:=True;
  Width:=aWidth;
  Height:=aHeight;
  Position.X:=aX;
  Position.Y:=aY;
  OnClick:=DoClose;
  aGap:=2;
  fCloseOnce:=false;
  fIp:='192.168.0.51';//that's my ip, fill in your own..
  fPort:='9000';

  //space.. make it deep...
  //when you make it deep
  //increase im's w h in porportion
  fIm:=TImage3d.Create(nil);
  fIm.Projection:=tProjection.Screen;
  fIm.Bitmap:=MaterialsDm.tmStarsImg.Texture;
  fIm.Position.Z:=1500;
  fIm.Width:=aWidth+1500;
  if GoFullScreen then
  fIm.Height:=aHeight+1700 else
  fIm.Height:=aHeight+1500;
  fIm.Position.X:=aX;
  fIm.Position.Y:=aY;

  fIm.Parent:=self;

  //6 btns wide by 6 tall
  aBtnWidth:=(Width/6)-aGap;
  aBtnHeight:=(Height/6)-aGap;

  newy:=((Height/2)*-1)+(aBtnHeight/2);//top
  newx:=((Width/2)*-1)+(aBtnWidth*2)+aGap;//left


      fBtnIP:=tDlgInputButton.Create(self,aBtnWidth*4,aBtnHeight,newx,newy);
      fBtnIP.Projection:=TProjection.Screen;
      fBtnIP.Parent:=self;
      fBtnIP.MaterialSource:=dlgMaterial.LongRects;
      fBtnIP.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnIP.LabelColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnIP.FontSize:=dlgMaterial.FontSize;
      fBtnIP.LabelSize:=dlgMaterial.FontSize/1.5;
      fBtnIP.BtnBitMap.Assign(dlgMaterial.LongRects.Texture);
      fBtnIP.Text:=fIp;
      fBtnIP.LabelText:='Server Ip';
      fBtnIP.OnClick:=GetIp;

     newx:=newx+(aBtnWidth*2)+(aBtnWidth/2)+aGap;

      fBtnPort:=tDlgInputButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnPort.Projection:=TProjection.Screen;
      fBtnPort.Parent:=self;
      fBtnPort.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnPort.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnPort.LabelColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnPort.FontSize:=dlgMaterial.FontSize;
      fBtnPort.LabelSize:=dlgMaterial.FontSize/1.5;
      fBtnPort.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnPort.Text:=fPort;
      fBtnPort.LabelText:='Server Port';
      fBtnPort.OnClick:=GetPort;

      newx:=newx+(aBtnWidth)+aGap;

      fBtnCmd:=tDlgInputButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnCmd.Projection:=TProjection.Screen;
      fBtnCmd.Parent:=self;
      fBtnCmd.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnCmd.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnCmd.LabelColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnCmd.FontSize:=dlgMaterial.FontSize;
      fBtnCmd.LabelSize:=dlgMaterial.FontSize/1.5;
      fBtnCmd.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnCmd.Text:='NOP';
      fBtnCmd.LabelText:='Command Byte';
      fBtnCmd.OnClick:=TogCmd;

      //now we go down..
      newy:=newy+aBtnHeight+aGap;

      fBtnConnect:=tDlgButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnConnect.Projection:=TProjection.Screen;
      fBtnConnect.Parent:=self;
      fBtnConnect.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnConnect.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnConnect.FontSize:=dlgMaterial.FontSize;
      fBtnConnect.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnConnect.Text:='Connect';
      fBtnConnect.OnClick:=Connect;

      newy:=newy+aBtnHeight+aGap;

      fBtnDisConnect:=tDlgButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnDisConnect.Projection:=TProjection.Screen;
      fBtnDisConnect.Parent:=self;
      fBtnDisConnect.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnDisConnect.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnDisConnect.FontSize:=dlgMaterial.FontSize;
      fBtnDisConnect.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnDisConnect.Text:='Disconnect';
      fBtnDisConnect.OnClick:=Disconnect;

      newy:=newy+aBtnHeight+aGap;

      fBtnSend:=tDlgButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnSend.Projection:=TProjection.Screen;
      fBtnSend.Parent:=self;
      fBtnSend.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnSend.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnSend.FontSize:=dlgMaterial.FontSize;
      fBtnSend.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnSend.Text:='Send';
      fBtnSend.OnClick:=Send;


      newy:=((Height/2))-(aBtnHeight/2)-(Height/55)-(aGap*2);//bottom
      newx:=((Width/2)*-1)+(aBtnWidth/2)+aGap;//left


      fBtnDuration:=tDlgInputButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnDuration.Projection:=TProjection.Screen;
      fBtnDuration.Parent:=self;
      fBtnDuration.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnDuration.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnDuration.LabelColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnDuration.FontSize:=dlgMaterial.FontSize;
      fBtnDuration.LabelSize:=dlgMaterial.FontSize/1.5;
      fBtnDuration.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnDuration.Text:='50';
      fBtnDuration.LabelText:='Spin Duration';
      fBtnDuration.OnClick:=DurationClick;


      newx:=newx+aBtnWidth+aGap;

      fBtnSpin:=tDlgInputButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnSpin.Projection:=TProjection.Screen;
      fBtnSpin.Parent:=self;
      fBtnSpin.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnSpin.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnSpin.LabelColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnSpin.FontSize:=dlgMaterial.FontSize;
      fBtnSpin.LabelSize:=dlgMaterial.FontSize/1.5;
      fBtnSpin.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnSpin.Text:='No';
      fBtnSpin.LabelText:='Spin';
      fBtnSpin.OnClick:=TogSpin;

      newx:=(Width/2)-(aBtnWidth/2)-aGap;//Right

      fBtnClose:=tDlgButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnClose.Projection:=TProjection.Screen;
      fBtnClose.Parent:=self;
      fBtnClose.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnClose.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnClose.FontSize:=dlgMaterial.FontSize;
      fBtnClose.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);
      fBtnClose.Text:='Close';
      fBtnClose.OnClick:=DoClose;









  fBorg:=TCube.Create(self);
  fBorg.Projection:=tProjection.Screen;
  fBorg.Parent:=self;
  fBorg.Depth:=Height-(Height/2);
  fBorg.Width:=Height-(Height/2);
  fBorg.Height:=Height-(Height/2);
  fBorg.Position.X:=0;
  fBorg.Position.Y:=0;
  fBorg.Position.Z:=500;
  fBorg.MaterialSource:=MaterialsDm.tmBorgImg;
  fBorg.OnClick:=nil;
  fBorg.OnMouseDown:=BorgMouseDown;//save the x
  fBorg.OnMouseUp:=BorgMouseUp;//spin the borg
  fBorg.Visible:=true;



  fTxt:=TText3d.Create(nil);
  fTxt.Projection:=tProjection.Screen;
  fTxt.Parent:=self;
  fTxt.Depth:=2;
  fTxt.Stretch:=true;
  fTxt.WordWrap:=false;
  fTxt.Width:=Width/8;
  fTxt.Height:=Height/55;
  fTxt.Position.X:=((Width/2)*-1)+(fTxt.Width/2)+(aGap);
  fTxt.Position.Y:=((Height/2))-(fTxt.Height);
  fTxt.Position.Z:=-1;
  fTxt.Text:='Indy Packet Client Test..';
  fTxt.MaterialSource:=DlgMaterial.TextColor;
  fTxt.MaterialBackSource:=DlgMaterial.TextColor;
  fTxt.MaterialShaftSource:=DlgMaterial.TextColor;
  fTxt.OnClick:=DoClose;
  fTxt.Visible:=true;

  fWebTxt:=TText3d.Create(nil);
  fWebTxt.Projection:=tProjection.Screen;
  fWebTxt.Parent:=self;
  fWebTxt.Depth:=2;
  fWebTxt.Stretch:=true;
  fWebTxt.Width:=Width/10;
  fWebTxt.Height:=Height/55;
  fWebTxt.WordWrap:=false;
  fWebTxt.Position.X:=((Width/2)-(fWebTxt.Width/2))-aGap;
  fWebTxt.Position.Y:=((Height/2))-(fWebTxt.Height);
  fWebTxt.Position.Z:=-1;
  fWebTxt.Text:='www.qubits.us';
  fWebTxt.MaterialSource:=DlgMaterial.TextColor;
  fWebTxt.MaterialBackSource:=DlgMaterial.TextColor;
  fWebTxt.MaterialShaftSource:=DlgMaterial.TextColor;
  fWebTxt.OnClick:=DoClose;
  fWebTxt.Visible:=true;







  fBorgSpin:=TFloatAnimation.Create(nil);
  fBorgSpin.Duration:=50;
  fBorgSpin.StartValue:=0;
  fBorgSpin.StopValue:=360;
  fBorgSpin.Loop:=true;
  fBorgSpin.Parent:=fBorg;
  fBorgSpin.PropertyName:='RotationAngle.Y';
  fBorgSpin.Enabled:=False;

  PacketClientDm.OnConnect:=OnConnect;
  PacketClientDm.OnDisconnect:=OnDisconnect;
  PacketClientDm.OnRecvImage:=ChangeIm;



end;

Destructor TDlgMainScene.Destroy;
begin

  if not fCleanedUp then CleanUp;


  Inherited;
end;

procedure TDlgMainScene.CleanUp;
var
i:integer;
begin
  //destroy
  if fCleanedUp then exit;

  fCleanedUp:=true;

  if Assigned(fNumPad) then
    begin
      fNumPad.CleanUp;
      fNumPad.Free;
      fNumPad:=nil;
    end;

  if Assigned(fIPNumPad) then
    begin
      fIPNumPad.CleanUp;
      fIPNumPad.Free;
      fIPNumPad:=nil;
    end;



  fBorgSpin.Stop;
  fBorgSpin.Parent:=nil;
  fBorgSpin.free;
  fBorgSpin:=nil;


  fBtnIp.CleanUp;
  fBtnIp.Free;
  fBtnIp:=nil;

  fBtnPort.CleanUp;
  fBtnPort.Free;
  fBtnPort:=nil;

  fBtnCmd.CleanUp;
  fBtnCmd.Free;
  fBtnCmd:=nil;

  fBtnConnect.CleanUp;
  fBtnConnect.Free;
  fBtnConnect:=nil;

  fBtnDisconnect.CleanUp;
  fBtnDisconnect.Free;
  fBtnDisconnect:=nil;

  fBtnSend.CleanUp;
  fBtnSend.Free;
  fBtnSend:=nil;

  fBtnClose.CleanUp;
  fBtnClose.Free;
  fBtnClose:=nil;

  fBtnDuration.CleanUp;
  fBtnDuration.Free;
  fBtnDuration:=nil;

  fBtnSpin.CleanUp;
  fBtnSpin.Free;
  fBtnSpin:=nil;

  fIm.Parent:=nil;
  fIm.OnClick:=nil;
  fIm.Bitmap:=nil;

  fIm.Free;
  fIm:=nil;


  fBorg.MaterialSource:=nil;
  fBorg.OnClick:=nil;
  fBorg.Parent:=nil;
  fBorg.Free;
  fBorg:=nil;


  fWebTxt.Text:='';
  fWebTxt.MaterialBackSource:=nil;
  fWebTxt.MaterialShaftSource:=nil;
  fWebTxt.MaterialSource:=nil;
  fWebTxt.Parent:=nil;
  fWebTxt.OnClick:=nil;
  fWebTxt.Free;
  fWebTxt:=nil;

  fTxt.Text:='';
  fTxt.MaterialBackSource:=nil;
  fTxt.MaterialShaftSource:=nil;
  fTxt.MaterialSource:=nil;
  fTxt.Parent:=nil;
  fTxt.OnClick:=nil;
  fTxt.Free;
  fTxt:=nil;

  fCloseEvent:=nil;
  Parent:=nil;

end;

procedure TDlgMainScene.GetIp(sender: TObject);
begin
  if  fDlgUp then exit;

         if not assigned(fIPNumPad) then
        begin
          //creae a Ip Numpad here
          fIPNumPad:=tDlgIPNumPad.Create(self,DlgMaterial,height-50,height-50,0,0);
        end;
          fIPNumPad.IP:=fIp;
          fIPNumPad.OnDone:=GetIPDone;
          fIpNumPad.OnCancel:=GetIpCancel;
          fIPNumPad.Parent:=self;
          fIPNumPad.Position.Z:=-2;
          fIPNumPad.Visible:=true;
          fIpNumPad.BackIm.Visible:=true;
          fDlgUp:=True;

end;
procedure TDlgMainScene.GetIpDone(sender: TObject);
begin
  //
    if assigned(fIPNumPad) then
    begin
      fIp:=fIpNumPad.IP;
      fBtnIp.Text:=fIP;
      fIPNumPad.Visible:=false;
      fIpNumPad.BackIm.Visible:=false;
      Repaint;
    end;
    fDlgUp:=False;

end;
procedure TDlgMainScene.GetIpCancel(sender: TObject);
begin
  //
    if assigned(fIPNumPad) then
    begin
    fIPNumPad.Visible:=false;
    fIpNumPad.BackIm.Visible:=false;
    Repaint;
    end;
    fDlgUp:=False;

end;

procedure TDlgMainScene.GetPort(sender: TObject);
begin
  //
    if  fDlgUp then exit;
     if not assigned(fNumPad) then
        begin
          //creae a number pad
          fNumPad:=tDlgNumPad.Create(self,DlgMaterial,height-50,height-50,0,0);
        end;
          fNumPad.Number:=StrToInt(fPort);
          fNumPad.OnDone:=GetPortDone;
          fNumPad.Parent:=self;
          fNumPad.Position.Z:=-2;
          fNumPad.Opacity:=0.85;
          fNumPad.Visible:=true;
          fDlgUp:=true;

end;
procedure TDlgMainScene.GetPortDone(sender: TObject;Selected:integer);
begin
  //
     fPort:=IntToStr(fNumPad.Number);
     fBtnPort.Text:=fPort;
     fNumPad.Visible:=false;
     fDlgUp:=False;
end;
procedure TDlgMainScene.GetPortCancel(sender: TObject);
begin
  //
   fNumPad.Visible:=false;
     fDlgUp:=False;
end;

procedure TDlgMainScene.TogCMD(sender: TObject);
begin
  if  fDlgUp then exit;

  if fCmd<1 then Inc(fCmd) else fCmd:=0;

     case fCmd of
     0:fBtnCmd.Text:='NOP';
     1:fBtnCmd.Text:='JPG';
     end;

end;

procedure TDlgMainScene.TogSpin(sender: TObject);
begin
  if  fDlgUp then exit;

  if fBorgSpin.Enabled then
    begin
     fBorgSpin.Enabled:=false;
     fBtnSpin.Text:='No';
    end else
       begin
       fBorgSpin.Enabled:=true;
       fBtnSpin.Text:='Yes';
       end;
end;


procedure TDlgMainScene.DurationClick(sender: TObject);
begin
  //open up a numpad..
  if  fDlgUp then exit;
     if not assigned(fNumPad) then
        begin
          //create a num pad here
          fNumPad:=tDlgNumPad.Create(self,DlgMaterial,height-50,height-50,0,0);
        end;
          fNumPad.Number:=fDuration;
          fNumPad.OnDone:=DurationDone;
          fNumPad.Parent:=self;

          fNumPad.Position.Z:=-2;
          fNumPad.Opacity:=0.85;
          fNumPad.Visible:=true;
          fDlgUp:=true;

end;

procedure TDlgMainScene.DurationDone(sender: TObject;Selected:integer);
var
aNum:integer;
begin

   aNum:=fNumPad.Number;
   fNumPad.Visible:=false;

       if aNum<10 then aNum:=10;
       if aNum>200 then aNum:=200;

       if fDuration<>aNum then
          begin
            fDuration:=aNum;
            fBtnDuration.Text:=IntToStr(fDuration);
            if fBorgSpin.Enabled then
                     fBorgSpin.Stop;
            fBorgSpin.Duration:=aNum;
             if fBorgSpin.Enabled then
                     fBorgSpin.Start;
          end;

      fDlgUp:=False;

end;

procedure TDlgMainScene.DoClose(sender: TObject);
begin
if fCloseOnce then exit;//only one time please
  fCloseOnce:=true;

  if Assigned(fCloseEvent) then
      fCloseEvent(nil);
end;

procedure TDlgMainScene.ChangeIm(sender: TObject; aBitmap: TBitmap);
begin
    //have to kill it and start over.. only on android/ windows works with a fborg.repaint;
   MaterialsDm.tmTempImg.Texture.Assign(aBitmap);
  fBorgSpin.Stop;
  fBorgSpin.Parent:=nil;
  //kill the borg..
  fBorg.MaterialSource:=nil;
  fBorg.OnClick:=nil;
  fBorg.Parent:=nil;
  fBorg.Free;
  fBorg:=nil;
  //make new borg
  fBorg:=TCube.Create(self);
  fBorg.Projection:=tProjection.Screen;
  fBorg.Parent:=self;
  fBorg.Depth:=Height-(Height/2);
  fBorg.Width:=Height-(Height/2);
  fBorg.Height:=Height-(Height/2);
  fBorg.Position.X:=0;
  fBorg.Position.Y:=0;
  fBorg.Position.Z:=500;
  fBorg.MaterialSource:=MaterialsDm.tmTempImg;
  fBorg.OnClick:=nil;
  fBorg.OnMouseDown:=BorgMouseDown;//save the x
  fBorg.OnMouseUp:=BorgMouseUp;//spin the borg
  fBorg.Visible:=true;
  fBorgSpin.Parent:=fBorg;






end;


procedure TDlgMainScene.BorgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X: Single; Y: Single; RayPos: TVector3D; RayDir: TVector3D);
begin
  if  fDlgUp then exit;
  bDownx:=X;
end;

procedure TDlgMainScene.BorgMouseup(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X: Single; Y: Single; RayPos,
                                   RayDir: TVector3D);
begin
  if  fDlgUp then exit;

  if x>bDownX then
     begin
       //spin left
      fBorgSpin.Stop;
      fBorgSpin.StartValue:=360;
      fBorgSpin.StopValue:=0;
      fBorgSpin.Start;
      fBtnSpin.Text:='Yes';
     end else
        begin
          //spin right
        fBorgSpin.Stop;
        fBorgSpin.StartValue:=0;
        fBorgSpin.StopValue:=360;
        fBorgSpin.Start;
        fBtnSpin.Text:='Yes';
        end;
end;

procedure TDlgMainScene.OnConnect(sender: TObject);
begin
  fConnected:=true;
end;

procedure TDlgMainScene.OnDisconnect(sender: TObject);
begin
  fConnected:=False;
end;

procedure TDlgMainScene.Connect(sender: TObject);
begin
  //try to connect comms
  if fConnected then exit;//nop

  PacketClientDm.ClientComms.Host:=fIp;
  PacketClientDm.ClientComms.Port:=StrToInt(fPort);
  PacketClientDm.ClientComms.Connect;

end;

procedure TDlgMainScene.Disconnect(sender: TObject);
begin
//disconnect comms
if not fConnected then exit;//nop

PacketClientDm.ClientComms.Disconnect;


end;


procedure TDlgMainScene.Send(sender: TObject);
begin
 if not fConnected then exit;//nop

  case fCmd of
  0:SendNOP;
  1:SendJPG;
  end;




end;

//do nothing, one of my all time favs.. :P
procedure TDlgMainScene.SendNOP;
var
aHdr:TPacketHdr;
pBuff:pDataBuff;
begin
  FillPacketIdent(aHdr.Ident);
  aHdr.Command:=CMD_NOP;//nop
  aHdr.DataSize:=0;//nothing
  New(pBuff);
  SetLength(pBuff^.DataP,SizeOf(tPacketHdr));
  Move(aHdr,pBuff^.DataP[0],SizeOf(tPacketHdr));
  PacketClientDm.ClientComms.PushPacket(pBuff);
end;

//no tJpegImage
//use Codec Manager to get a jpeg stream
//which requires a bitmap surface
procedure TDlgMainScene.SendJPG;
var
aHdr:TPacketHdr;
pBuff:pDataBuff;
aStrm:TMemoryStream;
aSurf:TBitmapSurface;
offSet:integer;
begin
  aSurf:=tBitmapSurface.Create;
  aSurf.Assign(MaterialsDm.tmBorgImg.Texture);
  aStrm:=TMemoryStream.Create;
  try
  TBitmapCodecManager.SaveToStream(aStrm,aSurf,'.jpg');
  FillPacketIdent(aHdr.Ident);
  aHdr.Command:=CMD_JPG;//Send Jpeg
  aHdr.DataSize:=aStrm.Size;//size of jpeg
  aStrm.Position:=0;
  New(pBuff);//need one of these, wrap it all up
  SetLength(pBuff^.DataP,SizeOf(tPacketHdr)+aStrm.Size);
  offSet:=0;
  Move(aHdr,pBuff^.DataP[offSet],SizeOf(tPacketHdr));
  offSet:=OffSet+SizeOf(tPacketHdr);
  aStrm.ReadBuffer(pBuff^.DataP[offSet],aHdr.DataSize);//i usually put WriteBuffer here first, then fix it when it blows up lol
  PacketClientDm.ClientComms.PushPacket(pBuff);//it's gone, server already has it, look and see.. :)
  finally
  aSurf.Free;
  aStrm.SetSize(0);
  aStrm.Free;
  end;

end;

end.
