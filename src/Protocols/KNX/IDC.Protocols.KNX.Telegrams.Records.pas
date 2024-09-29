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
    * Purpose      : Define packets records used across KNX Protocol units

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}


unit IDC.Protocols.KNX.Telegrams.Records;

interface
uses
  System.SysUtils, System.Classes,System.Types , System.StrUtils
  /// IDC Units
  ,IDC.Protocols.KNX.Consts
  ,IDC.Global
  ,IDC.Exceptions
  ;

type
  TKNXDeviceSerial = array[0..5] of TIDCByte;

  TKNXIndividualAddress = packed record
  private
    function GetAsString: TIDCString;
    procedure SetAsString(const Value: TIDCString);
  public
    WordValue : TIDCWord_MSB;
    procedure GetDetails(var Area, Line, Device: TIDCByte);
    procedure SetDetails(const Area, Line, Device: TIDCByte);
    property AsString : TIDCString read GetAsString write SetAsString;
  end;

  TKNXGroupAddress = packed record
  private
    function GetAsString: TIDCString;
    procedure SetAsString(const Value: TIDCString);
  public
    WordValue : TIDCWord_MSB;
    procedure GetDetails(var Main, Middle, Group: TIDCByte);
    procedure SetDetails(const Main, Middle, Group: TIDCByte);
    property AsString : TIDCString read GetAsString write SetAsString;
  end;

  TKNXPacket_Header = packed record    // KNXnet/IP Header section
    HeaderLength     : TIDCByte; // 6 Bytes
    ProtocolVersion  : TIDCByte;
    ServiceIdentifer : TIDCWord_MSB;
    TotalLength      : TIDCWord_MSB;
    procedure New();
  end;

  TKNXPacket_Empty = packed record     // Empty section
  end;

  TKNXPacket_Base<T1,T2,T3,T4> = packed record  /// Based packet dont use it directly
    Header   : TKNXPacket_Header;
    Section1 : T1;
    Section2 : T2;
    Section3 : T3;
    Section4 : T4;
    procedure CalcTotalLength(Correction : integer);
  end;

  TKNXPacket_HPAIEndpoint = packed record
    StructureLength  : TIDCByte; // 8 Bytes
    HostProtocol     : TIDCByte; // 0x01 IPv4 UDP
    IPAddress        : TIDCIPv4Addr;
    IPPort           : TIDCIPPort;
    procedure New();
  end;

  TKNXPacket_DeviceInformation = packed record
    StructureLength  : TIDCByte;                 // 54 bytes
    DescriptionType  : TIDCByte;                 // Device Information (0x01)
    KNXMedium        : TIDCByte;                 // KNX Medium (0x02 for TP1)
    DeviceStatus     : TIDCByte;                 // Device Status (Programming Mode, etc.)
    IndividualAddress: TKNXIndividualAddress;    // KNX Individual Address (e.g., 0xff00)
    ProjectID        : TIDCWord_MSB;             // Project Installation Identifier (0x0001)
    SerialNumber     : TKNXDeviceSerial;         // KNX Serial Number (6 bytes)
    MulticastAddress : TIDCIPv4Addr;             // Multicast Address (4 bytes)
    MACAddress       : TIDCMacAddr;              // MAC Address (6 bytes)
    FriendlyName     : array[0..29] of TIDCChar; // Friendly Name (30 bytes)
    procedure New();
  end;

  TKNXSupportedService = packed record
    ServiceFamily  : TIDCByte;  // Service Family identifier (e.g., Core, Tunneling, Routing)
    ServiceVersion : TIDCByte;  // Version of the service (e.g., 0x01 for version 1)
  end;

  TKNXPacket_SupportedServices = packed record
    StructureLength   : TIDCByte;                            // Structure length (eg. 10 bytes)
    DescriptionType   : TIDCByte;                            // Description Type (0x02 for Supported Service Families)
    Services          : array[0..3] of TKNXSupportedService; // KNXnet/IP Core Service
    procedure New();
  end;

  TKNXPacket_CRITunneling = packed record
    StructureLength: TIDCByte;            // Structure Length (4 bytes)
    ConnectionType: TIDCByte;             // Connection Type (use the constants) (0x03)
    KNXLayer: TIDCByte;                   // KNX Layer (LinkLayer - 0x02)
    Reserved: TIDCByte;                   // Reserved (0x00)
    procedure New;
  end;

  TKNXPacket_CRDTunneling = packed record
    StructureLength: TIDCByte;                // Structure Length (4 bytes)
    ConnectionType: TIDCByte;                 // Connection Type (use the constants) (0x03)
    IndividualAddress: TKNXIndividualAddress; // KNX Individual Address (e.g., 0xff00)
    procedure New;
  end;

  TKNXPacket_ChannelStatus = packed record
    Channel: TIDCByte;
    Status: TIDCByte;
    procedure New;
  end;

  TKNXPacket_Disconnect = packed record
    Channel: TIDCByte;
    Reserved: TIDCByte;
  end;

  TKNXPacket_ConnectionHeader = packed record
    StructureLength  : TIDCByte; // 4 Bytes
    Channel   : TIDCByte;
    Sequence  : TIDCByte;
    Status    : TIDCByte;     // Reserved (0x00)
    procedure New();
  end;

  PKNXPacket_cEMI = ^TKNXPacket_cEMI;
  TKNXPacket_cEMI = packed record               // cEMI: common external message interface
    MessageCode     : TIDCByte;                 // COMMON EMI MESSAGE CODES FOR DATA LINK LAYER PRIMITIVES
    AddInfoLength   : TIDCByte;                 // Addional info length, (Should be zero in this packet)
    Ctrl1           : TIDCByte;                 // Control Field 1
    Ctrl2           : TIDCByte;                 // Control Field 2
    SrcAddress      : TKNXIndividualAddress;    // filled in by router/gateway with its source address which is part of the KNX subnet
    DestAddress     : TKNXGroupAddress;         // KNX group or individual address
    DataLength      : TIDCByte;                 // Number of bytes of data in the APDU excluding the TPCI/APCI bit
    APDU            : array[0..29] of TIDCByte; // Application Protocol Data Unit - the actual payload including TPCI/APCI and data
    procedure New();
  end;



implementation

{ TKNXPacket_Header }

procedure TKNXPacket_Header.New;
begin
  HeaderLength := SizeOf(Self);
  ProtocolVersion := KNX_PROTOCOL_VERSION;
  ServiceIdentifer := 0;
  TotalLength := 0;
end;

{ TKNXPacket_HPAIEndpoint }

procedure TKNXPacket_HPAIEndpoint.New;
begin
  StructureLength := SizeOf(Self);
  HostProtocol := KNX_HOSTPROTOCOL_IPv4UDP;
  IPAddress[0] := 0;
  IPAddress[1] := 0;
  IPAddress[2] := 0;
  IPAddress[3] := 0;
  IPPort := 0;
end;

{ TKNXPacket_DeviceInformation }

procedure TKNXPacket_DeviceInformation.New;
begin
  StructureLength := SizeOf(Self);

end;

{ TKNXPacket_SupportedServices }

procedure TKNXPacket_SupportedServices.New;
begin
  StructureLength := SizeOf(Self);
end;

{ TKNXPacket_Base<T1, T2, T3, T4> }

procedure TKNXPacket_Base<T1, T2, T3, T4>.CalcTotalLength(Correction : integer);
begin
  Header.TotalLength := SizeOf(Self)+Correction;
end;

{ TKNXIndividualAddress }

function TKNXIndividualAddress.GetAsString: TIDCString;
var Area, Line, Device: TIDCByte;
begin
  GetDetails(Area, Line, Device);
  Result := Format('%d.%d.%d',[Area, Line, Device]);
end;

procedure TKNXIndividualAddress.GetDetails(var Area, Line, Device: TIDCByte);
var W: Word;
begin
  w := swap(WordValue.Value);
  Area := (w shr 12) and $0F;    // Extract Area (top 4 bits)
  Line := (w shr 8) and $0F;     // Extract Line (next 4 bits)
  Device := w and $FF;           // Extract Device (last 8 bits)
end;

procedure TKNXIndividualAddress.SetAsString(const Value: TIDCString);
var Area, Line, Device: TIDCByte;
    S: TStringDynArray;
begin
  S := SplitString(Value,'.');
  try
    Area   := StrToInt(S[0]);
    Line   := StrToInt(S[1]);
    Device := StrToInt(S[2]);
    if Area > 15 then raise EArgumentOutOfRangeException.Create('');
    if Line > 15 then raise EArgumentOutOfRangeException.Create('');
    SetDetails(Area,Line,Device);
  except
    raise EIDC.Create(MS_Protocols,SS_KNX,0,'Error converting string to KNX Individual Address');
  end;

end;

procedure TKNXIndividualAddress.SetDetails(const Area, Line, Device: TIDCByte);
var
  W: Word;
begin
  W := (Word(Area) shl 12) or (Word(Line) shl 8) or Word(Device);  // Combine Area, Line, and Device into a single Word
  WordValue := W;  // Store the swapped Word value

end;

{ TKNXPacket_CRITunneling }

procedure TKNXPacket_CRITunneling.New;
begin
  StructureLength := SizeOf(Self);
  ConnectionType := KNX_CONNECTION_TYPE_TUNNEL_CONNECTION;  // Tunneling Connection
  KNXLayer := $02;                         // LinkLayer (0x02)
  Reserved := $00;                         // Reserved byte
end;

{ TKNXPacket_CRDTunneling }

procedure TKNXPacket_CRDTunneling.New;
begin
  StructureLength := SizeOf(Self);
  ConnectionType := KNX_CONNECTION_TYPE_TUNNEL_CONNECTION;  // Tunneling Connection

end;

{ TKNXPacket_ChannelStatus }

procedure TKNXPacket_ChannelStatus.New;
begin
  Channel := 0;
  Status  := 255;

end;

{ TKNXPacket_ConnectionHeader }

procedure TKNXPacket_ConnectionHeader.New;
begin
  StructureLength := SizeOf(Self);
  Channel   := 255;
  Sequence  := 255;
  Status    := 255;
end;

{ TKNXGroupAddress }

function TKNXGroupAddress.GetAsString: TIDCString;
var Main, Middle, Group: TIDCByte;
begin
  GetDetails(Main, Middle, Group);
  Result := Format('%d/%d/%d',[Main, Middle, Group]);
end;

procedure TKNXGroupAddress.GetDetails(var Main, Middle, Group: TIDCByte);
var W: Word;
begin
  w := swap(WordValue.Value);
  Main   := (w shr 12) and $0F;    // Extract Area (top 4 bits)
  Middle := (w shr 8) and $0F;     // Extract Line (next 4 bits)
  Group  := w and $FF;           // Extract Device (last 8 bits)

end;

procedure TKNXGroupAddress.SetAsString(const Value: TIDCString);
var Main, Middle, Group: TIDCByte;
    S: TStringDynArray;
begin
  S := SplitString(Value,'/');
  try
    Main   := StrToInt(S[0]);
    Middle := StrToInt(S[1]);
    Group  := StrToInt(S[2]);
    if Main   > 15 then raise EArgumentOutOfRangeException.Create('');
    if Middle > 15 then raise EArgumentOutOfRangeException.Create('');
    SetDetails(Main,Middle,Group);
  except
    raise EIDC.Create(MS_Protocols,SS_KNX,0,'Error converting string to KNX Individual Address');
  end;
end;

procedure TKNXGroupAddress.SetDetails(const Main, Middle, Group: TIDCByte);
var
  W: Word;
begin
  W := (Word(Main) shl 12) or (Word(Middle) shl 8) or Word(Group);  // Combine Area, Line, and Device into a single Word
  WordValue := (W);  // Store the swapped Word value

end;

{ TKNXPacket_cEMI }

procedure TKNXPacket_cEMI.New;
begin
  MessageCode := 0;
  AddInfoLength := 0;
  Ctrl1 := 0;
  Ctrl2 := 0;
  FillChar(APDU[0],SizeOF(APDU),0);
end;

end.
