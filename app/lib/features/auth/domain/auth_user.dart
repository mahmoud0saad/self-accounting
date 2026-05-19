class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.timezone,
    this.locale,
    this.bio,
    this.emailConfirmedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String? timezone;
  final String? locale;
  final String? bio;
  final DateTime? emailConfirmedAt;

  bool get isEmailConfirmed => emailConfirmedAt != null;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final confirmed = json['emailConfirmedAt'] as String?;
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      photoUrl: json['photoUrl'] as String?,
      timezone: json['timezone'] as String?,
      locale: json['locale'] as String?,
      bio: json['bio'] as String?,
      emailConfirmedAt:
          confirmed != null ? DateTime.tryParse(confirmed) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'photoUrl': photoUrl,
    'timezone': timezone,
    'locale': locale,
    'bio': bio,
    'emailConfirmedAt': emailConfirmedAt?.toUtc().toIso8601String(),
  };

  AuthUser copyWith({
    String? fullName,
    String? photoUrl,
    String? timezone,
    String? locale,
    String? bio,
    DateTime? emailConfirmedAt,
  }) {
    return AuthUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      bio: bio ?? this.bio,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
    );
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}
