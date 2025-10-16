import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GpsLoggerScreen(),
    );
  }
}

class GpsLoggerScreen extends StatefulWidget {
  const GpsLoggerScreen({super.key});
  @override
  State<GpsLoggerScreen> createState() => _GpsLoggerScreenState();
}

class _GpsLoggerScreenState extends State<GpsLoggerScreen> {
  Timer? _timer;
  String _lastLine = '기록 없음';
  List<String> _lines = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<File> _getTodayFile() async {
  // ✅ 외부 저장소 경로 지정 (사용자 접근 가능)
  final dir = Directory('/storage/emulated/0/Download/gps_logs');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final date = DateFormat('yyyyMMdd').format(DateTime.now());
  return File('${dir.path}/$date.txt');
}

  Future<void> _logPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final now = DateTime.now();
      final t = DateFormat('HH:mm:ss').format(now);
      final line =
          '$t | lat:${pos.latitude.toStringAsFixed(6)}, lon:${pos.longitude.toStringAsFixed(6)}';

      print('📍 $line'); // ✅ 콘솔에 바로 출력 (실시간 확인용)

      final file = await _getTodayFile();
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);

      setState(() {
        _lastLine = line;
        _lines.add(line);
      });
    } catch (e) {
      print('⚠️ 위치 기록 실패: $e');
    }
  }

  void _startLogging() {
    _logPosition(); // 즉시 1회
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _logPosition());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS 실시간 로깅')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _startLogging,
              child: const Text('시작하기'),
            ),
            const SizedBox(height: 20),
            Text('마지막 좌표:'),
            Text(
              _lastLine,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Text('최근 로그 (화면 표시용)'),
            Expanded(
              child: ListView.builder(
                itemCount: _lines.length,
                itemBuilder: (context, index) => Text(_lines[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
