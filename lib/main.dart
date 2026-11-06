import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
​void main() {
runApp(const MongolianHeritageApp());
}
​class MongolianHeritageApp extends StatelessWidget {
const MongolianHeritageApp({super.key});
​@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Монгол Наадгай & Хөзрийн Сүлжээ',
debugShowCheckedModeBanner: false,
theme: ThemeData.dark().copyWith(
scaffoldBackgroundColor: const Color(0xFF1C0A00),
primaryColor: const Color(0xFFF59E0B),
colorScheme: const ColorScheme.dark(
primary: Color(0xFFF59E0B),
secondary: Color(0xFFD97706),
surface: Color(0xFF2A1609),
),
),
home: const MainLoungeScreen(),
);
}
}
​class MainLoungeScreen extends StatefulWidget {
const MainLoungeScreen({super.key});
​@override
State<MainLoungeScreen> createState() => _MainLoungeScreenState();
}
​class _MainLoungeScreenState extends State<MainLoungeScreen> {
int _userBalance = 50000;
int _selectedTab = 0; // 0: Морь уралдах, 1: Шагай няслах, 2: Омаха Покер
​void _showQPayDialog() {
showDialog(
context: context,
builder: (context) => AlertDialog(
backgroundColor: const Color(0xFF2A1609),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
),
title: const Row(
children: [
Icon(Icons.account_balance_wallet, color: Color(0xFFF59E0B)),
SizedBox(width: 10),
Text('Чип Цэнэглэх (QPay)', style: TextStyle(color: Color(0xFFF59E0B))),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Text(
'QPay болон SocialPay-ээр дансаа цэнэглэж виртуал чип авна уу.',
style: TextStyle(fontSize: 13, color: Colors.white70),
),
const SizedBox(height: 16),
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
),
child: Image.network(
'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=QPayMongolianHeritageGame',
height: 140,
width: 140,
fit: BoxFit.cover,
errorBuilder: (context, error, stackTrace) => const Icon(
Icons.qr_code_2,
size: 100,
color: Colors.black,
),
),
),
const SizedBox(height: 12),
const Text(
'Уншуулах дүнгээ сонгоно уу:\n• 5,000₮ = 50,000 Чип\n• 10,000₮ = 120,000 Чип',
textAlign: TextAlign.center,
style: TextStyle(fontSize: 12, color: Colors.amberAccent),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Болих', style: TextStyle(color: Colors.white54)),
),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFF59E0B),
foregroundColor: Colors.black,
),
onPressed: () {
setState(() {
_userBalance += 50000;
});
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('50,000 Чип амжилттай нэмэгдлээ!')),
);
},
child: const Text('Төлбөр Шалгах'),
),
],
),
);
}
​@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
backgroundColor: Colors.black.withOpacity(0.8),
title: const Row(
children: [
Text('🐎', style: TextStyle(fontSize: 22)),
SizedBox(width: 8),
Text(
'МОНГОЛ НААДГАЙ',
style: TextStyle(
fontWeight: FontWeight.bold,
letterSpacing: 1.2,
color: Color(0xFFF59E0B),
),
),
],
),
actions: [
Container(
margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
decoration: BoxDecoration(
color: const Color(0xFF451A03),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: const Color(0xFFF59E0B)),
),
child: Row(
children: [
const Text('🪙 ', style: TextStyle(fontSize: 14)),
Text(
'$_userBalance',
style: const TextStyle(
color: Color(0xFFF59E0B),
fontWeight: FontWeight.bold,
),
),
],
),
),
IconButton(
icon: const Icon(Icons.add_circle, color: Color(0xFFF59E0B)),
onPressed: _showQPayDialog,
tooltip: 'Чип Авах',
)
],
),
body: Column(
children: [
// Top Navigation Tabs
Container(
color: Colors.black45,
padding: const EdgeInsets.symmetric(vertical: 8),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildTabButton(0, '🐎 Морь Уралдах'),
_buildTabButton(1, '🎯 Шагай Няслах'),
_buildTabButton(2, '♠️ Омаха Покер'),
],
),
),
Expanded(
child: IndexedStack(
index: _selectedTab,
children: const [
ShagaiHorseRaceView(),
ShagaiNyaslahView(),
OmahaPokerView(),
],
),
),
],
),
);
}
​Widget _buildTabButton(int index, String title) {
final isSelected = _selectedTab == index;
return GestureDetector(
onTap: () => setState(() => _selectedTab = index),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
decoration: BoxDecoration(
color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: isSelected ? const Color(0xFFF59E0B) : Colors.amber.withOpacity(0.3),
),
),
child: Text(
title,
style: TextStyle(
color: isSelected ? Colors.black : Colors.amber,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
),
);
}
}
​// 1. Морь уралдуулах View
class ShagaiHorseRaceView extends StatefulWidget {
const ShagaiHorseRaceView({super.key});
​@override
State<ShagaiHorseRaceView> createState() => _ShagaiHorseRaceViewState();
}
​class _ShagaiHorseRaceViewState extends State<ShagaiHorseRaceView> {
int _playerPos = 0;
int _botPos = 0;
final int _totalSteps = 8;
String _lastRollResult = 'Шагай орхих товчийг дарна уу.';
​void _rollShagai() {
final sides = ['Мори 🐎', 'Тэмээ 🐪', 'Хони 🐑', 'Ямаа 🐐'];
final rand = Random();
int horses = 0;
List<String> rolled = [];
​for (int i = 0; i < 4; i++) {
String res = sides[rand.nextInt(sides.length)];
rolled.add(res);
if (res.contains('Мори')) horses++;
}
​setState(() {
_lastRollResult = 'Буусан: ${rolled.join(', ')}\n(+$horses алхам)';
_playerPos = min(_totalSteps, _playerPos + horses);
_botPos = min(_totalSteps, _botPos + rand.nextInt(2));
});
​if (_playerPos >= _totalSteps) {
showDialog(
context: context,
builder: (context) => AlertDialog(
backgroundColor: const Color(0xFF2A1609),
title: const Text('🏆 ТҮРҮҮЛЛЭЭ!'),
content: const Text('Баяр хүргэе! Таны морь түрүүлж 10,000 чипний бай авлаа!'),
actions: [
TextButton(
onPressed: () {
Navigator.pop(context);
setState(() {
_playerPos = 0;
_botPos = 0;
});
},
child: const Text('Дахин Тоглох'),
)
],
),
);
}
}
​@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(16),
child: Column(
children: [
const Text(
'МОРЬ УРАЛДУУЛАХ НААДАМ',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Color(0xFFF59E0B),
),
),
const SizedBox(height: 20),
// Tracks
_buildTrackRow('👤 Таны морь', _playerPos, Colors.amber),
const SizedBox(height: 16),
_buildTrackRow('🤖 Өрсөлдөгч', _botPos, Colors.redAccent),
const Spacer(),
Container(
padding: const EdgeInsets.all(16),
width: double.infinity,
decoration: BoxDecoration(
color: Colors.black38,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: Colors.amber.withOpacity(0.3)),
),
child: Text(
_lastRollResult,
textAlign: TextAlign.center,
style: const TextStyle(color: Colors.amberAccent, fontSize: 14),
),
),
const SizedBox(height: 20),
SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton.icon(
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFF59E0B),
foregroundColor: Colors.black,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
onPressed: _rollShagai,
icon: const Icon(Icons.casino),
label: const Text(
'🎲 4 ШАГАЙ ОРХИХ',
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
),
),
],
),
);
}
​Widget _buildTrackRow(String label, int currentPos, Color color) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
const SizedBox(height: 6),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: List.generate(_totalSteps + 1, (index) {
final isCurrent = index == currentPos;
return Container(
margin: const EdgeInsets.only(right: 6),
width: 38,
height: 48,
decoration: BoxDecoration(
color: isCurrent ? color.withOpacity(0.3) : Colors.white10,
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: isCurrent ? color : Colors.white24,
width: isCurrent ? 2 : 1,
),
),
child: Center(
child: Text(
isCurrent
? '🐎'
: (index == _totalSteps ? '🏁' : '$index'),
style: const TextStyle(fontSize: 16),
),
),
);
}),
),
),
],
);
}
}
​// 2. Шагай Няслах View
class ShagaiNyaslahView extends StatelessWidget {
const ShagaiNyaslahView({super.key});
​@override
Widget build(BuildContext context) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.sports_esports, size: 64, color: Color(0xFFF59E0B)),
const SizedBox(height: 12),
const Text(
'🎯 ШАГАЙ НЯСЛАХ',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
),
const SizedBox(height: 8),
const Text(
'Ижил буусан 2 морийг чиглүүлэн нясалж оноо цуглуулаарай.',
style: TextStyle(color: Colors.white70, fontSize: 12),
),
const SizedBox(height: 24),
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
onPressed: () {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Шагай няслалт амжилттай! +500 Чип')),
);
},
child: const Text('Эхлүүлэх', style: TextStyle(color: Colors.black)),
)
],
),
);
}
}
​// 3. Омаха Покер View
class OmahaPokerView extends StatelessWidget {
const OmahaPokerView({super.key});
​@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(16),
child: Column(
children: [
const Text(
'♠️ ОМАХА ПОКЕР (4 CARDS)',
style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
),
const SizedBox(height: 20),
Expanded(
child: Container(
decoration: BoxDecoration(
color: const Color(0xFF0F5132),
borderRadius: BorderRadius.circular(100),
border: Border.all(color: const Color(0xFF451A03), width: 8),
),
child: const Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text('BANK: 15,000 ₮', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
SizedBox(height: 10),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_CardWidget('Q', '♥️', Colors.red),
_CardWidget('J', '♥️', Colors.red),
_CardWidget('2', '♦️', Colors.red),
_CardWidget('7', '♠️', Colors.white),
],
),
],
),
),
),
),
const SizedBox(height: 16),
const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_CardWidget('A', '♥️', Colors.red),
_CardWidget('K', '♥️', Colors.red),
_CardWidget('10', '♠️', Colors.white),
_CardWidget('J', '♣️', Colors.white),
],
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
onPressed: () {},
child: const Text('Fold'),
),
),
const SizedBox(width: 8),
Expanded(
child: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
onPressed: () {},
child: const Text('Call', style: TextStyle(color: Colors.black)),
),
),
],
)
],
),
);
}
}
​class _CardWidget extends StatelessWidget {
final String val;
final String suit;
final Color color;
​const _CardWidget(this.val, this.suit, this.color);
​@override
Widget build(BuildContext context) {
return Container(
margin: const EdgeInsets.symmetric(horizontal: 2),
width: 36,
height: 52,
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(6),
),
child: Center(
child: Text(
'valsuit',
style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
),
),
);
}
}
