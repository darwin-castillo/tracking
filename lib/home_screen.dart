import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:tracking/common/widget_utils.dart';
import 'dart:math' show cos, sqrt, asin;

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  double zoom = 17.4746;
  LatLng position = const LatLng(7.7681964, -72.2233186);
  Location location = Location();
  bool enableTracking = false;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> listLocations = [];
  double distance = 0;
  late geo.LocationSettings locationSettings;
  late StreamSubscription<geo.Position> positionStream;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => getLocation());
  }

  void setLocationSettings() {
    if (Platform.isAndroid) {
      locationSettings = geo.AndroidSettings(
          accuracy: geo.LocationAccuracy.best,
          distanceFilter: 0,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 5),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
            notificationText:
                "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
          ));
    }
  }

  Future<void> getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    final GoogleMapController? controller = await _controller.future;
    setLocationSettings();

    _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        // ignore: use_build_context_synchronously
        await WidgetUtils.showOKDialiog(context,
            title: "GPS Desactivado",
            message: "Por favor active GPS para continuar");
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // ignore: use_build_context_synchronously
        await WidgetUtils.showOKDialiog(context,
            title: "Acceso no permitido",
            message: "No hay acceso a los permisos de ubicación");
        return;
      }
    }
    if (_permissionGranted == PermissionStatus.granted) {
      //  location.changeSettings(accuracy: LocationAccuracy.high);
      geo.Position _location = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.best);

      setState(() {
        enableTracking = true;
        position = LatLng(_location.latitude, _location.longitude);
      });
      moveCamera(latitude: _location.latitude, longitude: _location.longitude);

      /**
      * Iniciar el stream
      */
      positionStream =
          geo.Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((geo.Position? currentLocation) {
        double dist = calculateDistance(position.latitude, position.longitude,
            currentLocation!.latitude, currentLocation.longitude);
        print(
            "user current location ${currentLocation!.latitude}, ${currentLocation.longitude}");
        setState(() {
          position = LatLng(_location.latitude, _location.longitude);
          distance = dist + distance;
          listLocations.add(position);
        });
        moveCamera(latitude: _location.latitude, longitude: _location.latitude);
        addPolyLine(listLocations);
      });

      positionStream.onData((data) {
        print("user current location ${data.latitude}, ${data.longitude}");
        double dist = calculateDistance(position.latitude, position.longitude,
            data.latitude, data.longitude);

        setState(() {
          position = LatLng(data.latitude, data.longitude);
          distance = dist + distance;
          listLocations.add(position);
        });
        moveCamera(latitude: data.latitude, longitude: data.latitude);
        addPolyLine(listLocations);
      });

      /* location.onLocationChanged.listen((LocationData currentLocation) {
        // Use current location
        print("user current location ${currentLocation.latitude}, ${currentLocation.longitude}");
      });*/
    }
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  void moveCamera({required double latitude, required double longitude}) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(latitude, longitude), zoom: 17.1519)));
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking"),
      ),
      body: Stack(children: [
        GoogleMap(
          mapType: MapType.normal,
          polylines: Set<Polyline>.of(polylines.values),
          initialCameraPosition: CameraPosition(target: position, zoom: zoom),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
        Positioned(
          bottom: 10,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey, //New
                    blurRadius: 5.0,
                    offset: Offset(0, -5))
              ],
            ),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * .15,
            child: Column(
              children: [
                Text(
                  "Distancia Recorrida:",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                Text(
                  "${distance.toStringAsFixed(3)} m",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                Text(
                  "${position.latitude},${position.longitude}",
                  style: TextStyle(fontSize: 15, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * .5,
          right: 15,
          child: FloatingActionButton(
            onPressed: getLocation,
            child: Icon(Icons.my_location),
          ),
        )
      ]),
    );
  }
}
