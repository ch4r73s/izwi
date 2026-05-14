class AppConstants {
  AppConstants._();

  // Update this once to point the app to your backend.
  static const String apiBaseUrl = 'https://izwi-api.steinovate.com';

  static const String loginPath = '/api/auth/login';
  static const String refreshPath = '/api/auth/refresh';
  static const String healthPath = '/health';

  static const String addUserPath = '/api/users/addUser';
  static const String registerUserPath = '/api/users/registerUser';
  static const String messageGatewayCredentialsPath =
      '/api/messagegatewayapi/credentials';
  static const String notificationsPath = '/api/notifications';
  static const String notificationsSentPath = '/api/notifications/sent';
  static const String recipientsPath = '/api/recipients';
  static const String clientsPath = '/api/clients';
  static const String templatesPath = '/api/templates';
  static const String changePasswordPath = '/api/auth/change-password';
  static const String profilePath = '/api/auth/profile';
  static const String clientsMyPath = '/api/clients/my';
  static const String recordSmsPath = '/api/clients/my/record-sms';
}
