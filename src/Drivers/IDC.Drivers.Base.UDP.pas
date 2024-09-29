{
  *****************************************************
  * Free Source Project: IDC4Delphi Components         *
  * Industrial Direct Communications for Delphi        *
  * https://github.com/IoTBench-org/IDC4Delphi         *
  * https://IoTBench.org/IDC4Delphi                    *
  *****************************************************

  Unit Information:
    * Main Section : Drivers
    * Sub Section  : -
    * Purpose      : Base types and procedure for UDP Based drivers (Endpoint protocols)
    * Notes:
       --> Don't use any class from here directly unless of creating new driver

  Initial author
    * Shadi Ajam (https://github.com/shadiajam)

  License:
    * This project is open-source and free to use. You are encouraged to
      contribute, modify, and redistribute it under the MIT license.
}

unit IDC.Drivers.Base.UDP;

interface

uses
     {System utils}
      System.SysUtils, System.Types
     {Indy Utils}
     ,IdUDPServer, IdGlobal, IdSocketHandle, IdBaseComponent, IdComponent, IdUDPBase
     {IDC Utils}
     ,IDC.Exceptions, IDC.Drivers.Base, IDC.Network, IDC.Global;

type
  TIDCUDPMessageType = (udpIncoming,udpOutgoing);

  TIDCUDPConnectionOptions = class (TIDCConnectionOptions)
  protected
    FServerAddress : string;
    FServerPort : Word;
  public
    procedure AfterConstruction; override;
    property ServerAddress : string read FServerAddress write FServerAddress;
    property ServerPort : Word read FServerPort write FServerPort;
  end;

  PIDCUDPMessage = ^TIDCUDPMessage;
  TIDCUDPMessage = record
    MessageType: TIDCUDPMessageType;
    Data: TIDCBytes;
  end;

  TIDCUDPDriverBase<TCO: constructor,TIDCUDPConnectionOptions> = class abstract (TIDCDriverBase<TCO,PIDCUDPMessage>)
  private
    FUDPServer: TIdUDPServer;
    FBindingIPs: TStringDynArray;
    FLocalPort : Word;
    procedure CreateUDPServer;
    procedure ConnectUDPServer;
    procedure FreeUDPServer;
    procedure OnUDPRead(AThread: TIdUDPListenerThread;
                        const AData: TIdBytes; ABinding: TIdSocketHandle);
  protected
    procedure ConsumeMessagingThreadData(AData:PIDCUDPMessage); override;
    procedure FreeMessagingThreadData(AData:PIDCUDPMessage); override;

    procedure RestartUDPServer; virtual;
    procedure SetActive(const Value: boolean); override;
    procedure HandleIncomingUDPData(const AData: TIDCBytes);virtual; abstract;
    procedure SendUDPData(const AData: TIDCBytes);virtual;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property BindingIPs: TStringDynArray read FBindingIPs;
    property LocalPort: Word read FLocalPort;
  end;


implementation

{ TIDCUDPDriverBase<TCO> }

procedure TIDCUDPDriverBase<TCO>.AfterConstruction;
begin
  inherited;
end;

procedure TIDCUDPDriverBase<TCO>.BeforeDestruction;
begin
  inherited;
  Active := False;
  FreeUDPServer;
end;

procedure TIDCUDPDriverBase<TCO>.ConnectUDPServer;
begin
  if not Assigned(FUDPServer) then exit;
  if not IsNormalMode then exit;
  try
    FUDPServer.Active := True;
    FLocalPort := FUDPServer.Binding.Port;
  except
    raise Exception.Create('Error while open udp');// ToDo:
  end;
end;

procedure TIDCUDPDriverBase<TCO>.ConsumeMessagingThreadData(AData: PIDCUDPMessage);
begin
  case  AData.MessageType of
    udpIncoming:
    begin
      HandleIncomingUDPData(AData.Data);
    end;
    udpOutgoing:
    begin
      FUDPServer.SendBuffer(ConnectionOptions.ServerAddress,ConnectionOptions.ServerPort,TIdBytes(AData.Data));
    end;
  end;
end;

procedure TIDCUDPDriverBase<TCO>.CreateUDPServer;
var
  i: Integer;
  Binding: TIdSocketHandle;
begin
  if Assigned(FUDPServer) then FreeUDPServer;
  if not IsNormalMode then exit;
  FUDPServer := TIdUDPServer.Create(nil);
  FUDPServer.ThreadedEvent := True;
  FUDPServer.BroadcastEnabled := True;
  FUDPServer.OnUDPRead := OnUDPRead;
  FBindingIPs := GetListLocalIPv4Address;
  for I := 0 to length(FBindingIPs)-1 do
  begin
    with FUDPServer.Bindings.Add do
    begin
      IP := FBindingIPs[I];
      Port := 0;
    end;
  end;
end;

procedure TIDCUDPDriverBase<TCO>.FreeMessagingThreadData(AData: PIDCUDPMessage);
begin
  Dispose(AData);
end;

procedure TIDCUDPDriverBase<TCO>.FreeUDPServer;
begin
  if Assigned(FUDPServer) then
  begin
    SetActive(False);
    FreeAndNil(FUDPServer);
  end;
end;

procedure TIDCUDPDriverBase<TCO>.OnUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var UDPMessage: PIDCUDPMessage;
begin
  New(UDPMessage);
  UDPMessage.MessageType := udpIncoming;
  SetLength(UDPMessage.Data,Length(AData));
  Move(AData[0],UDPMessage.Data[0],Length(AData));
  FMessagingThread.AddToQueue(UDPMessage);
end;

procedure TIDCUDPDriverBase<TCO>.RestartUDPServer;
var SaveActiveState : boolean;
begin
  SaveActiveState := FActive;
  FreeUDPServer;
  SetActive(SaveActiveState); // Recreate it and connect as last state
end;

procedure TIDCUDPDriverBase<TCO>.SendUDPData(const AData: TIDCBytes);
var UDPMessage: PIDCUDPMessage;
begin
  New(UDPMessage);
  UDPMessage.MessageType := udpOutgoing;
  SetLength(UDPMessage.Data,Length(AData));
  Move(AData[0],UDPMessage.Data[0],Length(AData));
  FMessagingThread.AddToQueue(UDPMessage);
end;

procedure TIDCUDPDriverBase<TCO>.SetActive(const Value: boolean);
begin
  if FActive <> Value then
  begin
    if Value then
    begin
      CreateUDPServer;  // Create UDP if not created
      ConnectUDPServer; // Try to connect
    end else
    begin
      if Assigned(FUDPServer) then
        FUDPServer.Active := False;
    end;

    FActive := Value;
  end;
end;

{ TIDCUDPConnectionOptions }

procedure TIDCUDPConnectionOptions.AfterConstruction;
begin
  inherited;
  FServerAddress := '';
  FServerPort := 0;
end;

end.
