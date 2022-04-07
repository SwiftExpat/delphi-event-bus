unit ThreadProcStats;

interface

uses
  System.Classes, EventBus, MsgEventsU;

type
  TAppStatsThread = class(TThread)
  strict private
    FEnabled: boolean;
  private
    FProcName: string;
    FPID: Cardinal;
    function ThreadList(var AThreadList: TStringList): boolean;
    function ProcessPID: Cardinal;
  protected
    procedure Execute; override;
  public
    [Subscribe(TThreadMode.Background, ctx_StatsWorker)]
    procedure OnEnableStats(AEvent: IEnablePolling);
    constructor Create;
  end;

implementation

uses ShellAPI, psapi, Windows, TlHelp32, System.SysUtils, System.IOUtils;
{
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

  Synchronize(UpdateCaption);

  and UpdateCaption could look like,

  procedure TAppStatsThread.UpdateCaption;
  begin
  Form1.Caption := 'Updated in a thread';
  end;

  or

  Synchronize(
  procedure
  begin
  Form1.Caption := 'Updated in thread via an anonymous method'
  end
  )
  );

  where an anonymous method is passed.

  Similarly, the developer can call the Queue method with similar parameters as
  above, instead passing another TThread class as the first parameter, putting
  the calling thread in a queue with the other thread.

}

{ TAppStatsThread }

constructor TAppStatsThread.Create;
begin
inherited Create(true);
  GlobalEventBus.RegisterSubscriberForEvents(self);
end;

procedure TAppStatsThread.Execute;
var
  tl: TStringList;
  ps: IOnProcStat;
begin
  FProcName := TPath.GetFileName(ParamStr(0));
  FPID := ProcessPID;
  NameThreadForDebugging('AppStatsThread');
  while not Terminated do
  begin
    if FEnabled then
    begin
      tl := TStringList.Create;
      // get the stats from the app
      // send them to the gui
      ThreadList(tl);
      ps := TProcStat.Create;
      TProcStat(ps).SetThreadCount(tl.Count);
      GlobalEventBus.Post(ps, ctx_ThreadCountOnly);
      tl.Free;
      Sleep(500);
    end;
  end;
end;

procedure TAppStatsThread.OnEnableStats(AEvent: IEnablePolling);
begin
  FEnabled := AEvent.Enabled;
end;

function TAppStatsThread.ProcessPID: Cardinal;
var
  hSnapShot: THandle;
  ProcInfo: TProcessEntry32;
begin
  result := 0;
  try
    hSnapShot := CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnapShot <> THandle(-1)) then
    begin
      ProcInfo.dwSize := SizeOf(ProcInfo);
      if Process32First(hSnapShot, ProcInfo) then
      begin
        if ProcInfo.szExeFile = FProcName then
          result := ProcInfo.th32ProcessID
        else
          while Process32Next(hSnapShot, ProcInfo) do
            if ProcInfo.szExeFile = FProcName then
            begin
              result := ProcInfo.th32ProcessID;
              Break;
            end;
      end;
      CloseHandle(hSnapShot);
    end;
  except
    on E: Exception do
      result := 0;
  end;

end;

function TAppStatsThread.ThreadList(var AThreadList: TStringList): boolean;
var
  ThreadSnapShot: THandle;
  te32: TThreadEntry32;
begin
result := false;
  try
    ThreadSnapShot := CreateToolHelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (ThreadSnapShot <> THandle(-1)) then
    begin
      te32.dwSize := SizeOf(te32);
      if (Thread32First(ThreadSnapShot, te32)) then
      begin
        if te32.th32OwnerProcessID = FPID then
          AThreadList.Add(te32.th32ThreadID.ToString);
        while Thread32Next(ThreadSnapShot, te32) do
          if te32.th32OwnerProcessID = FPID then
            AThreadList.Add(te32.th32ThreadID.ToString);
      end;
      CloseHandle(ThreadSnapShot);
      result := True;
    end;
  except
    on E: Exception do
      result := false;
  end;

end;

end.
