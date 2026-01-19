import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/member_entity.dart';

/// Local data source for authentication
abstract class AuthLocalDataSource {
  Future<void> saveMember(MemberEntity member);
  Future<MemberEntity?> getMember();
  Future<bool> isLoggedIn();
  Future<void> logout();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyMemberId = 'member_id';
  static const String _keyMemberName = 'member_name';
  static const String _keyTemplateId = 'template_id';
  static const String _keyTemplateName = 'template_name';

  @override
  Future<void> saveMember(MemberEntity member) async {
    await sharedPreferences.setBool(_keyIsLoggedIn, true);
    await sharedPreferences.setInt(_keyMemberId, member.memberId);
    await sharedPreferences.setString(_keyMemberName, member.memberName);
    await sharedPreferences.setInt(_keyTemplateId, member.templateId);
    await sharedPreferences.setString(_keyTemplateName, member.templateName);

    // Debugging requirements
    // ignore: avoid_print
    print(
        '[SESSION] saved is_logged_in=true member_id=${member.memberId} member_name="${member.memberName}" template_id=${member.templateId} template_name="${member.templateName}"');
  }

  @override
  Future<MemberEntity?> getMember() async {
    final isLoggedIn = sharedPreferences.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final memberId = sharedPreferences.getInt(_keyMemberId);
    final memberName = sharedPreferences.getString(_keyMemberName);
    final templateId = sharedPreferences.getInt(_keyTemplateId);
    final templateName = sharedPreferences.getString(_keyTemplateName);

    if (memberId == null || memberName == null || templateId == null || templateName == null) {
      // Debugging requirements
      // ignore: avoid_print
      print(
          '[SESSION] missing stored values: memberId=$memberId memberName=$memberName templateId=$templateId templateName=$templateName');
      return null;
    }

    // Debugging requirements
    // ignore: avoid_print
    print(
        '[SESSION] loaded member_id=$memberId member_name="$memberName" template_id=$templateId template_name="$templateName"');

    return MemberEntity(
      memberId: memberId,
      memberName: memberName,
      templateId: templateId,
      templateName: templateName,
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    return sharedPreferences.getBool(_keyIsLoggedIn) ?? false;
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(_keyIsLoggedIn);
    await sharedPreferences.remove(_keyMemberId);
    await sharedPreferences.remove(_keyMemberName);
    await sharedPreferences.remove(_keyTemplateId);
    await sharedPreferences.remove(_keyTemplateName);
  }
}

