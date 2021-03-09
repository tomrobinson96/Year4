import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

String _encode(Object object) => const JsonEncoder.withIndent(' ').convert(object);

void main() {
  setUp(() {
    // This is a hack. Need to create some serialization object in order to intialize searialization.
    Study study = Study("123", "kkk");
  });

  /// Test if we can load a raw JSON from a file and convert it into a [Study] object with all its [Task]s and [Measure]s.
  /// Note that this test, tests if a [Study] object can be create 'from scratch', i.e. without having been created before.
  test('Raw JSON string -> Study object', () async {
    String plainStudyJson = File("test/study_1234.json").readAsStringSync();

    Study plainStudy = Study.fromJson(json.decode(plainStudyJson) as Map<String, dynamic>);
    expect(plainStudy.id, "1234");

    print(_encode(plainStudy));
  });

  /// Test template.
  test('...', () {
    // test template
  });
}
