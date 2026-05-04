class UserModel {
  final String id;
  final String email;
  final String role;
  final String? adminId;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.adminId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'cashier',
      adminId: data['adminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      if (adminId != null) 'adminId': adminId,
    };
  }
}
