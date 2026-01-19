import '../../domain/entities/member_entity.dart';

/// Member model for API response
class MemberModel extends MemberEntity {
  const MemberModel({
    required super.memberId,
    required super.memberName,
    required super.templateId,
    required super.templateName,
  });

  /// Create from JSON (member payload) + optional template payload
  factory MemberModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? templateJson,
  }) {
    final template = json['template'];
    final templateMap = template is Map<String, dynamic>
        ? template
        : (templateJson is Map<String, dynamic> ? templateJson : null);

    final templateIdFromTemplate =
        templateMap == null ? 0 : _readInt(templateMap, const ['id', 'template_id', 'templateId']);
    final templateNameFromTemplate =
        templateMap == null ? '' : _readString(templateMap, const ['name', 'template_name', 'templateName']);

    return MemberModel(
      memberId: _readInt(json, const ['id', 'member_id', 'memberId']),
      memberName: _readString(json, const ['name', 'member_name', 'memberName']),
      templateId: _readInt(json, const ['template_id', 'templateId']) != 0
          ? _readInt(json, const ['template_id', 'templateId'])
          : templateIdFromTemplate,
      templateName: _readString(json, const ['template_name', 'templateName']).isNotEmpty
          ? _readString(json, const ['template_name', 'templateName'])
          : templateNameFromTemplate,
    );
  }

  /// Create from API response where member data might be wrapped
  /// e.g. { "data": {...} } or { "member": {...} } or direct member map.
  factory MemberModel.fromApi(dynamic data) {
    if (data is Map<String, dynamic>) {
      final memberMap = data['member'] ?? data['data'] ?? data['result'] ?? data;
      final templateMap = data['template'];
      if (memberMap is Map<String, dynamic>) {
        return MemberModel.fromJson(
          memberMap,
          templateJson: templateMap is Map<String, dynamic> ? templateMap : null,
        );
      }
      return const MemberModel(
        memberId: 0,
        memberName: '',
        templateId: 0,
        templateName: '',
      );
    }
    return const MemberModel(
      memberId: 0,
      memberName: '',
      templateId: 0,
      templateName: '',
    );
  }

  /// Convert to entity
  MemberEntity toEntity() {
    return MemberEntity(
      memberId: memberId,
      memberName: memberName,
      templateId: templateId,
      templateName: templateName,
    );
  }
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is int) return v;
    if (v is String) {
      final parsed = int.tryParse(v.trim());
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is String) return v.trim();
  }
  return '';
}

