{
  *****************************************************
  * Free Source Project: IDC4Delphi Components         *
  * Industrial Direct Communications for Delphi        *
  * https://github.com/IoTBench-org/IDC4Delphi         *
  * https://IoTBench.org/IDC4Delphi                    *
  *****************************************************

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Exceptions;

interface

uses System.SysUtils;

type
  EIDC_MainSection = ( MS_Global = $010000      // Main Section Global
                      ,MS_Protocols = $020000   // Main Section Protocols
                      );
  EIDC_SubSection  = ( SS_Global = $0100        // Main Section Global
                      ,SS_KNX    = $0200        // Sub  Section KNX
                     );
  EIDC = class(Exception)
  public
    IDC_ErrorCode: Cardinal;
    IDC_ErrorMsg: string;
    constructor Create(MainSection: EIDC_MainSection;
                       SubSection: EIDC_SubSection;
                       ErrorID:Byte;const Msg: string);
  end;

implementation

{ EIDC }

constructor EIDC.Create(MainSection: EIDC_MainSection;
  SubSection: EIDC_SubSection; ErrorID: Byte; const Msg: string);
begin
  IDC_ErrorCode := Cardinal(MainSection)+Cardinal(SubSection)+ErrorID;
  IDC_ErrorMsg := Msg;
  Inherited CreateFmt('IDC Error($%s): %s',[IntToHex(IDC_ErrorCode),IDC_ErrorMsg]);
end;

end.
