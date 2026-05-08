

class NewsArticle {
  final String title;
  final String link;
  final DateTime? publishedAt;
  final String description;
  final String? imageUrl;
  final String source;

  const NewsArticle({
    required this.title,
    required this.link,
    required this.publishedAt,
    required this.description,
    required this.imageUrl,
    this.source = 'Oumma',
  });
}
