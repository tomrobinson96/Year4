/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of sensors;

/// The [LightProbe] listens to the phone's light sensor typically located near the front camera.
/// Every value is in the SI unit Lux and will be stored in a [LightDatum] object.
class LightProbe extends BufferingPeriodicStreamProbe {
  List<num> luxValues = new List();

  //LightProbe(PeriodicMeasure measure) : super(measure, lightSensorStream);
  //LightProbe() : super(lightSensorStream);

  Stream<dynamic> get bufferingStream => Light().lightSensorStream;

  Future<Datum> getDatum() async {
    if (luxValues.length > 0) {
      Stats stats = Stats.fromData(luxValues);
      return LightDatum(meanLux: stats.mean, stdLux: stats.standardDeviation, minLux: stats.min, maxLux: stats.max);
    } else {
      return null;
    }
  }

  void onSamplingStart() {
    luxValues.clear();
  }

  void onSamplingEnd() {}

  void onSamplingData(luxValue) => luxValues.add(luxValue);
}
