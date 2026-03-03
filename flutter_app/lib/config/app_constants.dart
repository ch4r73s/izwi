class AppConstants {
  AppConstants._();

  // Update this once to point the app to your backend.
  static const String apiBaseUrl = 'https://2135-196-201-16-142.ngrok-free.app';

  static const String loginPath = '/api/auth/login';
  static const String healthPath = '/health';

  static const String addUserPath = '/api/users/addUser';
  static const String registerUserPath = '/api/users/registerUser';
  static const String messageGatewayCredentialsPath =
      '/api/messagegatewayapi/credentials';
  static const String notificationsPath = '/api/notifications';
  static const String notificationsSentPath = '/api/notifications/sent';
  static const String recipientsPath = '/api/recipients';
  static const String clientsPath = '/api/clients';
}
