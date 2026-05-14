class NotificationTemplate {
  final String id;
  final String name;
  final String title;
  final String body;

  const NotificationTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.body,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'body': body,
  };
}
