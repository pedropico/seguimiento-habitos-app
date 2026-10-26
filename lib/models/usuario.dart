class Usuario {
  final int id;
  final String email;

  const Usuario({required this.id, required this.email});

  @override
  String toString() => '$email (#$id)';
}
