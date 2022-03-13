program IndyPacketSrvr;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmMain in 'ufrmMain.pas' {MainFrm},
  uPacketContext in '..\common\uPacketContext.pas',
  uPacketDefs in '..\common\uPacketDefs.pas',
  uIndyPacketServer in '..\common\uIndyPacketServer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
