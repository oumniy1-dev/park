import 'package:supabase_flutter/supabase_flutter.dart';

/// Сервис для работы с транспортными средствами пользователя в базе данных (Supabase).
/// Позволяет добавлять, получать и удалять автомобили.
class VehicleService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Добавляет новое транспортное средство в базу данных.
  /// 
  /// Принимает марку/модель [make] и госномер [plate].
  /// Привязывает созданный автомобиль к текущему авторизованному пользователю.
  Future<void> addVehicle({required String make, required String plate}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    await _supabase.from('vehicles').insert({
      'user_id': user.id,
      'make': make,
      'plate': plate,
    });
  }

  /// Возвращает список всех транспортных средств текущего пользователя.
  /// 
  /// Возвращает список в виде Map, отсортированный по дате добавления (самые новые сверху).
  /// Возвращает пустой список, если пользователь не авторизован.
  Future<List<Map<String, dynamic>>> getVehicles() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return [];
    }
    final response = await _supabase
        .from('vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Удаляет выбранные транспортные средства по их [ids].
  /// Вызывается из UI "My Vehicles" при множественном выборе.
  Future<void> deleteVehicles(List<dynamic> ids) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }
    
    // Шаг 1: Проходим циклом по каждому ID, который был выделен в UI
    for (var id in ids) {
      // Шаг 2: Выполняем удаление записи из таблицы 'vehicles'.
      // ВАЖНО: Мы добавляем условие .eq('user_id', user.id). 
      // Это критическая мера безопасности на стороне клиента, гарантирующая, 
      // что никто не сможет удалить чужую машину, даже украв её айди.
      await _supabase
          .from('vehicles')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    }
  }
}
