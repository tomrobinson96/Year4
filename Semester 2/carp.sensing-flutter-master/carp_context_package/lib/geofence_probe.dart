part of context;

/// Listen on location movements and reports a [GeofenceDatum] to the [stream]
/// when a geofence event happens. This probe can handle only one [GeofenceMeasure].
/// If you need multiple geofences, add a [GeofenceMeasure] for each to your [Study].
class GeofenceProbe extends StreamProbe {
  Geofence fence;
  StreamController<GeofenceDatum> geoFenceStreamController = StreamController<GeofenceDatum>.broadcast();

  void onInitialize(Measure measure) {
    assert(measure is GeofenceMeasure);
    super.onInitialize(measure);
    fence = Geofence.fromMeasure(measure);
    // listen in on the location service
    locationService
        .onLocationChanged()
        .asBroadcastStream()
        .map((location) => Location.fromLocationData(location))
        .listen((location) {
      // when a location event is fired, check if the new location creates a new [GeofenceDatum] event.
      // if so -- add it to the main stream.
      GeofenceDatum datum = fence.moved(location);
      if (datum != null) geoFenceStreamController.add(datum);
    });
  }

  Stream<GeofenceDatum> get stream => geoFenceStreamController.stream;
}

enum GeofenceState { ENTER, EXIT, DWELL }

/// A class representing a circular geofence with a center, a radius (in meters) and a name.

class Geofence {
  /// The last known state of this geofence.
  GeofenceState state = GeofenceState.EXIT;

  /// The last time an event was fired inside this geofence.
  DateTime lastEvent = DateTime.now();

  /// The center of the geofence as a GPS location.
  Location center;

  /// The radius of the geofence in meters.
  double radius;

  /// The dwell time of this geofence in miliseconds.
  /// If an object is located inside this geofence for more that [dwell] miliseconds,
  /// the [GeofenceState.DWELL] event is fired.
  int dwell;

  /// The name of this geofence.
  String name;

  /// Specify a geofence.
  Geofence({this.center, this.radius, this.dwell, this.name}) : super();

  Geofence.fromMeasure(GeofenceMeasure measure) {
    this.center = measure.center;
    this.radius = measure.radius;
    this.dwell = measure.dwell;
    this.name = measure.name;
  }

  GeofenceDatum moved(Location location) {
    GeofenceDatum datum;
    if (center.distanceTo(location) < radius) {
      // we're inside the geofence
      switch (state) {
        case GeofenceState.EXIT:
          // if we came from outside the fence, we have now entered
          state = GeofenceState.ENTER;
          lastEvent = DateTime.now();
          datum = GeofenceDatum(type: "ENTER", name: name);
          break;
        case GeofenceState.ENTER:
        case GeofenceState.DWELL:
          // if we were already inside, check if dwelling takes place
          if (dwell != null && DateTime.now().difference(lastEvent).inMilliseconds > dwell) {
            // we have been dwelling in this geofence
            state = GeofenceState.DWELL;
            lastEvent = DateTime.now();
            datum = GeofenceDatum(type: "DWELL", name: name);
          }
          break;
      }
    } else {
      // we're outside the geofence - check if we have left
      if (state != GeofenceState.EXIT) {
        // we have just left the geofence
        state = GeofenceState.EXIT;
        lastEvent = DateTime.now();
        datum = GeofenceDatum(type: "EXIT", name: name);
      }
    }

    return datum;
  }

  String toString() => 'Geofence - center: $center, radius: $radius, dwell: $dwell, name: $name, state: $state';
}
