{
  *****************************************************
  * Free Source Project: IDC4Delphi Components         *
  * Industrial Direct Communications for Delphi        *
  * https://github.com/IoTBench-org/IDC4Delphi         *
  * https://IoTBench.org/IDC4Delphi                    *
  *****************************************************

  Unit Information:
    * Main Section : Global
    * Sub Section  : -
    * Purpose      : Define Global types used across project

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}


unit IDC.Global;

interface
uses   System.SysUtils
     , IDC.Exceptions
      ;

type
  TIDCByte = Byte;
  TIDCWord_MSB = packed record
    Value : Word;
    class operator Implicit(a: Word): TIDCWord_MSB; inline;
    class operator Implicit(a: TIDCWord_MSB): Word;  inline;
    class operator Equal(a: TIDCWord_MSB;B: Word): Boolean; inline;
  End;
  TIDCChar   = AnsiChar;
  TIDCString = AnsiString;

  TIDCStringArr  = array of AnsiString;
  TIDCBytes  = array of TIDCByte;
  TIDCIPv4Addr = array[0..3] of TIDCByte;
  TIDCIPPort   = TIDCWord_MSB;
  TIDCMacAddr  = array[0..5] of TIDCByte;


procedure CopyIPv4Addr(var Dest: TIDCIPv4Addr; const Source: TIDCIPv4Addr);
function IPv4AddrToString(const Addr: TIDCIPv4Addr): string;
function StringToIPv4Addr(const IPStr: string): TIDCIPv4Addr;
function MacAddrToString(const MacAddr: TIDCMacAddr): string;
function IDCBytesToString(const Bytes:TIDCBytes):string;


implementation

{ TIDCIPv4AddrHelper }

procedure CopyIPv4Addr(var Dest: TIDCIPv4Addr; const Source: TIDCIPv4Addr);
begin
  Move(Source[0], Dest[0], SizeOf(TIDCIPv4Addr));
end;

function IPv4AddrToString(const Addr: TIDCIPv4Addr): string;
begin
  Result := Format('%d.%d.%d.%d', [Addr[0], Addr[1], Addr[2], Addr[3]]);
end;

function StringToIPv4Addr(const IPStr: string): TIDCIPv4Addr;
var
  Parts: TArray<string>;
begin
  Parts := IPStr.Split(['.']);
  if Length(Parts) <> 4 then
    raise EIDC.Create(MS_Global,SS_Global,1,'Invalid IPv4 address string');

  Result[0] := StrToInt(Parts[0]);
  Result[1] := StrToInt(Parts[1]);
  Result[2] := StrToInt(Parts[2]);
  Result[3] := StrToInt(Parts[3]);
end;

function IDCBytesToString(const Bytes:TIDCBytes):string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(Bytes) to High(Bytes) do
    Result := Result + IntToHex(Bytes[I], 2);
end;

function MacAddrToString(const MacAddr: TIDCMacAddr): string;
begin
  // Use Format to create a MAC address string in the format XX:XX:XX:XX:XX:XX
  Result := Format('%.2X:%.2X:%.2X:%.2X:%.2X:%.2X',
                   [MacAddr[0], MacAddr[1], MacAddr[2], MacAddr[3], MacAddr[4], MacAddr[5]]);
end;

{ TIDCWord_MSB }

class operator TIDCWord_MSB.Equal(a: TIDCWord_MSB; B: Word): Boolean;
begin
  Result := a.Value = swap(b);
end;

class operator TIDCWord_MSB.Implicit(a: TIDCWord_MSB): Word;
begin
  Result := swap(a.Value);
end;

class operator TIDCWord_MSB.Implicit(a: Word): TIDCWord_MSB;
begin
  Result.Value := Swap(a);
end;

end.
