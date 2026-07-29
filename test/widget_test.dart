import 'package:bale_belajar_app/app.dart';
import 'package:bale_belajar_app/features/baleverse/domain/baleverse_models.dart';
import 'package:bale_belajar_app/features/baleverse/state/mission_state_machine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mission state machine escalates wrong attempts to mentor help', () {
    var state = const BaleVerseState();

    state = login(state);
    state = startMission(state);
    state = answerWrong(state);
    expect(state.step, MissionStep.hintOne);

    state = answerWrong(state);
    expect(state.step, MissionStep.hintTwo);

    state = answerWrong(state);
    expect(state.step, MissionStep.humanHelp);
    expect(state.wrongAttempts, 3);
  });

  test('mission state machine separates correct answer reward', () {
    final state = answerCorrect(
      beginQuestion(startMission(const BaleVerseState())),
    );

    expect(state.step, MissionStep.reward);
    expect(state.wrongAttempts, 0);
  });

  test('mission state machine advances to richer activity types', () {
    var state = beginQuestion(startMission(const BaleVerseState()));

    state = advanceActivity(state);
    expect(state.activityType, MissionActivityType.findMistake);

    state = advanceActivity(state);
    expect(state.activityType, MissionActivityType.teachBack);
  });

  testWidgets('BaleVerse dashboard renders after demo login', (tester) async {
    await tester.pumpWidget(const BaleBelajarApp());

    expect(find.text('Masuk ke BaleVerse'), findsOneWidget);

    await tester.tap(find.text('Masuk sebagai Nara'));
    await tester.pumpAndSettle();

    expect(find.textContaining('BaleVerse'), findsOneWidget);
    expect(find.text('Lanjutkan Misi'), findsOneWidget);
    await tester.drag(find.byType(Scrollable), const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('Numeria'), findsOneWidget);
    expect(find.text('XP Matematika'), findsOneWidget);
    expect(find.text('Mastery'), findsOneWidget);
  });

  testWidgets('wrong answers reveal human help card', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BaleBelajarApp());
    await tester.tap(find.text('Masuk sebagai Nara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan Misi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Misi'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('3x + 4'));
      await tester.pump();
      await tester.ensureVisible(find.text('Cek Jawaban'));
      await tester.tap(find.text('Cek Jawaban'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bantuan Manusia'), findsOneWidget);
    expect(find.text('Minta Mentor Membantu'), findsOneWidget);
  });

  testWidgets('correct answer continues to find mistake and teach back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BaleBelajarApp());
    await tester.tap(find.text('Masuk sebagai Nara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan Misi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Misi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3x + 12'));
    await tester.pump();
    await tester.tap(find.text('Cek Jawaban'));
    await tester.pumpAndSettle();
    expect(find.text('Cari kesalahannya'), findsOneWidget);

    await tester.tap(find.text('Tandai: 3 hanya dikali ke x'));
    await tester.pump();
    await tester.tap(find.text('Cek Jawaban'));
    await tester.pumpAndSettle();
    expect(find.text('Jelaskan Balik'), findsOneWidget);

    await tester.enterText(
        find.byType(EditableText), 'Karena 3 mengalikan semua isi kurung.');
    await tester.pump();
    await tester.tap(find.text('Kirim Penjelasan'));
    await tester.pumpAndSettle();
    expect(find.text('Gerbang Distribusi terbuka.'), findsOneWidget);
  });
}
