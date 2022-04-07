unit ThreadPythonEngineU;

interface

uses
  System.Classes, PythonEngine, EventBus, Generics.Collections, MsgEventsU;

type
  TTHPythonEngine = class(TThread)
  private
    PE: TPythonEngine;
    PythonIO: TPythonInputOutput;
    FEnabled: boolean;
    QFileFoundEvt: TThreadedQueue<IOnFileProcessed>;
    procedure PythonIOReceiveData(Sender: TObject; var Data: AnsiString);
    procedure PythonIOReceiveUniData(Sender: TObject; var Data: string);
    procedure PythonIOSendData(Sender: TObject; const Data: AnsiString);
    procedure PythonIOSendUniData(Sender: TObject; const Data: string);

    function CmdValidate: TStringList;
    procedure StartEngine;
    procedure SetInitScript;
    procedure LogMsg(AMsg: string);
    procedure TaskShort;
    procedure TaskLong;
    procedure SendQueueSize;
    procedure ProcQueueItem(AItem: IOnFileProcessed);
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    [Subscribe(TThreadMode.Async)]
    procedure OnFileFoundEvent(AEvent: IOnFileFound);
    [Subscribe(TThreadMode.Background, 'PyEng')]
    procedure OnEnablePolling(AEvent: IEnablePolling);
  end;

implementation

uses System.SysUtils;

{ TTHPythonEngine }

function TTHPythonEngine.CmdValidate: TStringList;
begin
  result := TStringList.Create;
  result.Add('from rttk import validate');
  result.Add('validate.printpath()');
end;

constructor TTHPythonEngine.Create;
begin
  inherited Create(true);
  GlobalEventBus.RegisterSubscriberForEvents(self);
  QFileFoundEvt := TThreadedQueue<IOnFileProcessed>.Create;
  PE := TPythonEngine.Create(nil);
  PythonIO := TPythonInputOutput.Create(nil);
  PythonIO.OnSendData := PythonIOSendData;
  PythonIO.OnSendUniData := PythonIOSendUniData;
  PythonIO.OnReceiveData := PythonIOReceiveData;
  PythonIO.OnReceiveUniData := PythonIOReceiveUniData;
  FEnabled := false;
end;

destructor TTHPythonEngine.Destroy;
begin
  QFileFoundEvt.free;
  PythonIO.free;
  // something else has to be done here
  PE.free;
  inherited;
end;

procedure TTHPythonEngine.Execute;

begin
  NameThreadForDebugging('THPythonEngine');
  StartEngine;
  while not Terminated do
  begin
    if ((QFileFoundEvt.TotalItemsPushed - QFileFoundEvt.TotalItemsPopped) > 0) and FEnabled then
    begin
      ProcQueueItem(QFileFoundEvt.PopItem);

      SendQueueSize;
    end;
    sleep(100);
  end;
end;

procedure TTHPythonEngine.LogMsg(AMsg: string);
begin

end;

procedure TTHPythonEngine.OnEnablePolling(AEvent: IEnablePolling);
begin
  FEnabled := AEvent.Enabled;
end;

procedure TTHPythonEngine.OnFileFoundEvent(AEvent: IOnFileFound);
var
  lfp: IOnFileProcessed;
begin
  lfp := TOnFileProcessed.Create();
  lfp.FileName := AEvent.FileName;
  lfp.EnQueueTime := Now;
  lfp.Success := false;
  QFileFoundEvt.PushItem(lfp);
  SendQueueSize;
  // sleep(250);
  GlobalEventBus.Post(lfp, 'EnQueue');
end;

procedure TTHPythonEngine.ProcQueueItem(AItem: IOnFileProcessed);
begin
  if not assigned(AItem) then
  begin
    GlobalEventBus.Post('WorkQueuePanic', 'Nil item recieved');
    exit;
  end;
  try
    TaskLong;
    AItem.ProcessedTime := Now;
    AItem.Success := true;
    GlobalEventBus.Post(AItem, 'Processed');
  except
    on E: Exception do
        GlobalEventBus.Post('WorkQueuePanic', E.Message);
  end;

end;

procedure TTHPythonEngine.PythonIOReceiveData(Sender: TObject; var Data: AnsiString);
begin

end;

procedure TTHPythonEngine.PythonIOReceiveUniData(Sender: TObject; var Data: string);
begin

end;

procedure TTHPythonEngine.PythonIOSendData(Sender: TObject; const Data: AnsiString);
begin

end;

procedure TTHPythonEngine.PythonIOSendUniData(Sender: TObject; const Data: string);
begin

end;

procedure TTHPythonEngine.SendQueueSize;
begin
  // Synchronize(
  // procedure
  // begin
  GlobalEventBus.Post('WorkQueueSize', (QFileFoundEvt.TotalItemsPushed - QFileFoundEvt.TotalItemsPopped).ToString);
  // end);
end;

procedure TTHPythonEngine.SetInitScript;
begin
  PE.InitScript.Clear;
  PE.InitScript.Add('import os');
  PE.InitScript.Add('os.environ[''RTTKPYINIFILE''] = ''C:\\Users\\Coder\\AppData\\Roaming\\RTTK\\rttkpy.ini''');
  PE.InitScript.Add('os.environ[''RTTKPYLOGFILE''] = ''C:\\Users\\Coder\\AppData\\Roaming\\RTTK\\rttkpy.log''');
end;

procedure TTHPythonEngine.StartEngine;
var
  cv: TStringList;
begin
  LogMsg('Python starting');
  PE.IO := PythonIO;
  SetInitScript;
  PE.DllPath := 'c:\Apps\py39\python-3.9.2-embed-amd64';
  PE.DllName := 'python39.dll';
  MaskFPUExceptions(true);
  PE.LoadDll;
  LogMsg('Python Loaded');
  cv := CmdValidate;
  PE.ExecStrings(cv);
  cv.free;
end;

procedure TTHPythonEngine.TaskLong;
begin
  sleep(1500);
end;

procedure TTHPythonEngine.TaskShort;
begin
  sleep(100);
end;

end.
