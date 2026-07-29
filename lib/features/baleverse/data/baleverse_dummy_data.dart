import '../../../theme/bale_theme.dart';
import '../domain/baleverse_models.dart';

const baleUser = BaleUser(
  name: 'Nara',
  rank: 'Penjelajah III',
  level: 12,
  dayaBale: 320,
  weeklyTarget: 3,
  weeklyCompleted: 2,
  xp: {
    BaleWorldKey.numeria: 4500,
    BaleWorldKey.kodex: 1880,
    BaleWorldKey.detectivia: 2600,
  },
  mastery: {
    BaleWorldKey.numeria: 62,
    BaleWorldKey.kodex: 41,
    BaleWorldKey.detectivia: 58,
  },
);

const baleWorlds = [
  BaleWorld(
    key: BaleWorldKey.numeria,
    name: 'Numeria',
    subject: 'Matematika',
    characterClass: 'Arsitek Logika',
    color: BaleColors.numeria,
    mastery: 62,
  ),
  BaleWorld(
    key: BaleWorldKey.kodex,
    name: 'KodeX',
    subject: 'Informatika',
    characterClass: 'Penjelajah Kode',
    color: BaleColors.kodex,
    mastery: 41,
  ),
  BaleWorld(
    key: BaleWorldKey.detectivia,
    name: 'Detectivia',
    subject: 'Observasi dan Analisis Bukti',
    characterClass: 'Bale Sleuth',
    color: BaleColors.detectivia,
    mastery: 58,
  ),
];

const numeriaMission = BaleMission(
  title: 'Gerbang Distribusi',
  story: 'Jembatan Numeria macet karena angka di dalam kurung belum terbuka.',
  goal: 'Memahami cara mendistribusikan angka ke semua bagian dalam kurung.',
  prompt: 'Bentuk yang setara dengan 3(x + 4) adalah...',
  estimatedMinutes: 8,
  rewardXp: 90,
  rewardDayaBale: 18,
  options: [
    MissionOption(
      id: 'a',
      label: 'A',
      text: '3x + 4',
      isCorrect: false,
      feedback: 'Angka 3 baru dikalikan ke x. Bagian +4 juga perlu mendapat 3.',
    ),
    MissionOption(
      id: 'b',
      label: 'B',
      text: '3x + 12',
      isCorrect: true,
      feedback: 'Benar. Kamu sudah mendistribusikan angka 3 ke x dan 4.',
    ),
    MissionOption(
      id: 'c',
      label: 'C',
      text: 'x + 12',
      isCorrect: false,
      feedback: 'Bagian 4 sudah dikali 3, tetapi x juga perlu dikali 3.',
    ),
  ],
  hints: [
    'Coba lihat 3(x + 4) sebagai 3 kali semua isi kurung.',
    'Kalikan 3 dengan x, lalu kalikan 3 dengan 4.',
    'Hasilnya punya dua bagian: 3x dan 12. Mentor bisa cek langkahmu.',
  ],
);

const humanHelpRecommendation = HumanHelpRecommendation(
  problem:
      'Kamu sudah mencoba beberapa kali dan masih tertukar saat mengalikan isi kurung.',
  reason:
      'Mentor dapat melihat langkah yang sudah kamu kerjakan dan memberi penjelasan personal.',
  helperName: 'Kak Arya',
  shareableContext: [
    'nama misi',
    'topik',
    'jawaban terkait',
    'hint yang sudah dipakai',
    'pola kesalahan',
  ],
  messageDraft:
      'Aku masih bingung kenapa angka di luar kurung harus dikalikan ke semua bagian.',
);

const mentorFeedback = MentorFeedback(
  mentorName: 'Kak Arya',
  message:
      'Tulis 3(x + 4) sebagai 3 x x ditambah 3 x 4. Jangan gabungkan x dan 4.',
  nextAction: 'Coba contoh ringan: 2(y + 5).',
  masteryReview: 'Butuh satu bukti lagi sebelum mastery dinaikkan penuh.',
);
