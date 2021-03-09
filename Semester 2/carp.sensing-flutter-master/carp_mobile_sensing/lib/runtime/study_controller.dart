/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of runtime;

/// A [StudyController] controls the execution of a [Study].
class StudyController {
  Study study;
  StudyExecutor executor;
  DataManager dataManager;
  SamplingSchema samplingSchema;
  String privacySchemaName;
  DatumStreamTransformer transformer;

  Stream<Datum> events;
  PowerAwarenessState powerAwarenessState = NormalSamplingState.instance;

  /// The size of this current study in terms of number of [Datum] object that has been collected.
  int samplingSize = 0;

  /// Create a new [StudyController] to control the [study].
  ///
  /// A number of optional parameters can be specified:
  ///    * A custom study [executor] can be specified. If null, the default [StudyExecutor] is used.
  ///    * A specific [samplingSchema] can be used. If null, [SamplingSchema.normal] with power-awareness is used.
  ///    * A specific [dataManager] can be provided. If null, a [DataManager] will be looked up in the
  ///      [DataManagerRegistry] based on the type of the study's [DataEndPoint].
  ///    * The name of a [PrivacySchema] can be provided in [privacySchemaName].
  ///      Use [PrivacySchema.DEFAULT] for the default, built-in schema. If null, no privacy schema is used.
  ///    * A generic [transformer] can be provided which transform each collected data. If null, a 1:1 mapping is done, i.e. no transformation.
  StudyController(this.study,
      {this.executor, this.samplingSchema, this.dataManager, this.privacySchemaName, this.transformer})
      : assert(study != null),
        super() {
    executor ??= StudyExecutor(study);
    samplingSchema ??= SamplingSchema.normal(powerAware: true);
    dataManager ??= DataManagerRegistry.lookup(study.dataEndPoint.type);
    privacySchemaName ??= NameSpace.CARP;
    transformer ??= ((events) => events);

    // set up transformation in the following order:
    // 1. privacy schema
    // 2. preferred data format as specified in the study protocol
    // 3. any custom transformer
    events = transformer(executor.events
        .map((datum) => TransformerSchemaRegistry.lookup(privacySchemaName).transform(datum))
        .map((datum) => TransformerSchemaRegistry.lookup(study.dataFormat).transform(datum)));

    // old, simple version below
    // events = transformer(executor.events);
  }

  /// Initialize this controller. Must be called only once, and before [start] is called.
  Future<void> initialize() async {
    await Device.getDeviceInfo();

    print('CARP Mobile sensing - Initializing Study Controller: ');
    print('     study id : ${study.id}');
    print('   study name : ${study.name}');
    print('         user : ${study.userId}');
    print('     endpoint : ${study.dataEndPoint.type}');
    print('  data format : ${study.dataFormat}');
    print('     platform : ${Device.platform.toString()}');
    print('    device ID : ${Device.deviceID.toString()}');
    print(' data manager : ${dataManager.toString()}');

    if (samplingSchema != null) {
      // doing two adaptation is a bit of a hack; used to ensure that
      // restoration values are set to the specified sampling schema
      study.adapt(samplingSchema, restore: false);
      study.adapt(samplingSchema, restore: false);
    }

    executor.initialize(Measure(MeasureType(NameSpace.CARP, DataType.EXECUTOR)));
    dataManager.initialize(study, events);

    events.listen((data) => samplingSize++);
  }

  BatteryProbe _battery = BatteryProbe();

  /// Enable power-aware sensing in this study. See [PowerAwarenessState].
  Future<void> enablePowerAwareness() async {
    if (samplingSchema.powerAware) {
      _battery.events.listen((datum) {
        BatteryDatum batteryState = (datum as BatteryDatum);
        if (batteryState.batteryStatus == BatteryDatum.STATE_DISCHARGING) {
          // only apply power-awareness if not charging.
          PowerAwarenessState newState = powerAwarenessState.adapt(batteryState.batteryLevel);
          if (newState != powerAwarenessState) {
            powerAwarenessState = newState;
            print('PowerAware: Going to $powerAwarenessState, level ${batteryState.batteryLevel}%');
            study.adapt(powerAwarenessState.schema);
          }
        }
      });
      _battery
          .initialize(Measure(MeasureType(NameSpace.CARP, DeviceSamplingPackage.BATTERY), name: 'PowerAwarenessProbe'));
      _battery.start();
    }
  }

  /// Disable power-aware sensing.
  void disablePowerAwareness() {
    _battery.stop();
  }

  /// Start this controller, i.e. start collecting data according to the specified [study] and [samplingSchema].
  Future<void> start() async {
    print("Starting data sampling ...");
    enablePowerAwareness();
    executor.start();
  }

  /// Stop the sampling.
  ///
  /// Once a controller is stopped it **cannot** be (re)started.
  /// If a controller should be restarted, use the [pause] and [resume] methods.
  void stop() {
    print("Stopping data sampling ...");
    disablePowerAwareness();
    dataManager.close();
    executor.stop();
  }

  /// Pause the controller, which will pause data collection.
  void pause() {
    print("Pausing data sampling ...");
    executor.pause();
  }

  /// Resume the controller, i.e. resume data collection.
  void resume() {
    print("Resuming data sampling ...");
    executor.resume();
  }
}

/// This default power-awareness schema operates with four power states:
///
///
///       0%   10%        30%        50%                         100%
///       +-----+----------+----------+----------------------------+
///        none   minimum     light              normal
///
abstract class PowerAwarenessState {
  static const int LIGHT_SAMPLING_LEVEL = 50;
  static const int MINIMUM_SAMPLING_LEVEL = 30;
  static const int NO_SAMPLING_LEVEL = 10;

  static PowerAwarenessState instance;

  PowerAwarenessState adapt(int level);
  SamplingSchema get schema;
}

class NoSamplingState implements PowerAwarenessState {
  static NoSamplingState instance = NoSamplingState();

  PowerAwarenessState adapt(int level) {
    if (level > PowerAwarenessState.NO_SAMPLING_LEVEL)
      return MinimumSamplingState.instance;
    else
      return NoSamplingState.instance;
  }

  SamplingSchema get schema => SamplingSchema.none();

  String toString() => "Disabled Sampling Mode";
}

class MinimumSamplingState implements PowerAwarenessState {
  static MinimumSamplingState instance = MinimumSamplingState();

  PowerAwarenessState adapt(int level) {
    if (level < PowerAwarenessState.NO_SAMPLING_LEVEL)
      return NoSamplingState.instance;
    else if (level > PowerAwarenessState.MINIMUM_SAMPLING_LEVEL)
      return LightSamplingState.instance;
    else
      return MinimumSamplingState.instance;
  }

  SamplingSchema get schema => SamplingSchema.minimum();

  String toString() => "Minimun Sampling Mode";
}

class LightSamplingState implements PowerAwarenessState {
  static LightSamplingState instance = LightSamplingState();

  PowerAwarenessState adapt(int level) {
    if (level < PowerAwarenessState.MINIMUM_SAMPLING_LEVEL)
      return MinimumSamplingState.instance;
    else if (level > PowerAwarenessState.LIGHT_SAMPLING_LEVEL)
      return NormalSamplingState.instance;
    else
      return LightSamplingState.instance;
  }

  SamplingSchema get schema => SamplingSchema.light();

  String toString() => "Light Sampling Mode";
}

class NormalSamplingState implements PowerAwarenessState {
  static NormalSamplingState instance = NormalSamplingState();

  PowerAwarenessState adapt(int level) {
    if (level < PowerAwarenessState.LIGHT_SAMPLING_LEVEL)
      return LightSamplingState.instance;
    else
      return NormalSamplingState.instance;
  }

  SamplingSchema get schema => SamplingSchema.normal();

  String toString() => "Normal Sampling Mode";
}
