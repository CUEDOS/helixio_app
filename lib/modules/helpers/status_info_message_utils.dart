import 'package:helixio_app/modules/core/models/mqtt_app_state.dart';

String prepareMQTTStateMessageFrom(MQTTAppConnectionState state) {
  switch (state) {
    case MQTTAppConnectionState.connected:
      return 'Connected';
    case MQTTAppConnectionState.connecting:
      return 'Connecting';
    case MQTTAppConnectionState.disconnected:
      return 'Disconnected';
    case MQTTAppConnectionState.connectedSubscribed:
      return 'Subscribed';
    case MQTTAppConnectionState.connectedUnSubscribed:
      return 'Unsubscribed';
  }
}
