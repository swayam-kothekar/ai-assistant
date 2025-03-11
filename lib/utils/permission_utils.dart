import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermission(Permission permission) async {
  final status = await permission.status;
  if (!status.isGranted) {
    final result = await permission.request();
    return result.isGranted;
  }
  return true;
}