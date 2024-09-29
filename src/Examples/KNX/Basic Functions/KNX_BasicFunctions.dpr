program KNX_BasicFunctions;

uses
  Vcl.Forms,
  mainFM in 'mainFM.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'IDC4Delphi - KNX Basic Functions';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
