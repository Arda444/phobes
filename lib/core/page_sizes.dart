/// Sayfa boyutu sabitleri — Not modülünde kullanılır.
/// mm → logical pixel dönüşümü 96 DPI standardına göredir (1mm ≈ 3.7795px).
class NotePageSize {
  final String key;
  final String label;
  final double widthMm;
  final double heightMm;

  const NotePageSize({
    required this.key,
    required this.label,
    required this.widthMm,
    required this.heightMm,
  });

  static const double _mmToPx = 3.7795;

  double get widthPx => widthMm * _mmToPx;
  double get heightPx => heightMm * _mmToPx;

  static const NotePageSize a4 = NotePageSize(
    key: 'a4', label: 'A4', widthMm: 210, heightMm: 297,
  );
  static const NotePageSize a5 = NotePageSize(
    key: 'a5', label: 'A5', widthMm: 148, heightMm: 210,
  );
  static const NotePageSize a6 = NotePageSize(
    key: 'a6', label: 'A6', widthMm: 105, heightMm: 148,
  );
  static const NotePageSize letter = NotePageSize(
    key: 'letter', label: 'Letter', widthMm: 216, heightMm: 279,
  );
  static const NotePageSize legal = NotePageSize(
    key: 'legal', label: 'Legal', widthMm: 216, heightMm: 356,
  );
  static const NotePageSize free = NotePageSize(
    key: 'free', label: 'Serbest', widthMm: 0, heightMm: 0,
  );

  static const List<NotePageSize> all = [a4, a5, a6, letter, legal, free];

  static NotePageSize byKey(String k) =>
      all.firstWhere((p) => p.key == k, orElse: () => a4);
}
