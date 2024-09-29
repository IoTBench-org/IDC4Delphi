{
  *****************************************************
  * Free Source Project: IDC4Delphi Components         *
  * Industrial Direct Communications for Delphi        *
  * https://github.com/IoTBench-org/IDC4Delphi         *
  * https://IoTBench.org/IDC4Delphi                    *
  *****************************************************

  Unit Information:
    * Main Section : Drivers
    * Sub Section  : KNX
    * Purpose      : KNXnet/IP Component (Tunnel Mode)
    * Notes:
       --> Don't use any class from here directly unless of creating new driver

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Drivers.KNX;

interface
uses
   {System units}
    System.SysUtils, System.Types, System.Classes
   {IDC units}
   ,IDC.Global, IDC.Exceptions, IDC.Drivers.Base.UDP, IDC.Threads
   {IDC KNX units}
   ,IDC.Protocols.KNX.Consts
   ,IDC.Protocols.KNX.Telegrams.Base
   ,IDC.Protocols.KNX.Telegrams.Responses
   ,IDC.Protocols.KNX.Telegrams.Requests
   ,IDC.Protocols.KNX.Telegrams.IO
   ;

type
  TIDCCustomKNXDriver = class;
  TKNXIPRouterDevice = class;


  TKNXDataTypes = (knxDataRequest,         // KNX_cEMI_MESSAGE_CODE_L_DATA_REQ       = $11;  // L_Data.req      // Request for data transmission
                   knxDataConfirmation,    // KNX_cEMI_MESSAGE_CODE_L_DATA_CON       = $2E;  // L_Data.con      // Confirmation of data transmission
                   knxDataIndication       // KNX_cEMI_MESSAGE_CODE_L_DATA_IND       = $29;  // L_Data.ind      // Indication of incoming data
                   );

  TKNXGroupValueType = (knxGroupRead,      // KNX_VALUE_TYPE_GROUP_VALUE_READ            = $00;  // GroupValueRead
                        knxGroupResponse,  // KNX_VALUE_TYPE_GROUP_VALUE_RESPONSE        = $01;  // GroupValueResponse
                        knxGroupWrite      // KNX_VALUE_TYPE_GROUP_VALUE_WRITE           = $02;  // GroupValueWrite
                        );

  TKNXGroupAddressEvent = procedure(Driver: TIDCCustomKNXDriver;
                                   DataType: TKNXDataTypes;
                                   GroupValueType: TKNXGroupValueType;
                                   const GroupAddress, IndividualAddress: string;
                                   const AData: TIDCBytes) of object;

  TKNXDeviceFoundEvent = procedure(Driver:  TIDCCustomKNXDriver;
                                   IPRouter: TKNXIPRouterDevice;
                                   var AutoConnect: boolean) of object;

  TKNXDeviceConnectedEvent = procedure(Driver:  TIDCCustomKNXDriver;
                                       IPRouter: TKNXIPRouterDevice;
                                       const ConnectedChannel:Word ) of object;

  TKNXIPRouterDevice = class(TObject)
  private
    FDriver : TIDCCustomKNXDriver;
  public
    IndividualAddress,
    MulticastAddress,
    IPAddress,
    MACAddress,
    FriendlyName : string;
  end;

  TIDCKNXConnectionOptions = class (TIDCUDPConnectionOptions)
  private
    FDiscoveryTimeout : integer;
  public
    procedure AfterConstruction; override;
  published
    property DiscoveryTimeout : integer read FDiscoveryTimeout write FDiscoveryTimeout;
  end;

  TIDCCustomKNXDriver = class(TIDCUDPDriverBase<TIDCKNXConnectionOptions>)
  private
    // Local objects
    FKNXDiscoveryTimer: TIDCTimerThread;

    //
    FCurrentIPIndex:  Integer;
    FCurrentIPRouter:TKNXIPRouterDevice;
    FCurrentTunnelChannel:Word;

    /// Events
    FOnKNXDeviceFound: TKNXDeviceFoundEvent;
    FOnKNXDeviceConnected: TKNXDeviceConnectedEvent;

    procedure OnKNXDiscoveryTimer;
    procedure SendKNXTelegram(Telegram:IKnxTelegram);
    procedure ProcessKNXTelegram(const AData: TIDCBytes);

    // KNX Incoming Handlers
    procedure HandleIncoming_SearchResp(KnxResponse : TKnxTelegram_SearchResp);
    procedure HandleIncoming_ConnectResp(KnxResponse : TKnxTelegram_ConnectResp);

    // KNX Outgoing Handlers
    procedure HandleOutgoing_SearchRequest(const SenderIP:string);
    procedure HandleOutgoing_ConnectRequest(const SenderIP:string);

  protected
    procedure SetActive(const Value: boolean); override;
    procedure HandleIncomingUDPData(const AData: TIDCBytes);override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure WriteBytesToGroupAddress(const DestAddress:string;
                                       const Value : TIDCBytes);
    procedure StartKNXDiscovery;
    procedure StopKNXDiscovery;

    property OnKNXDeviceFound: TKNXDeviceFoundEvent read FOnKNXDeviceFound write FOnKNXDeviceFound;
    property OnKNXDeviceConnected: TKNXDeviceConnectedEvent read FOnKNXDeviceConnected write FOnKNXDeviceConnected;
  end;

  TIDCKNXDriver = class(TIDCCustomKNXDriver);

implementation

{ TIDCKNXConnectionOptions }

procedure TIDCKNXConnectionOptions.AfterConstruction;
begin
  inherited;
  FServerAddress := KNX_MULTICAST_ADDRESS;
  FServerPort    := KNX_DEFAULT_PORT;
  FDiscoveryTimeout  := 3000;
end;

{ TIDCKNXDriver }

procedure TIDCCustomKNXDriver.AfterConstruction;
begin
  inherited;
  FCurrentIPIndex := -1;
  FCurrentIPRouter :=TKNXIPRouterDevice.Create;
end;

procedure TIDCCustomKNXDriver.BeforeDestruction;
begin
  StopKNXDiscovery; // Keep it to stop and destroy it before destroy anything
  inherited;
  FreeAndNil(FCurrentIPRouter);
end;

procedure TIDCCustomKNXDriver.HandleIncomingUDPData(const AData: TIDCBytes);
begin
  if ThreadedEvents then
    ProcessKNXTelegram(AData)
  else
    FMessagingThread.Synchronize(
    procedure
    begin
      ProcessKNXTelegram(AData)
    end);
end;

procedure TIDCCustomKNXDriver.HandleIncoming_ConnectResp(
  KnxResponse: TKnxTelegram_ConnectResp);
begin
  FCurrentTunnelChannel := KnxResponse.Telegram.Section1.Channel;
  if Assigned(FOnKNXDeviceFound) then
    FOnKNXDeviceConnected(Self,FCurrentIPRouter,FCurrentTunnelChannel);
end;

procedure TIDCCustomKNXDriver.HandleIncoming_SearchResp(
  KnxResponse: TKnxTelegram_SearchResp);
var AutoConnect:boolean;
begin
  StopKNXDiscovery;

  FCurrentIPRouter.FDriver := Self;
  FCurrentIPRouter.IndividualAddress := KnxResponse.Telegram.Section2.IndividualAddress.AsString;
  FCurrentIPRouter.MulticastAddress := IPv4AddrToString(KnxResponse.Telegram.Section2.MulticastAddress);
//  FCurrentIPRouter.IPAddress := KnxResponse.Telegram.Section2..AsString;  // ToDO: Get from UDP packet
  FCurrentIPRouter.MACAddress := MacAddrToString(KnxResponse.Telegram.Section2.MACAddress);
  FCurrentIPRouter.FriendlyName := KnxResponse.Telegram.Section2.FriendlyName;
  AutoConnect := True;
  if Assigned(FOnKNXDeviceFound) then
    FOnKNXDeviceFound(Self,FCurrentIPRouter,AutoConnect);
  if AutoConnect then
    HandleOutgoing_ConnectRequest(BindingIPs[FCurrentIPIndex]);
end;

procedure TIDCCustomKNXDriver.OnKNXDiscoveryTimer;
begin
  Inc(FCurrentIPIndex);
  if FCurrentIPIndex >= length(BindingIPs) then FCurrentIPIndex := 0;
  HandleOutgoing_SearchRequest(BindingIPs[FCurrentIPIndex]);
end;

procedure TIDCCustomKNXDriver.ProcessKNXTelegram(const AData: TIDCBytes);
var
  ServiceIdentifer:word;
  KnxResponse : IKnxTelegram;
begin
  try
    KnxResponse := TKnxIO_Utils.CreateIncomingTelegram(TIDCBytes(AData),ServiceIdentifer);
    case ServiceIdentifer of
      ///////// Responses
      KNX_SERVICE_IDENTIFIER_SEARCH_RESPONSE :
        HandleIncoming_SearchResp(TKnxTelegram_SearchResp(KnxResponse));

      KNX_SERVICE_IDENTIFIER_CONNECT_RESPONSE :
        HandleIncoming_ConnectResp(TKnxTelegram_ConnectResp(KnxResponse));
//
//      KNX_SERVICE_IDENTIFIER_TUNNEL_ACK :
//        Handle_TunnelAck(TKnxTelegram_TunnelAck(KnxResponse));
//
//      //////// Requests
//      KNX_SERVICE_IDENTIFIER_TUNNEL_REQUEST :
//        Handle_TunnelReq(TKnxTelegram_TunnelReq(KnxResponse));
    end;
  except
    on E: Exception do ;// ToDo
  end;

end;

procedure TIDCCustomKNXDriver.HandleOutgoing_SearchRequest(const SenderIP:string);
var
  KnxRequest: IKnxTelegram;
begin
  KnxRequest := TKnxTelegram_SearchReq.CreateTelegram(SenderIP{Sender ip address},LocalPort {Sender udp port});
  SendKNXTelegram(KnxRequest);
end;

procedure TIDCCustomKNXDriver.HandleOutgoing_ConnectRequest(
  const SenderIP: string);
var
  KnxRequest: IKnxTelegram;
begin
  KnxRequest := TKnxTelegram_ConnectReq.CreateTelegram(SenderIP{Sender ip address},LocalPort {Sender udp port});
  SendKNXTelegram(KnxRequest);
end;

procedure TIDCCustomKNXDriver.SendKNXTelegram(Telegram: IKnxTelegram);
var
  Bytes: TIDCBytes;
begin
  try
    Bytes := Telegram.AsBytes;
    SendUDPData(Bytes);
  finally
    setlength(Bytes,0);
  end;
end;

procedure TIDCCustomKNXDriver.SetActive(const Value: boolean);
begin
  if FActive <> Value then
  begin

  end; // Set FActive to value is inside inherited
  inherited; // Must be on last line
end;

procedure TIDCCustomKNXDriver.StartKNXDiscovery;
begin

  StopKNXDiscovery;
  Active := True;
  FCurrentIPIndex := 0;
  FKNXDiscoveryTimer := TIDCTimerThread.Create(OnKNXDiscoveryTimer,1000);
  FKNXDiscoveryTimer.StartTimer;
end;

procedure TIDCCustomKNXDriver.StopKNXDiscovery;
begin
  if Assigned(FKNXDiscoveryTimer) then
    FreeAndNil(FKNXDiscoveryTimer);
end;

procedure TIDCCustomKNXDriver.WriteBytesToGroupAddress(const DestAddress: string;
  const Value: TIDCBytes);
begin

end;

end.