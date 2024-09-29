unit mainFM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,Winapi.ShellAPI, Vcl.ComCtrls,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.StdCtrls,DateUtils,
  IDC.Protocols.KNX.Consts,
  IDC.Drivers.KNX,
  IDC.Global
  ;

type
  TLogType = (ltInfo,ltError,ltIncoming,ltOutgoing);

  TfrmMain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    lblExampleDescrip: TLabel;
    lblIDC4Delphi: TLabel;
    Panel3: TPanel;
    imgIoTBenchLogo: TImage;
    lblSlogan: TLabel;
    Label3: TLabel;
    Panel4: TPanel;
    Image1: TImage;
    Label2: TLabel;
    pnlMainContent: TPanel;
    memLogs: TMemo;
    StatusBar: TStatusBar;
    Panel5: TPanel;
    btnClearLog: TButton;
    GroupBox1: TGroupBox;
    edtPort: TEdit;
    Label1: TLabel;
    Label4: TLabel;
    edtIPAddress: TEdit;
    chkAutoDiscovery: TCheckBox;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    edtSendValueByte: TEdit;
    edtDestAddr: TEdit;
    btnWriteKNX: TButton;
    procedure imgIoTBenchLogoClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chkAutoDiscoveryClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure OnDeviceFoundEvent(Driver:  TIDCCustomKNXDriver;
                                 IPRouter: TKNXIPRouterDevice;
                                 var AutoConnect: Boolean);

    procedure OnDeviceConnectedEvent(Driver:  TIDCCustomKNXDriver;
                                     IPRouter: TKNXIPRouterDevice;
                                     const ConnectedChannel:Word);

    procedure OnGroupAddressEvent(Driver: TIDCCustomKNXDriver;
                                  DataType: TKNXDataTypes;
                                  GroupValueType: TKNXGroupValueType;
                                  const GroupAddress, IndividualAddress: string;
                                  const AData: TIDCBytes);
    procedure btnWriteKNXClick(Sender: TObject);
  private
    FKNX: TIDCKNXDriver;
    procedure AddLog(LogType:TLogType;const Str:string);

    procedure StartKNXDiscovery;
    procedure SetDefualts;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.AddLog(LogType:TLogType;const Str:string);
var ATime: TTime;
    StrTime:string;
    LogTypeStr: string;
begin
  ATime:= Now;
  StrTime := FormatDateTime('hh:nn:ss', ATime) + Format('.%-3d',[ MilliSecondOf(ATime)]);
  case LogType of
    ltInfo: LogTypeStr := 'INF';
    ltError: LogTypeStr := 'ERR';
    ltIncoming: LogTypeStr := 'MSG';
    ltOutgoing: LogTypeStr := 'OUT';
  end;
  memLogs.Lines.Add(Format('[%s] [%s] %s',[StrTime,LogTypeStr,Str]));
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memLogs.Clear;
end;

procedure TfrmMain.btnWriteKNXClick(Sender: TObject);
var ABytes: TIDCBytes;
begin
  if not Assigned(FKNX) then exit;
  SetLength(ABytes,1);
  ABytes[0] := StrToInt(edtSendValueByte.Text);
  FKNX.WriteBytesToGroupAddress(edtDestAddr.Text,ABytes);

end;

procedure TfrmMain.chkAutoDiscoveryClick(Sender: TObject);
begin
  StartKNXDiscovery;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetDefualts;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FKNX) then
    FreeAndNil(FKNX);
end;

procedure TfrmMain.imgIoTBenchLogoClick(Sender: TObject);
var URL: string;
begin
  URL := (sender as TControl).Hint;
  if URL.Contains('https://') then
  begin
    ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
  end;

end;

procedure TfrmMain.OnDeviceConnectedEvent(Driver: TIDCCustomKNXDriver;
  IPRouter: TKNXIPRouterDevice; const ConnectedChannel: Word);
begin
  AddLog(ltInfo,Format('Tunnel Connected: Channel = "%d"',[ConnectedChannel]));
end;

procedure TfrmMain.OnDeviceFoundEvent(Driver: TIDCCustomKNXDriver;
  IPRouter: TKNXIPRouterDevice; var AutoConnect: Boolean);
begin
  AddLog(ltInfo,Format('Found KNXnet/IP Router: Mac Address = "%s", Name = "%s"',[IPRouter.MACAddress,IPRouter.FriendlyName]));
end;

procedure TfrmMain.OnGroupAddressEvent(Driver: TIDCCustomKNXDriver;
  DataType: TKNXDataTypes; GroupValueType: TKNXGroupValueType;
  const GroupAddress, IndividualAddress: string; const AData: TIDCBytes);
var S1,S2: string;
begin
  case DataType of
    knxDataRequest: S1 := 'Data Request';
    knxDataConfirmation: S1 := 'Data Confirmation';
    knxDataIndication: S1 := 'Data Indication';
  end;
  case GroupValueType of
    knxGroupRead: S2 := 'Group Read';
    knxGroupResponse: S2 := 'Group Response';
    knxGroupWrite: S2 := 'Group Write';
  end;
  AddLog(ltIncoming,Format('%s/%s --> Source: "%s" Destination: "%s" -- Value(Decimal) = "%s"',[s1,s2,IndividualAddress,GroupAddress,AData[0].ToString]))
end;

procedure TfrmMain.SetDefualts;
begin
  edtIPAddress.Text := KNX_MULTICAST_ADDRESS;
  edtPort.Text := KNX_DEFAULT_PORT.ToString;
end;

procedure TfrmMain.StartKNXDiscovery;
begin
  edtIPAddress.Enabled := False;
  edtPort.Enabled := False;
  chkAutoDiscovery.Enabled := False;
  AddLog(ltInfo,'Start Searching for KNXnet/IP Router in local network...');

  if Assigned(FKNX) then FreeAndNil(FKNX);
  FKNX := TIDCKNXDriver.Create(nil);
  FKNX.OnKNXDeviceFound := OnDeviceFoundEvent;
  FKNX.OnKNXDeviceConnected := OnDeviceConnectedEvent;
  FKNX.OnKNXGroupAddressEvent := OnGroupAddressEvent;
  FKNX.StartKNXDiscovery;
end;

end.
