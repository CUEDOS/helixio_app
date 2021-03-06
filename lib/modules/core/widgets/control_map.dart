import 'package:flutter/material.dart';
//import 'package:helixio_app/pages/page_scaffold.dart';
import 'package:helixio_app/modules/core/secrets/keys.dart';
import 'package:helixio_app/modules/helpers/service_locator.dart';
import 'package:helixio_app/modules/core/models/agent_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart';
import 'package:helixio_app/modules/core/managers/swarm_manager.dart';
import 'package:timer_builder/timer_builder.dart';
import 'dart:math' as math;

class ControlMap extends StatefulWidget {
  const ControlMap({Key? key}) : super(key: key);
  //final SwarmManager swarmManager;

  @override
  _ControlMapState createState() => _ControlMapState();
}

class _ControlMapState extends State<ControlMap> {
  final controller = MapController(
    //location: LatLng(53.43578053111544, -2.250343561172483),
    location: LatLng(52.81651946850575, -4.124781265539541),
  );

  bool _darkMode = false;

  List<AgentMarker> _generateMarkers(var swarm, MapTransformer transformer) {
    List<AgentMarker> agentMarkers = [];

    if (swarm.isNotEmpty) {
      Iterable<AgentState> agents = swarm.values;
      for (AgentState agent in agents) {
        agentMarkers.add(AgentMarker(agent.getLatLng, agent.getHeading,
            transformer.fromLatLngToXYCoords(agent.getLatLng)));
      }
    }
    return agentMarkers;
  }

  void _gotoDefault() {
    controller.center = LatLng(53.43578053111544, -2.250343561172483);
    setState(() {});
  }

  void _onDoubleTap() {
    controller.zoom += 0.5;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller.zoom = 16.5;
    setState(() {});
  }

  // void _setInitialZoom() {
  //   controller.zoom = 10;
  //   setState(() {});
  // }

  Offset? _dragStart;
  double _scaleStart = 1.0;
  void _onScaleStart(ScaleStartDetails details) {
    _dragStart = details.focalPoint;
    _scaleStart = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final scaleDiff = details.scale - _scaleStart;
    _scaleStart = details.scale;

    if (scaleDiff > 0) {
      controller.zoom += 0.02;
      setState(() {});
    } else if (scaleDiff < 0) {
      controller.zoom -= 0.02;
      setState(() {});
    } else {
      final now = details.focalPoint;
      final diff = now - _dragStart!;
      _dragStart = now;
      controller.drag(diff.dx, diff.dy);
      setState(() {});
    }
  }

  Widget _buildMarkerWidget(Offset pos, double heading, Color color) {
    return Positioned(
      left: pos.dx - 16,
      top: pos.dy - 16,
      width: 24,
      height: 24,
      // child: Row(
      //   children: [
      //     const Text('SXXX'),
      //     Icon(Icons.airplanemode_active, color: color),
      //   ],
      // ),
      child: Transform.rotate(
          //convert heading in degrees to radians
          angle: heading * (math.pi / 180),
          child: Icon(Icons.airplanemode_active, color: color, size: 15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('drawing map');
    // used to update map at set frequency rather than as fast as updates are received
    // increases performance
    return TimerBuilder.periodic(const Duration(milliseconds: 100),
        builder: (context) {
      return MapLayoutBuilder(
        controller: controller,
        builder: (context, transformer) {
          // final markerPositions = _generateMarkers(widget.swarmManager)
          //     .map((agentMarker) =>
          //         transformer.fromLatLngToXYCoords(agentMarker.getLatLng))
          //     .toList();

          var swarm = serviceLocator<SwarmManager>().swarm;

          final markerPositions = _generateMarkers(swarm, transformer);

          final markerWidgets = markerPositions.map(
            (agentMarker) => _buildMarkerWidget(
                agentMarker.cartesian, agentMarker.heading, Colors.red),
          );

          // final homeLocation = transformer.fromLatLngToXYCoords(
          //     LatLng(53.43578053111544, -2.250343561172483));

          //final homeMarkerWidget = _buildMarkerWidget(homeLocation, Colors.black);

          final centerLocation = Offset(
              transformer.constraints.biggest.width / 2,
              transformer.constraints.biggest.height / 2);

          // final centerMarkerWidget =
          //     _buildMarkerWidget(centerLocation, Colors.purple);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: _onDoubleTap,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onTapUp: (details) {
              final location =
                  transformer.fromXYCoordsToLatLng(details.localPosition);

              final clicked = transformer.fromLatLngToXYCoords(location);

              print('${location.longitude}, ${location.latitude}');
              print('${clicked.dx}, ${clicked.dy}');
              print('${details.localPosition.dx}, ${details.localPosition.dy}');
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  final delta = event.scrollDelta;

                  controller.zoom -= delta.dy / 1000.0;
                  setState(() {});
                }
              },
              child: Stack(
                children: [
                  Map(
                    controller: controller,
                    builder: (context, x, y, z) {
                      //Mapbox Streets
                      final url =
                          'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/$z/$x/$y?access_token=' +
                              mapBoxApiKey;

                      return CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  //homeMarkerWidget,
                  ...markerWidgets,
                  //centerMarkerWidget,
                ],
              ),
            ),
          );
        },
      );
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _gotoDefault,
      //   tooltip: 'My Location',
      //   child: const Icon(Icons.my_location),
      //),
    });
  }
}

// Defines marker object containing position and heading
class AgentMarker {
  final LatLng latLng;
  final double heading;
  final Offset cartesian;

  AgentMarker(this.latLng, this.heading, this.cartesian);

  // LatLng get getLatLng => _latLng;
  // double get getHeading => _heading;
  // Offset get getCartesian => _cartesian;
}
