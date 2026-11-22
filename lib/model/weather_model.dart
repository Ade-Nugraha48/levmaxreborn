/// Real-Time Weather Data Model
/// Conforms to Open-Meteo REST API specification in `docs/api_spec.md` (Module 5).
class WeatherModel {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final int isDay;
  final String time;
  final bool isOffline;

  const WeatherModel({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    required this.time,
    this.isOffline = false,
  });

  /// Factory constructor to parse Open-Meteo response
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>? ?? json;
    return WeatherModel(
      temperature: (current['temperature'] as num?)?.toDouble() ?? 28.0,
      windSpeed: (current['windspeed'] as num?)?.toDouble() ?? 10.0,
      weatherCode: (current['weathercode'] as num?)?.toInt() ?? 0,
      isDay: (current['is_day'] as num?)?.toInt() ?? 1,
      time: current['time']?.toString() ?? '',
      isOffline: false,
    );
  }

  /// Curated offline fallback weather
  factory WeatherModel.fallback({bool isOffline = true}) {
    return const WeatherModel(
      temperature: 28.0,
      windSpeed: 10.0,
      weatherCode: 0,
      isDay: 1,
      time: '',
      isOffline: true,
    );
  }

  /// WMO Weather interpretation code mapper
  /// Code 0: Clear sky
  /// Code 1-3: Mainly clear, partly cloudy, and overcast
  /// Code 45, 48: Fog
  /// Code 51-67, 80-82: Rain showers
  /// Code 71-77, 85-86: Snow
  /// Code 95-99: Thunderstorm
  String get conditionLabel {
    if (isOffline) return 'CLEAR SKY';
    if (weatherCode == 0) return 'CLEAR SKY';
    if (weatherCode >= 1 && weatherCode <= 3) return 'CLOUDY';
    if (weatherCode == 45 || weatherCode == 48) return 'FOGGY';
    if ((weatherCode >= 51 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return 'RAIN';
    }
    if ((weatherCode >= 71 && weatherCode <= 77) ||
        (weatherCode >= 85 && weatherCode <= 86)) {
      return 'SNOW';
    }
    if (weatherCode >= 95 && weatherCode <= 99) return 'STORM';
    return 'CLEAR SKY';
  }

  /// Weather icon representation
  String get iconName {
    if (weatherCode == 0) return isDay == 1 ? 'wb_sunny' : 'nightlight_round';
    if (weatherCode >= 1 && weatherCode <= 3) return 'cloud';
    if (weatherCode == 45 || weatherCode == 48) return 'foggy';
    if ((weatherCode >= 51 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return 'water_drop';
    }
    if (weatherCode >= 95 && weatherCode <= 99) return 'thunderstorm';
    return 'wb_sunny';
  }

  /// Display string for Map header HUD (e.g. "28°C · CLEAR SKY")
  String get displayTelemetry {
    return '${temperature.round()}°C · $conditionLabel';
  }
}
