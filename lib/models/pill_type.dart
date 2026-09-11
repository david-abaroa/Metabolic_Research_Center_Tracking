/// A configurable kind of pill (set up in Settings), with the count you
/// normally take of it.
class PillType {
  final int? id;
  final String name;
  final int defaultCount;

  const PillType({this.id, required this.name, required this.defaultCount});
}

/// A pill (+ count) actually logged on a 'pills' timeline entry.
class PillDose {
  final String name;
  final int count;

  const PillDose({required this.name, required this.count});

  Map<String, dynamic> toJson() => {'name': name, 'count': count};

  factory PillDose.fromJson(Map<String, dynamic> json) => PillDose(
        name: json['name'] as String,
        count: (json['count'] as num).toInt(),
      );
}
