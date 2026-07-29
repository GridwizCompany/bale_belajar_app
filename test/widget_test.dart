import 'dart:ui';

import 'package:bale_belajar_app/app.dart';
import 'package:bale_belajar_app/features/baleverse/domain/baleverse_models.dart';
import 'package:bale_belajar_app/features/baleverse/state/mission_state_machine.dart';
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
    final state =
        answerCorrect(beginQuestion(startMission(const BaleVerseState())));

    expect(state.step, MissionStep.reward);
    expect(state.wrongAttempts, 0);
  });

  testWidgets('BaleVerse dashboard renders after demo login', (tester) async {
    await tester.pumpWidget(const BaleBelajarApp());

    expect(find.text('Masuk ke BaleVerse'), findsOneWidget);

    await tester.tap(find.text('Masuk sebagai Nara'));
    await tester.pumpAndSettle();

    expect(find.textContaining('BaleVerse'), findsOneWidget);
    expect(find.text('Lanjutkan Misi'), findsOneWidget);
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
}
