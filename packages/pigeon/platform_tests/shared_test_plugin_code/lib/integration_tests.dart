// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'generated.dart';

/// Possible host languages that test can target.
enum TargetGenerator {
  /// The Windows C++ generator.
  cpp,

  /// The Android Java generator.
  java,

  /// The Android Kotlin generator.
  kotlin,

  /// The iOS Objective-C generator.
  objc,

  /// The iOS or macOS Swift generator.
  swift,
}

/// Sets up and runs the integration tests.
void runPigeonIntegrationTests(TargetGenerator targetGenerator) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final AllTypes genericAllTypes = AllTypes(
    aBool: true,
    anInt: 42,
    aDouble: 3.14159,
    aString: 'Hello host!',
    aByteArray: Uint8List.fromList(<int>[1, 2, 3]),
    a4ByteArray: Int32List.fromList(<int>[4, 5, 6]),
    a8ByteArray: Int64List.fromList(<int>[7, 8, 9]),
    aFloatArray: Float64List.fromList(<double>[2.71828, 3.14159]),
    aList: <Object?>['Thing 1', 2, true, 3.14],
    aMap: <Object?, Object?>{'a': 1, 'b': 2.0, 'c': 'three', 'd': false},
    anEnum: AnEnum.two,
  );

  final AllNullableTypes genericAllNullableTypes = AllNullableTypes(
    aNullableBool: true,
    aNullableInt: 42,
    aNullableDouble: 3.14159,
    aNullableString: 'Hello host!',
    aNullableByteArray: Uint8List.fromList(<int>[1, 2, 3]),
    aNullable4ByteArray: Int32List.fromList(<int>[4, 5, 6]),
    aNullable8ByteArray: Int64List.fromList(<int>[7, 8, 9]),
    aNullableFloatArray: Float64List.fromList(<double>[2.71828, 3.14159]),
    aNullableList: <Object?>['Thing 1', 2, true, 3.14],
    aNullableMap: <Object?, Object?>{
      'a': 1,
      'b': 2.0,
      'c': 'three',
      'd': false
    },
    nullableNestedList: <List<bool>>[
      <bool>[true, false],
      <bool>[false, true]
    ],
    nullableMapWithAnnotations: <String?, String?>{},
    nullableMapWithObject: <String?, Object?>{},
    aNullableEnum: AnEnum.two,
  );

  group('Host sync API tests', () {
    testWidgets('basic void->void call works', (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      expect(api.noop(), completes);
    });

    testWidgets('all datatypes serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final AllTypes echoObject = await api.echoAllTypes(genericAllTypes);

      expect(echoObject.aBool, genericAllTypes.aBool);
      expect(echoObject.anInt, genericAllTypes.anInt);
      expect(echoObject.aDouble, genericAllTypes.aDouble);
      expect(echoObject.aString, genericAllTypes.aString);
      expect(echoObject.aByteArray, genericAllTypes.aByteArray);
      expect(echoObject.a4ByteArray, genericAllTypes.a4ByteArray);
      expect(echoObject.a8ByteArray, genericAllTypes.a8ByteArray);
      expect(echoObject.aFloatArray, genericAllTypes.aFloatArray);
      expect(listEquals(echoObject.aList, genericAllTypes.aList), true);
      expect(mapEquals(echoObject.aMap, genericAllTypes.aMap), true);
      // TODO(stuartmorgan): Enable this once the Dart types are fixed; see
      // https://github.com/flutter/flutter/issues/116117
      // expect(echoObject.nestedList.length, genericAllTypes.nestedList.length);
      //for (int i = 0; i < echoObject.nestedList!.length; i++) {
      //  expect(listEquals(echoObject.nestedList![i], genericAllTypes.nestedList![i]),
      //      true);
      //}
      // expect(
      //     mapEquals(
      //         echoObject.mapWithAnnotations, genericAllTypes.mapWithAnnotations),
      //     true);
      // expect(
      //     mapEquals(echoObject.mapWithObject, genericAllTypes.mapWithObject), true);
      expect(echoObject.anEnum, genericAllTypes.anEnum);
    });

    testWidgets('all nullable datatypes serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final AllNullableTypes? echoObject =
          await api.echoAllNullableTypes(genericAllNullableTypes);
      expect(echoObject?.aNullableBool, genericAllNullableTypes.aNullableBool);
      expect(echoObject?.aNullableInt, genericAllNullableTypes.aNullableInt);
      expect(
          echoObject?.aNullableDouble, genericAllNullableTypes.aNullableDouble);
      expect(
          echoObject?.aNullableString, genericAllNullableTypes.aNullableString);
      expect(echoObject?.aNullableByteArray,
          genericAllNullableTypes.aNullableByteArray);
      expect(echoObject?.aNullable4ByteArray,
          genericAllNullableTypes.aNullable4ByteArray);
      expect(echoObject?.aNullable8ByteArray,
          genericAllNullableTypes.aNullable8ByteArray);
      expect(echoObject?.aNullableFloatArray,
          genericAllNullableTypes.aNullableFloatArray);
      expect(
          listEquals(
              echoObject?.aNullableList, genericAllNullableTypes.aNullableList),
          true);
      expect(
          mapEquals(
              echoObject?.aNullableMap, genericAllNullableTypes.aNullableMap),
          true);
      expect(echoObject?.nullableNestedList?.length,
          genericAllNullableTypes.nullableNestedList?.length);
      // TODO(stuartmorgan): Enable this once the Dart types are fixed; see
      // https://github.com/flutter/flutter/issues/116117
      //for (int i = 0; i < echoObject?.nullableNestedList!.length; i++) {
      //  expect(listEquals(echoObject?.nullableNestedList![i], genericAllNullableTypes.nullableNestedList![i]),
      //      true);
      //}
      expect(
          mapEquals(echoObject?.nullableMapWithAnnotations,
              genericAllNullableTypes.nullableMapWithAnnotations),
          true);
      expect(
          mapEquals(echoObject?.nullableMapWithObject,
              genericAllNullableTypes.nullableMapWithObject),
          true);
      expect(echoObject?.aNullableEnum, genericAllNullableTypes.aNullableEnum);
    });

    testWidgets('all nulla datatypes serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final AllNullableTypes allTypesNull = AllNullableTypes();

      final AllNullableTypes? echoNullFilledObject =
          await api.echoAllNullableTypes(allTypesNull);

      expect(echoNullFilledObject?.aNullableBool, allTypesNull.aNullableBool);
      expect(echoNullFilledObject?.aNullableBool, null);

      expect(echoNullFilledObject?.aNullableInt, allTypesNull.aNullableInt);
      expect(echoNullFilledObject?.aNullableInt, null);

      expect(
          echoNullFilledObject?.aNullableDouble, allTypesNull.aNullableDouble);
      expect(echoNullFilledObject?.aNullableDouble, null);

      expect(
          echoNullFilledObject?.aNullableString, allTypesNull.aNullableString);
      expect(echoNullFilledObject?.aNullableString, null);

      expect(echoNullFilledObject?.aNullableByteArray,
          allTypesNull.aNullableByteArray);
      expect(echoNullFilledObject?.aNullableByteArray, null);

      expect(echoNullFilledObject?.aNullable4ByteArray,
          allTypesNull.aNullable4ByteArray);
      expect(echoNullFilledObject?.aNullable4ByteArray, null);

      expect(echoNullFilledObject?.aNullable8ByteArray,
          allTypesNull.aNullable8ByteArray);
      expect(echoNullFilledObject?.aNullable8ByteArray, null);

      expect(echoNullFilledObject?.aNullableFloatArray,
          allTypesNull.aNullableFloatArray);
      expect(echoNullFilledObject?.aNullableFloatArray, null);

      expect(
          listEquals(
              echoNullFilledObject?.aNullableList, allTypesNull.aNullableList),
          true);
      expect(echoNullFilledObject?.aNullableList, null);

      expect(
          mapEquals(
              echoNullFilledObject?.aNullableMap, allTypesNull.aNullableMap),
          true);
      expect(echoNullFilledObject?.aNullableMap, null);

      // TODO(stuartmorgan): Enable this once the Dart types are fixed; see
      // https://github.com/flutter/flutter/issues/116117
      //for (int i = 0; i < echoNullFilledObject?.nullableNestedList!.length; i++) {
      //  expect(listEquals(echoNullFilledObject?.nullableNestedList![i], allTypesNull.nullableNestedList![i]),
      //      true);
      //}
      expect(echoNullFilledObject?.nullableNestedList, null);

      expect(
          mapEquals(echoNullFilledObject?.nullableMapWithAnnotations,
              allTypesNull.nullableMapWithAnnotations),
          true);
      expect(echoNullFilledObject?.nullableMapWithAnnotations, null);

      expect(
          mapEquals(echoNullFilledObject?.nullableMapWithObject,
              allTypesNull.nullableMapWithObject),
          true);
      expect(echoNullFilledObject?.nullableMapWithObject, null);

      expect(echoNullFilledObject?.aNullableEnum, allTypesNull.aNullableEnum);
      expect(echoNullFilledObject?.aNullableEnum, null);
    });

    testWidgets('errors are returned correctly', (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      expect(() async {
        await api.throwError();
      }, throwsA(isA<PlatformException>()));
    },
        // Currently unimplementable for Swift:
        // https://github.com/flutter/flutter/issues/112483
        skip: targetGenerator == TargetGenerator.swift);

    testWidgets('nested objects can be sent correctly', (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final AllNullableTypesWrapper sentObject =
          AllNullableTypesWrapper(values: genericAllNullableTypes);

      final String? receivedString =
          await api.extractNestedNullableString(sentObject);
      expect(receivedString, sentObject.values.aNullableString);
    });

    testWidgets('nested objects can be received correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const String sentString = 'Some string';
      final AllNullableTypesWrapper receivedObject =
          await api.createNestedNullableString(sentString);
      expect(receivedObject.values.aNullableString, sentString);
    });

    testWidgets(
        'Arguments of multiple types serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();
      const String aNullableString = 'this is a String';
      const bool aNullableBool = false;
      const int aNullableInt = 42;

      final AllNullableTypes echoObject = await api.sendMultipleNullableTypes(
          aNullableBool, aNullableInt, aNullableString);
      expect(echoObject.aNullableInt, aNullableInt);
      expect(echoObject.aNullableBool, aNullableBool);
      expect(echoObject.aNullableString, aNullableString);
    });

    testWidgets(
        'Arguments of multiple null types serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final AllNullableTypes echoNullFilledObject =
          await api.sendMultipleNullableTypes(null, null, null);
      expect(echoNullFilledObject.aNullableInt, null);
      expect(echoNullFilledObject.aNullableBool, null);
      expect(echoNullFilledObject.aNullableString, null);
    });

    testWidgets('Ints serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const int sentInt = -13;
      final int receivedInt = await api.echoInt(sentInt);
      expect(receivedInt, sentInt);
    });

    testWidgets('Doubles serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const double sentDouble = 2.0694;
      final double receivedDouble = await api.echoDouble(sentDouble);
      expect(receivedDouble, sentDouble);
    });

    testWidgets('booleans serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      for (final bool sentBool in <bool>[true, false]) {
        final bool receivedBool = await api.echoBool(sentBool);
        expect(receivedBool, sentBool);
      }
    });

    testWidgets('strings serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();
      const String sentString = "I'm a computer";
      final String receivedString = await api.echoString(sentString);
      expect(receivedString, sentString);
    });

    testWidgets('Uint8List serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();
      final List<int> data = <int>[
        102,
        111,
        114,
        116,
        121,
        45,
        116,
        119,
        111,
        0
      ];
      final Uint8List sentUint8List = Uint8List.fromList(data);
      final Uint8List receivedUint8List =
          await api.echoUint8List(sentUint8List);
      expect(receivedUint8List, sentUint8List);
    });

    testWidgets('generic Objects serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();
      const Object sentString = "I'm a computer";
      final Object receivedString = await api.echoObject(sentString);
      expect(receivedString, sentString);

      // Echo a second type as well to ensure the handling is generic.
      const Object sentInt = 42;
      final Object receivedInt = await api.echoObject(sentInt);
      expect(receivedInt, sentInt);
    });

    testWidgets('Nullable Ints serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const int sentInt = -13;
      final int? receivedInt = await api.echoNullableInt(sentInt);
      expect(receivedInt, sentInt);
    });

    testWidgets('Null Ints serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final int? receivedNullInt = await api.echoNullableInt(null);
      expect(receivedNullInt, null);
    });

    testWidgets('Nullable Doubles serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const double sentDouble = 2.0694;
      final double? receivedDouble = await api.echoNullableDouble(sentDouble);
      expect(receivedDouble, sentDouble);
    });

    testWidgets('Null Doubles serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final double? receivedNullDouble = await api.echoNullableDouble(null);
      expect(receivedNullDouble, null);
    });

    testWidgets('Nullable booleans serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      for (final bool? sentBool in <bool?>[true, false]) {
        final bool? receivedBool = await api.echoNullableBool(sentBool);
        expect(receivedBool, sentBool);
      }
    });

    testWidgets('Null booleans serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const bool? sentBool = null;
      final bool? receivedBool = await api.echoNullableBool(sentBool);
      expect(receivedBool, sentBool);
    });

    testWidgets('Nullable strings serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();
      const String sentString = "I'm a computer";
      final String? receivedString = await api.echoNullableString(sentString);
      expect(receivedString, sentString);
    });

    testWidgets('Null strings serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final String? receivedNullString = await api.echoNullableString(null);
      expect(receivedNullString, null);
    });

    testWidgets('Nullable Uint8List serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();
      final List<int> data = <int>[
        102,
        111,
        114,
        116,
        121,
        45,
        116,
        119,
        111,
        0
      ];
      final Uint8List sentUint8List = Uint8List.fromList(data);
      final Uint8List? receivedUint8List =
          await api.echoNullableUint8List(sentUint8List);
      expect(receivedUint8List, sentUint8List);
    });

    testWidgets('Null Uint8List serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final Uint8List? receivedNullUint8List =
          await api.echoNullableUint8List(null);
      expect(receivedNullUint8List, null);
    });

    testWidgets('generic nullable Objects serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();
      const Object sentString = "I'm a computer";
      final Object? receivedString = await api.echoNullableObject(sentString);
      expect(receivedString, sentString);

      // Echo a second type as well to ensure the handling is generic.
      const Object sentInt = 42;
      final Object? receivedInt = await api.echoNullableObject(sentInt);
      expect(receivedInt, sentInt);
    });

    testWidgets('Null generic Objects serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      final Object? receivedNullObject = await api.echoNullableObject(null);
      expect(receivedNullObject, null);
    });
  });

  group('Host async API tests', () {
    testWidgets('basic void->void call works', (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      expect(api.noopAsync(), completes);
    });

    testWidgets('strings serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const String sentObject = 'Hello, asyncronously!';

      final String echoObject = await api.echoAsyncString(sentObject);
      expect(echoObject, sentObject);
    });
  });

  // These tests rely on the ansync Dart->host calls to work correctly, since
  // the host->Dart call is wrapped in a driving Dart->host call, so any test
  // added to this group should have coverage of the relevant arguments and
  // return value in the "Host async API tests" group.
  group('Flutter API tests', () {
    setUp(() {
      FlutterIntegrationCoreApi.setup(_FlutterApiTestImplementation());
    });

    testWidgets('basic void->void call works', (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      expect(api.callFlutterNoop(), completes);
    });

    testWidgets('strings serialize and deserialize correctly',
        (WidgetTester _) async {
      final HostIntegrationCoreApi api = HostIntegrationCoreApi();

      const String sentObject = 'Hello Dart!';

      final String echoObject = await api.callFlutterEchoString(sentObject);
      expect(echoObject, sentObject);
    });
  },
      // TODO(stuartmorgan): Enable when FlutterApi generation is fixed for
      // C++. See https://github.com/flutter/flutter/issues/108682.
      skip: targetGenerator == TargetGenerator.cpp);
}

class _FlutterApiTestImplementation implements FlutterIntegrationCoreApi {
  @override
  AllTypes echoAllTypes(AllTypes everything) {
    return everything;
  }

  @override
  AllNullableTypes echoAllNullableTypes(AllNullableTypes everything) {
    return everything;
  }

  @override
  String echoString(String aString) {
    return aString;
  }

  @override
  void noop() {}
}
