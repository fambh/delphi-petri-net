program Petri;

uses
  Forms,
  RPMain in 'RPMain.pas' {frmRPMain},
  RPLib in 'RPLib.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'LadyPetri';
  Application.CreateForm(TfrmRPMain, frmRPMain);
  Application.Run;
end.
