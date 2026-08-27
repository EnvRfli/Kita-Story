class BookModel {
  final String id;
  final String title;
  final String? author;
  final int? personalRating;
  final String? personalReview;
  final String? synopsis;
  final String? coverUrl;
  final int totalPages;
  final int currentPage;
  final String? addedBy;
  final String? lastUpdatedBy;

  BookModel({
    required this.id,
    required this.title,
    this.author,
    this.personalRating,
    this.personalReview,
    this.synopsis,
    this.coverUrl,
    required this.totalPages,
    this.currentPage = 0,
    this.addedBy,
    this.lastUpdatedBy,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      personalRating: json['personal_rating'] as int?,
      personalReview: json['personal_review'] as String?,
      synopsis: json['synopsis'] as String?,
      coverUrl: json['cover_url'] as String?,
      totalPages: json['total_pages'] as int,
      currentPage: json['current_page'] as int? ?? 0,
      addedBy: json['added_by'] as String?,
      lastUpdatedBy: json['last_updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (author != null) 'author': author,
      if (personalRating != null) 'personal_rating': personalRating,
      if (personalReview != null) 'personal_review': personalReview,
      if (synopsis != null) 'synopsis': synopsis,
      if (coverUrl != null) 'cover_url': coverUrl,
      'total_pages': totalPages,
      'current_page': currentPage,
      if (addedBy != null) 'added_by': addedBy,
      if (lastUpdatedBy != null) 'last_updated_by': lastUpdatedBy,
    };
  }
}
