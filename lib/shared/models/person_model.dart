class PersonModel {
  final int id;
  final String name;
  final String? profilePath;
  final String? knownForDepartment;
  final String? character;
  final String? job;

  PersonModel({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownForDepartment,
    this.character,
    this.job,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profilePath: json['profile_path'],
      knownForDepartment: json['known_for_department'],
      character: json['character'],
      job: json['job'],
    );
  }

  String? get profileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : null;
}
