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
    * Purpose      : Define KNX telegrams base objects

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Protocols.KNX.Telegrams.Base;

interface

uses
  System.SysUtils, System.Classes,Math
  /// IDC Units
  ,IDC.Global
  ,IDC.Protocols.KNX.Consts
  ,IDC.Protocols.KNX.Telegrams.Records
  ,IDC.Exceptions
  ;

const
  KNX_Error_HeaderLength_Zero = 01;
  KNX_Error_ServiceIdentifer_Zero = 02;
  KNX_Error_ProtocolVersion_Zero = 03;
  KNX_Error_ServiceIdentifer_UnRecognized = 04;

type
  IKnxTelegram = interface(IInterface)
    function GetBytes: TIDCBytes;
    procedure SetBytes(const ABytes:TIDCBytes);
    property AsBytes: TIDCBytes read GetBytes write SetBytes;
  end;

  TKnxTelegram<T1,T2,T3,T4> = class(TInterfacedObject,IKnxTelegram)
  protected
    LengthCorrection : integer;

    function GetBytes: TIDCBytes; virtual;
    procedure SetBytes(const ABytes:TIDCBytes); virtual;
    procedure AssertTelegramData;
    procedure ResetTelegram; virtual;
    procedure AdjustTelegramSize(const ABytes:TIDCBytes); virtual;

    procedure HandleData; virtual;
  public
    Telegram : TKNXPacket_Base<T1,T2,T3,T4>;
    procedure BeforeDestruction; override;
    procedure AfterConstruction; override;
  end;

implementation

{ TIDCKnxTelegram<Section1, Section2, Section3, Section4> }


procedure TKnxTelegram<T1, T2, T3, T4>.AdjustTelegramSize(
  const ABytes: TIDCBytes);
begin

end;

procedure TKnxTelegram<T1, T2, T3, T4>.AfterConstruction;
begin
  inherited;
  ResetTelegram;
end;

procedure TKnxTelegram<T1, T2, T3, T4>.AssertTelegramData;
begin
  if Telegram.Header.HeaderLength=0 then
    raise EIDC.Create(MS_Protocols,SS_KNX,KNX_Error_HeaderLength_Zero,'KNX Telegram "HeaderLength" is zero');
  if Telegram.Header.ServiceIdentifer=0 then
    raise EIDC.Create(MS_Protocols,SS_KNX,KNX_Error_ServiceIdentifer_Zero,'KNX Telegram "ServiceIdentifer" is zero');
  if Telegram.Header.ProtocolVersion=0 then
    raise EIDC.Create(MS_Protocols,SS_KNX,KNX_Error_ProtocolVersion_Zero,'KNX Telegram "ProtocolVersion" is zero');
end;

procedure TKnxTelegram<T1, T2, T3, T4>.BeforeDestruction;
begin
  inherited;
  LengthCorrection := 0;
end;

function TKnxTelegram<T1, T2, T3, T4>.GetBytes: TIDCBytes;
var a: word;
begin
  Telegram.CalcTotalLength(LengthCorrection);
  AssertTelegramData;
  SetLength(Result,Telegram.Header.TotalLength);
  Move(Telegram,Result[0],Telegram.Header.TotalLength);
end;

procedure TKnxTelegram<T1, T2, T3, T4>.HandleData;
begin

end;

procedure TKnxTelegram<T1, T2, T3, T4>.ResetTelegram;
begin
  Telegram.Header.New;
end;

procedure TKnxTelegram<T1, T2, T3, T4>.SetBytes(const ABytes: TIDCBytes);
begin
  ResetTelegram;
  AdjustTelegramSize(ABytes);
  Move(ABytes[0],Telegram,Min(SizeOf(Telegram),Length(ABytes)));
  HandleData();
  AssertTelegramData;
end;

end.
