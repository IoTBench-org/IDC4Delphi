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
    * Purpose      : KNX Telegrams Incoming/Outcoming utils

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}


unit IDC.Protocols.KNX.Telegrams.IO;

interface
uses
  System.SysUtils, System.Classes
  /// IDC Units
  ,IDC.Global
  ,IDC.Exceptions
  ,IDC.Protocols.KNX.Consts
  ,IDC.Protocols.KNX.Telegrams.Records
  ,IDC.Protocols.KNX.Telegrams.Base
  ,IDC.Protocols.KNX.Telegrams.Responses
  ,IDC.Protocols.KNX.Telegrams.Requests
  ;

type
  // KNX Incoming/Outcoming utils
  TKnxIO_Utils = class
  public
    class function CreateIncomingTelegram(const ABytes:TIDCBytes; var ServiceIdentifier: Word):IKnxTelegram;
  end;


implementation

class function TKnxIO_Utils.CreateIncomingTelegram(const ABytes:TIDCBytes; var ServiceIdentifier: Word):IKnxTelegram;
var PacketHeader: TKNXPacket_Header;
begin
  Move(ABytes[0],PacketHeader,SizeOf(PacketHeader));
  ServiceIdentifier := PacketHeader.ServiceIdentifer;
  Result := nil;
  case ServiceIdentifier of
    KNX_SERVICE_IDENTIFIER_SEARCH_RESPONSE :
        Result := TKnxTelegram_SearchResp.Create;
    KNX_SERVICE_IDENTIFIER_CONNECT_RESPONSE :
        Result := TKnxTelegram_ConnectResp.Create;
    KNX_SERVICE_IDENTIFIER_TUNNEL_ACK :
        Result := TKnxTelegram_TunnelAck.Create;
    KNX_SERVICE_IDENTIFIER_TUNNEL_REQUEST :
        Result := TKnxTelegram_TunnelReq.Create;

    else raise EIDC.Create(MS_Protocols,SS_KNX,KNX_Error_ServiceIdentifer_UnRecognized,'Service identifer unrecognized');
  end;
  if Assigned(Result) then
    Result.AsBytes := ABytes;

end;

end.
