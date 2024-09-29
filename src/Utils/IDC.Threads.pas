{
  *****************************************************
  * Free Source Project: IDC4Delphi Components         *
  * Industrial Direct Communications for Delphi        *
  * https://github.com/IoTBench-org/IDC4Delphi         *
  * https://IoTBench.org/IDC4Delphi                    *
  *****************************************************

  Unit Information:
    * Purpose      : Provides thread and queue thread functionality.
    * Notes:
       --> Implements a generic queue-based thread with consumer and destroyer
           functions for processing items and cleaning up resources.

    Initial Author:
      * Shadi Ajam (https://github.com/shadiajam)

    License:
      * This project is open-source and free to use. You are encouraged to
        contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Threads;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.Types;

type
  // Base thread class with shutdown event handling
  TIDCThread = class(TThread)
  private
    FShutdownEvent: THandle;
  public
    constructor Create; reintroduce; overload;
    constructor Create(CreateSuspended: Boolean); reintroduce; overload;
    procedure Terminate; reintroduce; virtual;
    destructor Destroy; override;

    // Waits for AEvent to trigger or the shutdown event
    function WaitForExactEvent(AEvent: THandle; Timeout: Cardinal = INFINITE): Boolean;
    function WaitForTimeout(Timeout: Cardinal = INFINITE): Boolean;
  end;

  // Generic queue-based thread for processing and cleaning up items
  TIDCQueueThread<T> = class(TIDCThread)
  private
    FQueue: TThreadList<T>;
    FConsumerProc: TProc<T>;
    FDestoryerProc: TProc<T>;
    FQueueEvent: THandle;
  protected
    procedure Execute; override;
    procedure ClearQueue;
    function GetNextItem(out Item: T): Boolean;
  public
    constructor Create(AConsumerProc: TProc<T>; ADestoryerProc: TProc<T>); reintroduce; overload;
    destructor Destroy; override;
    procedure AddToQueue(const Item: T);
  end;

  // Timer-based thread class that performs tasks at regular intervals
  TIDCTimerThread = class(TIDCThread)
  private
    FInterval: Cardinal;       // Timer interval in milliseconds
    FTaskProc: TProc;          // Task to perform at each interval
  protected
    procedure Execute; override;
  public
    constructor Create(ATaskProc: TProc; AInterval: Cardinal); reintroduce;
    destructor Destroy; override;

    procedure StartTimer;
    procedure StopTimer;

    // Property to set or get the interval of the timer in milliseconds
    property Interval: Cardinal read FInterval write FInterval;
  end;

implementation

uses
  WinApi.Windows;

var
  IDCRunningThreads: TThreadList;

{ TIDCThread }

constructor TIDCThread.Create;
begin
  Create(False);
end;

constructor TIDCThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FShutdownEvent := CreateEvent(nil, True, False, nil); // Manual-reset shutdown event
  IDCRunningThreads.Add(Self);
end;

destructor TIDCThread.Destroy;
begin
  Terminate;
  WaitFor;
  CloseHandle(FShutdownEvent); // Clean up the shutdown event handle
  IDCRunningThreads.Remove(Self);
  inherited Destroy;
end;

procedure TIDCThread.Terminate;
begin
  SetEvent(FShutdownEvent); // Trigger shutdown event
  inherited Terminate;
end;

// Waits for either the AEvent or the shutdown event to trigger
function TIDCThread.WaitForExactEvent(AEvent: THandle; Timeout: Cardinal): Boolean;
var
  Events: array[0..1] of THandle;
begin
  Events[0] := AEvent;
  Events[1] := FShutdownEvent;
  Result := WaitForMultipleObjects(2, @Events[0], False, Timeout) = WAIT_OBJECT_0;
end;

function TIDCThread.WaitForTimeout(Timeout: Cardinal): Boolean;
begin
  Result := WaitForSingleObject(FShutdownEvent, Timeout) = WAIT_TIMEOUT;

end;

{ TIDCQueueThread<T> }

// Clears all items in the queue using the destroyer procedure
procedure TIDCQueueThread<T>.ClearQueue;
var
  QueueList: TList<T>;
  Item: T;
begin
  QueueList := FQueue.LockList;
  try
    while QueueList.Count > 0 do
    begin
      Item := QueueList.First;
      if Assigned(FDestoryerProc) then
        FDestoryerProc(Item);
      QueueList.Delete(0);
    end;
  finally
    FQueue.UnlockList;
  end;
end;

constructor TIDCQueueThread<T>.Create(AConsumerProc: TProc<T>; ADestoryerProc: TProc<T>);
begin
  inherited Create(True);
  FQueue := TThreadList<T>.Create;
  FConsumerProc := AConsumerProc;
  FDestoryerProc := ADestoryerProc;
  FQueueEvent := CreateEvent(nil, False, False, nil); // Auto-reset event
end;

destructor TIDCQueueThread<T>.Destroy;
begin
  CloseHandle(FQueueEvent); // Free event handle
  ClearQueue;
  FreeAndNil(FQueue);
  inherited;
end;

// Adds a new item to the queue and signals the queue event
procedure TIDCQueueThread<T>.AddToQueue(const Item: T);
var
  QueueList: TList<T>;
begin
  QueueList := FQueue.LockList;
  try
    QueueList.Add(Item);
    SetEvent(FQueueEvent); // Trigger queue event
  finally
    FQueue.UnlockList;
  end;
end;

// Retrieves the next item from the queue if available
function TIDCQueueThread<T>.GetNextItem(out Item: T): Boolean;
var
  QueueList: TList<T>;
begin
  Result := False;
  QueueList := FQueue.LockList;
  try
    if QueueList.Count > 0 then
    begin
      Item := QueueList.First;
      QueueList.Delete(0);
      Result := True;
    end;
  finally
    FQueue.UnlockList;
  end;
end;

procedure TIDCQueueThread<T>.Execute;
var
  Item: T;
  Found: Boolean;
begin
  while not Terminated do
  begin
    Found := GetNextItem(Item);
    if Found then
    begin
      if Assigned(FConsumerProc) then FConsumerProc(Item);
      if Assigned(FDestoryerProc) then FDestoryerProc(Item);
    end
    else
    begin
      // Wait for either the queue event or shutdown event
      if not WaitForExactEvent(FQueueEvent) then
        Break;
    end;
  end;
end;

{ TIDCTimerThread }

constructor TIDCTimerThread.Create(ATaskProc: TProc; AInterval: Cardinal);
begin
  inherited Create(True);
  FInterval := AInterval;
  FTaskProc := ATaskProc;
end;

destructor TIDCTimerThread.Destroy;
begin
  StopTimer;
  inherited Destroy;
end;

procedure TIDCTimerThread.Execute;
begin
  while not Terminated do
  begin
    if Assigned(FTaskProc) then
      FTaskProc;

    if not WaitForTimeout(FInterval) then
      Break;
  end;
end;

procedure TIDCTimerThread.StartTimer;
begin
  if Suspended then
    Start;
end;

procedure TIDCTimerThread.StopTimer;
begin
  Terminate;  // Signal the shutdown event via the inherited Terminate method
  WaitFor;    // Wait for the thread to finish executing
end;

initialization
  IDCRunningThreads := TThreadList.Create;

finalization
  IDCRunningThreads.Free;

end.

