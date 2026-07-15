// lib/widgets/location_picker_screen.dart
import 'package:flutter/material.dart';
// Добавьте зависимости для Yandex Maps
// yandex_map_kit: ^x.x.x (уточните версию)

// import 'package:yandex_map_kit/yandex_map_kit.dart'; // Пример импорта

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // YandexMapController? mapController;
  // Point? _selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите местоположение'),
        actions: [
          TextButton(
            onPressed: () {
              // if (_selectedPoint != null) {
              //   // Возвращаем координаты и адрес (если возможно получить)
              //   Navigator.pop(context, {
              //     'latitude': _selectedPoint!.latitude,
              //     'longitude': _selectedPoint!.longitude,
              //     'address': 'Адрес пока не реализован' // Нужно использовать геокодер
              //   });
              // }
            },
            child: const Text('Отправить', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Expanded(
          //   child: YandexMap(
          //     onMapCreated: (controller) {
          //       mapController = controller;
          //       // Добавьте слушатель нажатий на карту для выбора точки
          //       controller.onMapTap.add((point) {
          //         setState(() {
          //           _selectedPoint = point;
          //           // Опционально: добавить маркер на карту
          //         });
          //       });
          //     },
          //   ),
          // ),
          // if (_selectedPoint != null)
          //   Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: Text(
          //       'Выбрано: ${_selectedPoint!.latitude}, ${_selectedPoint!.longitude}',
          //       style: const TextStyle(fontSize: 16),
          //     ),
          //   ),
          // Временная заглушка, пока не подключим Yandex Maps
          const Expanded(
            child: Center(
              child: Text('Интеграция с Yandex MapsKit в процессе разработки.'),
            ),
          ),
        ],
      ),
    );
  }
}