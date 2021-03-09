/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of communication;

/// This is the base class for this communication sampling package.
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry.register(CommunicationSamplingPackage());
/// ```
class CommunicationSamplingPackage implements SamplingPackage {
  static const String PHONE_LOG = "phone_log";
  static const String TELEPHONY = "telephony";
  static const String TEXT_MESSAGE_LOG = "text_message_log";
  static const String TEXT_MESSAGE = "text_message";
  static const String CALENDAR = "calendar";

  List<String> get dataTypes => [
        PHONE_LOG,
        //TELEPHONY,
        TEXT_MESSAGE_LOG,
        TEXT_MESSAGE,
        CALENDAR,
      ];

  Probe create(String type) {
    switch (type) {
      case PHONE_LOG:
        return PhoneLogProbe();
      case TEXT_MESSAGE_LOG:
        return TextMessageLogProbe();
      case TEXT_MESSAGE:
        return TextMessageProbe();
      case TELEPHONY:
        throw "Not implemented yet";
      case CALENDAR:
        return CalendarProbe();
      default:
        return null;
    }
  }

  void onRegister() {
    FromJsonFactory.registerFromJsonFunction("PhoneLogMeasure", PhoneLogMeasure.fromJsonFunction);
    FromJsonFactory.registerFromJsonFunction("CalendarMeasure", CalendarMeasure.fromJsonFunction);

    TransformerSchemaRegistry.lookup(PrivacySchema.DEFAULT).add(TEXT_MESSAGE, text_message_datum_anoymizer);
    TransformerSchemaRegistry.lookup(PrivacySchema.DEFAULT).add(TEXT_MESSAGE_LOG, text_message_log_anoymizer);
    TransformerSchemaRegistry.lookup(PrivacySchema.DEFAULT).add(PHONE_LOG, phone_log_anoymizer);
    TransformerSchemaRegistry.lookup(PrivacySchema.DEFAULT).add(CALENDAR, calendar_anoymizer);
  }

  SamplingSchema get common => SamplingSchema()
    ..type = SamplingSchemaType.COMMON
    ..name = 'Common (default) communication sampling schema'
    ..powerAware = true
    ..measures.addEntries([
      MapEntry(
          PHONE_LOG,
          PhoneLogMeasure(MeasureType(NameSpace.CARP, PHONE_LOG),
              // collect phone log once pr. day
              name: 'Phone Log',
              enabled: true,
              //frequency: 60 * 1000,
              frequency: 1 * 24 * 60 * 60 * 1000,
              days: 2)),
      MapEntry(
          TEXT_MESSAGE_LOG,
          PeriodicMeasure(
            MeasureType(NameSpace.CARP, TEXT_MESSAGE_LOG),
            // collect text messages once pr. day
            name: 'Text Message (SMS) Log',
            enabled: true,
            frequency: 1 * 24 * 60 * 60 * 1000,
            //frequency: 60 * 1000
          )),
      MapEntry(
          TEXT_MESSAGE, Measure(MeasureType(NameSpace.CARP, TEXT_MESSAGE), name: 'Text Message (SMS)', enabled: true)),
      MapEntry(
          CALENDAR,
          CalendarMeasure(MeasureType(NameSpace.CARP, CALENDAR),
              // collect calendar events once pr. day
              name: 'Calendar Events',
              enabled: true,
              frequency: 1 * 24 * 60 * 60 * 1000,
              daysBack: 1,
              daysFuture: 1)),
    ]);

  SamplingSchema get light => common
    ..type = SamplingSchemaType.LIGHT
    ..name = 'Light communication sampling'
    ..measures[PHONE_LOG].enabled = false
    ..measures[TEXT_MESSAGE_LOG].enabled = false
    ..measures[TEXT_MESSAGE].enabled = false
    ..measures[CALENDAR].enabled = false;

  SamplingSchema get minimum => light..type = SamplingSchemaType.MINIMUM;

  SamplingSchema get normal => common;

  SamplingSchema get debug => common
    ..type = SamplingSchemaType.DEBUG
    ..name = 'Debugging communication sampling schema'
    ..powerAware = false
    ..measures[PHONE_LOG] = PhoneLogMeasure(MeasureType(NameSpace.CARP, PHONE_LOG),
        // collect calendar events once pr. minute
        name: 'Phone Log',
        frequency: 60 * 1000,
        days: 1)
    ..measures[TEXT_MESSAGE_LOG] = PeriodicMeasure(MeasureType(NameSpace.CARP, TEXT_MESSAGE_LOG),
        // collect calendar events once pr. minute
        name: 'Text Message (SMS) Log',
        frequency: 60 * 1000)
    ..measures[CALENDAR] = CalendarMeasure(MeasureType(NameSpace.CARP, CALENDAR),
        // collect calendar events once pr. minute
        name: 'Calendar Events',
        frequency: 60 * 1000,
        daysBack: 1,
        daysFuture: 1);
}
