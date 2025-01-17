import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const TabataTimerApp());
}

class TabataTimerApp extends StatelessWidget {
  const TabataTimerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimerProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tabata Timer',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const TabataHomePage(),
      ),
    );
  }
}

class TabataHomePage extends StatelessWidget {
  const TabataHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabata Timer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 显示当前状态（工作/休息）
            Text(
              timerProvider.isWork ? "WORK" : "REST",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: timerProvider.isWork ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            // 显示倒计时
            Text(
              "${timerProvider.remainingTime}s",
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // 显示循环进度
            Text(
              "Cycle: ${timerProvider.currentCycle} / ${timerProvider.totalCycles}",
              style: const TextStyle(fontSize: 24),
            ),
            const Spacer(),
            // 设置工作时间、休息时间、循环次数
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _timeSetting(
                  "Work",
                  timerProvider.workTime,
                      () => timerProvider.incrementWorkTime(),
                      () => timerProvider.decrementWorkTime(),
                ),
                _timeSetting(
                  "Rest",
                  timerProvider.restTime,
                      () => timerProvider.incrementRestTime(),
                      () => timerProvider.decrementRestTime(),
                ),
                _timeSetting(
                  "Cycles",
                  timerProvider.totalCycles,
                      () => timerProvider.incrementCycles(),
                      () => timerProvider.decrementCycles(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 开始/重置按钮
            ElevatedButton(
              onPressed: () {
                if (timerProvider.isRunning) {
                  timerProvider.resetTimer();
                } else {
                  timerProvider.startTimer();
                }
              },
              child: Text(timerProvider.isRunning ? "Reset" : "Start"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 时间设置组件
  Widget _timeSetting(
      String label, int value, VoidCallback onIncrement, VoidCallback onDecrement) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove)),
            Text("$value", style: const TextStyle(fontSize: 18)),
            IconButton(onPressed: onIncrement, icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}

class TimerProvider extends ChangeNotifier {
  int workTime = 20; // 工作时间
  int restTime = 10; // 休息时间
  int totalCycles = 8; // 循环次数

  int remainingTime = 20;
  int currentCycle = 1;

  bool isWork = true;
  bool isRunning = false;

  late AudioPlayer _audioPlayer;

  TimerProvider() {
    _audioPlayer = AudioPlayer();
  }

  void incrementWorkTime() {
    workTime += 5;
    if (isWork) remainingTime = workTime;
    notifyListeners();
  }

  void decrementWorkTime() {
    if (workTime > 5) {
      workTime -= 5;
      if (isWork) remainingTime = workTime;
      notifyListeners();
    }
  }

  void incrementRestTime() {
    restTime += 5;
    if (!isWork) remainingTime = restTime;
    notifyListeners();
  }

  void decrementRestTime() {
    if (restTime > 5) {
      restTime -= 5;
      if (!isWork) remainingTime = restTime;
      notifyListeners();
    }
  }

  void incrementCycles() {
    totalCycles++;
    notifyListeners();
  }

  void decrementCycles() {
    if (totalCycles > 1) {
      totalCycles--;
      notifyListeners();
    }
  }

  void startTimer() {
    isRunning = true;
    remainingTime = isWork ? workTime : restTime;
    _startCountdown();
    notifyListeners();
  }

  void resetTimer() {
    isRunning = false;
    currentCycle = 1;
    isWork = true;
    remainingTime = workTime;
    notifyListeners();
  }

  void _startCountdown() async {
    while (isRunning && remainingTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (isRunning) {
        remainingTime--;
        notifyListeners();
      }
    }

    if (isRunning) {
      if (isWork) {
        // 工作结束播放声音/震动
        _playSound();
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate();
        }
      }

      // 切换状态或结束
      if (isWork) {
        isWork = false;
        remainingTime = restTime;
      } else {
        currentCycle++;
        if (currentCycle > totalCycles) {
          resetTimer();
          return;
        }
        isWork = true;
        remainingTime = workTime;
      }

      notifyListeners();
      _startCountdown();
    }
  }

  Future<void> _playSound() async {
    await _audioPlayer.play(AssetSource('assets/beep.mp3'));
  }
}