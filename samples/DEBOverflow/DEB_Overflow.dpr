program DEB_Overflow;

uses
  System.StartUpCopy,
  FMX.Forms,
  frmPy4dDEB in 'frmPy4dDEB.pas' {frmPy4DEB},
  ThreadFSPollFolder in 'ThreadFSPollFolder.pas',
  MsgEventsU in 'MsgEventsU.pas',
  ThreadItemWorker in 'ThreadItemWorker.pas',
  ThreadProcStats in 'ThreadProcStats.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.CreateForm(TfrmPy4DEB, frmPy4DEB);
  Application.Run;
end.
