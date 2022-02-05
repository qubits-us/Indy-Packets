{ the Globs!!
  Created:1.16.22 -dm

  reused for this demo 2.4.2022 -q




  be it harm none, do as ye wish
     }
unit uGlobs;

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms3D, FMX.Types3D, FMX.Forms, FMX.Graphics,
  FMX.MaterialSources,FMX.Objects, FMX.Dialogs,FMX.Layers3D,FMX.Objects3D,
  System.UIConsts,dmMaterials,System.SyncObjs, System.Math.Vectors,
  FMX.Controls3D,FMX.Platform{$IFDEF ANDROID},FMX.Platform.Android{$ENDIF},
  uDlg3dCtrls,uSceneMain,uCommon3dDlgs,uNumPadDlg,uKeyboardDlg,uDlg3dTextures;



   //Tron -in charge of memory defense, kills things..
 type
    TTron = Class(tObject)
    procedure KillConfirm(sender:tObject;aYesNo:integer);
    procedure KillInfo(sender:tObject);
    procedure KillGetNumDone(sender:tObject;Selected:integer);
    procedure KillGetStr(sender:tObject);
    procedure KillScene1;
    End;




    procedure ShowConfirm(sender:tObject);
    procedure ShowInfo(sender:tObject);
    procedure GetNum(sender:tObject);
    procedure GetStr(sender:tObject);







var
  Scene1:TDlgMainScene;
  ConfirmDlg:TDlgConfirmation;
  InfoDlg:TDlgInformation;
  KeyboardDlg:tDlgKeyboard;
  NumPadDlg:TDlgNumPad;
  DlgUp:Boolean;
  Tron:TTron;


implementation

uses ufrmMain;



 procedure TTron.KillScene1;
 begin
     if Assigned(Scene1) then
      begin
        Scene1.Visible:=false;
       TThread.CreateAnonymousThread(
        procedure
         begin
          TThread.Queue(nil,
           procedure
            begin
              Scene1.CleanUp;
              Scene1.Free;
              Scene1:=nil;
             end);
         end).Start;
      end;
 end;




 procedure ShowConfirm(sender: TObject);
 var
 newx,newy:single;
 begin

   if not Assigned(ConfirmDlg) then
      begin
      newx:=(MainFrm.ClientWidth/2);
      newy:=(MainFrm.ClientHeight/2);
      ConfirmDlg:=tDlgConfirmation.Create(MainFrm,DlgMaterial,MainFrm.width/1.5,MainFrm.height/2,newx,newy);
      ConfirmDlg.DlgText.Text:='Yes and No prompt';
      ConfirmDlg.Parent:=MainFrm;
      ConfirmDlg.Position.Z:=-10;
      ConfirmDlg.OnButtonClick:=Tron.KillConfirm;
      ConfirmDlg.Opacity:=0.95;
      DlgUp:=true;
      end;

 end;


 procedure TTron.KillConfirm(sender: TObject;aYesNo:integer);
 begin


   if Assigned(ConfirmDlg) then
      begin
        ConfirmDlg.Visible:=false;
       TThread.CreateAnonymousThread(
        procedure
         begin
          TThread.Queue(nil,
           procedure
            begin
              ConfirmDlg.CleanUp;
              ConfirmDlg.Free;
              ConfirmDlg:=nil;
              DlgUp:=False;
             end);
         end).Start;
      end;
 end;

 procedure ShowInfo(sender: TObject);
 var
 newx,newy:single;

 begin
   if not Assigned(InfoDlg) then
      begin
       newx:=(MainFrm.ClientWidth/2);
       newy:=(MainFrm.ClientHeight/2);
      InfoDlg:=tDlgInformation.Create(MainFrm,DlgMaterial,MainFrm.width/1.5,MainFrm.height/2,newx,newy);
      InfoDlg.DlgText.Text:='H:'+FloatToStr(MainFrm.ClientHeight)+' W:'+FloatToStr(MainFrm.ClientWidth)+' Scale:'+FloatToStr(CurrentScale);
      InfoDlg.Parent:=MainFrm;
      InfoDlg.Position.Z:=-10;
      InfoDlg.OnClick:=Tron.KillInfo;
      DlgUp:=true;

      end;

 end;


 procedure TTron.KillInfo(sender: TObject);
 begin
   if Assigned(InfoDlg) then
      begin
        InfoDlg.Visible:=false;
       TThread.CreateAnonymousThread(
        procedure
         begin
          TThread.Queue(nil,
           procedure
            begin
              InfoDlg.CleanUp;
              InfoDlg.Free;
              InfoDlg:=nil;
              DlgUp:=False;
             end);
         end).Start;
      end;
 end;

 procedure GetNum(sender: TObject);
 var
 newx,newy:single;
 begin

   if not Assigned(NumPadDlg) then
      begin
       newx:=(MainFrm.ClientWidth/2);
       newy:=(MainFrm.ClientHeight/2);

      NumPadDlg:=tDlgNumPad.Create(MainFrm,DlgMaterial,MainFrm.height/1.25,MainFrm.height/1.25,newx,newy);
      NumPadDlg.Number:=100;
      NumPadDlg.NumBtn.Text:='100';
      NumPadDlg.Parent:=MainFrm;
      NumPadDlg.Position.Z:=-10;
      NumPadDlg.OnDone:=Tron.KillGetNumDone;
      NumPadDlg.BackIm.Visible:=true;
      NumPadDlg.Opacity:=0.95;
      DlgUp:=true;

      end;

 end;


 procedure TTron.KillGetNumDone(sender: TObject;Selected:integer);
 begin
   if Assigned(NumPadDlg) then
      begin
        NumPadDlg.Visible:=false;
       TThread.CreateAnonymousThread(
        procedure
         begin
          TThread.Queue(nil,
           procedure
            begin
              NumPadDlg.CleanUp;
              NumPadDlg.Free;
              NumPadDlg:=nil;
              DlgUp:=False;
             end);
         end).Start;
      end;
 end;


 procedure GetStr(sender: TObject);
 var
 newx,newy:single;
 begin

   if not Assigned(KeyboardDlg) then
      begin
       newx:=(MainFrm.ClientWidth/2);
       newy:=(MainFrm.ClientHeight/2);

      KeyboardDlg:=tDlgKeyboard.Create(MainFrm,DlgMaterial,MainFrm.ClientWidth,MainFrm.ClientHeight,newx,newy);
      KeyboardDlg.Parent:=MainFrm;
      KeyboardDlg.Position.Z:=-10;
      KeyboardDlg.OnDone:=Tron.KillGetStr;
      KeyboardDlg.BackIm.Visible:=true;
      KeyboardDlg.StrGet:='Jupiter';
      KeyboardDlg.Opacity:=0.90;
      DlgUp:=true;

      end;

 end;


 procedure TTron.KillGetStr(sender: TObject);
 begin

   if Assigned(KeyboardDlg) then
      begin
        KeyboardDlg.Visible:=false;
       TThread.CreateAnonymousThread(
        procedure
         begin
          TThread.Queue(nil,
           procedure
            begin
              KeyboardDlg.CleanUp;
              KeyboardDlg.Free;
              KeyboardDlg:=nil;
              DlgUp:=False;
             end);
         end).Start;
      end;
 end;









end.
