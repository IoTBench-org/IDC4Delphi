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

  Unit Online Documentation
  https://docs.iotbench.org/idc4delphi/code-ref/drivers-components/TIDCKNXDriver
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
   ,IDC.Protocols.KNX.Telegrams.Records
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
    FInternalSendSequence:byte;

    /// Events
    FOnKNXDeviceFound: TKNXDeviceFoundEvent;
    FOnKNXDeviceConnected: TKNXDeviceConnectedEvent;
    FOnKNXGroupAddressEvent: TKNXGroupAddressEvent;

    procedure OnKNXDiscoveryTimer;
    procedure SendKNXTelegram(Telegram:IKnxTelegram);
    procedure ProcessKNXTelegram(const AData: TIDCBytes);

    // KNX Incoming Handlers
    procedure HandleIncoming_SearchResp(KnxResponse : TKnxTelegram_SearchResp);
    procedure HandleIncoming_ConnectResp(KnxResponse : TKnxTelegram_ConnectResp);
    procedure HandleIncoming_TunnelAck(KnxResponse : TKnxTelegram_TunnelAck);
    procedure HandleIncoming_TunnelReq(KnxRequest : TKnxTelegram_TunnelReq);

    // KNX Outgoing Handlers
    procedure HandleOutgoing_SearchRequest(const SenderIP:string);
    procedure HandleOutgoing_ConnectRequest(const SenderIP:string);
    procedure HandleOutgoing_TunnelAck(Channel, Sequence, Status: TIDCByte);

  protected
    procedure SetActive(const Value: boolean); override;
    procedure HandleIncomingUDPData(const AData: TIDCBytes);override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure ReadBytesFromGroupAddress(const ADestAddress:string);

    procedure WriteBytesToGroupAddress(const ADestAddress:string;
                                       const Value : TIDCBytes);

    procedure StartKNXDiscovery;
    procedure StopKNXDiscovery;

    property OnKNXDeviceFound: TKNXDeviceFoundEvent read FOnKNXDeviceFound write FOnKNXDeviceFound;
    property OnKNXDeviceConnected: TKNXDeviceConnectedEvent read FOnKNXDeviceConnected write FOnKNXDeviceConnected;
    property OnKNXGroupAddressEvent: TKNXGroupAddressEvent read FOnKNXGroupAddressEvent write FOnKNXGroupAddressEvent;
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
  FInternalSendSequence:=0;
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

procedure TIDCCustomKNXDriver.HandleIncoming_TunnelAck(
  KnxResponse: TKnxTelegram_TunnelAck);
begin
  // ToDo
end;

procedure TIDCCustomKNXDriver.HandleIncoming_TunnelReq(
  KnxRequest: TKnxTelegram_TunnelReq);
var
  DataType: TKNXDataTypes;
  GroupValueType: TKNXGroupValueType;
  Data: TIDCBytes;

begin
  if Assigned(OnKNXGroupAddressEvent) then
  begin
    case KnxRequest.Telegram.Section2.MessageCode of
      KNX_cEMI_MESSAGE_CODE_L_DATA_REQ : DataType := knxDataRequest;
      KNX_cEMI_MESSAGE_CODE_L_DATA_CON : DataType := knxDataConfirmation;
      KNX_cEMI_MESSAGE_CODE_L_DATA_IND : DataType := knxDataIndication;
    end;

    case KnxRequest.ADPU.ValueType of
      KNX_VALUE_TYPE_GROUP_VALUE_READ : GroupValueType := knxGroupRead;
      KNX_VALUE_TYPE_GROUP_VALUE_RESPONSE : GroupValueType := knxGroupResponse;
      KNX_VALUE_TYPE_GROUP_VALUE_WRITE : GroupValueType := knxGroupWrite;
    end;

    setlength(Data,1);
    Data[0] := KnxRequest.ADPU.ValueAsByte;
    OnKNXGroupAddressEvent(Self,DataType,GroupValueType,
                           KnxRequest.Telegram.Section2.DestAddress.AsString,
                           KnxRequest.Telegram.Section2.SrcAddress.AsString,
                           Data);
  end;
  HandleOutgoing_TunnelAck(KnxRequest.Telegram.Section1.Channel,
                           KnxRequest.Telegram.Section1.Sequence,
                           KNX_STATUS_OK  );
end;

procedure TIDCCustomKNXDriver.OnKNXDiscoveryTimer;
begin
  Inc(FCurrentIPIndex);
  if FCurrentIPIndex >= length(BindingIPs) then FCurrentIPIndex := 0;
  RestartUDPServer;

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

      KNX_SERVICE_IDENTIFIER_TUNNEL_ACK :
        HandleIncoming_TunnelAck(TKnxTelegram_TunnelAck(KnxResponse));
//
//      //////// Requests
      KNX_SERVICE_IDENTIFIER_TUNNEL_REQUEST :
        HandleIncoming_TunnelReq(TKnxTelegram_TunnelReq(KnxResponse));
    end;
  except
    on E: Exception do ;// ToDo
  end;

end;

procedure TIDCCustomKNXDriver.ReadBytesFromGroupAddress(
  const ADestAddress: string);
var
  KnxRequest: IKnxTelegram;
  SrcAddress: TKNXIndividualAddress;
  DestAddress: TKNXGroupAddress;
begin
  SrcAddress.AsString := KNX_DEFAULT_INDIVIDUAL_ADDRESS;
  DestAddress.AsString := ADestAddress;
  inc(FInternalSendSequence);
  KnxRequest := TKnxTelegram_TunnelReq.CreateTelegram(
                                       FCurrentTunnelChannel,FInternalSendSequence,
                                       KNX_cEMI_MESSAGE_CODE_L_DATA_REQ,
                                       SrcAddress,DestAddress,
                                       KNX_VALUE_TYPE_GROUP_VALUE_READ,
                                       0);

  if FInternalSendSequence>254 then FInternalSendSequence := 0;
  SendKNXTelegram(KnxRequest);
end;

procedure TIDCCustomKNXDriver.HandleOutgoing_SearchRequest(const SenderIP:string);
var
  KnxRequest: IKnxTelegram;
begin
  KnxRequest := TKnxTelegram_SearchReq.CreateTelegram(SenderIP{Sender ip address},LocalPort {Sender udp port});
  SendKNXTelegram(KnxRequest);
end;

procedure TIDCCustomKNXDriver.HandleOutgoing_TunnelAck(Channel, Sequence,
  Status: TIDCByte);
var
  KnxAck: IKnxTelegram;
begin
  KnxAck := TKnxTelegram_TunnelAck.CreateTelegram(Channel,Sequence,Status);
  SendKNXTelegram(KnxAck);
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

procedure TIDCCustomKNXDriver.WriteBytesToGroupAddress(const ADestAddress: string;
  const Value: TIDCBytes);
var
  KnxRequest: IKnxTelegram;
  SrcAddress: TKNXIndividualAddress;
  DestAddress: TKNXGroupAddress;
begin
  SrcAddress.AsString := KNX_DEFAULT_INDIVIDUAL_ADDRESS;
  DestAddress.AsString := ADestAddress;
  inc(FInternalSendSequence);
  KnxRequest := TKnxTelegram_TunnelReq.CreateTelegram(
                                       FCurrentTunnelChannel,FInternalSendSequence,
                                       KNX_cEMI_MESSAGE_CODE_L_DATA_REQ,
                                       SrcAddress,DestAddress,
                                       KNX_VALUE_TYPE_GROUP_VALUE_WRITE,
                                       Value[0]);

  if FInternalSendSequence>254 then FInternalSendSequence := 0;
  SendKNXTelegram(KnxRequest);
end;

end.
