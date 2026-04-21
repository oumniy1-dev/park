import 'package:supabase_flutter/supabase_flutter.dart';

/// Сервис для управления избранными (сохраненными) парковками.
/// Позволяет добавлять парковки в закладки и проверять, сохранена ли парковка.
class SavedService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Возвращает список ID всех сохраненных (избранных) парковок текущего пользователя.
  /// Если пользователь не авторизован, возвращает пустой список.
  Future<List<String>> getSavedParkings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return [];
    }
    final response = await _supabase
        .from('saved_parkings')
        .select('parking_id')
        .eq('user_id', user.id);
    final data = List<Map<String, dynamic>>.from(response);
    return data.map((row) => row['parking_id'].toString()).toList();
  }

  /// Переключает статус сохранения конкретной парковки [parkingId].
  /// 
  /// Если [isSaved] == true, сохраняет парковку в базу данных (upsert).
  /// Если [isSaved] == false, удаляет парковку из сохраненных (таблица `saved_parkings`).
  Future<void> toggleSaved(String parkingId, bool isSaved) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (isSaved) {
      try {
        await _supabase.from('saved_parkings').upsert({
          'user_id': user.id,
          'parking_id': parkingId,
        }, onConflict: 'user_id, parking_id');
      } catch (e) {
        await _supabase
            .from('saved_parkings')
            .delete()
            .eq('user_id', user.id)
            .eq('parking_id', parkingId);
        await _supabase.from('saved_parkings').insert({
          'user_id': user.id,
          'parking_id': parkingId,
        });
      }
    } else {
      await _supabase
          .from('saved_parkings')
          .delete()
          .eq('user_id', user.id)
          .eq('parking_id', parkingId);
    }
  }
}
