import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GpsUtil {
  /// Determina a posição atual do dispositivo.
  /// Lança exceções se o serviço estiver desabilitado ou permissões negadas.
  static Future<LatLng?> obterLocalizacaoAtual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o GPS está ligado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Serviço desabilitado
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permissão negada
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Permissão negada permanentemente
    }

    // Pega a posição
    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  /// Calcula a distância em metros entre dois pontos
  static double calcularDistancia(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude, 
      p1.longitude, 
      p2.latitude, 
      p2.longitude
    );
  }
}