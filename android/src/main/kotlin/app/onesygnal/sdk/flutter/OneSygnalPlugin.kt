package app.onesygnal.sdk.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import app.onesygnal.sdk.api.OneSygnal

// Identifies this plugin's calls to the native SDK as coming from the Flutter bridge rather than
// a native Android app — see OneSygnal.setSdkWrapper(). Keep in sync with
// apps/flutter-sdk/pubspec.yaml's `version` on every release; there's no runtime way to read the
// Dart package's own version from Kotlin.
private const val WRAPPER_LIBRARY = "onesygnal-flutter"
private const val WRAPPER_VERSION = "0.4.0"

/**
 * Thin bridge over the native [OneSygnal] Android SDK — every method here delegates straight
 * through, no business logic lives in this plugin. Mirrors the equivalent
 * apps/flutter-sdk/ios/onesygnal Swift plugin exactly (same channel names, same method/event
 * contract) so a single Dart-side implementation can serve both platforms.
 */
class OneSygnalPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var applicationContext: android.content.Context
    private var activityBinding: ActivityPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null

    // Registered once per event name in onListen, cancelled in onCancel — only listen to native
    // events while Dart is actually subscribed to the EventChannel stream.
    // contract:events:begin — asserted against fixtures/channel/event-channel.json
    private val eventNames = listOf(
        "ready",
        "survey:shown",
        "survey:completed",
        "survey:dismissed",
        "survey:question_answered",
    )
    // contract:events:end
    private val registrations = mutableListOf<OneSygnal.Registration>()

    // contract:methods:begin — asserted against fixtures/channel/method-channel.json
    @Suppress("UNCHECKED_CAST")
    private val handlers: Map<String, (MethodCall, Result) -> Unit> = mapOf(
        "initialize" to { _, result ->
            // Falls back to applicationContext if no Activity is attached yet — initialize()
            // still works, it just won't have an Activity seeded for CurrentActivityTracker
            // until one resumes (matches native's own "seed(context as? Activity)" fallback).
            OneSygnal.initialize(activityBinding?.activity ?: applicationContext) { success ->
                result.success(success)
            }
        },
        "setApiKey" to { call, result ->
            OneSygnal.setApiKey(call.arguments as String)
            result.success(null)
        },
        "setLocale" to { call, result ->
            OneSygnal.setLocale(call.arguments as String)
            result.success(null)
        },
        "track" to { call, result ->
            val args = call.arguments as Map<String, Any?>
            val eventName = args["eventName"] as String
            val properties = (args["properties"] as? Map<String, Any?>) ?: emptyMap()
            result.success(OneSygnal.track(eventName, properties))
        },
        "identify" to { call, result ->
            val args = call.arguments as Map<String, Any?>
            val userId = args["userId"] as String
            val attributes = args["attributes"] as? Map<String, Any?>
            OneSygnal.identify(userId, attributes) { success -> result.success(success) }
        },
        "logout" to { _, result -> OneSygnal.logout { result.success(null) } },
        "reset" to { _, result -> OneSygnal.reset { result.success(null) } },
        "setSurveysEnabled" to { call, result ->
            OneSygnal.setSurveysEnabled(call.arguments as Boolean)
            result.success(null)
        },
        "areSurveysEnabled" to { _, result -> result.success(OneSygnal.areSurveysEnabled()) },
        "isInitialized" to { _, result -> result.success(OneSygnal.isInitialized()) },
        "shutdown" to { _, result -> OneSygnal.shutdown { result.success(null) } },
    )
    // contract:methods:end

    internal val supportedMethods: Set<String> get() = handlers.keys

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        // Must run before any method channel call — Dart can't call initialize() until this
        // binding exists, so this always precedes native init/device-context capture.
        OneSygnal.setSdkWrapper(WRAPPER_LIBRARY, WRAPPER_VERSION)
        methodChannel = MethodChannel(binding.binaryMessenger, "onesygnal")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "onesygnal_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        // Without this, a hot restart re-registers the plugin (and re-listens) against the same
        // process-wide OneSygnal singleton without ever releasing the previous engine's listeners.
        registrations.forEach { it.cancel() }
        registrations.clear()
        eventSink = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val handler = handlers[call.method] ?: return result.notImplemented()
        handler(call, result)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        for (eventName in eventNames) {
            val listener: (Any?) -> Unit = { data ->
                val payload = mutableMapOf<String, Any?>("event_type" to eventName)
                if (data is Map<*, *>) {
                    @Suppress("UNCHECKED_CAST")
                    payload.putAll(data as Map<String, Any?>)
                } else if (data != null) {
                    payload["surveyId"] = data
                }
                eventSink?.success(payload)
            }
            registrations.add(OneSygnal.on(eventName, listener))
        }
    }

    override fun onCancel(arguments: Any?) {
        registrations.forEach { it.cancel() }
        registrations.clear()
        eventSink = null
    }
}
