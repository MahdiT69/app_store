class Supplier {
  final String id;
  final String nom;
  final String prenom;

  Supplier({required this.id, required this.nom, required this.prenom});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id_user']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
    );
  }

  String get fullName => "$prenom $nom".trim().isEmpty ? id : "$prenom $nom".trim();
}
