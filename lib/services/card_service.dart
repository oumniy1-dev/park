import 'package:supabase_flutter/supabase_flutter.dart';

/// Сервис для сохранения банковских карт пользователя.
/// Сохраняет маскированный номер карты (например, `.... .... .... 1234`) и имя держателя в Supabase.
class CardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Добавляет новую банковскую карту в профиль пользователя.
  /// 
  /// Полный номер карты [cardNumber] не сохраняется в целях безопасности.
  /// Записывается только [cardholderName] и маскированный номер (последние 4 цифры).
  Future<void> addCard({
    required String cardholderName,
    required String cardNumber,
    required String expiry,
    required String cvv,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User applies to be logged in');
    }
    String cleanNumber = cardNumber.replaceAll(' ', '');
    String masked = '.... .... .... ';
    if (cleanNumber.length >= 4) {
      masked += cleanNumber.substring(cleanNumber.length - 4);
    } else {
      masked += cleanNumber;
    }
    await _supabase.from('user_cards').insert({
      'user_id': user.id,
      'cardholder_name': cardholderName,
      'masked_number': masked,
    });
  }

  /// Возвращает список сохраненных банковских карт текущего пользователя.
  Future<List<Map<String, dynamic>>> getUserCards() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final response = await _supabase
        .from('user_cards')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Удаляет выбранные банковские карты из базы данных по их [ids].
  /// Проверяет, что удаляемые карты принадлежат текущему пользователю (`user_id`).
  Future<void> deleteCards(List<dynamic> ids) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    if (ids.isEmpty) return;
    await _supabase
        .from('user_cards')
        .delete()
        .inFilter('id', ids)
        .eq('user_id', user.id);
  }
}
