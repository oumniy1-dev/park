import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

enum NotificationType { reminder, payment, promotion, system }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String time;
  final String dateCategory;
  bool isRead;
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    required this.dateCategory,
    this.isRead = false,
  });
}

/// Экран списка уведомлений.
/// Использует асинхронный [StreamBuilder], чтобы слушать новые уведомления из базы
/// данных в реальном времени (без необходимости обновлять страницу вручную).
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  void _markAllAsRead(List<NotificationModel> currentNotes) {
    if (currentNotes.any((n) => !n.isRead)) {
      _notificationService.markAllAsRead();
    }
  }

  void _deleteNotification(String id) {
    _notificationService.deleteNotification(id);
  }

  NotificationModel _parseNotification(Map<String, dynamic> data) {
    final createdStr = data['created_at'] as String;
    final createdAt = DateTime.parse(createdStr).toLocal();
    final now = DateTime.now();
    String dateCat = 'Older';
    final diffDays = DateTime(now.year, now.month, now.day)
        .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
        .inDays;
    if (diffDays == 0) {
      dateCat = 'Today';
    } else if (diffDays == 1) {
      dateCat = 'Yesterday';
    } else {
      dateCat = DateFormat('MMMM d, yyyy').format(createdAt);
    }
    String timeStr = DateFormat('hh:mm a').format(createdAt);
    final typeStr = data['type'] as String? ?? 'system';
    NotificationType nType = NotificationType.system;
    if (typeStr == 'reminder') nType = NotificationType.reminder;
    if (typeStr == 'payment') nType = NotificationType.payment;
    if (typeStr == 'promotion') nType = NotificationType.promotion;
    return NotificationModel(
      id: data['id'],
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      type: nType,
      time: timeStr,
      dateCategory: dateCat,
      isRead: data['is_read'] ?? false,
    );
  }

  Widget _buildIconForType(NotificationType type) {
    Color bgColor;
    IconData iconData;
    Color iconColor;
    switch (type) {
      case NotificationType.reminder:
        bgColor = const Color(0xFFFFF4E5);
        iconColor = const Color(0xFFFF9800);
        iconData = Icons.access_time_filled_rounded;
        break;
      case NotificationType.payment:
        bgColor = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF4CAF50);
        iconData = Icons.account_balance_wallet_rounded;
        break;
      case NotificationType.promotion:
        bgColor = const Color(0xFFF3E5F5);
        iconColor = const Color(0xFF9C27B0);
        iconData = Icons.card_giftcard_rounded;
        break;
      case NotificationType.system:
        bgColor = AppColors.primary.withOpacity(0.1);
        iconColor = AppColors.primary;
        iconData = Icons.info_rounded;
        break;
    }
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 24.w),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    const double globalLetterSpacing = 1.0;
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification deleted',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.errorColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 28.w),
      ),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 24.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconForType(notification.type),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16.sp,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              letterSpacing: globalLetterSpacing,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          notification.time,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: notification.isRead
                            ? AppColors.textLight
                            : AppColors.textDark.withOpacity(0.7),
                        fontSize: 14.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        letterSpacing: globalLetterSpacing,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                SizedBox(width: 12.w),
                Container(
                  margin: EdgeInsets.only(top: 6.h),
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    
    // StreamBuilder - это специальный виджет Flutter, который "слушает" поток данных (Stream).
    // Как только в базе появляется новое уведомление, он автоматически перерисовывает экран.
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notificationService.getUserNotifications(),
      builder: (context, snapshot) {
        
        // Пока данные загружаются первый раз, показываем индикатор загрузки
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(context, [], globalLetterSpacing),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final rawData = snapshot.data ?? [];
        List<NotificationModel> notifications = rawData
            .map((d) => _parseNotification(d))
            .toList();
        Map<String, List<NotificationModel>> groupedNotifications = {};
        for (var n in notifications) {
          if (!groupedNotifications.containsKey(n.dateCategory)) {
            groupedNotifications[n.dateCategory] = [];
          }
          groupedNotifications[n.dateCategory]!.add(n);
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, notifications, globalLetterSpacing),
          body: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 80.w,
                        color: AppColors.textLight.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No new notifications',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: globalLetterSpacing,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'You are all caught up!',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: globalLetterSpacing,
                        ),
                      ),
                    ],
                  ),
                )
              // Если уведомления ЕСТЬ, строим прокручиваемый список (ListView.builder)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(), // Эффект "пружины" при прокрутке как на iOS
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  itemCount: groupedNotifications.keys.length,
                  itemBuilder: (context, sectionIndex) {
                    // Группируем их по датам (Сегодня, Вчера, и т.д.)
                    String dateCat = groupedNotifications.keys.elementAt(
                      sectionIndex,
                    );
                    List<NotificationModel> sectionNotes =
                        groupedNotifications[dateCat]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 24.w,
                            right: 24.w,
                            top: 16.h,
                            bottom: 8.h,
                          ),
                          child: Text(
                            dateCat,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: globalLetterSpacing,
                            ),
                          ),
                        ),
                        ...sectionNotes.map(
                          (note) => _buildNotificationItem(note),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    List<NotificationModel> notifications,
    double globalLetterSpacing,
  ) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/ic_arrow_back.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: const ColorFilter.mode(
            AppColors.textDark,
            BlendMode.srcIn,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Notifications',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: globalLetterSpacing,
        ),
      ),
      actions: [
        TextButton(
          onPressed: notifications.any((n) => !n.isRead)
              ? () => _markAllAsRead(notifications)
              : null,
          child: Text(
            'Mark read',
            style: TextStyle(
              color: notifications.any((n) => !n.isRead)
                  ? AppColors.primary
                  : AppColors.textLight,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: globalLetterSpacing,
            ),
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }
}
