---
description: TIDCKNXDriver Component
---

# IDC.Drivers.KNX

## Unit overview

This unit provides the implementation of the KNXnet/IP protocol in tunnel mode. The primary purpose of the component is to enable communication with KNX devices using KNXnet/IP via UDP. The component allows sending and receiving KNX telegrams, discovering KNX devices, and handling group addresses.

### Get Started

To get started with this component, follow these steps:

1. Create an instance of `TIDCKNXDriver`.
2. Set the necessary properties such as IP, multicast addresses, and ports.
3. Attach event handlers for events like `OnKNXDeviceFound` and `OnKNXGroupAddressEvent`.
4. Call the `StartKNXDiscovery` method to begin KNX device discovery.
5. Use `WriteBytesToGroupAddress` and `ReadBytesFromGroupAddress` to interact with KNX group addresses.

### Usage Example

{% code overflow="wrap" %}
```pascal
var
  KNXDriver: TIDCKNXDriver;

begin
  KNXDriver := TIDCKNXDriver.Create(nil);
  KNXDriver.OnKNXDeviceFound := MyDeviceFoundEvent;
  KNXDriver.OnKNXGroupAddressEvent := MyGroupAddressEvent;
  KNXDriver.StartKNXDiscovery;
end;
```
{% endcode %}

***

## TIDCKNXDriver

{% hint style="info" %}
<mark style="color:blue;">Cases of usage</mark>

Can used this class directly at low level, when direct and fast commnection is reqiured.
{% endhint %}

### Properties

* **`DiscoveryTimeout`**: Sets the timeout (in milliseconds) for KNX device discovery. This is part of the `TIDCKNXConnectionOptions`.
* **`Active`**: Controls whether the driver is active.
* **`OnKNXDeviceFound`**: Event triggered when a KNX device is found during discovery.
* **`OnKNXGroupAddressEvent`**: Event triggered when a group address message is received.

### Events

*   **`OnKNXDeviceFound`**:&#x20;

    {% code overflow="wrap" %}
    ```pascal
    procedure (Driver: TIDCCustomKNXDriver; IPRouter: TKNXIPRouterDevice; var AutoConnect: boolean) of object;
    ```
    {% endcode %}

    This event is triggered when a KNX device is discovered.
*   **`OnKNXGroupAddressEvent`**:&#x20;

    {% code overflow="wrap" %}
    ```pascal
    procedure (Driver: TIDCCustomKNXDriver; DataType: TKNXDataTypes; GroupValueType: TKNXGroupValueType; const GroupAddress, IndividualAddress: string; const AData: TIDCBytes) of object;
    ```
    {% endcode %}

    This event is triggered when a KNX group address telegram is received.
*   **`OnKNXDeviceConnected`**:&#x20;

    {% code overflow="wrap" %}
    ```objectpascal
    procedure (Driver: TIDCCustomKNXDriver; IPRouter: TKNXIPRouterDevice; const ConnectedChannel: Word) of object;
    ```
    {% endcode %}

    This event is triggered when a KNX device successfully connects.

### Methods

* **`StartKNXDiscovery`**: Starts the KNX device discovery process.
* **`StopKNXDiscovery`**: Stops the KNX device discovery process.
*   **`WriteBytesToGroupAddress`**: Sends a write request to a KNX group address.

    ```pascal
    procedure WriteBytesToGroupAddress(const ADestAddress: string; const Value: TIDCBytes);
    ```
*   **`ReadBytesFromGroupAddress`**: Sends a read request to a KNX group address.

    ```pascal
    procedure ReadBytesFromGroupAddress(const ADestAddress: string);
    ```
* **`HandleIncomingUDPData`**: Handles incoming UDP packets and processes them as KNX telegrams.
* **`ProcessKNXTelegram`**: Processes a KNX telegram received via UDP.

***

## Usage Examples

### [Example 1: KNX Basic Functions](../../prebuilt-demos.md#knx-basic-functions)

<details>

<summary>Quick snippets</summary>

{% code title="KNX Device Discovery" overflow="wrap" lineNumbers="true" %}
```pascal
procedure MyDeviceFoundEvent(Driver: TIDCCustomKNXDriver; IPRouter: TKNXIPRouterDevice; var AutoConnect: boolean);
begin
  WriteLn('Found KNX Device: ', IPRouter.FriendlyName);
  AutoConnect := True;  // Automatically connect to the device
end;

var
  KNXDriver: TIDCKNXDriver;
begin
  KNXDriver := TIDCKNXDriver.Create(nil);
  KNXDriver.OnKNXDeviceFound := MyDeviceFoundEvent;
  KNXDriver.StartKNXDiscovery;
end;
```
{% endcode %}

{% code title="Send Raw KNX Data" overflow="wrap" lineNumbers="true" %}
```pascal
procedure SendGroupValue;
var
  KNXDriver: TIDCKNXDriver;
  Value: TIDCBytes;
begin
  KNXDriver := TIDCKNXDriver.Create(nil);
  SetLength(Value, 1);
  Value[0] := $01;  // Example data value to write
  KNXDriver.WriteBytesToGroupAddress('1/2/3', Value);
end;
```
{% endcode %}

</details>
