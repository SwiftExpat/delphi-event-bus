unit frmDebOverflowU;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, EventBus, ThreadFSPollFolder, ThreadItemWorker,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, MsgEventsU, FMX.ListBox, Generics.Collections, ThreadProcStats,
  FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics, FMX.TMSFNCGraphicsTypes,
  FMX.TMSFNCChart;

type
  TfrmPy4DEB = class(TForm)
    lytTools: TLayout;
    cbPolling: TCheckBox;
    cbPyEngine: TCheckBox;
    AniIndicator1: TAniIndicator;
    lbQueue: TListBox;
    ListBoxHeader1: TListBoxHeader;
    Label1: TLabel;
    ghQueueItems: TListBoxGroupHeader;
    gfQueueCount: TListBoxGroupFooter;
    ghProcessed: TListBoxGroupHeader;
    ghFileFound: TListBoxGroupHeader;
    Layout1: TLayout;
    chart: TTMSFNCChart;
    cbStats: TCheckBox;
    cbPubDebEvent: TCheckBox;
    procedure cbPollingChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbPyEngineChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbStatsChange(Sender: TObject);
    procedure cbPubDebEventChange(Sender: TObject);
  private
    FTHPollFolder: TFSPollFolder;
    FThIW: TItemWorkerThread;
    FThStats: TAppStatsThread;
    FProcItems: TDictionary<string, TListBoxItem>;
    procedure InitChart;
    // procedure LogMsg(amsg: string);
    procedure ProcItemAdd(AFileName: string);
    procedure ProcItemMoveQueue(AFileName: string);
    procedure ProcItemMoveProcessed(AFileName: string);
  public
    { Public declarations }
    [Channel('FileFound')]
    procedure OnFileFound(amsg: String);
    [Channel('PyMsgLog')]
    procedure OnPyMsgFound(amsg: String);
    [Channel('PyProcLog')]
    procedure OnPyProcMsg(amsg: String);
    [Channel('WorkQueueSize')]
    procedure OnWorkQueueSize(amsg: String);
    [Channel('WorkQueuePanic')]
    procedure OnWorkQueuePanic(amsg: String);

    [Subscribe(TThreadMode.Main, ctx_StatReady)]
    procedure OnStatThreadCount(AEvent: IOnProcStat);

    [Subscribe(TThreadMode.Main)]
    procedure OnFileFoundEvent(AEvent: IDEBEvent<TOnFileFound>);
    [Subscribe(TThreadMode.Main)]
    procedure OnFileFoundEventCustom(AEvent: IOnFileFound);
    [Subscribe(TThreadMode.Main, 'Processed')]
    procedure OnFileProcessed(AEvent: IOnFileProcessed);
    [Subscribe(TThreadMode.Main, 'EnQueue')]
    procedure OnFileEnQueue(AEvent: IOnFileProcessed);

  end;

var
  frmPy4DEB: TfrmPy4DEB;

implementation

{$R *.fmx}

procedure TfrmPy4DEB.ProcItemAdd(AFileName: string);
var
  i: integer;
  lbi: TListBoxItem;
begin
  i := lbQueue.Items.Add(AFileName);
  lbi := lbQueue.ListItems[i];
  lbi.Index := ghFileFound.Index + 1;
  FProcItems.Add(AFileName, lbi);
end;

procedure TfrmPy4DEB.ProcItemMoveProcessed(AFileName: string);
var
  lbi: TListBoxItem;
begin
  if FProcItems.TryGetValue(AFileName, lbi) then
    lbi.Index := ghProcessed.Index;
end;

procedure TfrmPy4DEB.ProcItemMoveQueue(AFileName: string);
var
  lbi: TListBoxItem;
begin
  if FProcItems.TryGetValue(AFileName, lbi) then
    lbi.Index := gfQueueCount.Index;
end;

procedure TfrmPy4DEB.cbPollingChange(Sender: TObject);
begin
FTHPollFolder.EnablePolling(cbPolling.IsChecked)
  end;

procedure TfrmPy4DEB.cbPubDebEventChange(Sender: TObject);
var
  levt: IPubDebEvent;
begin
  levt := TPubDebEvent.Create;
  levt.PubDebEvent := cbPubDebEvent.IsChecked;
  GlobalEventBus.Post(levt);
end;

procedure TfrmPy4DEB.cbPyEngineChange(Sender: TObject);
var
  lp: IEnablePolling;
begin
  lp := TEnablePolling.Create;
  lp.Enabled := cbPyEngine.IsChecked;
  GlobalEventBus.Post(lp, ctx_ItemWorker);
end;

procedure TfrmPy4DEB.cbStatsChange(Sender: TObject);
var
  lp: IEnablePolling;
begin
  lp := TEnablePolling.Create;
  lp.Enabled := cbStats.IsChecked;
  GlobalEventBus.Post(lp, ctx_StatsWorker);
end;

procedure TfrmPy4DEB.FormCreate(Sender: TObject);
begin
  // Order matters here, because I want the form to get the event first
  GlobalEventBus.RegisterSubscriberForChannels(self);
  GlobalEventBus.RegisterSubscriberForEvents(self);
  // you either have rules in the engine or ability to re-order
  // I want this event to be first subscriber
  // I want this event to be before X subscriber if present
  // If X subscriber registers later I want to remain first
  FTHPollFolder := TFSPollFolder.Create();
  FTHPollFolder.Start;
  FThIW := TItemWorkerThread.Create();
  FThIW.Start;
  FThStats := TAppStatsThread.Create();
  FThStats.Start;

  FProcItems := TDictionary<string, TListBoxItem>.Create;
  InitChart;
end;

procedure TfrmPy4DEB.FormDestroy(Sender: TObject);
begin
  FTHPollFolder.Free;
  FThIW.Free;
  FThStats.Free;
  FProcItems.Free;
end;

procedure TfrmPy4DEB.InitChart;
begin
  chart.BeginUpdate;
  chart.Series[0].points.clear;
  chart.Series[1].points.clear;
  chart.EndUpdate;
end;

procedure TfrmPy4DEB.OnFileEnQueue(AEvent: IOnFileProcessed);
begin
  ProcItemMoveQueue(AEvent.FileName);
end;

procedure TfrmPy4DEB.OnFileFound(amsg: String);
begin
  // Memo1.lines.Add(amsg);
end;

procedure TfrmPy4DEB.OnFileFoundEvent(AEvent: IDEBEvent<TOnFileFound>);
begin
  // Memo1.lines.Add('FF ' + AEvent.FileName);
  ProcItemAdd(AEvent.Data.FileName);
end;

procedure TfrmPy4DEB.OnFileFoundEventCustom(AEvent: IOnFileFound);
begin
  ProcItemAdd(AEvent.FileName);
end;

procedure TfrmPy4DEB.OnFileProcessed(AEvent: IOnFileProcessed);
begin
  // Memo2.lines.Add('FP ' + AEvent.FileName);
  ProcItemMoveProcessed(AEvent.FileName);
end;

procedure TfrmPy4DEB.OnPyMsgFound(amsg: String);
begin
  // Memo2.lines.Add('PyMsg: ' + amsg);
end;

procedure TfrmPy4DEB.OnPyProcMsg(amsg: String);
begin
  // Memo2.lines.Add('ProcMsg : ' + amsg);
end;

procedure TfrmPy4DEB.OnStatThreadCount(AEvent: IOnProcStat);
begin
  chart.Series[0].AddPoint(AEvent.ThreadCount);
  chart.Series[1].AddPoint(AEvent.QueueLength);
end;

procedure TfrmPy4DEB.OnWorkQueuePanic(amsg: String);
begin
  // Memo2.lines.Add('Panic' + amsg);
end;

procedure TfrmPy4DEB.OnWorkQueueSize(amsg: String);
begin
  gfQueueCount.Text := amsg + ' Items in Queue';
end;

end.
