import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ForecastDay {
  final String date;
  final String maxTemp;
  final String minTemp;
  final String avgTemp;
  final String description;

  ForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.avgTemp,
    required this.description,
  });
}

class WeatherData {
  final String tempC;
  final String feelsLikeC;
  final String humidity;
  final String windSpeed;
  final String description;
  final String city;
  final List<ForecastDay> forecast;

  WeatherData({
    required this.tempC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.city,
    required this.forecast,
  });
}

class WeatherService {
  Future<WeatherData?> fetchWeather({String cityName = "İstanbul"}) async {
    try {
      final encodedCity = Uri.encodeComponent(cityName);
      final weatherUrl = 'https://wttr.in/$encodedCity?format=j1&lang=tr';
      final response = await http.get(Uri.parse(weatherUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_condition'][0];
        final nearestArea = data['nearest_area']?[0];
        final weatherDays = data['weather'] as List?;

        String areaName = cityName;
        if (nearestArea != null &&
            nearestArea['areaName'] != null &&
            (nearestArea['areaName'] as List).isNotEmpty) {
          areaName = nearestArea['areaName'][0]['value'];
        }

        String desc = '';
        if (current['lang_tr'] != null &&
            (current['lang_tr'] as List).isNotEmpty) {
          desc = current['lang_tr'][0]['value'];
        } else {
          desc = current['weatherDesc'][0]['value'];
        }

        List<ForecastDay> forecastList = [];
        if (weatherDays != null) {
          for (var day in weatherDays.take(3)) {
            String dayDesc = '';
            // Get description from the middle of the day (hourly index 4 is approx 12:00)
            final hourly = day['hourly'] as List?;
            if (hourly != null && hourly.length > 4) {
              final noon = hourly[4];
              if (noon['lang_tr'] != null &&
                  (noon['lang_tr'] as List).isNotEmpty) {
                dayDesc = noon['lang_tr'][0]['value'];
              } else {
                dayDesc = noon['weatherDesc'][0]['value'];
              }
            }

            forecastList.add(ForecastDay(
              date: day['date'] ?? '',
              maxTemp: day['maxtempC'] ?? '',
              minTemp: day['mintempC'] ?? '',
              avgTemp: day['avgtempC'] ?? '',
              description: dayDesc,
            ));
          }
        }

        return WeatherData(
          tempC: current['temp_C'],
          feelsLikeC: current['FeelsLikeC'],
          humidity: current['humidity'],
          windSpeed: current['windspeedKmph'],
          description: desc,
          city: areaName,
          forecast: forecastList,
        );
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    }
    return null;
  }
}
