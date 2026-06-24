import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/website_permission_rule.dart';

class WebsitePermissionStorageService {
  static const _key = 'zyro_website_permission_rules_v1';

  Future<List<WebsitePermissionRule>> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_key);
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List)
          .map(
            (item) =>
                WebsitePermissionRule.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<WebsitePermissionRule> rules) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(rules.map((rule) => rule.toMap()).toList()),
    );
  }

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
