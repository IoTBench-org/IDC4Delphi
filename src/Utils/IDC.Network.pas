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
    * Purpose      : Network global tools and procedures

  Initial Author:
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Network;

interface
uses
     {System Utils}
     System.SysUtils,System.Types
     {Indy Utils}
     , IdStack, IdGlobal
     {IDC Utils}
     , IDC.Exceptions
     ;

// Purpose : Retrieve a list of local IPv4 addresses available on the machine.
function GetListLocalIPv4Address:TStringDynArray;

implementation

function GetListLocalIPv4Address:TStringDynArray;
var
  i,x: Integer;
  IPList: TIdStackLocalAddressList;
begin
  IPList := TIdStackLocalAddressList.Create;
  try
    GStack.GetLocalAddressList(IPList);
    SetLength(Result,0);
    x := 0;
    for i := 0 to IPList.Count - 1 do
      if IPList[i].IPVersion= Id_IPv4 then
      begin
        Inc(X);
        SetLength(Result,X);
        Result[X-1] := IPList[I].IPAddress;
      end;
  finally
    IPList.Free;
  end;
end;

end.
