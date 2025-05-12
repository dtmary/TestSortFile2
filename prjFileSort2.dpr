program prjFileSort2;

uses
  Vcl.Forms,
  uFileSortMain in 'uFileSortMain.pas' {fmFileSortMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmFileSortMain, fmFileSortMain);
  Application.Run;
end.
