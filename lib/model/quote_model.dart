/// Quote Model for Daily Stoic & Discipline Quotes
/// Conforms to `docs/api_spec.md` and `docs/roadmap.md`.
class QuoteModel {
  final int id;
  final String quote;
  final String author;

  const QuoteModel({
    required this.id,
    required this.quote,
    required this.author,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      quote: json['quote']?.toString() ?? '',
      author: json['author']?.toString() ?? 'SYSTEM CODEX',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quote': quote,
        'author': author,
      };
}
