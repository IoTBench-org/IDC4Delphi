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
    * Purpose      : Define KNX telegrams responses objects

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}


unit IDC.Protocols.KNX.Telegrams.Responses;

interface

uses
  System.SysUtils, System.Classes
  /// IDC Units
  ,IDC.Global
  ,IDC.Exceptions
  ,IDC.Protocols.KNX.Consts
  ,IDC.Protocols.KNX.Telegrams.Records
  ,IDC.Protocols.KNX.Telegrams.Base
  ;

type
  TKnxTelegram_SearchResp = class(TKnxTelegram<TKNXPacket_HPAIEndpoint,TKNXPacket_DeviceInformation,TKNXPacket_SupportedServices,TKNXPacket_Empty>)
  protected
    procedure ResetTelegram; override;
  public
  end;

  TKnxTelegram_ConnectResp = class(TKnxTelegram<TKNXPacket_ChannelStatus,TKNXPacket_HPAIEndpoint,TKNXPacket_CRDTunneling,TKNXPacket_Empty>)
  protected
    procedure ResetTelegram; override;
  public
  end;

  TKnxTelegram_TunnelAck = class(TKnxTelegram<TKNXPacket_ConnectionHeader,TKNXPacket_Empty,TKNXPacket_Empty,TKNXPacket_Empty>)
  protected
    procedure ResetTelegram; override;
  public
    class function CreateTelegram(Channel,Sequence,Status : TIDCByte):IKnxTelegram;overload;
  end;

implementation

{ TKnxTelegram_SearchResp }


procedure TKnxTelegram_SearchResp.ResetTelegram;
begin
  inherited;
  Telegram.Section1.New;
  Telegram.Section2.New;
  Telegram.Section3.New;
end;

{ TKnxTelegram_ConnectResp }

procedure TKnxTelegram_ConnectResp.ResetTelegram;
begin
  inherited;
  Telegram.Section1.New;
  Telegram.Section2.New;
  Telegram.Section3.New;

end;

{ TKnxTelegram_TunnelAck }

class function TKnxTelegram_TunnelAck.CreateTelegram(Channel, Sequence,
  Status: TIDCByte): IKnxTelegram;
begin
  Result := TKnxTelegram_TunnelAck.Create();
  TKnxTelegram_TunnelAck(Result).Telegram.Header.ServiceIdentifer := KNX_SERVICE_IDENTIFIER_TUNNEL_ACK;

  // Header TKNXPacket_Header
  TKnxTelegram_TunnelAck(Result).Telegram.Section1.Channel := Channel;
  TKnxTelegram_TunnelAck(Result).Telegram.Section1.Sequence := Sequence;
  TKnxTelegram_TunnelAck(Result).Telegram.Section1.Status := Status;

end;

procedure TKnxTelegram_TunnelAck.ResetTelegram;
begin
  inherited;
  Telegram.Section1.New;
end;

end.
