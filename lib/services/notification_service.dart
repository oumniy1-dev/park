import 'package:supabase_flutter/supabase_flutter.dart';

/// Сервис для работы с уведомлениями пользователя (Notifications).
/// Обеспечивает добавление, получение, пометку прочитанными и удаление уведомлений.
class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Добавляет новое уведомление в базу данных.
  /// 
  /// Принимает заголовок [title], текст сообщения [message] и тип [type].
  /// Опциональный [userId] позволяет отправить уведомление конкретному пользователю.
  /// Если [userId] не передан, используется ID текущего пользователя.
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? userId,
  }) async {
    final uid = userId ?? _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _supabase.from('notifications').insert({
        'user_id': uid,
        'title': title,
        'message': message,
        'type': type,
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  /// Открывает реактивный поток данных (Stream) для получения уведомлений в реальном времени.
  /// Метод используется в виджете [StreamBuilder] для мгновенного обновления UI.
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    
    // Шаг 1: Вместо .select() вызываем .stream(). 
    // Это создает вебсокет-подключение и слушает все события в таблице 'notifications'.
    // Шаг 2: Ограничиваем события только уведомлениями текущего пользователя (eq 'user_id').
    // Шаг 3: Сортируем новые (по дате 'created_at') к вершине списка (ascending: false).
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Асинхронно скачивает уведомления текущего пользователя (один раз).
  /// Сортирует по дате создания (новые сверху).
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Помечает конкретное уведомление как прочитанное по его [id].
  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  /// Помечает все непрочитанные уведомления текущего пользователя как прочитанные.
  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications read: $e');
    }
  }

  /// Удаляет конкретное уведомление из базы данных по его [id].
  Future<void> deleteNotification(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}
