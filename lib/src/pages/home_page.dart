import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as prefix0;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

import 'package:uber_clone/src/requests/google_maps_services.dart';
import 'package:uber_clone/src/utils/main.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Map()
    );
  }
}

class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  GoogleMapController mapController;
  GoogleMapsServices _googleMapsServices      = GoogleMapsServices();
  TextEditingController locationController    = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  static LatLng _initialPosition;
  LatLng _lastPosition = _initialPosition;
  final Set<Marker> _markers     = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return _initialPosition == null? Container(
      alignment: Alignment.center,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ) : Stack(
      children: <Widget>[
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _initialPosition,
            zoom: 15.0
          ),
          onMapCreated: _onCreated,
          myLocationEnabled: true,
          mapType: MapType.normal,
          compassEnabled: true,
          markers: _markers,
          onCameraMove: _onCameraMove,
          polylines: _polylines,
        ),
        Positioned(
          top: 50.0,
          right: 15.0,
          left: 15.0,
          child: Container(
            height: 50.0,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(1.0, 5.0),
                  blurRadius: 10,
                  spreadRadius: 3)
              ],
              ),
              child: TextField(
                cursorColor: Colors.black,
                controller: locationController,
                decoration: InputDecoration(
                  icon: Container(
                    margin: EdgeInsets.only(left: 20, top: 5),
                    width: 10,
                    height: 10,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.black,
                    ),
                  ),
                  hintText: "pick up",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
                ),
              ),
            ),
          ),
          Positioned(
            top: 110.0,
            right: 15.0,
            left: 15.0,
            child: Container(
              height: 50.0,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      offset: Offset(1.0, 5.0),
                      blurRadius: 10,
                      spreadRadius: 3)
                ],
              ),
              child: TextField(
                cursorColor: Colors.black,
                controller: destinationController,
                textInputAction: TextInputAction.go,
                onSubmitted: (value){
                  sendRequest(value);
                },
                decoration: InputDecoration(
                  icon: Container(
                    margin: EdgeInsets.only(left: 20, top: 5),
                    width: 10,
                    height: 10,
                    child: Icon(
                      Icons.local_taxi,
                      color: Colors.black,
                    ),
                  ),
                  hintText: "destination?",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
                ),
              ),
            ),
          ),   
        //Positioned(
        //  top: 40,
        //  right: 10,
        //  child: FloatingActionButton(
        //    onPressed: _onAddMarkerPressed,
        //    tooltip: "Add marker",
        //    backgroundColor: greenCMM,
        //    child: Icon(Icons.add_location),
        //  ),
        //)
      ],
    );
  }

  void _onCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() { 
      _lastPosition = position.target;
    });
  }

  void _addMarker(LatLng location, String address) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(_lastPosition.toString()),
          position: location,
          infoWindow: InfoWindow(
            title: address,
            snippet: "GOOD VIBES"
          ),
          icon: BitmapDescriptor.defaultMarker
      ));
    });
  }

  void createRoute(String encodedPoly) {
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId(_lastPosition.toString()),
          width: 5,
          points: _convertToLatLng(decodePoly(encodedPoly)),
          color: Colors.red,
          visible: true
      ));
    });
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
// repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negetive then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

/*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    print(lList.toString());

    return lList;
  }

  void _getUserLocation() async {
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: prefix0.LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      locationController.text = "${placemark[0].thoroughfare} ${placemark[0].name}, ${placemark[0].subAdministrativeArea}";
    });
  }

  void sendRequest(String intendedLocation) async {
    List<Placemark> placemark = await Geolocator().placemarkFromAddress(intendedLocation);
    double latitude    = placemark[0].position.latitude;
    double longitude   = placemark[0].position.longitude;
    LatLng destination = LatLng(latitude, longitude);
    _addMarker(destination, intendedLocation);
    String route = await _googleMapsServices.getRouteCoordinates(_initialPosition, destination);
    createRoute(route);

  }
}