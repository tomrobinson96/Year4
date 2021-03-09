part of movisens;

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class MovisensMeasure extends Measure {
  String address , deviceName ;

  int weight, height, age;
  Gender gender;
  SensorLocation sensorLocation;

  String get getAddress => address;

  MovisensMeasure(MeasureType type,
      {name, enabled, this.address,this.sensorLocation, this.gender, this.deviceName, this.height, this.weight,this.age})
      : super(type, name: name, enabled: enabled);

  static Function get fromJsonFunction => _$MovisensMeasureFromJson;
  factory MovisensMeasure.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory.fromJson(
          json[Serializable.CLASS_IDENTIFIER].toString(), json);
  Map<String, dynamic> toJson() => _$MovisensMeasureToJson(this);
}
