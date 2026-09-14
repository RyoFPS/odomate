import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/service_editor_screen.dart';

class _FakeRepository extends OdomateRepository {
  final List<ServiceItem> saved = [];
  final List<ServiceLog> logged = [];
  final List<int> clearedNotifications = [];

  @override
  Future<int> saveService(ServiceItem item) async {
    saved.add(item);
    return item.id ?? 77;
  }

  @override
  Future<void> recordService(ServiceLog log) async => logged.add(log);

  @override
  Future<void> clearNotificationState(int serviceItemId) async =>
      clearedNotifications.add(serviceItemId);
}

const _vehicle = Vehicle(
  name: 'Honda Vario 160',
  odometerKm: 24582,
  plateNumber: 'B 1234 XYZ',
);

/// Jadwal yang sudah ada, dipakai untuk menguji mode edit.
const _existing = ServiceItem(
  id: 5,
  name: 'Ganti Oli Mesin',
  description: 'Oli SPX 2 0.8L',
  location: 'AHASS',
  cost: 65000,
  intervalKm: 2000,
  lastServicedOdometerKm: 22500,
);

Future<void> _pump(
  WidgetTester tester,
  _FakeRepository repository, {
  ServiceItem? service,
  Vehicle? vehicle = _vehicle,
}) async {
  // Formulirnya lebih tinggi dari viewport bawaan 800x600, dan `ListView` tidak
  // membangun anak yang jauh di luar layar — jadi kolom biaya dan bengkel tidak
  // akan ada sama sekali untuk diketik kalau permukaannya tidak ditinggikan.
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ServiceEditorScreen(
        repository: repository,
        service: service,
        odometerKm: 24582,
        vehicle: vehicle,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _saveButton => find.widgetWithText(FilledButton, 'Simpan Jadwal Servis');
Finder get _saveEditButton => find.widgetWithText(FilledButton, 'Simpan Perubahan');

void main() {
  testWidgets('a new schedule starts from the vehicle odometer', (tester) async {
    await _pump(tester, _FakeRepository());

    final odo = tester.widget<TextField>(
      find.byKey(const Key('service-editor-odometer')),
    );
    expect(odo.controller?.text, '24582');
  });

  testWidgets('the form is a page with its own header, not a bottom sheet', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Tambah Servis'), findsOneWidget);
    expect(find.text('Pilih Cepat Komponen'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('choosing a preset fills the name and its maker interval', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    await tester.tap(find.text('Oli Gardan'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('service-editor-name')))
          .controller
          ?.text,
      'Oli Gardan',
    );
    // Oli Gardan satu-satunya angka pabrikan yang dipakai desain untuk komponen
    // ini; kalau presetnya berubah, badge target di bawah ikut berubah.
    expect(find.text('Target: 32.582 km'), findsOneWidget);
  });

  testWidgets('a preset with no maker interval leaves the field alone', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    await tester.tap(find.text('Kampas Rem'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('service-editor-name')))
          .controller
          ?.text,
      'Kampas Rem',
    );
    // Aplikasi tidak mengarang interval untuk komponen yang tidak punya angka
    // pabrikan, jadi kolomnya harus tetap kosong dan tombol simpan tetap mati.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('service-editor-interval')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(find.textContaining('Target:'), findsNothing);
    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);
  });

  testWidgets('the interval pills add to the entered odometer in the badge', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    await tester.tap(find.text('+4.000'));
    await tester.pumpAndSettle();

    expect(find.text('Target: 28.582 km'), findsOneWidget);
  });

  testWidgets('save stays disabled until name, interval, and odo are present', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('service-editor-name')),
      'Servis Karburator',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('service-editor-interval')),
      '3000',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNotNull);
  });

  testWidgets('a new schedule writes a history log for its first service', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.enterText(
      find.byKey(const Key('service-editor-name')),
      'Ganti Oli Mesin',
    );
    await tester.enterText(
      find.byKey(const Key('service-editor-interval')),
      '2000',
    );
    await tester.enterText(
      find.byKey(const Key('service-editor-cost')),
      '65000',
    );
    await tester.enterText(
      find.byKey(const Key('service-editor-location')),
      'AHASS',
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(repository.saved, hasLength(1));
    final item = repository.saved.single;
    expect(item.name, 'Ganti Oli Mesin');
    expect(item.intervalKm, 2000);
    expect(item.lastServicedOdometerKm, 24582);
    expect(item.cost, 65000);
    expect(item.location, 'AHASS');
    expect(item.remind, isTrue);

    // Tanggal dan odometer di formulir adalah servis yang baru dikerjakan, jadi
    // jadwal baru harus punya satu baris riwayat — kalau tidak, servis pertama
    // tidak pernah tercatat di halaman Riwayat.
    expect(repository.logged, hasLength(1));
    expect(repository.logged.single.serviceItemId, 77);
    expect(repository.logged.single.odometerKm, 24582);
  });

  testWidgets('turning the reminder off is saved as remind: false', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.enterText(
      find.byKey(const Key('service-editor-name')),
      'Servis Karburator',
    );
    await tester.enterText(
      find.byKey(const Key('service-editor-interval')),
      '3000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('service-editor-remind')));
    await tester.pumpAndSettle();
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(repository.saved.single.remind, isFalse);
  });

  testWidgets('editing an existing schedule does not append a history entry', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository, service: _existing);

    expect(find.text('Edit Servis'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('service-editor-name')))
          .controller
          ?.text,
      'Ganti Oli Mesin',
    );

    await tester.enterText(
      find.byKey(const Key('service-editor-interval')),
      '3000',
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveEditButton);
    await tester.pumpAndSettle();

    expect(repository.saved.single.id, 5);
    expect(repository.saved.single.intervalKm, 3000);
    // Mengubah interval bukan peristiwa servis: riwayatnya tidak boleh bertambah
    // hanya karena formulirnya dibuka lalu disimpan lagi.
    expect(repository.logged, isEmpty);
  });

  testWidgets('saving clears the reminder state so the new schedule can fire', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository, service: _existing);

    await tester.tap(_saveEditButton);
    await tester.pumpAndSettle();

    expect(repository.clearedNotifications, [5]);
  });

  testWidgets('Batal leaves without writing anything', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repository.saved, isEmpty);
    expect(repository.logged, isEmpty);
  });

  testWidgets('the routine/custom switch hides the component catalogue', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    expect(find.text('Pilih Cepat Komponen'), findsOneWidget);

    await tester.tap(find.text('Kustom / Perbaikan'));
    await tester.pumpAndSettle();

    // Perbaikan sekali jalan tidak punya interval berkala, jadi katalog komponen
    // yang semuanya berjadwal itu tidak relevan dan disembunyikan.
    expect(find.text('Pilih Cepat Komponen'), findsNothing);
    // Label wajib diakhiri tanda bintang, jadi dicari sebagai awalan teks.
    expect(find.textContaining('Nama Servis / Pekerjaan'), findsOneWidget);
  });

  testWidgets('with no vehicle the banner still renders', (tester) async {
    await _pump(tester, _FakeRepository(), vehicle: null);

    expect(find.text('Kendaraan'), findsOneWidget);
  });
}
