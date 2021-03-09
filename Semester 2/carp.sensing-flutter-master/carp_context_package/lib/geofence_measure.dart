/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of context;

/// Earth radius in km.
const double earthRadius = 6371000.0;

/// Convert degrees to radians.
double degToRad(num deg) => deg * (math.pi / 180.0);

/// Convert radians to degrees.
double radToDeg(num rad) => rad * (180.0 / math.pi);

/// Location coordinated in Degrees (i.e. GPS-style).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class Location extends Serializable {
  /// Latitude in GPS coordinates.
  final double latitude;

  /// Longitude in GPS coordinates.
  final double longitude;

  Location(this.latitude, this.longitude)
      : assert(latitude != null),
        assert(longitude != null);

  Location.fromLocationData(location.LocationData location)
      : latitude = location.latitude,
        longitude = location.longitude,
        super();

  /// Returns the approximate distance in meters between this location and the given location.
  ///
  /// For distance calculations we use the  'haversine' formula to calculate the great-circle distance between two points.
  /// See http://www.movable-type.co.uk/scripts/latlong.html for details on how to
  /// calculate distance, bearing and more between latitude/longitude points.
  double distanceTo(Location destination) {
    assert(destination != null);
    final sDLat = math.sin((degToRad(destination.latitude) - degToRad(latitude)) / 2);
    final sDLng = math.sin((degToRad(destination.longitude) - degToRad(longitude)) / 2);
    final a = sDLat * sDLat + sDLng * sDLng * math.cos(degToRad(latitude)) * math.cos(degToRad(destination.latitude));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static Function get fromJsonFunction => _$LocationFromJson;
  factory Location.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory.fromJson(json[Serializable.CLASS_IDENTIFIER].toString(), json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  String toString() => 'Location (latitude:$latitude, longitude:$longitude)';
  int get hashCode => latitude.hashCode + longitude.hashCode;
  bool operator ==(Object other) => other is Location && latitude == other.latitude && longitude == other.longitude;
}

/// Specify the configuration of a circular geofence measure, specifying the:
///  - center
///  - radius
///  - name
/// of the geofence.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class GeofenceMeasure extends Measure {
  /// The center of the geofence as a GPS location.
  Location center;

  /// The radius of the geofence in meters.
  double radius;

  /// The dwell time of this geofence in miliseconds.
  /// If an object is located inside a geofence for more that [dwell] miliseconds,
  /// [GeofenceState.DWELL] are fired.
  int dwell;

  /// The name of this geofence.
  String name;

  /// Specify a geofence measure
  GeofenceMeasure(MeasureType type, {enabled, this.center, this.radius, this.name}) : super(type, enabled: enabled);

  static Function get fromJsonFunction => _$GeofenceMeasureFromJson;
  factory GeofenceMeasure.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory.fromJson(json[Serializable.CLASS_IDENTIFIER].toString(), json);
  Map<String, dynamic> toJson() => _$GeofenceMeasureToJson(this);
}
