import 'package:fl_uberapp/src/config/configs.dart';
import 'package:fl_uberapp/src/model/place_item_res.dart';
import 'package:fl_uberapp/src/model/step_res.dart';
import 'package:fl_uberapp/src/model/trip_info_res.dart';
import 'package:fl_uberapp/src/repository/place_service.dart';
import 'package:fl_uberapp/src/resources/widgets/car_pickup.dart';
import 'package:fl_uberapp/src/resources/widgets/home_menu.dart';
import 'package:fl_uberapp/src/resources/widgets/ride_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _tripDistance = 0;
  final Map<String, Marker> _markers = <String, Marker>{};

  //final Set<Marker> _markers = {};

  GoogleMapController _mapController;

  Set<Polyline> _polylines = {};

  @override
  Widget build(BuildContext context) {
    print("build UI");
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        constraints: BoxConstraints.expand(),
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            GoogleMap(
              key: Key(Configs.ggKEY),
//              markers: Set.of(_markers.values),
              markers: _markers.values.toSet(),
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                //_mapController.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(10.7915178, 106.7271422),
                zoom: 14.4746,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    title: Text(
                      "Taxi App",
                      style: TextStyle(color: Colors.black),
                    ),
                    leading: FlatButton(
                        onPressed: () {
                          print("click menu");
                          _scaffoldKey.currentState.openDrawer();
                        },
                        child: Image.asset("ic_menu.png")),
                    actions: <Widget>[Image.asset("ic_notify.png")],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                    child: RidePicker(onPlaceSelected),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              height: 248,
              child: CarPickup(_tripDistance),
            )
          ],
        ),
      ),
      drawer: Drawer(
        child: HomeMenu(),
      ),
    );
  }

  void onPlaceSelected(PlaceItemRes place, bool fromAddress) {
    var mkId = fromAddress ? "from_address" : "to_address";
    _addMarker(mkId, place);
// was commented...
 _moveCamera();
    _checkDrawPolyline();
  }

  void _addMarker(String mkId, PlaceItemRes place) async {
    // remove old
    _markers.remove(mkId);
    //_mapController.clearMarkers();

    _markers[mkId] = new Marker(
      markerId: MarkerId(mkId),
      position: LatLng(place.lat, place.lng),
      infoWindow: new InfoWindow(title: place.name, snippet: place.address),
      //+
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    );

//    for (var m in _markers.values) {
//      await _mapController.addMarker(m.options);
//    }
  }

  void _moveCamera() {
    print("move camera: ");
    print(_markers);

    if (_markers.values.length > 1) {
      var fromLatLng = _markers["from_address"].position;
      var toLatLng = _markers["to_address"].position;

      var sLat, sLng, nLat, nLng;
      if (fromLatLng.latitude <= toLatLng.latitude) {
        sLat = fromLatLng.latitude;
        nLat = toLatLng.latitude;
      } else {
        sLat = toLatLng.latitude;
        nLat = fromLatLng.latitude;
      }

      if (fromLatLng.longitude <= toLatLng.longitude) {
        sLng = fromLatLng.longitude;
        nLng = toLatLng.longitude;
      } else {
        sLng = toLatLng.longitude;
        nLng = fromLatLng.longitude;
      }

      LatLngBounds bounds = LatLngBounds(
          northeast: LatLng(nLat, nLng),
          southwest: LatLng(sLat, sLng)
      );
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else if (_markers.values.length >0) {
      //One marker required
      _mapController.animateCamera(
          CameraUpdate.newLatLng(_markers.entries.first.value.position)
      );
    }
  }

  void _checkDrawPolyline() {
//  remove old polyline
    //_mapController.clearPolylines();
    _polylines.clear();

    if (_markers.length > 1) {
      var from = _markers["from_address"].position;
      var to = _markers["to_address"].position;
      PlaceService.getStep(
              from.latitude, from.longitude, to.latitude, to.longitude)
          .then((vl) {
        TripInfoRes infoRes = vl;

        _tripDistance = infoRes.distance;
        setState(() {});
        List<StepsRes> rs = infoRes.steps;
        List<LatLng> paths = new List();
        for (var t in rs) {
          paths
              .add(LatLng(t.startLocation.latitude, t.startLocation.longitude));
          paths.add(LatLng(t.endLocation.latitude, t.endLocation.longitude));
        }

        //print(paths);
//        _mapController.addPolyline(PolylineOptions(
//            points: paths, color: Color(0xFF3ADF00).value, width: 10));
//      });

        _polylines.add(
            new Polyline(polylineId: PolylineId("polyline-1"), points: paths, color: Color(0xFF3ADF00), width: 10));
      });
    }
  }
}
