{
  *****************************************************
  * Free Source Project: IDC4Delphi Components         *
  * Industrial Direct Communications for Delphi        *
  * https://github.com/IoTBench-org/IDC4Delphi         *
  * https://IoTBench.org/IDC4Delphi                    *
  *****************************************************

  Unit Information:
    * Main Section : Drivers
    * Sub Section  : -
    * Purpose      : Base types and procedure for drivers (Endpoint protocols)
    * Notes:
       --> Don't use any class from here directly unless of creating new driver

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Drivers.Base;

interface

uses  System.SysUtils, System.Classes
     ,IDC.Exceptions
     ,IDC.Global
     ,IDC.Threads;

type
  TIDCConnectionOptions = class(TObject);

  TIDCMessagingQueueThread<T> = class(TIDCQueueThread<T>);

  TIDCDriverBase<TCO: constructor,TIDCConnectionOptions;DataPointer> = class abstract (TComponent)
  private
    FThreadedEvents:Boolean;
  protected
    FConnectionOptions : TCO;
    FMessagingThread : TIDCMessagingQueueThread<DataPointer>;
    FActive: boolean;
    function GetDriverName: string; virtual; abstract;
    function IsDesignTime: Boolean;
    function IsLoading: Boolean;
    function IsNormalMode: Boolean;
    procedure SetActive(const Value: boolean); virtual; abstract;
    procedure ConsumeMessagingThreadData(Obj:DataPointer); virtual; abstract;
    procedure FreeMessagingThreadData(Obj:DataPointer); virtual; abstract;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property DriverName: string read GetDriverName;
    property ConnectionOptions: TCO read FConnectionOptions;
    property WorkerThread: TIDCMessagingQueueThread<DataPointer> read FMessagingThread;
    property Active : boolean read FActive write SetActive;
    property ThreadedEvents : boolean read FThreadedEvents write FThreadedEvents default false;
  end;


implementation

{ TIDCDriverBase<TCO,TWO> }

procedure TIDCDriverBase<TCO,DataPointer>.AfterConstruction;
begin
  inherited;
  FThreadedEvents := False;
  FMessagingThread := TIDCMessagingQueueThread<DataPointer>.Create(ConsumeMessagingThreadData,FreeMessagingThreadData);
  FConnectionOptions := TCO.create;

  if IsNormalMode then
    FMessagingThread.Start;
end;

procedure TIDCDriverBase<TCO,DataPointer>.BeforeDestruction;
begin
  inherited;
  FreeAndNil(FMessagingThread);
  FreeAndNil(FConnectionOptions);
end;

function TIDCDriverBase<TCO,DataPointer>.IsDesignTime: Boolean;
begin
  Result := (csDesigning in ComponentState);
end;

function TIDCDriverBase<TCO,DataPointer>.IsLoading: Boolean;
begin
  Result := (csLoading in ComponentState);
end;

function TIDCDriverBase<TCO,DataPointer>.IsNormalMode: Boolean;
begin
  Result := (not IsDesignTime) and (not IsLoading);
end;

end.
