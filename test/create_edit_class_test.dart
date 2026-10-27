import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_pulse/models/models.dart';
import 'package:iron_pulse/screens/create_edit_class_screen.dart';

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Duration? connectionTimeout;
  @override
  bool Function(X509Certificate cert, String host, int port)? badCertificateCallback;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static const List<int> _kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ];

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_kTransparentImage).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _FakeHttpOverrides();
  });

  testWidgets('CreateEditClassScreen renders create mode correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: CreateEditClassScreen.create(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title in TopBar and Save button
    expect(find.text('Create Class'), findsNWidgets(2));
    expect(find.text('Cancel'), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Class Name'), findsOneWidget);
    expect(find.text('Instructor'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('End Time'), findsOneWidget);
    expect(find.text('Max Capacity'), findsOneWidget);

    // Verify Image URL section and presets
    expect(find.text('Imagen Identificadora de la Clase (URL o Preset)'), findsOneWidget);
    expect(find.text('Galería'), findsOneWidget);

    // Verify Dropdown Menu for Instructor
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

    // Verify Delete button is absent in create mode
    expect(find.text('Delete Class'), findsNothing);

    // Verify capacity counter interaction (+ and -)
    expect(find.text('30'), findsOneWidget);
    final plusButton = find.byIcon(Icons.add_rounded);
    expect(plusButton, findsOneWidget);

    await tester.tap(plusButton);
    await tester.pumpAndSettle();
    expect(find.text('31'), findsOneWidget);

    final minusButton = find.byIcon(Icons.remove_rounded);
    expect(minusButton, findsOneWidget);
    await tester.tap(minusButton);
    await tester.pumpAndSettle();
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('CreateEditClassScreen renders edit mode with Delete button and existing data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockSchedule = ClassScheduleModel(
      id: 'sched-101',
      classId: 'class-101',
      instructorId: 'inst-1',
      startTime: DateTime(2026, 10, 28, 9, 0),
      endTime: DateTime(2026, 10, 28, 10, 0),
      capacity: 25,
      locationName: 'Studio B',
      gymClass: GymClassModel(
        id: 'class-101',
        name: 'Olympic Weightlifting',
        description: 'Snatch and Clean & Jerk technique session.',
        imageUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800',
        intensity: ClassIntensity.high,
        durationMinutes: 60,
      ),
      instructor: InstructorModel(
        id: 'inst-1',
        name: 'Alex Johnson',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreateEditClassScreen.edit(schedule: mockSchedule),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Edit Mode elements
    expect(find.text('Edit Class'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Delete Class'), findsOneWidget);

    // Verify prefilled name and capacity
    expect(find.text('Olympic Weightlifting'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });
}
