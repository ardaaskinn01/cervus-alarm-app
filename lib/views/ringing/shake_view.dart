import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/alarm_service.dart';
import '../home/success_view.dart';

import 'dart:math';

class ShakeView extends ConsumerStatefulWidget {
  final int alarmId;
  final bool isSnooze;

  const ShakeView({super.key, required this.alarmId, this.isSnooze = false});

  @override
  ConsumerState<ShakeView> createState() => _ShakeViewState();
}

class _ShakeViewState extends ConsumerState<ShakeView> {
  int shakeCount = 0;
  final int targetShakes = 30;
  final double shakeThreshold = 15.0;
  DateTime? lastShakeTime;
  StreamSubscription<UserAccelerometerEvent>? _sensorSubscription;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    try {
      _sensorSubscription = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((event) {
        if (_isFinished) return;

        final now = DateTime.now();
        
        // Calculate acceleration
        final double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        
        if (acceleration > shakeThreshold) {
          if (lastShakeTime == null || now.difference(lastShakeTime!) > const Duration(milliseconds: 200)) {
            lastShakeTime = now;
            if (mounted) {
              setState(() {
                if (shakeCount < targetShakes) {
                  shakeCount++;
                }
              });
              if (shakeCount >= targetShakes && !_isFinished) {
                _finishTask();
              }
            }
          }
        }
      }, onError: (error) {
        debugPrint("Sensor error: $error");
      });
    } catch (e) {
      debugPrint("Could not start accelerometer: $e");
    }
  }

  Future<void> _finishTask() async {
    if (_isFinished) return;
    
    setState(() {
      _isFinished = true;
    });
    
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
    
    if (!mounted) return;
    
    if (widget.isSnooze) {
      await ref.read(homeViewModelProvider.notifier).snoozeAlarm(widget.alarmId);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      try {
        final alarms = ref.read(homeViewModelProvider);
        final currentAlarm = alarms.firstWhere((a) => a.id == widget.alarmId);
        await ref.read(homeViewModelProvider.notifier).toggleAlarm(currentAlarm, false);
      } catch (e) {
        await ref.read(alarmServiceProvider).stopAlarm(widget.alarmId);
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessView()),
        );
      }
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ertelemek için Salla!', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.gradientEndColor,
              AppTheme.backgroundColor,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.vibration_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 48),
              
              // Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: shakeCount / targetShakes,
                      strokeWidth: 16,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        shakeCount > (targetShakes * 0.7) 
                            ? AppTheme.primaryColor 
                            : AppTheme.secondaryColor
                      ),
                    ),
                  ),
                  Text(
                    '$shakeCount',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Hedef: $targetShakes sallama',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

            ],
          ),
        ),
      ),
    );
  }
}
