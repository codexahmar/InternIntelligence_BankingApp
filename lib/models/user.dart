class User {
  final String id;
  String name;
  final String email;
  String password;
  String phoneNumber;
  String profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.profileImageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'] ?? '',
    );
  }

  // Create a copy of the user with updated fields
  User copyWith({String? name, String? phoneNumber, String? profileImageUrl}) {
    return User(
      id: this.id,
      name: name ?? this.name,
      email: this.email,
      password: this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
