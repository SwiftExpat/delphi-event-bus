unit ThreadItemWorker;

interface

uses
  System.Classes, Generics.Collections, EventBus, MsgEventsU;

type
  TItemWorkerThread = class(TThread)
  strict private
    FPollEnabled: boolean;
  private

    QueueWorkItems: TThreadedQueue<IOnFileProcessed>;
   // FIterations, FIteration: cardinal;
    procedure SendQueueSize;
    procedure ProcQueueItem(AItem: IOnFileProcessed);
    function QueueDepth: UInt64;
    procedure TaskLong;
  protected
    procedure Execute; override;
  public
    [Subscribe(TThreadMode.Async)]
    procedure OnFileFoundEvent(AEvent: IDEBEvent<TOnFileFound>);
    [Subscribe(TThreadMode.Async)]
    procedure OnFileFoundEventCustom(AEvent: IOnFileFound);
    [Subscribe(TThreadMode.Background, ctx_ItemWorker)]
    procedure OnEnablePolling(AEvent: IEnablePolling);
    [Subscribe(TThreadMode.Async, ctx_ThreadCountOnly)]
    procedure OnStatThreadCount(AEvent: IOnProcStat);
    destructor Destroy; override;
    constructor Create;
  end;

implementation

uses System.SysUtils;

{ TItemWorkerThread }

constructor TItemWorkerThread.Create;
begin
  inherited Create(true);
  FPollEnabled := false;
  QueueWorkItems := TThreadedQueue<IOnFileProcessed>.Create;
  GlobalEventBus.RegisterSubscriberForEvents(self);
end;

destructor TItemWorkerThread.Destroy;
begin
  QueueWorkItems.Free;
  inherited;
end;

procedure TItemWorkerThread.Execute;
begin
  inherited;
  NameThreadForDebugging('ThreadItemWorker');
  while not Terminated do
  begin
    if (QueueDepth > 0) and FPollEnabled then
    begin
      ProcQueueItem(QueueWorkItems.PopItem);
      SendQueueSize;
    end;
    sleep(100);
  end;

end;

procedure TItemWorkerThread.OnEnablePolling(AEvent: IEnablePolling);
begin
  FPollEnabled := AEvent.Enabled;
end;

procedure TItemWorkerThread.OnFileFoundEvent(AEvent: IDEBEvent<TOnFileFound>);
var
  lfp: IOnFileProcessed;
begin
  lfp := TOnFileProcessed.Create();
  lfp.FileName := AEvent.Data.FileName;
  lfp.EnQueueTime := Now;
  lfp.Success := false;
  QueueWorkItems.PushItem(lfp);
  SendQueueSize;
  GlobalEventBus.Post(lfp, 'EnQueue');
end;

procedure TItemWorkerThread.OnFileFoundEventCustom(AEvent: IOnFileFound);
var
  lfp: IOnFileProcessed;
begin
  lfp := TOnFileProcessed.Create();
  lfp.FileName := AEvent.FileName;
  lfp.EnQueueTime := Now;
  lfp.Success := false;
  QueueWorkItems.PushItem(lfp);
  SendQueueSize;
  GlobalEventBus.Post(lfp, 'EnQueue');
end;

procedure TItemWorkerThread.OnStatThreadCount(AEvent: IOnProcStat);
begin
TProcStat(AEvent).SetQueueLength(QueueDepth);
GlobalEventBus.Post(AEvent, ctx_StatReady);
end;

procedure TItemWorkerThread.ProcQueueItem(AItem: IOnFileProcessed);
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

function TItemWorkerThread.QueueDepth: UInt64;
begin
  result := (QueueWorkItems.TotalItemsPushed - QueueWorkItems.TotalItemsPopped);
end;

procedure TItemWorkerThread.SendQueueSize;
begin
  GlobalEventBus.Post('WorkQueueSize', QueueDepth.ToString);

end;

procedure TItemWorkerThread.TaskLong;
begin
  sleep(900);
end;

end.
