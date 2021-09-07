import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _CHANNEL_NAME = "guardian_liveness";
const MethodChannel _channel = const MethodChannel(_CHANNEL_NAME,);

const _IS_DEVICE_SUPPORT_LIVENESS = "isDeviceSupportLiveness";
const _INIT_LIVENESS = "initLiveness";
const _DETECT_LIVENESS = "detectLiveness";

@immutable
abstract class Liveness {

  static Future<T?> _guardedCallForUnsupportedPlatform<T>(Future<T?> functionCall,) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw LivenessException._(
        LivenessException.ERROR_DEVICE_NOT_SUPPORT,
        "Your device doesn't support Liveness Detection.",
      );
    }
    return functionCall;
  }

  static Future<bool?> isDeviceSupportLiveness() {
    return _guardedCallForUnsupportedPlatform<bool>(
      _channel.invokeMethod<bool>(_IS_DEVICE_SUPPORT_LIVENESS,)
    );
  }

  static Future<void> initLiveness() async {
    final isSupported = await isDeviceSupportLiveness() ?? false;
    if (!isSupported) {
      throw LivenessException._(
        LivenessException.ERROR_DEVICE_NOT_SUPPORT,
        "Your device doesn't support Liveness Detection.",
      );
    }
    return _channel.invokeMethod<void>(_INIT_LIVENESS,);
  }

  static Future<LivenessResult> detectLiveness() async {
    try {
      final result = await _guardedCallForUnsupportedPlatform<dynamic>(
        _channel.invokeMethod<dynamic>(_DETECT_LIVENESS,),
      );
      final data = Map<String, dynamic>.from(result,);
      return LivenessResult._(
        data["base64Str"], data["bitmap"],
      );
    } on PlatformException catch (ex) {
      throw LivenessException._(ex.code, ex.message??'',);
    } catch (e) {
      throw e;
    }
  }
}

@immutable
class LivenessResult {

  final String base64String;
  final Uint8List bitmap;

  LivenessResult._(this.base64String, this.bitmap,);
}

@immutable
class LivenessException implements Exception {

  static const ERROR_FACE_MISSING = "FACE_MISSING";
  static const ERROR_ACTION_TIMEOUT = "ACTION_TIMEOUT";
  static const ERROR_MULTIPLE_FACE = "MULTIPLE_FACE";
  static const ERROR_MUCH_MOTION = "MUCH_MOTION";
  static const ERROR_DEVICE_NOT_SUPPORT = "DEVICE_NOT_SUPPORT";
  static const ERROR_USER_GIVE_UP = "USER_GIVE_UP";
  static const ERROR_UNDEFINED = "UNDEFINED";

  final String code;
  final String message;

  LivenessException._(this.code, this.message,);

  @override
  String toString() => "($runtimeType):\ncode: $code\nmessage: $message";
}