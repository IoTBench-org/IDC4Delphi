{
  *****************************************************
  * Free Source Project: IDC4Delphi Components         *
  * Industrial Direct Communications for Delphi        *
  * https://github.com/IoTBench-org/IDC4Delphi         *
  * https://IoTBench.org/IDC4Delphi                    *
  *****************************************************

  Unit Information:
    * Main Section : Industrial Protocols Handling
    * Sub Section  : KNX Protocol (KNXnet/IP) ISO-22510
    * Purpose      : Define KNX telegrams requests objects

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}


unit IDC.Protocols.KNX.Telegrams.Requests;

interface

uses
  System.SysUtils, System.Classes, System.Math
  /// IDC Units
  ,IDC.Global
  ,IDC.Protocols.KNX.Consts
  ,IDC.Protocols.KNX.Telegrams.Records
  ,IDC.Protocols.KNX.Telegrams.Base
  ,IDC.Protocols.KNX.cEMI
  ;

type
  TKnxTelegram_SearchReq = class(TKnxTelegram<TKNXPacket_HPAIEndpoint,TKNXPacket_Empty,TKNXPacket_Empty,TKNXPacket_Empty>)
  protected
    procedure ResetTelegram; override;
  public
    class function CreateTelegram(const IPAddress :TIDCIPv4Addr;
                                  const IPPort    :TIDCIPPort):IKnxTelegram;overload;
    class function CreateTelegram(const IPAddress :string;
                                  const IPPort    :TIDCIPPort):IKnxTelegram;overload;
  end;

  TKnxTelegram_ConnectReq = class(TKnxTelegram<TKNXPacket_HPAIEndpoint,TKNXPacket_HPAIEndpoint,TKNXPacket_CRITunneling,TKNXPacket_Empty>)
  protected
    procedure ResetTelegram; override;
  public
    class function CreateTelegram(const IPAddress :TIDCIPv4Addr;
                                  const IPPort    :TIDCIPPort):IKnxTelegram;overload;
    class function CreateTelegram(const IPAddress :string;
                                  const IPPort    :TIDCIPPort):IKnxTelegram;overload;
  end;

  TKnxTelegram_TunnelReq = class(TKnxTelegram<TKNXPacket_ConnectionHeader,TKNXPacket_cEMI,TKNXPacket_Empty,TKNXPacket_Empty>)
  protected
    procedure ResetTelegram; override;
    procedure HandleData; override;
  public
    ADPU:IKnxAPDUData; //(Application Protocol Data Unit)
    class function CreateTelegram(Channel,Sequence : TIDCByte;
                                  cEMIMessageCode : TIDCByte;
                                  SrcAddress   : TKNXIndividualAddress;
                                  DestAddress  : TKNXGroupAddress;
                                  ValueType    : TIDCByte;
                                  Value        : TIDCByte):IKnxTelegram; overload;
  end;

implementation

{ TKnxTelegram_SearchReq }

class function TKnxTelegram_SearchReq.CreateTelegram(
  const IPAddress: TIDCIPv4Addr; const IPPort: TIDCIPPort): IKnxTelegram;
begin
  Result := TKnxTelegram_SearchReq.Create();
  with TKnxTelegram_SearchReq(Result).Telegram do
  begin
    Header.ServiceIdentifer := KNX_SERVICE_IDENTIFIER_SEARCH_REQUEST;
    CopyIPv4Addr(Section1.IPAddress,IPAddress);
    Section1.IPPort := IPPort;
  end;
end;

class function TKnxTelegram_SearchReq.CreateTelegram(const IPAddress: string;
  const IPPort: TIDCIPPort): IKnxTelegram;

var _IPAddress: TIDCIPv4Addr;
begin
  _IPAddress := StringToIPv4Addr(IPAddress);
  Result := TKnxTelegram_SearchReq.CreateTelegram(_IPAddress,IPPort);

end;

procedure TKnxTelegram_SearchReq.ResetTelegram;
begin
  inherited;
  Telegram.Section1.New;
end;

{ TKnxTelegram_ConnectReq }

class function TKnxTelegram_ConnectReq.CreateTelegram(
  const IPAddress: TIDCIPv4Addr; const IPPort: TIDCIPPort): IKnxTelegram;
begin
  Result := TKnxTelegram_ConnectReq.Create();
  with TKnxTelegram_ConnectReq(Result).Telegram do
  begin
    // Header TKNXPacket_Header
    Header.ServiceIdentifer := KNX_SERVICE_IDENTIFIER_CONNECT_REQUEST;
    // Section1 TKNXPacket_HPAIEndpoint
    CopyIPv4Addr(Section1.IPAddress,IPAddress);
    Section1.IPPort := IPPort;
    // Section2 TKNXPacket_HPAIEndpoint
    CopyIPv4Addr(Section2.IPAddress,IPAddress);
    Section2.IPPort := IPPort;
  end;
end;

class function TKnxTelegram_ConnectReq.CreateTelegram(const IPAddress: string;
  const IPPort: TIDCIPPort): IKnxTelegram;
var _IPAddress: TIDCIPv4Addr;
begin
  _IPAddress := StringToIPv4Addr(IPAddress);
  Result := TKnxTelegram_ConnectReq.CreateTelegram(_IPAddress,IPPort);

end;

procedure TKnxTelegram_ConnectReq.ResetTelegram;
begin
  inherited;
  Telegram.Section1.New;
  Telegram.Section2.New;
  Telegram.Section3.New;

end;

{ TKnxTelegram_TunnelReq }

class function TKnxTelegram_TunnelReq.CreateTelegram(Channel,
  Sequence, cEMIMessageCode: TIDCByte; SrcAddress: TKNXIndividualAddress;
  DestAddress: TKNXGroupAddress; ValueType, Value: TIDCByte): IKnxTelegram;
var ADPUData: TIDCBytes;
    ADPULen: TIDCByte;
begin
  Result := TKnxTelegram_TunnelReq.Create();

  with TKnxTelegram_TunnelReq(Result) do
  begin
    ResetTelegram;
    ADPU := TKnxADPUData.Create;
    ADPU.ValueType := ValueType;
    ADPU.ValueAsByte := Value;
    ADPUData := ADPU.GetBytes(ADPULen);
    LengthCorrection := -SizeOf(Telegram.Section2.APDU) + ADPULen +1;
  end;
  with TKnxTelegram_TunnelReq(Result).Telegram do
  begin
    // Header TKNXPacket_Header
    Header.ServiceIdentifer := KNX_SERVICE_IDENTIFIER_TUNNEL_REQUEST;
    Section1.Channel := Channel;
    Section1.Sequence := Sequence;
    Section1.Status := 0;
    Section2.MessageCode := cEMIMessageCode;
    //Ctrl1: Prio = Low
    //    1... .... = Frame Type: Standard (1)
    //    ..1. .... = Repeat On Error: No
    //    ...1 .... = Broadcast Type: Domain (1)
    //    .... 11.. = Priority: Low (3)
    //    .... ..0. = Ack Wanted: Yes
    //    .... ...0 = Confirmation Error: Yes
    Section2.Ctrl1 := 188; // ToDo: Set Ctrl1 bits
    //Ctrl2: Hops = 6
    //    1... .... = Address Type: Group (1)
    //    .110 .... = Hop Count: 6
    //    .... 0000 = Extended Frame Format: 0x0
    Section2.Ctrl2 := 224; // ToDo: Set Ctrl2 bits
    Section2.SrcAddress := SrcAddress;
    Section2.DestAddress := DestAddress;
    Section2.DataLength := ADPULen;
    Move(ADPUData[0], Section2.APDU[0], Length(ADPUData));
  end;

end;

procedure TKnxTelegram_TunnelReq.HandleData;
var A1: TIDCBytes;
begin
  inherited;
  try
    SetLength(A1,SizeOf(Telegram.Section2.APDU));
    Move(Telegram.Section2.APDU[0], A1[0], Length(A1));
    ADPU := TKnxADPUData.Create;
    ADPU.FillFromBytes(A1,Telegram.Section2.DataLength);
  finally
    SetLength(A1,0);
  end;
end;

procedure TKnxTelegram_TunnelReq.ResetTelegram;
begin
  inherited;
  Telegram.Section1.New;
  Telegram.Section2.New;
end;

end.
