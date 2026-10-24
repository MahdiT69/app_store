class AppUser {
  final String idUser;
  final String? nom;
  final String? prenom;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;

  AppUser({
    required this.idUser,
    this.nom,
    this.prenom,
    this.fullName,
    this.email,
    this.phone,
    this.role,
  });

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final combined = "${nom ?? ''} ${prenom ?? ''}".trim();
    if (combined.isNotEmpty) return combined;
    return idUser;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      idUser: json['id_user']?.toString() ?? '',
      nom: json['nom'],
      prenom: json['prenom'],
      fullName: json['full_name'] ?? (json['nom'] != null || json['prenom'] != null ? "${json['nom'] ?? ''} ${json['prenom'] ?? ''}".trim() : null),
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
    );
  }
}
