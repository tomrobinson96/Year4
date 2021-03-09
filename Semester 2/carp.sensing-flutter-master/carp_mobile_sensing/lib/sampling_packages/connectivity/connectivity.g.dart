// GENERATED CODE - DO NOT MODIFY BY HAND

part of connectivity;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectivityDatum _$ConnectivityDatumFromJson(Map<String, dynamic> json) {
  return ConnectivityDatum()
    ..id = json['id'] as String
    ..timestamp = json['timestamp'] == null
        ? null
        : DateTime.parse(json['timestamp'] as String)
    ..connectivityStatus = json['connectivity_status'] as String;
}

Map<String, dynamic> _$ConnectivityDatumToJson(ConnectivityDatum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('timestamp', instance.timestamp?.toIso8601String());
  writeNotNull('connectivity_status', instance.connectivityStatus);
  return val;
}

BluetoothDatum _$BluetoothDatumFromJson(Map<String, dynamic> json) {
  return BluetoothDatum()
    ..id = json['id'] as String
    ..timestamp = json['timestamp'] == null
        ? null
        : DateTime.parse(json['timestamp'] as String)
    ..advertisementName = json['advertisement_name'] as String
    ..bluetoothDeviceId = json['bluetooth_device_id'] as String
    ..bluetoothDeviceName = json['bluetooth_device_name'] as String
    ..bluetoothDeviceType = json['bluetooth_device_type'] as String
    ..connectable = json['connectable'] as bool
    ..txPowerLevel = json['tx_power_level'] as int
    ..rssi = json['rssi'] as int;
}

Map<String, dynamic> _$BluetoothDatumToJson(BluetoothDatum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('timestamp', instance.timestamp?.toIso8601String());
  writeNotNull('advertisement_name', instance.advertisementName);
  writeNotNull('bluetooth_device_id', instance.bluetoothDeviceId);
  writeNotNull('bluetooth_device_name', instance.bluetoothDeviceName);
  writeNotNull('bluetooth_device_type', instance.bluetoothDeviceType);
  writeNotNull('connectable', instance.connectable);
  writeNotNull('tx_power_level', instance.txPowerLevel);
  writeNotNull('rssi', instance.rssi);
  return val;
}
