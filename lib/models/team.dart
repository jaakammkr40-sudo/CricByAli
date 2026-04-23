class Team {
  final String id;
  final String name;

  const Team({required this.id, required this.name});

  Team copyWith({String? id, String? name}) =>
      Team(id: id ?? this.id, name: name ?? this.name);

  @override
  bool operator ==(Object other) => other is Team && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team($name)';
}
