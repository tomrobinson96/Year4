part of mobile_sensing_app;

class ProbeDescription {
  static Map<String, String> get probeTypeDescription => {
        DataType.UNKNOWN: 'Unknown Probe',
        DataType.NONE: 'Non-configured Probe',
        DeviceSamplingPackage.MEMORY: 'Collecting free physical and virtual memory.',
        DeviceSamplingPackage.DEVICE: 'Basic Device (Phone) Information.',
        DeviceSamplingPackage.BATTERY: 'Collecting battery level and charging status.',
        SensorSamplingPackage.PEDOMETER: 'Collecting step counts on a regular basis.',
        SensorSamplingPackage.ACCELEROMETER: "Collecting sensor data from the phone's onboard accelerometer.",
        SensorSamplingPackage.GYROSCOPE: "Collecting sensor data from the phone's onboard gyroscope.",
        SensorSamplingPackage.LIGHT: 'Measures ambient light in lux on a regular basis.',
        ConnectivitySamplingPackage.BLUETOOTH: 'Collecting nearby bluetooth devices on a regular basis.',
        AudioSamplingPackage.AUDIO: 'Records ambient sound on a regular basis.',
        AudioSamplingPackage.NOISE: 'Measures noise level in decibel on a regular basis.',
        ContextSamplingPackage.LOCATION: 'Collecting location information when moving.',
        ConnectivitySamplingPackage.CONNECTIVITY: 'Collecting information on connectivity status and mode.',
        AppsSamplingPackage.APPS: 'Collecting a list of installed apps.',
        AppsSamplingPackage.APP_USAGE: 'Collecting app usage statistics.',
        CommunicationSamplingPackage.TEXT_MESSAGE_LOG: 'Collecting the SMS message log.',
        CommunicationSamplingPackage.TEXT_MESSAGE: 'Collecting in/out-going SMS text messages.',
        DeviceSamplingPackage.SCREEN: 'Collecting screen events (on/off/unlock).',
        CommunicationSamplingPackage.PHONE_LOG: 'Collects the phone call log.',
        ContextSamplingPackage.ACTIVITY: 'Recognize physical activity, e.g. sitting, walking, biking, etc.',
        ContextSamplingPackage.WEATHER: 'Collects local weather on a regular basis.',
        ContextSamplingPackage.GEOFENCE: 'Track movement in/our of this geofence.',
        CommunicationSamplingPackage.CALENDAR: 'Collects entries from phone calendars'
        //DataType.APPLE_HEALTHKIT: 'Collects health data from Apple Health Kit.',
        //DataType.GOOGLE_FIT: 'Collects health data from Google Fit.',
      };

  static Map<String, Icon> get probeTypeIcon => {
        DataType.UNKNOWN: Icon(Icons.error, size: 50, color: CACHET.GREY_4),
        DataType.NONE: Icon(Icons.report_problem, size: 50, color: CACHET.GREY_4),
        DeviceSamplingPackage.MEMORY: Icon(Icons.memory, size: 50, color: CACHET.GREY_4),
        DeviceSamplingPackage.DEVICE: Icon(Icons.phone_android, size: 50, color: CACHET.GREY_4),
        DeviceSamplingPackage.BATTERY: Icon(Icons.battery_charging_full, size: 50, color: CACHET.GREEN),
        SensorSamplingPackage.PEDOMETER: Icon(Icons.directions_walk, size: 50, color: CACHET.LIGHT_PURPLE),
        SensorSamplingPackage.ACCELEROMETER: Icon(Icons.adb, size: 50, color: CACHET.GREY_4),
        SensorSamplingPackage.GYROSCOPE: Icon(Icons.adb, size: 50, color: CACHET.GREY_4),
        SensorSamplingPackage.LIGHT: Icon(Icons.highlight, size: 50, color: CACHET.YELLOW),
        ConnectivitySamplingPackage.BLUETOOTH: Icon(Icons.bluetooth_searching, size: 50, color: CACHET.DARK_BLUE),
        AudioSamplingPackage.AUDIO: Icon(Icons.mic, size: 50, color: CACHET.ORANGE),
        AudioSamplingPackage.NOISE: Icon(Icons.hearing, size: 50, color: CACHET.YELLOW),
        ContextSamplingPackage.LOCATION: Icon(Icons.location_searching, size: 50, color: CACHET.CYAN),
        ConnectivitySamplingPackage.CONNECTIVITY: Icon(Icons.wifi, size: 50, color: CACHET.GREEN),
        AppsSamplingPackage.APPS: Icon(Icons.apps, size: 50, color: CACHET.LIGHT_GREEN),
        AppsSamplingPackage.APP_USAGE: Icon(Icons.get_app, size: 50, color: CACHET.LIGHT_GREEN),
        CommunicationSamplingPackage.TEXT_MESSAGE_LOG: Icon(Icons.textsms, size: 50, color: CACHET.LIGHT_PURPLE),
        CommunicationSamplingPackage.TEXT_MESSAGE: Icon(Icons.text_fields, size: 50, color: CACHET.LIGHT_PURPLE),
        DeviceSamplingPackage.SCREEN: Icon(Icons.screen_lock_portrait, size: 50, color: CACHET.LIGHT_PURPLE),
        CommunicationSamplingPackage.PHONE_LOG: Icon(Icons.phone_in_talk, size: 50, color: CACHET.ORANGE),
        ContextSamplingPackage.ACTIVITY: Icon(Icons.directions_bike, size: 50, color: CACHET.ORANGE),
        ContextSamplingPackage.WEATHER: Icon(Icons.cloud, size: 50, color: CACHET.LIGHT_BLUE_2),
        ContextSamplingPackage.GEOFENCE: Icon(Icons.location_on, size: 50, color: CACHET.CYAN),
        CommunicationSamplingPackage.CALENDAR: Icon(Icons.event, size: 50, color: CACHET.CYAN)
        //DataType.APPLE_HEALTHKIT: Icon(Icons.healing, size: 50, color: CACHET.RED),
        //DataType.GOOGLE_FIT: Icon(Icons.directions_run, size: 50, color: CACHET.GREEN),
      };

  static Map<ProbeState, Icon> get probeStateIcon => {
        ProbeState.created: Icon(Icons.child_care, color: CACHET.GREY_4),
        ProbeState.initialized: Icon(Icons.check, color: CACHET.LIGHT_PURPLE),
        ProbeState.resumed: Icon(Icons.radio_button_checked, color: CACHET.GREEN),
        ProbeState.paused: Icon(Icons.radio_button_unchecked, color: CACHET.RED),
        ProbeState.stopped: Icon(Icons.close, color: CACHET.GREY_2)
      };
}
