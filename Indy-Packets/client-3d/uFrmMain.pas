{Indy Packet Client Demo -
  Testing my indy client object..

  created 2.4.2022 -q
  www.qubits.us

  Uses ics packet server, sends/recvs jpegs

  be it harm none, do as ye wish..

}
unit uFrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms3D, FMX.Types3D, FMX.Forms, FMX.Graphics,
  FMX.Dialogs,FMX.MaterialSources,FMX.Objects,FMX.Layers3D,FMX.Objects3D,
  System.UIConsts,dmMaterials,System.SyncObjs, System.Math.Vectors,
  FMX.Controls3D,FMX.Platform{$IFDEF ANDROID},FMX.Platform.Android{$ENDIF},
  uDlg3dCtrls,uSceneMain,uCommon3dDlgs,uNumPadDlg,uKeyboardDlg,uDlg3dTextures,uGlobs;


type
  TMainFrm = class(TForm3D)
    im: TImage3D;
    procedure Form3DCreate(Sender: TObject);
    procedure Form3DClose(Sender: TObject; var Action: TCloseAction);
    procedure InitMainScene;
    procedure DoCloseApp(sender:tObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.fmx}

uses uPacketClientDm;



function GetScreenScale: Single;var ScreenService: IFMXScreenService;
begin
  Result := 1;
  if TPlatformServices.Current.SupportsPlatformService (IFMXScreenService, IInterface(ScreenService)) then
    Result := ScreenService.GetScreenScale;
end;





procedure TMainFrm.Form3DClose(Sender: TObject; var Action: TCloseAction);
begin
//all done


  if Assigned(Scene1) then Scene1.Free;

  dlgMaterial.Free;
  dlgMaterial:=nil;

  MaterialsDm.Free;


  if PacketClientDm.ClientComms.Connected then
     PacketClientDm.ClientComms.Disconnect;
 PacketClientDm.Free;

  Tron.Free;


  {$IFDEF ANDROID}
  MainActivity.finish;
  {$ENDIF}






end;

procedure TMainFrm.Form3DCreate(Sender: TObject);
begin
//in the beginning, there was only code..
   System.ReportMemoryLeaksOnShutdown:=true;//catch me if you can.. :P

   MaterialsDm:=TMaterialsDm.Create(self);//pics
   PacketClientDm:=tPacketClientDm.Create(self);//comms
   PacketClientDm.CreateComms;//puf,puf brumm, brumm..

   DlgMaterial:=tDlgMaterial.Create(self);//holds pics

  Scene1:=nil;
  DlgUp:=False;
  Tron:=TTron.Create;//just because your cool, really no other reason.. :P

  CurrentTheme:=3;//Aurora -my fave.. :)


      //everybody scales!!
      CurrentScale:=GetScreenScale;

     {Berlin gotta ya!!
       don't trunc and replace / with div
       those are ints, d11 singles}

    ClientWidth:=Trunc(Screen.Width-(Screen.Width / 2));//the first of many divisions..
    ClientHeight:=Trunc(Screen.Height-(Screen.Height / 2));
    Left:=50;
    Top:=10;


 {$IFDEF ANDROID} //robots
       GoFullScreen:=true;
       Caption:='';
       Width:=Trunc(Screen.Width);
       Height:=Trunc(Screen.Height);
       ClientWidth:=Trunc(Screen.Width);
       ClientHeight:=Trunc(Screen.Height);
       im.Width:=Width;
       im.Height:=Height;
       Left:=0;
       Top:=0;
       BorderStyle:=TFmxFormBorderStyle.None;
       FullScreen:=true;
       StartUpTmr.Enabled:=true;
       //wait 5 secs.. screen will be ready..
 {$ENDIF}

  {$IFDEF MSWINDOWS}  //windows
    GoFullScreen:=false;
    BorderStyle:=TFmxFormBorderStyle.ToolWindow;
    Caption:='3d Packet Client Test';
    //my 4k phone's res, but it's hdpi
    ClientWidth:=916;
    ClientHeight:=411;
     {Berlin gotta ya!!
       don't trunc and replace / with div
       those are ints, d11 singles}
    Left:=Trunc((Screen.Width/2)-(ClientWidth/2));
    Top:=Trunc((Screen.Height/2)-(ClientHeight/2));
    InitMainScene;
 {$ENDIF}



end;



procedure TMainFrm.InitMainScene;
var
  newx,newy:single;
 begin
   //lift off..

   im.Visible:=false;


  DlgMaterial.GreenTxt.Color:=claGreen;
  DlgMaterial.RedTxt.Color:=claRed;

   MaterialsDm.LoadTheme;

   newx:=(MainFrm.ClientWidth/2);
   newy:=(MainFrm.ClientHeight/2);
   Scene1:=tDlgMainScene.Create(MainFrm,MainFrm.ClientWidth,MainFrm.ClientHeight,0,0);
   Scene1.Parent:=MainFrm;
   Scene1.Position.X:=newx;
   Scene1.Position.Y:=newy;
   Scene1.OnClose:=DoCloseApp;

 end;

 procedure TMainFrm.DoCloseApp(sender: TObject);
 begin
   Close;
 end;


end.
