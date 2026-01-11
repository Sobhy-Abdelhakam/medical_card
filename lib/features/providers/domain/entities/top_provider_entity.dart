import 'package:equatable/equatable.dart';

/// Entity representing a top/featured provider for home screen cards
class TopProviderEntity extends Equatable {
  final int id;
  final String nameEnglish;
  final String nameArabic;
  final String typeEnglish;
  final String typeArabic;
  final String logoUrl;

  const TopProviderEntity({
    required this.id,
    required this.nameEnglish,
    required this.nameArabic,
    required this.typeEnglish,
    required this.typeArabic,
    required this.logoUrl,
  });

  @override
  List<Object?> get props => [
        id,
        nameEnglish,
        nameArabic,
        typeEnglish,
        typeArabic,
        logoUrl,
      ];

  @override
  String toString() =>
      'TopProviderEntity(id: $id, nameArabic: $nameArabic, typeArabic: $typeArabic)';
}
