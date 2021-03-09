/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of runtime;

//---------------------------------------------------------------------------------------
//                                        PROBES
//---------------------------------------------------------------------------------------

/// Enumerates the different states of a probe.
enum ProbeState { created, initialized, resumed, paused, stopped }

/// A [Probe] is responsible for collecting data.
///
/// The runtime state of a [Probe] is defined in [ProbeState] and has the following
/// state machine:
///
///         +-----------------------------------------------+
///         | created -> initialized -> resumed <-> paused  | -> stopped
///         +-----------------------------------------------+
///
/// A probe's [state] can be set using the [initialize], [start], [pause], [resume], and [stop] methods.
/// The [restart] is only used if the probes [measure] has changed (e.g. disabling the probe).
/// This is rarely needed.
///
/// The [state] property reveals the probe's current runtime state.
/// The [stateEvents] is a stream of state changes which can be listen to as a broadcast stream.
///
/// Probes return sensed data in a [Stream] as [events]. This is the main
/// usage of a probe. For example, to listens to events and print them;
///
///     probe.events.forEach(print);
///
abstract class Probe {
  /// Is this probe enabled, i.e. should run.
  bool get enabled;

  /// The type of this probe according to [DataType].
  String get type;

  /// The runtime state of this probe.
  ProbeState get state;

  /// The runtime state changes of this probe.
  ///
  /// This is useful for listening on state changes as specified in [ProbeState].
  /// Can e.g. be used in a [StreamBuilder] when showing the UI of a probe.
  /// The following example is taken from the CARP Mobile Sensing App
  ///
  ///       Widget buildProbeListTile(BuildContext context, ProbeModel probe) {
  ///           return StreamBuilder<ProbeStateType>(
  ///             stream: probe.stateEvents,
  ///             initialData: ProbeState.created,
  ///             builder: (context, AsyncSnapshot<ProbeState> snapshot) {
  ///               if (snapshot.hasData) {
  ///                 return ListTile(
  ///                   isThreeLine: true,
  ///                   leading: Icon(
  ///                     probe.icon.icon,
  ///                     size: 50,
  ///                     color: probe.icon.color,
  ///                   ),
  ///                   title: Text(probe.name),
  ///                   subtitle: Text(probe.description),
  ///                   trailing: probe.stateIcon,
  ///                 );
  ///               } else if (snapshot.hasError) {
  ///                 return Text('Error in probe state - ${snapshot.error}');
  ///              }
  ///              return Text('Unknown');
  ///           },
  ///         );
  ///       }
  /// This will update the trailing icon of the probe every time the probe change
  /// state (e.g. from `resumed` to `paused`).
  Stream<ProbeState> get stateEvents;

  /// The [Measure] that configures this probe.
  Measure get measure;

  /// A printer-friendly name for this probe. Takes its name from [Measure.name] as default.
  String get name;

  /// A [Stream] generating sensor data events from this probe.
  Stream<Datum> get events;

  /// Initialize the probe before starting it.
  ///
  /// The configuration of the probe is specified in the [measure].
  void initialize(Measure measure);

  /// Start the probe();
  void start();

  /// Pause the probe. The probe is paused until [resume] or [restart] is called.
  void pause();

  /// Resume the probe.
  void resume();

  /// Restart the probe.
  ///
  /// This forces the probe to reload its configuration from
  /// its [Measure] and restart sampling accordingly. If a new [measure] is
  /// to be used, this new measure must be specified in the
  /// [initialize] method before calling restart.
  ///
  /// This methods is used when sampling configuration is adapted, e.g. as
  /// part of the power-awareness.
  void restart();

  /// Stop the probe. Once a probe is stopped, it cannot be started again.
  /// If you need to restart a probe, use the [restart] or [pause] and [resume] methods.
  void stop();
}

/// An abstract implementation of a [Probe] to extend from.
abstract class AbstractProbe with MeasureListener implements Probe {
  StreamController<ProbeState> _stateEventController = StreamController.broadcast();
  Stream<ProbeState> get stateEvents => _stateEventController.stream;

  bool get enabled => measure.enabled ?? true;
  String get type => measure.type.name;
  String get name => measure.name ?? 'NO_NAME';

  ProbeState get state => _stateMachine.state;

  _ProbeStateMachine _stateMachine;
  void _setState(_ProbeStateMachine state) {
    _stateMachine = state;
    _stateEventController.add(state.state);
  }

  Measure _measure;
  Measure get measure => _measure;

  AbstractProbe() : super() {
    _stateMachine = _CreatedState(this);
  }

  // ProbeState handlers
  void initialize(Measure measure) async {
    assert(measure != null, 'Probe cannot be initialized with a null measure.');
    _measure = measure;
    measure.addMeasureListener(this);
    _stateMachine.initialize(measure);
  }

  void start() => _stateMachine.start();
  void restart() => _stateMachine.restart();
  void pause() => _stateMachine.pause();
  void resume() => _stateMachine.resume();
  void stop() {
    _stateMachine.stop();
    _stateEventController.close();
  }

  /// Callback for initialization of probe
  void onInitialize(Measure measure);

  /// Callback for starting probe
  void onStart();

  /// Callback for resuming probe
  void onResume();

  /// Callback for pausing probe
  void onPause();

  /// Callback for restarting probe
  void onRestart();

  /// Callback for stopping probe
  void onStop();

  /// Callback when this probe's [measure] has changed.
  void hasChanged(Measure measure) {
    restart();
  }
}

//---------------------------------------------------------------------------------------
//                                 PROBE STATE MACHINE
//
//         created -> initialized -> resumed <-> paused *-> stopped
//
//---------------------------------------------------------------------------------------

// all of the below probe state machine classes are private and only used internally
// hence, they are not documented

abstract class _ProbeStateMachine {
  ProbeState get state;
  void initialize(Measure measure);
  void start();
  void pause();
  void resume();
  void restart();
  void stop();
}

abstract class _AbstractProbeState implements _ProbeStateMachine {
  ProbeState state;
  AbstractProbe probe;
  _AbstractProbeState(this.probe, this.state) : assert(probe != null);

  // pr. default, a probe cannot be initialized while running -- only when created
  void initialize(Measure measure) {}

  // Default stop behavior. A probe can be stopped in all states.
  void stop() {
    print('Stopping $probe');
    probe._setState(_StoppedState(probe));
    probe.onStop();
  }
}

class _CreatedState extends _AbstractProbeState implements _ProbeStateMachine {
  _CreatedState(Probe probe) : super(probe, ProbeState.created);

  void initialize(Measure measure) {
    print('Initializing $probe, measure: $measure');
    probe.onInitialize(measure);
    probe._setState(_InitializedState(probe));
  }

  void start() {} // cannot be started
  void restart() {} // cannot be restarted
  void pause() {} // cannot be paused
  void resume() {} // cannot be resumed
}

class _InitializedState extends _AbstractProbeState implements _ProbeStateMachine {
  _InitializedState(Probe probe) : super(probe, ProbeState.initialized);

  void start() {
    print('Starting $probe');
    probe.onStart();
    if (probe.enabled) {
      probe.onResume();
      probe._setState(_ResumedState(probe));
    } else {
      probe.onPause();
      probe._setState(_PausedState(probe));
    }
  }

  void restart() {} // cannot be restarted before started
  void pause() {} // cannot be paused before started
  void resume() {} // cannot be resumed before started
}

class _ResumedState extends _AbstractProbeState implements _ProbeStateMachine {
  _ResumedState(Probe probe) : super(probe, ProbeState.resumed);

  void start() {} // cannot be started (again)

  void restart() {
    print('Restarting $probe');
    probe.pause(); // first pause probe, setting it in a paused state
    probe.onRestart();
    if (probe.enabled) // check if it has been enabled
      probe.resume();
  }

  void pause() {
    print('Pausing $probe');
    probe.onPause();
    probe._setState(_PausedState(probe));
  }

  void resume() {} // resuming a resumed probe does nothing
}

class _PausedState extends _AbstractProbeState implements _ProbeStateMachine {
  _PausedState(Probe probe) : super(probe, ProbeState.paused);

  void start() {} // cannot be started (again)

  void restart() {
    print('Restarting $probe');
    probe.onRestart();
    if (probe.enabled) // check if probe is enabled
      probe.resume();
  }

  void pause() {} // pausing a paused probe does nothing

  void resume() {
    if (probe.enabled) {
      print('Resuming $probe');
      probe.onResume();
      probe._setState(_ResumedState(probe));
    }
  }
}

class _StoppedState extends _AbstractProbeState implements _ProbeStateMachine {
  _StoppedState(Probe probe) : super(probe, ProbeState.stopped);

  // in a stopped state, a probe does not respond to any state changes.
  void start() {}
  void restart() {}
  void pause() {}
  void resume() {}
}

//---------------------------------------------------------------------------------------
//                                SPECIALIZED PROBES
//---------------------------------------------------------------------------------------

/// A [DatumProbe] can collect one piece of [Datum], send its to its stream, and then stops.
///
/// The [Datum] to be collected should be implemented in the [getDatum] method.
abstract class DatumProbe extends AbstractProbe {
  StreamController<Datum> _events = StreamController<Datum>();
  Stream<Datum> get events => _events.stream;

  void onInitialize(Measure measure) {}

  void onStart() {
    _events.addStream(Stream.fromFuture(getDatum()));
  }

  void onRestart() {}
  void onResume() {}
  void onPause() {}
  void onStop() {}

  /// Subclasses should implement this method to collect a [Datum].
  Future<Datum> getDatum();
}

/// A periodic probe is triggered at regular intervals, specified by its [frequency] property
/// in a [PeriodicMeasure].
///
/// When triggered, a periodic probe collect a piece of data ([Datum]) using the [getDatum] method.
/// Note that the [duration] parameter in a [PeriodicMeasure] is **not** used.
///
/// See [MemoryProbe] for an example.
abstract class PeriodicDatumProbe extends DatumProbe {
  Timer timer;
  StreamController<Datum> controller = StreamController<Datum>.broadcast();
  Duration frequency, duration;

  Stream<Datum> get events => controller.stream;

  void onInitialize(Measure measure) {
    assert(measure is PeriodicMeasure);
    frequency = Duration(milliseconds: (measure as PeriodicMeasure).frequency);
    duration = ((measure as PeriodicMeasure).duration != null)
        ? Duration(milliseconds: (measure as PeriodicMeasure).duration)
        : null;
  }

  void onRestart() {
    frequency = Duration(milliseconds: (measure as PeriodicMeasure).frequency);
    duration = ((measure as PeriodicMeasure).duration != null)
        ? Duration(milliseconds: (measure as PeriodicMeasure).duration)
        : null;
  }

  void onResume() {
    super.onResume();
    // create a recurrent timer that resumes sampling every [frequency].
    timer = Timer.periodic(frequency, (Timer t) async {
      try {
        getDatum().then((Datum data) {
          if (data != null) controller.add(data);
        });
      } catch (e, s) {
        controller.addError(e, s);
      }
    });
  }

  void onPause() {
    super.onPause();
    if (timer != null) timer.cancel();
  }

  void onStop() {
    if (timer != null) timer.cancel();
    controller.close();
  }
}

/// An abstract class used to create a probe that listen to events from a [Stream].
///
/// Sub-classes must implement the
///
///     Stream<Datum> get stream => ...
///
/// method in order to provide the stream to collect data from.
/// See [ConnectivityProbe] for a simple example or [BatteryProbe] for a more
/// sophisticated example.
abstract class StreamProbe extends AbstractProbe {
  StreamSubscription<dynamic> subscription;
  StreamController<Datum> controller = StreamController<Datum>.broadcast();
  Stream<Datum> get events => controller.stream;

  /// The stream for this [StreamProbe]. Must be implemented by sub-classes.
  Stream<Datum> get stream;

  // Do nothing here. Can be overwritten in subclasses.
  void onInitialize(Measure measure) {}

  void onStart() {
    assert(stream != null, 'Stream cannot be null in a StreamProbe');
    subscription = stream.listen(onData, onError: onError, onDone: onDone);
  }

  void onRestart() {}

  void onPause() {
    // Not all underlying streams seems to comply to the pause event.
    // For example, the location and activity probe
    // TODO - implement support for pause/resume in the StreamProbe
    if (subscription != null) subscription.pause();
  }

  void onResume() {
    if (subscription != null) subscription.resume();
  }

  void onStop() {
    if (subscription != null) subscription.cancel();
    controller.close();
  }

  void onData(Datum event) => controller.add(event);

  void onError(error) => controller.addError(error);

  void onDone() => controller.close();
}

/// A periodic probe listening on a stream. Listening is done periodically as specified in a
/// [PeriodicMeasure] listening on intervals every [frequency] for a period of [duration]. During this
/// period, all events are forwarded to this probes [events] stream.
///
/// Just like in [StreamProbe], sub-classes must implement the
///
///     Stream<Datum> get stream => ...
///
/// method in order to provide the stream to collect data from.
abstract class PeriodicStreamProbe extends StreamProbe {
  Timer timer;
  Duration frequency, duration;

  void onInitialize(Measure measure) {
    assert(measure is PeriodicMeasure);
    frequency = Duration(milliseconds: (measure as PeriodicMeasure).frequency);
    duration = ((measure as PeriodicMeasure).duration != null)
        ? Duration(milliseconds: (measure as PeriodicMeasure).duration)
        : null;
  }

  void onRestart() {
    frequency = Duration(milliseconds: (measure as PeriodicMeasure).frequency);
    duration = ((measure as PeriodicMeasure).duration != null)
        ? Duration(milliseconds: (measure as PeriodicMeasure).duration)
        : null;
  }

  void onResume() {
    if (subscription != null) {
      // create a recurrent timer that resume sampling.
      timer = Timer.periodic(frequency, (Timer t) {
        subscription.resume();
        // create a timer that pause the sampling after the specified duration.
        Timer(duration, () {
          subscription.pause();
        });
      });
    }
  }

  void onPause() {
    if (timer != null) timer.cancel();
    super.onPause();
  }

  void onStop() async {
    if (timer != null) timer.cancel();
    super.onStop();
  }
}

/// An abstract probe which can be used to sample data into a buffer,
/// every [frequency] for a period of [duration]. These events are buffered, and
/// once collected for the [duration], are collected from the [getDatum] method and
/// send to the main [events] stream.
///
/// When sampling starts, the [onSamplingStart] handle is called.
/// When the sampling window ends, the [onSamplingEnd] handle is called.
///
/// See [AudioProbe] for an example.
abstract class BufferingPeriodicProbe extends DatumProbe {
  StreamController<Datum> controller = StreamController<Datum>.broadcast();
  Stream<Datum> get events => controller.stream;
  Timer timer;
  Duration frequency, duration;

  void onInitialize(Measure measure) {
    assert(measure is PeriodicMeasure);
    frequency = Duration(milliseconds: (measure as PeriodicMeasure).frequency);
    duration = ((measure as PeriodicMeasure).duration != null)
        ? Duration(milliseconds: (measure as PeriodicMeasure).duration)
        : null;
  }

  void onRestart() {
    frequency = Duration(milliseconds: (measure as PeriodicMeasure).frequency);
    duration = ((measure as PeriodicMeasure).duration != null)
        ? Duration(milliseconds: (measure as PeriodicMeasure).duration)
        : null;
  }

  void onResume() {
    // create a recurrent timer that every [frequency] resumes the buffering.
    timer = Timer.periodic(frequency, (Timer t) {
      onSamplingStart();
      // create a timer that stops the buffering after the specified [duration].
      Timer(duration, () {
        onSamplingEnd();
        // collect the datum
        getDatum().then((datum) {
          if (datum != null) controller.add(datum);
        });
      });
    });
  }

  void onPause() {
    if (timer != null) timer.cancel();
    // check if there are some buffered data that needs to be collected before pausing
    getDatum().then((datum) {
      if (datum != null) controller.add(datum);
    });
  }

  void onStop() {
    if (timer != null) timer.cancel();
    controller.close();
  }

  /// Handler called when sampling period starts.
  void onSamplingStart();

  /// Handler called when sampling period ends.
  void onSamplingEnd();

  /// Subclasses should implement / override this method to collect the [Datum].
  /// This method will be called every time data has been buffered for a [duration]
  /// and should return the final [Datum] for the buffered data.
  Future<Datum> getDatum();
}

//typedef OnSamplingDataCallback = void Function(dynamic event);
//typedef OnSamplingCallback = void Function();

/// An abstract probe which can be used to sample data from a buffering stream,
/// every [frequency] for a period of [duration]. These events are buffered, and
/// once collected for the [duration], are collected from the [getDatum] method and
/// send to the main [events] stream.
///
/// Sub-classes must implement the
///
///     Stream<dynamic> get bufferingStream => ...
///
/// method in order to provide the stream to be buffered.
///
/// When sampling starts, the [onSamplingStart] handle is called.
/// When the sampling window ends, the [onSamplingEnd] handle is called.
///
/// See [LightProbe] for an example.
abstract class BufferingPeriodicStreamProbe extends PeriodicStreamProbe {
  // we don't use the stream in the super class so we give it an empty non-null stream
  Stream<Datum> get stream => Stream<Datum>.empty();

  void onStart() async {
    assert(bufferingStream != null, 'Buffering event stream must not be null');
    subscription = bufferingStream.listen(onSamplingData, onError: onError, onDone: onDone);
  }

  void onResume() {
    subscription.resume();
    timer = Timer.periodic(frequency, (Timer t) {
      onSamplingStart();
      subscription.resume();
      Timer(duration, () {
        subscription.pause();
        onSamplingEnd();
        getDatum().then((datum) {
          if (datum != null) controller.add(datum);
        });
      });
    });
  }

  void onPause() {
    if (timer != null) timer.cancel();
    subscription.pause();
    // check if there are some buffered data that needs to be collected before pausing
    getDatum().then((datum) {
      if (datum != null) controller.add(datum);
    });
  }

  // Sub-classes should implement the following handler methods.

  /// The stream of events to be buffered. Must be specified by sub-classes.
  Stream<dynamic> get bufferingStream;

  /// Handler called when sampling period starts.
  void onSamplingStart();

  /// Handler called when sampling period ends.
  void onSamplingEnd();

  /// Handler for handling onData events from the buffering stream.
  void onSamplingData(dynamic event);

  /// Subclasses should implement / override this method to collect the [Datum].
  /// This method will be called every time data has been buffered for a [duration]
  /// and should return the final [Datum] for the buffered data.
  Future<Datum> getDatum();
}

/// An abstract probe which can be used to buffer data from a stream and collect data
/// every [frequency]. All events from the [bufferingStream] are buffered, and
/// collected from the [getDatum] method every [frequency] and send to the
/// main [events] stream.
///
/// Sub-classes must implement the
///
///     Stream<dynamic> get bufferingStream => ...
///
/// method in order to provide the stream to be buffered.
///
/// When the sampling window ends, the [getDatum] method is called.
///
/// See [PedometerProbe] for an example.
abstract class BufferingStreamProbe extends BufferingPeriodicStreamProbe {
  void onResume() {
    subscription.resume();
    timer = Timer.periodic(frequency, (Timer t) {
      onSamplingStart();
      getDatum().then((datum) {
        if (datum != null) controller.add(datum);
      });
    });
  }

  void onSamplingEnd() {}
  void onSamplingStart() {}
}
