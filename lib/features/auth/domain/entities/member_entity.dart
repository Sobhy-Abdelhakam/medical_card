import 'package:equatable/equatable.dart';

/// Member entity representing authenticated user data
class MemberEntity extends Equatable {
  final int memberId;
  final String memberName;
  final int templateId;
  final String templateName;

  const MemberEntity({
    required this.memberId,
    required this.memberName,
    required this.templateId,
    required this.templateName,
  });

  @override
  List<Object> get props => [memberId, memberName, templateId, templateName];
}

