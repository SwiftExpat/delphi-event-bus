unit ThreadFSPollFolder;

interface

uses
  System.Classes, EventBus, MsgEventsU;

type
  TFSPollFolder = class(TThread)
  private
    FIterations, FIteration: cardinal;
    FPollEnabled, FPubDebEvent: boolean;
  protected
    procedure Execute; override;
  public
    [Subscribe(TThreadMode.Background, 'FSPoll')]
    procedure OnEnablePolling(AEvent: IEnablePolling);
    [Subscribe(TThreadMode.Background)]
    procedure OnPubDebEvent(AEvent: IPubDebEvent);
    procedure EnablePolling(AEnabled: boolean);

    destructor Destroy; override;
    constructor Create;
  end;

implementation

uses System.SysUtils;

{ TFSPollFolder }

constructor TFSPollFolder.Create;
begin
  inherited Create(true);
  FPollEnabled := false;
  GlobalEventBus.RegisterSubscriberForEvents(self);
end;

destructor TFSPollFolder.Destroy;
begin

  inherited;
end;

procedure TFSPollFolder.EnablePolling(AEnabled: boolean);
begin
  FPollEnabled := AEnabled;
end;

procedure TFSPollFolder.Execute;
var
  lff: IOnFileFound;
  lfo: TOnFileFound;
  levt: IDEBEvent<TOnFileFound>;
  ft: string;
begin
  NameThreadForDebugging('FSPollFolder');
  FIterations := 2;
  FIteration := 0;
  while not Terminated do
  begin
    if (FIteration = FIterations) and FPollEnabled then
    begin
      DateTimeToString(ft, 'hh:nn:ss zzz', Now);
      if FPubDebEvent then
      begin
        lfo := TOnFileFound.Create;
        lfo.FileName := 'File ' + ft;
        levt := TDEBEvent<TOnFileFound>.Create(lfo);
        GlobalEventBus.Post(levt);
      end
      else
      begin
        lff := TOnFileFound.Create;
        lff.FileName := 'File ' + ft;
        GlobalEventBus.Post(lff);
      end;
      FIteration := 0;
    end
    else if FIteration <= FIterations then
      Inc(FIteration)
    else
      FIteration := 0;

    sleep(50);
  end;
end;

procedure TFSPollFolder.OnEnablePolling(AEvent: IEnablePolling);
begin
  FPollEnabled := AEvent.Enabled;
end;

procedure TFSPollFolder.OnPubDebEvent(AEvent: IPubDebEvent);
begin
  FPubDebEvent := AEvent.PubDebEvent;
end;

end.
