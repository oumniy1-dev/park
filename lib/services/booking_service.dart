import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Сервис для управления бронированием парковочных мест.
/// Отвечает за создание, отмену, проверку статусов и автоматическое завершение истекших бронирований.
class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Создает новое бронирование парковочного места.
  /// 
  /// Принимает ID места [spotId], название парковки [parkingTitle], адрес [location],
  /// период времени [timeRange], стоимость [price], длительность [duration] и данные авто.
  /// Также автоматически обновляет статус места в базе на 'booked' и отправляет уведомление об оплате.
  Future<void> addBooking({
    required String spotId,
    required String parkingTitle,
    required String location,
    required String timeRange,
    required String price,
    required String duration,
    required String vehicleName,
    required String vehiclePlate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    final metadata = user.userMetadata ?? {};
    final String name = metadata['full_name'] ?? 'Unknown User';
    final String phone = metadata['phone'] ?? '+7 700 000 00 00';
    final now = DateTime.now();
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final String currentDateStr =
        '${months[now.month - 1]} ${now.day}, ${now.year}';
    await _supabase.from('bookings').insert({
      'user_id': user.id,
      'spot_id': spotId,
      'parking_title': parkingTitle,
      'location': location,
      'time_range': timeRange,
      'price': price,
      'duration': duration,
      'status': 'Now active',
      'vehicle_name': vehicleName,
      'vehicle_plate': vehiclePlate,
      'name': name,
      'phone': phone,
      'booking_date': currentDateStr,
    });
    await _supabase
        .from('parking_spots')
        .update({'status': 'booked'})
        .eq('id', spotId);
    NotificationService().addNotification(
      title: 'Payment Successful',
      message: 'Paid $price for parking at $parkingTitle ($location).',
      type: 'payment',
      userId: user.id,
    );
  }

  /// Отменяет существующее бронирование пользователя.
  /// 
  /// Меняет статус бронирования на 'Cancelled' в таблице `bookings` 
  /// и освобождает парковочное место в таблице `parking_spots` (устанавливает status = 'available').
  /// Отправляет системное уведомление об отмене.
  Future<void> cancelBooking({
    required String bookingId,
    required String spotId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase
        .from('bookings')
        .update({'status': 'Cancelled'})
        .eq('user_id', user.id)
        .eq('spot_id', spotId);
    await _supabase
        .from('parking_spots')
        .update({'status': 'available'})
        .eq('id', spotId);
    NotificationService().addNotification(
      title: 'Booking Cancelled',
      message:
          'Your active booking was cancelled and your spot is now released.',
      type: 'system',
      userId: user.id,
    );
  }

  /// Получает историю бронирований текущего пользователя.
  /// 
  /// При получении данных автоматически проверяет, не истекло ли время активных бронирований ('Now active').
  /// Если время вышло, статус меняется на 'Completed', а парковочное место освобождается.
  Future<List<Map<String, dynamic>>> getBookings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return [];
    }
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
      response,
    );
    final now = DateTime.now();
    for (var b in data) {
      if (b['status'] == 'Now active') {
        final endTime = _parseEndTime(
          b['booking_date'],
          b['time_range'],
          b['created_at'],
        );
        if (endTime != null && now.isAfter(endTime)) {
          b['status'] = 'Completed';
          _supabase
              .from('bookings')
              .update({'status': 'Completed'})
              .eq('id', b['id'])
              .catchError((e) {
                print('Error completing expire: $e');
              });
          _supabase
              .from('parking_spots')
              .update({'status': 'available'})
              .eq('id', b['spot_id'])
              .catchError((e) {
                print('Error freeing spot: $e');
              });
        }
      }
    }
    return data;
  }

  /// Глобальная проверка всех активных бронирований ('Now active') в базе данных.
  /// 
  /// Вызывается для автоматического завершения бронирований, время которых истекло.
  /// Освобождает занятые парковочные места и отправляет PUSH-уведомление пользователю об окончании парковки.
  Future<void> checkAndClearExpiredBookingsGlobally() async {
    try {
      // 1. Получаем из базы только те брони, которые сейчас активны
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('status', 'Now active');
      final List<Map<String, dynamic>> activeBookings =
          List<Map<String, dynamic>>.from(response);
          
      final now = DateTime.now(); // Текущее время устройства
      
      // 2. Проходим в цикле по каждому активному бронированию
      for (var b in activeBookings) {
        // Вычисляем точное время завершения бронирования, конвертируя строки из БД
        final endTime = _parseEndTime(
          b['booking_date'],
          b['time_range'],
          b['created_at'],
        );
        
        // 3. Если время успешно распарсилось и текущее время превысило endTime (бронь истекла)
        if (endTime != null && now.isAfter(endTime)) {
          // Отмечаем саму бронь как "Completed" (Завершено)
          await _supabase
              .from('bookings')
              .update({'status': 'Completed'})
              .eq('id', b['id'])
              .catchError((e) {
                print('Error completing global expire: $e');
              });
              
          // Освобождаем физическое место на парковке для других водителей
          await _supabase
              .from('parking_spots')
              .update({'status': 'available'})
              .eq('id', b['spot_id'])
              .catchError((e) {
                print('Error globally freeing spot: $e');
              });
              
          // Генерируем уведомление для владельца аккаунта, что сессия закончилась
          NotificationService().addNotification(
            title: 'Parking Session Ended',
            message:
                'Your time is up at ${b['parking_title']}! Hope you had a great experience.',
            type: 'system',
            userId: b['user_id'],
          );
        }
      }
    } catch (e) {
      print('Error checking global expired bookings: $e');
    }
  }

  /// Внутренняя функция (утилита) для парсинга текстовой строки времени [timeRangeStr]
  /// и конвертации ее в объект DateTime, представляющий точное время окончания брони.
  DateTime? _parseEndTime(
    String? dateStr,
    String? timeRangeStr,
    String? createdAtStr,
  ) {
    if (dateStr == null || timeRangeStr == null) return null;
    try {
      // Шаг 1: Парсим строку даты формата "Month DD, YYYY" (например "March 30, 2026")
      final parts = dateStr.replaceAll(',', '').split(' ');
      if (parts.length < 3) return null;
      final monthStr = parts[0];
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      // Шаг 2: Создаем маппинг месяцев в их числовые эквиваленты (1-12)
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      final month = months.indexOf(monthStr) + 1;
      if (month == 0) return null;
      
      // Шаг 3: Парсим строку времени формата "HH:MM - HH:MM"
      // Нас интересует только второе значение (окончание бронирования)
      final timeParts = timeRangeStr.split(' - ');
      if (timeParts.length != 2) return null;
      final endParts = timeParts[1].trim().split(':');
      final hour = int.parse(endParts[0]);
      final minute = int.parse(endParts[1]);
      
      // Шаг 4: Собираем финальный объект даты и времени окончания брони
      DateTime endTime = DateTime(year, month, day, hour, minute);
      
      // Шаг 5: Перенос через полночь. Если парковка была до раннего утра (например, 23:00 - 02:00),
      // то endTime (02:00 того же дня) может оказаться математически меньше времени начала.
      // В этом случае мы прибавляем один день (+24 часа), чтобы логика отсчета не сломалась.
      if (createdAtStr != null) {
        final createdAt = DateTime.parse(createdAtStr).toLocal();
        if (endTime.isBefore(createdAt)) {
          endTime = endTime.add(const Duration(days: 1));
        }
      }
      return endTime;
    } catch (e) {
      // Перехватываем ошибки преобразования типов, чтобы приложение не упало
      return null;
    }
  }
}
