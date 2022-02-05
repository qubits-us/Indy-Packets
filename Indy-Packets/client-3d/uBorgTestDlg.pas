{Spin a borg cube.. getting to be no one remembers the borg anymore.. :(
 either way, simple dialog, couple of input buttons one with popup getter..

 oh, should mention first i had a TRectange3d instead of TCube, renders really bad just on ine side...
 so, if it's a cube use a cube, fyi!!


 1.16.22 -dm

 be it harm none, do as ye wishes..


}
unit uBorgTestDlg;

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.UIConsts,
  FMX.Types, FMX.Controls, FMX.Forms3D, FMX.Types3D, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, System.Math.Vectors, FMX.Ani, FMX.Controls3D,
  FMX.MaterialSources, FMX.Objects3D, FMX.Effects, FMX.Filter.Effects,FMX.Layers3D,
  FMX.Objects,uDlg3dCtrls,uNumPadDlg;


  type
    TDlgBorgTest= class(TDummy)
      private
       fIm:TImage3d;
       fTxt:TText3d;
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
      protected
       procedure TogSpin(sender:tObject);
       procedure DoClose(sender:tObject);
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

uses dmMaterials;



Constructor TDlgBorgTest.Create(Sender: TComponent;aWidth,aHeight,aX,aY:single);
var
aGap:Single;
aBtnWidth,aBtnHeight:single;
newx,newy:single;

begin
  //create
  Inherited Create(nil);
  fCleanedUp:=false;
  fNumPad:=nil;
  fDuration:=180;
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
  fIm.HitTest:=true;
  fIm.OnClick:=DoClose;
  fIm.Position.X:=aX;
  fIm.Position.Y:=aY;

  fIm.Parent:=self;

  //6 btns wide by 6 tall
  aBtnWidth:=Width/6;
  aBtnHeight:=Height/6;

  newy:=((Height/2)*-1)+(aBtnHeight/2);//top
  newx:=((Width/2)*-1)+(aBtnWidth/2)+aGap;//left

      fBtnDuration:=tDlgInputButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnDuration.Projection:=TProjection.Screen;
      fBtnDuration.Parent:=self;
      fBtnDuration.MaterialSource:=dlgMaterial.Buttons.Button;
      fBtnDuration.MaterialBackSource:=dlgMaterial.Buttons.Button;
      fBtnDuration.MaterialShaftSource:=dlgMaterial.Buttons.Button;

      fBtnDuration.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnDuration.LabelColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnDuration.FontSize:=dlgMaterial.FontSize;
      fBtnDuration.LabelSize:=dlgMaterial.FontSize/1.5;
      //back up the texture, we be drawing our own text for awhile.. :(
      fBtnDuration.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);

      fBtnDuration.Text:='180';
      fBtnDuration.LabelText:='Spin Duration';
      fBtnDuration.OnClick:=DurationClick;


     newx:=newx+aBtnWidth+aGap;

      fBtnSpin:=tDlgInputButton.Create(self,aBtnWidth,aBtnHeight,newx,newy);
      fBtnSpin.Projection:=TProjection.Screen;
      fBtnSpin.Parent:=self;
      fBtnSpin.MaterialSource:=dlgMaterial.Buttons.Button;
     // fBtnSpin.RectButton.MaterialBackSource:=dlgMaterial.Buttons.Button;
    //  fBtnSpin.RectButton.MaterialShaftSource:=dlgMaterial.Buttons.Button;
      fBtnSpin.TextColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnSpin.LabelColor:=dlgMaterial.Buttons.TextColor.Color;
      fBtnSpin.FontSize:=dlgMaterial.FontSize;
      fBtnSpin.LabelSize:=dlgMaterial.FontSize/1.5;
      fBtnSpin.BtnBitMap.Assign(dlgMaterial.Buttons.Rect.Texture);

      fBtnSpin.Text:='No';
      fBtnSpin.LabelText:='Spin';
      fBtnSpin.OnClick:=TogSpin;











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
  fTxt.Position.Z:=-1;//((Height+400)/4)*-1;
  fTxt.Text:='Delphi -The future coded now..';
  fTxt.MaterialSource:=DlgMaterial.TextColor;
  fTxt.MaterialBackSource:=DlgMaterial.TextColor;
  fTxt.MaterialShaftSource:=DlgMaterial.TextColor;
  fTxt.OnClick:=DoClose;
  fTxt.Visible:=true;

  fWebTxt:=TText3d.Create(nil);
  fWebTxt.Projection:=tProjection.Screen;
  fWebTxt.Parent:=self;//TDummy(sender);
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
  fBorgSpin.Duration:=180;
  fBorgSpin.StartValue:=0;
  fBorgSpin.StopValue:=360;
  fBorgSpin.Loop:=true;
  fBorgSpin.Parent:=fBorg;
  fBorgSpin.PropertyName:='RotationAngle.Y';
  fBorgSpin.Enabled:=False;

end;

Destructor TDlgBorgTest.Destroy;
begin

  if not fCleanedUp then CleanUp;


  Inherited;
end;

procedure TDlgBorgTest.CleanUp;
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

  fBorgSpin.Stop;
  fBorgSpin.Parent:=nil;
  fBorgSpin.free;
  fBorgSpin:=nil;


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


  //fBorg.MaterialBackSource:=nil;
//  fBorg.MaterialShaftSource:=nil;
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

procedure TDlgBorgTest.TogSpin(sender: TObject);
begin
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


procedure TDlgBorgTest.DurationClick(sender: TObject);
begin
  //open up a numpad..
     if not assigned(fNumPad) then
        begin
          //creae a keyboard here
          fNumPad:=tDlgNumPad.Create(self,DlgMaterial,height-50,height-50,0,0);
        end;
          fNumPad.Number:=fDuration;
          fNumPad.OnDone:=DurationDone;
          fNumPad.Parent:=self;

          fNumPad.Position.Z:=-2;
          fNumPad.Opacity:=0.85;
          fNumPad.Visible:=true;

end;

procedure TDlgBorgTest.DurationDone(sender: TObject;Selected:integer);
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



end;

procedure TDlgBorgTest.DoClose(sender: TObject);
begin
if fCloseOnce then exit;//only one time please
  fCloseOnce:=true;

  if Assigned(fCloseEvent) then
      fCloseEvent(nil);
end;


procedure TDlgBorgTest.BorgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X: Single; Y: Single; RayPos: TVector3D; RayDir: TVector3D);
begin
  bDownx:=X;
end;

procedure TDlgBorgTest.BorgMouseup(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X: Single; Y: Single; RayPos,
                                   RayDir: TVector3D);
begin

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



end.
