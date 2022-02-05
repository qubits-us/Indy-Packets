program PacketClient3d;

uses
  System.StartUpCopy,
  FMX.Forms,
  uFrmMain in 'uFrmMain.pas' {MainFrm},
  uClientCommsObj in '..\common\uClientCommsObj.pas',
  uPacketClientDm in '..\common\uPacketClientDm.pas' {PacketClientDm: TDataModule},
  dmMaterials in 'dmMaterials.pas' {MaterialsDm: TDataModule},
  uInertiaTimer in '..\..\3dBase\common\uInertiaTimer.pas',
  uDlg3dCtrls in '..\..\3dBase\common\uDlg3dCtrls.pas',
  uDlg3dTextures in '..\..\3dBase\common\uDlg3dTextures.pas',
  uKeyboardDlg in '..\..\3dBase\common\uKeyboardDlg.pas',
  uNumPadDlg in '..\..\3dBase\common\uNumPadDlg.pas',
  uGlobs in 'uGlobs.pas',
  uCommon3dDlgs in '..\..\3dBase\common\uCommon3dDlgs.pas',
  uSceneMain in 'uSceneMain.pas',
  uIPChangeDlg in '..\..\3dBase\common\uIPChangeDlg.pas',
  uPacketDefs in '..\common\uPacketDefs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.InvertedLandscape];
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
