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
    * Purpose      : Define consts and enums used across KNX Protocol units

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}


unit IDC.Protocols.KNX.Consts;

interface

const
  KNX_MULTICAST_ADDRESS = '224.0.23.12';
  KNX_DEFAULT_PORT = 3671;

  KNX_PROTOCOL_VERSION = $10; // Protocol Version: 1.0
  KNX_HOSTPROTOCOL_IPv4UDP = $01; // IPv4 UDP

  KNX_SERVICE_IDENTIFIER_SEARCH_REQUEST               = $0201;
  KNX_SERVICE_IDENTIFIER_SEARCH_RESPONSE              = $0202;
  KNX_SERVICE_IDENTIFIER_DESCRIPTION_REQUEST          = $0203;
  KNX_SERVICE_IDENTIFIER_DESCRIPTION_RESPONSE         = $0204;
  KNX_SERVICE_IDENTIFIER_CONNECT_REQUEST              = $0205;
  KNX_SERVICE_IDENTIFIER_CONNECT_RESPONSE             = $0206;
  KNX_SERVICE_IDENTIFIER_CONNECTION_STATE_REQUEST     = $0207;
  KNX_SERVICE_IDENTIFIER_CONNECTION_STATE_RESPONSE    = $0208;
  KNX_SERVICE_IDENTIFIER_DISCONNECT_REQUEST           = $0209;
  KNX_SERVICE_IDENTIFIER_DISCONNECT_RESPONSE          = $020A;
  KNX_SERVICE_IDENTIFIER_DEVICE_CONFIGURATION_REQUEST = $0310;
  KNX_SERVICE_IDENTIFIER_DEVICE_CONFIGURATION_ACK     = $0311;
  KNX_SERVICE_IDENTIFIER_TUNNEL_REQUEST               = $0420;
  KNX_SERVICE_IDENTIFIER_TUNNEL_ACK                   = $0421;


  KNX_CONNECTION_TYPE_UNKNOWN            = $00;  // Unknown or unspecified connection type
  KNX_CONNECTION_TYPE_DEVICE_MANAGEMENT  = $03;  // Device Management Connection (0x03)
  KNX_CONNECTION_TYPE_TUNNEL_CONNECTION  = $04;  // Tunneling Connection (0x04)
  KNX_CONNECTION_TYPE_REMOTE_LOGGING     = $06;  // Remote Logging (0x06)
  KNX_CONNECTION_TYPE_REMOTE_CONFIG      = $07;  // Remote Configuration (0x07)
  KNX_CONNECTION_TYPE_OBJECT_SERVER      = $08;  // Object Server (0x08)


  KNX_STATUS_OK                    = $00; // Status: OK (0x00)
  KNX_STATUS_ERROR                 = $01; // Status: Error (0x01)
  KNX_STATUS_DEVICE_BUSY           = $02; // Status: Device Busy (0x02)
  KNX_STATUS_INVALID_COMMAND       = $03; // Status: Invalid Command (0x03)
  KNX_STATUS_MEMORY_ERROR          = $04; // Status: Memory Error (0x04)
  KNX_STATUS_TIMEOUT               = $05; // Status: Timeout (0x05)
  KNX_STATUS_INVALID_PARAMETER     = $06; // Status: Invalid Parameter (0x06)
  KNX_STATUS_DEVICE_NOT_RESPONDING = $07; // Status: Device Not Responding (0x07)
  KNX_STATUS_COMMUNICATION_ERROR   = $08; // Status: Communication Error (0x08)
  KNX_STATUS_ACCESS_DENIED         = $09; // Status: Access Denied (0x09)
  KNX_STATUS_NOT_SUPPORTED         = $0A; // Status: Not Supported (0x0A)
  KNX_STATUS_RESET_REQUIRED        = $0B; // Status: Reset Required (0x0B)
  KNX_STATUS_FIRMWARE_UPGRADE      = $0C; // Status: Firmware Upgrade Needed (0x0C)
  KNX_STATUS_CONFIGURATION_ERROR   = $0D; // Status: Configuration Error (0x0D)
  KNX_STATUS_INVALID_DATA          = $0E; // Status: Invalid Data (0x0E)
  KNX_STATUS_HARDWARE_FAILURE      = $0F; // Status: Hardware Failure (0x0F)

  KNX_VALUE_TYPE_GROUP_VALUE_READ            = $00;  // GroupValueRead
  KNX_VALUE_TYPE_GROUP_VALUE_RESPONSE        = $01;  // GroupValueResponse
  KNX_VALUE_TYPE_GROUP_VALUE_WRITE           = $02;  // GroupValueWrite
  KNX_VALUE_TYPE_INDIVIDUAL_ADDRESS_WRITE    = $03;  // IndividualAddressWrite
  KNX_VALUE_TYPE_INDIVIDUAL_ADDRESS_REQUEST  = $04;  // IndividualAddressRequest
  KNX_VALUE_TYPE_INDIVIDUAL_ADDRESS_RESPONSE = $05;  // IndividualAddressResponse
  KNX_VALUE_TYPE_ADC_READ                    = $06;  // AdcRead
  KNX_VALUE_TYPE_ADC_RESPONSE                = $07;  // AdcResponse
  KNX_VALUE_TYPE_MEMORY_WRITE                = $08;  // MemoryWrite
  KNX_VALUE_TYPE_MEMORY_REQUEST              = $09;  // MemoryRequest
  KNX_VALUE_TYPE_MEMORY_RESPONSE             = $0A;  // MemoryResponse
  KNX_VALUE_TYPE_USER_MEMORY_WRITE           = $0B;  // UserMemoryWrite
  KNX_VALUE_TYPE_USER_MEMORY_REQUEST         = $0C;  // UserMemoryRequest
  KNX_VALUE_TYPE_USER_MEMORY_RESPONSE        = $0D;  // UserMemoryResponse
  KNX_VALUE_TYPE_DEVICE_DESCRIPTOR_READ      = $0E;  // DeviceDescriptorRead
  KNX_VALUE_TYPE_DEVICE_DESCRIPTOR_RESPONSE  = $0F;  // DeviceDescriptorResponse

  KNX_cEMI_MESSAGE_CODE_L_DATA_REQ       = $11;  // L_Data.req      // Request for data transmission
  KNX_cEMI_MESSAGE_CODE_L_DATA_CON       = $2E;  // L_Data.con      // Confirmation of data transmission
  KNX_cEMI_MESSAGE_CODE_L_DATA_IND       = $29;  // L_Data.ind      // Indication of incoming data
  KNX_cEMI_MESSAGE_CODE_L_POLL_DATA_REQ  = $13;  // L_Poll_Data.req // Request for polling data
  KNX_cEMI_MESSAGE_CODE_L_BUSMON_IND     = $2B;  // L_Busmon.ind    // Bus monitor indication
  KNX_cEMI_MESSAGE_CODE_L_RAW_REQ        = $10;  // L_Raw.req       // Raw data request
  KNX_cEMI_MESSAGE_CODE_L_RAW_CON        = $2F;  // L_Raw.con       // Raw data confirmation
  KNX_cEMI_MESSAGE_CODE_L_RAW_IND        = $2D;  // L_Raw.ind       // Raw data indication
  KNX_cEMI_MESSAGE_CODE_L_POLL_DATA_CON  = $25;  // L_Poll_Data.con // Polling data confirmation
  KNX_cEMI_MESSAGE_CODE_L_RTM_REQ        = $05;  // L_RTM.req       // Request for runtime management
  KNX_cEMI_MESSAGE_CODE_L_RTM_CON        = $06;  // L_RTM.con       // Confirmation for runtime management

implementation

end.
