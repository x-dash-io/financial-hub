import 'package:permission_handler/permission_handler.dart';

/// Requests READ_SMS permission with proper handling.
Future<bool> requestSmsPermission() async {
  final status = await Permission.sms.status;
  if (status.isGranted) return true;
  if (status.isDenied) {
    return (await Permission.sms.request()).isGranted;
  }
  return false;
}
