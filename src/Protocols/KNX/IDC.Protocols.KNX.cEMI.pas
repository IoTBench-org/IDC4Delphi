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
    * Purpose      : Handle cEMI (Common External Message Interface) data and ADPU (Application Protocol Data Unit)

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Protocols.KNX.cEMI;

interface

uses
  System.SysUtils, System.Classes
  /// IDC Units
  ,IDC.Protocols.KNX.Telegrams.Records
  ,IDC.Protocols.KNX.Consts
  ,IDC.Global;

type
  // TPCI (Transport Protocol layer Control Information)
  TKnx_TPCIBits = packed record
  public
    TPCI: TIDCByte;  // 6 Bits for TPCI from the first byte
    procedure ApplyFromByte(Byte1: TIDCByte);
  end;

  // APCI (Application Protocol Layer control Information)
  TKnx_APCIBits = packed record
  public
    APCI: TIDCByte; // 4 bits total (2 from the 1st byte and 2 from the 2nd byte)
    procedure ApplyFromBytes(Byte1, Byte2: TIDCByte);
  end;

  // Data Bits (actual data from the third byte onwards)
  TKnx_DataBits = packed record
  public
    DataBits: TIDCByte;  // 6 bits from the second byte
    Data: TIDCBytes;     // Data from the third byte onwards
    procedure ApplyFromBytes(const DataBytes: TIDCBytes; DataLen: TIDCByte);
  end;

  IKnxAPDUData = interface(IInterface)
    function GetValueType: TIDCByte;
    function GetValueAsBoolean: boolean;
    function GetValueAsByte: TIDCByte;
    procedure SetValueType(const Value: TIDCByte);
    procedure SetValueAsByte(const Value: TIDCByte);

    function GetBytes(var Length: TIDCByte): TIDCBytes;
    procedure FillFromBytes(const ABytes: TIDCBytes; DataLen: TIDCByte);
    property ValueType : TIDCByte read GetValueType write SetValueType;
    property ValueAsByte    : TIDCByte read GetValueAsByte write SetValueAsByte;
    property ValueAsBoolean : boolean  read GetValueAsBoolean;
  end;
  // (Application Protocol Data Unit)
  TKnxADPUData = class(TInterfacedObject, IKnxAPDUData)
  private
    function GetValueType: TIDCByte; inline;
    function GetValueAsBoolean: boolean; inline;
    function GetValueAsByte: TIDCByte; inline;
    procedure SetValueType(const Value: TIDCByte); inline;
    procedure SetValueAsByte(const Value: TIDCByte); inline;
  public
    TPCI: TKnx_TPCIBits;
    APCI: TKnx_APCIBits;
    Data: TKnx_DataBits;
    procedure FillFromBytes(const ABytes: TIDCBytes; DataLen: TIDCByte); virtual;
    function GetBytes(var Length: TIDCByte): TIDCBytes;

    property ValueType : TIDCByte read GetValueType write SetValueType;
    property ValueAsByte    : TIDCByte read GetValueAsByte write SetValueAsByte;
    property ValueAsBoolean : boolean  read GetValueAsBoolean;
  end;


implementation

const
  // Hex masks for TPCI and APCI
  TPCI_TYPE_MASK = $FC;   // Mask for extracting the TPCI (6 bits from the first byte)
  APCI_MASK_1ST_BYTE =$03 ;  // Mask for the lowest 2 bits of APCI in the first byte
  APCI_MASK_2ND_BYTE = $C0;  // Mask for the highest 2 bits of APCI in the second byte
  DATA_MASK = $3F;       // Mask for extracting the 6 data bits from the second byte

{ TKnxADPUData }

procedure TKnxADPUData.FillFromBytes(const ABytes: TIDCBytes; DataLen: TIDCByte);
begin
  if Length(ABytes) >= 2 then
  begin
    TPCI.ApplyFromByte(ABytes[0]);
    APCI.ApplyFromBytes(ABytes[0], ABytes[1]);

    Data.ApplyFromBytes(ABytes, DataLen - 2);  // Process the data part
  end;
end;

function TKnxADPUData.GetBytes(var Length: TIDCByte): TIDCBytes;
var
  Byte1, Byte2: TIDCByte;
begin
  // First byte contains 6 bits of TPCI and 2 bits of APCI
  Byte1 := (TPCI.TPCI and TPCI_TYPE_MASK) or (APCI.APCI shr 2);

  // Second byte contains 2 bits of APCI and 6 bits of Data
  Byte2 := ((APCI.APCI and APCI_MASK_1ST_BYTE) shl 6) or (Data.DataBits and DATA_MASK);

  // Prepare result array with 2 bytes for TPCI/APCI + additional data
  SetLength(Result, 2);
  Result[0] := Byte1;
  Result[1] := Byte2;

  Length := 1;
end;

function TKnxADPUData.GetValueAsBoolean: boolean;
begin
  Result := Data.DataBits = 1;
end;

function TKnxADPUData.GetValueAsByte: TIDCByte;
begin
  Result := Data.DataBits;
end;

function TKnxADPUData.GetValueType: TIDCByte;
begin
  Result := APCI.APCI;
end;

procedure TKnxADPUData.SetValueAsByte(const Value: TIDCByte);
begin
  Data.DataBits := Value;
end;

procedure TKnxADPUData.SetValueType(const Value: TIDCByte);
begin
  APCI.APCI := Value;
end;

{ TKnx_TPCIBits }

procedure TKnx_TPCIBits.ApplyFromByte(Byte1: TIDCByte);
begin
  TPCI := (Byte1 and TPCI_TYPE_MASK) shr 2;  // Extract 6 bits for TPCI from the first byte
end;


{ TKnx_APCIBits }

procedure TKnx_APCIBits.ApplyFromBytes(Byte1, Byte2: TIDCByte);
var
  APCI_1, APCI_2: TIDCByte;
begin
  APCI_1 := Byte1 and APCI_MASK_1ST_BYTE;  // Extract the lowest 2 bits from the first byte
  APCI_2 := (Byte2 and APCI_MASK_2ND_BYTE)shr 6;  // Extract the highest 2 bits from the second byte
  APCI := (APCI_1 shl 2) or APCI_2;  // Combine the two parts into a 4-bit APCI value
end;

{ TKnx_DataBits }

procedure TKnx_DataBits.ApplyFromBytes(const DataBytes: TIDCBytes; DataLen: TIDCByte);
begin
  DataBits := DataBytes[1] and DATA_MASK;  // Extract 6 data bits from the second byte

  SetLength(Data, DataLen-1);  // Adjust the length of the data array
  if DataLen > 1 then
    Move(DataBytes[2], Data[0], DataLen-1);  // Copy remaining data into the data array
end;

end.

