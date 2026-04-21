import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

/// Сервис для управления авторизацией пользователей через Supabase Auth.
/// Реализует регистрацию, вход, выход и восстановление пароля.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Регистрация нового пользователя (Sign Up) в Supabase.
  /// 
  /// Процесс состоит из двух шагов:
  /// 1. Создание учетной записи (Auth) с помощью email и пароля.
  /// 2. Запись дополнительных метаданных пользователя (Имя 'full_name' и 'phone').
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Шаг 1: Вызов встроенного метода регистрации Supabase Auth.
      // Поля email и password уходят в системную таблицу auth.users.
      // Аргумент data сохраняет публичные метаданные в формате JSONB.
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Авторизует пользователя с использованием Email и пароля.
  /// Возвращает сессию или бросает ошибку при неверных данных.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Выходит из текущего аккаунта (разлогинивает пользователя).
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Возвращает текущего авторизованного пользователя.
  /// Возвращает null, если пользователь не вошел в систему.
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Отправляет на указанный [email] письмо с инструкциями по сбросу пароля.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Вызывает RPC-функцию в базе данных Supabase, чтобы проверить,
  /// зарегистрирован ли уже такой [email] в системе.
  /// Возвращает true, если email уже существует.
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase.rpc(
        'check_email_exists',
        params: {'email_to_check': email},
      );
      // RPC может вернуть bool, int (1/0) или строку — обрабатываем все варианты
      if (response == null) return false;
      if (response is bool) return response;
      if (response is int) return response != 0;
      return response.toString().toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Сбрасывает пароль пользователя напрямую через SQL-функцию в Supabase.
  /// Не требует отправки email — работает с фейковыми адресами.
  /// Возвращает true если пользователь найден и пароль обновлён.
  Future<bool> resetPasswordDirectly({required String email, required String newPassword}) async {
    try {
      final response = await _supabase.rpc(
        'reset_user_password',
        params: {
          'user_email': email,
          'new_password': newPassword,
        },
      );
      if (response == null) return false;
      if (response is bool) return response;
      if (response is int) return response != 0;
      return response.toString().toLowerCase() == 'true';
    } catch (e) {
      rethrow;
    }
  }

  /// Стрим для отслеживания изменений состояния аутентификации в реальном времени.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Обновляет текстовую информацию о профиле (имя [fullName] и телефон [phone]).
  /// Изменения записываются в user_metadata Supabase Auth.
  Future<void> updateProfile({String? fullName, String? phone}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final Map<String, dynamic> data = Map.from(user.userMetadata ?? {});
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    await _supabase.auth.updateUser(UserAttributes(data: data));
  }

  /// Загружает аватар (изображение профиля) в облачное хранилище Supabase Storage.
  Future<void> uploadAvatar(Uint8List imageBytes, String fileName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');
      
      // Шаг 1: Формируем уникальный путь к файлу.
      // Каждый пользователь хранит свои аватары в папке, названной по его user_id.
      final filePath = '${user.id}/$fileName';
      
      // Шаг 2: Загружаем бинарные данные картинки (Uint8List) напрямую в корзину (bucket) 'avatars'.
      // Параметр upsert: true означает, что если файл уже есть, он будет перезаписан.
      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(upsert: true),
          );
          
      // Шаг 3: Получаем публичную (доступную из интернета) прямую ссылку на картинку.
      final String publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(filePath);
          
      // Шаг 4: Сохраняем публичную ссылку в метаданные пользователя (avatar_url).
      // Таким образом, URL аватара будет загружаться вместе с юзером при каждом запуске приложения.
      await _supabase.auth.updateUser(UserAttributes(data: {
        'avatar_url': publicUrl,
      }));
    } catch (e) {
      throw Exception('Ошибка при загрузке аватара: $e');
    }
  }
}
