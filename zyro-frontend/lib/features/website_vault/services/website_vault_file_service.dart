import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WebsiteVaultFileService {
  const WebsiteVaultFileService();

  Future<Directory> domainDirectory(String domain) async {
    final root = await _vaultRoot();
    final safeDomain = domain.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final directory = Directory(p.join(root.path, safeDomain));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> copyFileToVault({
    required String sourcePath,
    required String domain,
    String? preferredName,
  }) async {
    final source = File(sourcePath);
    final directory = await domainDirectory(domain);
    final name = _safeName(preferredName ?? p.basename(sourcePath));
    final target = File(p.join(directory.path, name));
    return source.copy(target.path);
  }

  Future<int?> sizeForPath(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;
    final file = File(filePath);
    if (!await file.exists()) return null;
    return file.length();
  }

  Future<void> deleteLocalFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _vaultRoot() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download/Zyro/Vault');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'Zyro', 'Vault'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safeName(String value) {
    final extension = p.extension(value);
    final base = p.basenameWithoutExtension(value);
    final safeBase = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return '${safeBase.isEmpty ? 'vault_file' : safeBase}$extension';
  }
}
