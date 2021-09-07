package alpha.soft.liveness.liveness

import ai.advance.liveness.lib.GuardianLivenessDetectionSDK
import ai.advance.liveness.lib.LivenessResult
import alpha.soft.liveness.liveness.activity.LivenessActivity
import android.app.Activity
import android.app.Application
import android.content.Intent
import android.graphics.Bitmap
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.ByteArrayOutputStream

/** LivenessPlugin */
class LivenessPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var application: Application

    private lateinit var activity: Activity

    private var livenessResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        application = flutterPluginBinding.applicationContext as Application
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this);
    }

    ///
    /// Not implemented
    ///
    override fun onDetachedFromActivity() {}

    ///
    /// Not implemented
    ///
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    ///
    /// Not implemented
    ///
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, _, _ ->
            if (requestCode == REQUEST_CODE_LIVENESS) {
                handleLivenessActivityResult()
            }
            return@addActivityResultListener true
        }
    }

    ///
    /// Not implemented
    ///
    override fun onDetachedFromActivityForConfigChanges() {}

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {

        private const val CHANNEL_NAME = "guardian_liveness"

        const val REQUEST_CODE_LIVENESS = 1000
//    const val REQUEST_CODE_RESULT_PAGE = 1001

        private const val IS_DEVICE_SUPPORT_LIVENESS = "isDeviceSupportLiveness"
        private const val INIT_LIVENESS = "initLiveness"
        private const val DETECT_LIVENESS = "detectLiveness"
//    private const val EVALUATE_LIVENESS = "evaluateLiveness"

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            channel.setMethodCallHandler(LivenessPlugin())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        GuardianLivenessDetectionSDK.isDeviceSupportLiveness()
        when (call.method) {
            IS_DEVICE_SUPPORT_LIVENESS -> {
                result.success(GuardianLivenessDetectionSDK.isDeviceSupportLiveness())
            }
            INIT_LIVENESS -> {
                val accessKey = call.argument<String>("accessKey")
                val secretKey = call.argument<String>("secretKey")
                initLiveness(accessKey, secretKey, result)
            }
            DETECT_LIVENESS -> {
                livenessResult = result
                detectLiveness()
            }
//      EVALUATE_LIVENESS -> {
//
//      }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun initLiveness(accessKey: String?, secretKey: String?, result: Result) {
        GuardianLivenessDetectionSDK.initOffLine(application)
        GuardianLivenessDetectionSDK.letSDKHandleCameraPermission()
        result.success(null)
    }

    private fun detectLiveness() {
        val intent = Intent(activity, LivenessActivity::class.java)
        activity.startActivityForResult(intent, REQUEST_CODE_LIVENESS)
    }

    private fun handleLivenessActivityResult() {
        if (LivenessResult.isSuccess()) {
            val base64Result = LivenessResult.getLivenessBase64Str()
            val bitmap = LivenessResult.getLivenessBitmap()
            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            val bitmapBytes = out.toByteArray()

            this.livenessResult?.success(
                mapOf(
                    "base64Str" to base64Result,
                    "bitmap" to bitmapBytes
                )
            )
            out.close()
//      val intent = Intent(activity, ResultActivity::class.java)
//      activity.startActivityForResult(intent, REQUEST_CODE_RESULT_PAGE)
        } else {
            val errorCode = LivenessResult.getErrorCode()
            val errorMessage = LivenessResult.getErrorMsg()

            this.livenessResult?.error(errorCode, errorMessage, null)
        }
    }

    ///
    /// SUCCESS	pay OK
    /// ERROR	free Server error
    /// NO_AUTHORIZATION	free API authorization failed
    /// API_ACCESS_DENIED	free API not found or you have no access to API
    /// EMPTY_PARAMETER_ERROR	free Parameter should not be empty
    /// INSUFFICIENT_BALANCE	free Insufficient balance in your account please recharge your account
    /// SERVICE_BUSY	free The service is busy, please query later
    /// QUERY_LIMIT_REACHED	free Free query limit is reached, please query later
    ///
//  private fun evaluateLiveness(result: MethodChannel.Result) {
//
//  }
}
