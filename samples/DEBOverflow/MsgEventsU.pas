unit MsgEventsU;

interface

uses
  EventBus;

const
  ctx_ItemWorker = 'ItemWorker';
  ctx_StatsWorker = 'StatsWorker';
  ctx_ThreadCountOnly = 'ChnlThreadCountOnly';
  ctx_StatReady = 'ChnlStatReady';

type
  IPubDebEvent = interface
    ['{518AF6C2-7946-4F17-8B49-4D0F65FFDAC9}']
    procedure SetPubDeb(const AValue: Boolean);
    function GetPubDeb: Boolean;
    property PubDebEvent: Boolean read GetPubDeb write SetPubDeb;
  end;

  IEnablePolling = interface
    ['{D8793E27-B1B3-4D27-BAAD-C313B1B9F428}']
    procedure SetEnabled(const AValue: Boolean);
    function GetEnabled: Boolean;
    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;

  IOnFileFound = interface
    ['{51B9CAF2-AA7A-4048-B9C7-7BB75E15D294}']
    procedure SetFileName(const AValue: string);
    function GetFileName: string;
    property FileName: string read GetFileName write SetFileName;
  end;

  IOnFileProcessed = interface(IOnFileFound)
    ['{584EB138-4F08-4D59-AAA1-C16D32F7A70B}']
    procedure SetSuccess(const AValue: Boolean);
    function GetSuccess: Boolean;
    function GetEnQueueTime: TDateTime;
    procedure SetEnQueueTime(const AValue: TDateTime);
    function GetProcessedTime: TDateTime;
    procedure SetProcessedTime(const AValue: TDateTime);
    property Success: Boolean read GetSuccess write SetSuccess;
    property EnQueueTime: TDateTime read GetEnQueueTime write SetEnQueueTime;
    property ProcessedTime: TDateTime read GetProcessedTime write SetProcessedTime;
  end;

  IOnProcStat = interface
    ['{27F9C18D-FD98-4851-AE96-84949B191FF7}']
    function ThreadCount: cardinal;
    function QueueLength: cardinal;
  end;

  TEnablePolling = class(TInterfacedObject, IEnablePolling)
  private
    FEnabled: Boolean;
    procedure SetEnabled(const AValue: Boolean);
    function GetEnabled: Boolean;
  public
    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;

  TPubDebEvent = class(TInterfacedObject, IPubDebEvent)
  private
    FPubDeb: Boolean;
    procedure SetPubDeb(const AValue: Boolean);
    function GetPubDeb: Boolean;
  public
    property PubDebEvent: Boolean read GetPubDeb write SetPubDeb;
  end;

  TOnFileFound = class(TInterfacedObject, IOnFileFound)
  private
    FFileName: string;
    procedure SetFileName(const AValue: string);
    function GetFileName: string;
  public
    property FileName: string read GetFileName write SetFileName;
  end;

  TOnFileProcessed = class(TInterfacedObject, IOnFileProcessed)
  private
    FFileName: string;
    FEnQueueTime, FProcessedTime: TDateTime;
    FSuccess: Boolean;
    procedure SetFileName(const AValue: string);
    function GetFileName: string;
    procedure SetSuccess(const AValue: Boolean);
    function GetSuccess: Boolean;
    function GetEnQueueTime: TDateTime;
    procedure SetEnQueueTime(const AValue: TDateTime);
    function GetProcessedTime: TDateTime;
    procedure SetProcessedTime(const AValue: TDateTime);
  public
    property FileName: string read GetFileName write SetFileName;
    property Success: Boolean read GetSuccess write SetSuccess;
    property EnQueueTime: TDateTime read GetEnQueueTime write SetEnQueueTime;
    property ProcessedTime: TDateTime read GetProcessedTime write SetProcessedTime;
  end;

  TProcStat = class(TInterfacedObject, IOnProcStat)
  private
    FThreadCount, FQueueLength: cardinal;
  public
    procedure SetThreadCount(ACount: cardinal);
    procedure SetQueueLength(ACount: cardinal);
    function ThreadCount: cardinal;
    function QueueLength: cardinal;
  end;

implementation

{ TOnFileFound }

function TOnFileFound.GetFileName: string;
begin
  result := FFileName;
end;

procedure TOnFileFound.SetFileName(const AValue: string);
begin
  FFileName := AValue;
end;

{ TOnFileProcessed }

function TOnFileProcessed.GetEnQueueTime: TDateTime;
begin
  result := FEnQueueTime;
end;

function TOnFileProcessed.GetFileName: string;
begin
  result := FFileName;
end;

function TOnFileProcessed.GetProcessedTime: TDateTime;
begin
  result := FProcessedTime;
end;

function TOnFileProcessed.GetSuccess: Boolean;
begin
  result := FSuccess;
end;

procedure TOnFileProcessed.SetEnQueueTime(const AValue: TDateTime);
begin
  FEnQueueTime := AValue;
end;

procedure TOnFileProcessed.SetFileName(const AValue: string);
begin
  FFileName := AValue
end;

procedure TOnFileProcessed.SetProcessedTime(const AValue: TDateTime);
begin
  FProcessedTime := AValue
end;

procedure TOnFileProcessed.SetSuccess(const AValue: Boolean);
begin
  FSuccess := AValue;
end;

{ TEnablePolling }

function TEnablePolling.GetEnabled: Boolean;
begin
  result := FEnabled;
end;

procedure TEnablePolling.SetEnabled(const AValue: Boolean);
begin
  FEnabled := AValue;
end;

{ TProcStat }

function TProcStat.QueueLength: cardinal;
begin
  result := FQueueLength;
end;

procedure TProcStat.SetQueueLength(ACount: cardinal);
begin
  FQueueLength := ACount;
end;

procedure TProcStat.SetThreadCount(ACount: cardinal);
begin
  FThreadCount := ACount;
end;

function TProcStat.ThreadCount: cardinal;
begin
  result := FThreadCount;
end;

{ TPubDebEvent }

function TPubDebEvent.GetPubDeb: Boolean;
begin
  result := FPubDeb;
end;

procedure TPubDebEvent.SetPubDeb(const AValue: Boolean);
begin
  FPubDeb := AValue;
end;

end.
