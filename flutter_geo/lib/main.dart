import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_geo/widgets/StatusButton.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  FlutterForegroundTask.initCommunicationPort();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void sendTrack(Timer t) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (track.isNotEmpty) {
      prefs.remove("track");
      setState(() {
        track = [];
      });
    } else {}
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 10), sendTrack);
  }

  final duration = 5;

  bool onRoad = false;

  List<bool> buttons = [false, false, false, false];

  List<dynamic> track = [];

  Timer? timer;

  bool timerLocked = false;

  final locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
    forceLocationManager: true,
    intervalDuration: const Duration(seconds: 10),
    //(Optional) Set foreground notification config to keep the app alive
    //when going to the background
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationText:
          "Example app will continue to receive your location even when you aren't using it",
      notificationTitle: "Running in Background",
      enableWakeLock: true,
    ),
  );

  // Future<bool> _requestLocationPermission({bool background = false}) async {
  //   if (!await FlLocation.isLocationServicesEnabled) {
  //     return false;
  //   }

  //   LocationPermission permission = await FlLocation.checkLocationPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await FlLocation.requestLocationPermission();
  //   }

  //   if (permission == LocationPermission.denied ||
  //       permission == LocationPermission.deniedForever) {
  //     return false;
  //   }

  //   if (kIsWeb || kIsWasm) {
  //     return true;
  //   }

  //   if (Platform.isAndroid && permission == LocationPermission.whileInUse) {
  //     permission = await FlLocation.requestLocationPermission();

  //     if (permission != LocationPermission.always) {
  //       return false;
  //     }
  //   }

  //   return true;
  // }

  // Future<dynamic> _determinePosition() async {
  //   // await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  //   if (await _requestLocationPermission()) {
  //     final Location location = await FlLocation.getLocation();
  //     print(location.longitude);
  //     return location;
  //   }
  //   return;
  // }

  void tracker(Timer t) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!timerLocked) {
      timerLocked = true;
      if (buttons[0] || buttons[2] || buttons[3]) {
      } else {
        final position = await _determinePosition();
        final pos = '${position.longitude} ${position.latitude}';
        if (prefs.getStringList('track') != null) {
          final list = prefs.getStringList('track');
          list!.add(pos);
          prefs.setStringList('track', list);
        } else {
          prefs.setStringList('track', <String>[pos]);
        }
        setState(() {
          track.add('${position.longitude} ${position.latitude}');
        });
      }
      timerLocked = false;
    }
  }

  void startTimer() async {
    timer = Timer.periodic(const Duration(seconds: 5), tracker);
  }

  void cancelTimer() {
    timer?.cancel();
  }

/*
  void startTimer() {
    final timer = Timer.periodic(
      Duration(seconds: duration),
      (Timer t) async {
        final List<ConnectivityResult> connection =
            await (Connectivity().checkConnectivity());
        if (!connection.contains(ConnectivityResult.wifi) &&
            !connection.contains(ConnectivityResult.mobile)) {
          if (work) {
            final position = await _determinePosition();
            addData(position);
          } else {
            return;
          }
        } else {
          if (work) {
          } else {
            return;
          }
        }
      },
    );
  }
*/

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (Platform.isAndroid && permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.always) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.logout),
            ),
            Text("Длина трека: ${track.length}"),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person),
            ),
          ],
        ),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                onRoad = !onRoad;
              });
              if (onRoad) {
                startTimer();

                buttons[1] = true;
              } else {
                cancelTimer();
                buttons = [false, false, false, false];
              }
            },
            child: StatusButton(
              color: Colors.green,
              status: onRoad,
              title: "На дороге",
              icon: Icons.publish,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                for (int i = 0; i < buttons.length; i++) {
                  buttons[i] = i == 0;
                }
              });
            },
            child: StatusButton(
              color: Colors.orange,
              status: buttons[0],
              title: "Отдыхаю",
              icon: Icons.nights_stay,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                for (int i = 0; i < buttons.length; i++) {
                  buttons[i] = i == 1;
                }
              });
            },
            child: StatusButton(
              color: Colors.green,
              status: buttons[1],
              title: "В пути",
              icon: Icons.local_shipping,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                for (int i = 0; i < buttons.length; i++) {
                  buttons[i] = i == 2;
                }
              });
            },
            child: StatusButton(
              color: Colors.blue,
              status: buttons[2],
              title: "Доставил",
              icon: Icons.warehouse,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                for (int i = 0; i < buttons.length; i++) {
                  buttons[i] = i == 3;
                }
              });
            },
            child: StatusButton(
              color: Colors.red,
              status: buttons[3],
              title: "Закончил",
              icon: Icons.pause,
            ),
          ),
        ],
      )),
    );
  }
}
