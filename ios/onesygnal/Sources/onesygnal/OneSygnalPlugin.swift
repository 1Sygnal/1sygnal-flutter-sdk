import Flutter
import OneSygnalSDK
import UIKit

// Identifies this plugin's calls to the native SDK as coming from the Flutter bridge rather than
// a native iOS app — see OneSygnal.setSdkWrapper(). Keep in sync with
// apps/flutter-sdk/pubspec.yaml's `version` on every release; there's no runtime way to read the
// Dart package's own version from Swift.
private let wrapperLibrary = "onesygnal-flutter"
private let wrapperVersion = "0.4.0"

/// Thin bridge over the native `OneSygnal` iOS SDK — every method here delegates straight
/// through, no business logic lives in this plugin. Mirrors the equivalent
/// apps/flutter-sdk/android Kotlin plugin exactly (same channel names, same method/event
/// contract) so a single Dart-side implementation can serve both platforms.
///
/// No `import OneSygnalSDK` here deliberately: apps/flutter-sdk/ios/onesygnal.podspec compiles
/// this file together with apps/ios-sdk's own source directly into one CocoaPods pod target
/// (rather than depending on a separately-published OneSygnalSDK pod, which doesn't exist yet —
/// see the podspec's comment) — so `OneSygnal` is already in-module here, same as any other type
/// in this compilation unit.
public class OneSygnalPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    // Registered once per event name in onListen, cancelled in onCancel — only listen to native
    // events while Dart is actually subscribed to the EventChannel stream.
    // contract:events:begin — asserted against fixtures/channel/event-channel.json
    private static let eventNames = [
        "ready",
        "survey:shown",
        "survey:completed",
        "survey:dismissed",
        "survey:question_answered",
    ]
    // contract:events:end

    private var eventSink: FlutterEventSink?
    private var registrations: [OneSygnal.Registration] = []

    // contract:methods:begin — asserted against fixtures/channel/method-channel.json
    // `@escaping` on the `FlutterResult` parameter: "identify"/"initialize"'s handlers below
    // pass `result` into a completion closure handed to the native SDK, which invokes it later
    // (after native work finishes) rather than synchronously within the handler body — a
    // non-escaping `result` can't be captured by that outer escaping closure.
    private lazy var handlers: [String: (FlutterMethodCall, @escaping FlutterResult) -> Void] = [
        "initialize": { _, result in
            OneSygnal.shared.initialize { success in result(success) }
        },
        "setApiKey": { call, result in
            guard let apiKey = call.arguments as? String else { result(nil); return }
            OneSygnal.shared.setApiKey(apiKey)
            result(nil)
        },
        "setLocale": { call, result in
            guard let locale = call.arguments as? String else { result(nil); return }
            OneSygnal.shared.setLocale(locale)
            result(nil)
        },
        "track": { call, result in
            guard let args = call.arguments as? [String: Any], let eventName = args["eventName"] as? String else {
                result(false)
                return
            }
            let properties = args["properties"] as? [String: Any?] ?? [:]
            result(OneSygnal.shared.track(eventName, properties: properties))
        },
        "identify": { call, result in
            guard let args = call.arguments as? [String: Any], let userId = args["userId"] as? String else {
                result(false)
                return
            }
            let attributes = args["attributes"] as? [String: Any]
            OneSygnal.shared.identify(userId, attributes: attributes) { success in result(success) }
        },
        "logout": { _, result in OneSygnal.shared.logout { result(nil) } },
        "reset": { _, result in OneSygnal.shared.reset { result(nil) } },
        "setSurveysEnabled": { call, result in
            guard let enabled = call.arguments as? Bool else { result(nil); return }
            OneSygnal.shared.setSurveysEnabled(enabled)
            result(nil)
        },
        "areSurveysEnabled": { _, result in result(OneSygnal.shared.areSurveysEnabled()) },
        "isInitialized": { _, result in result(OneSygnal.shared.isInitialized()) },
        "shutdown": { _, result in OneSygnal.shared.shutdown { result(nil) } },
    ]
    // contract:methods:end

    var supportedMethods: Set<String> { Set(handlers.keys) }

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Must run before any method channel call — Dart can't call initialize() until this
        // registrar exists, so this always precedes native init/device-context capture.
        OneSygnal.shared.setSdkWrapper(library: wrapperLibrary, version: wrapperVersion)
        let methodChannel = FlutterMethodChannel(name: "onesygnal", binaryMessenger: registrar.messenger())
        let instance = OneSygnalPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: "onesygnal_events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)

        // `detachFromEngineForRegistrar:` below is only called if the plugin instance was
        // published — its own header doc says so. Without this, hot restart accumulates
        // registrations on the process-wide OneSygnal singleton forever.
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        registrations.forEach { $0.cancel() }
        registrations.removeAll()
        eventSink = nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let handler = handlers[call.method] else {
            result(FlutterMethodNotImplemented)
            return
        }
        handler(call, result)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        for eventName in Self.eventNames {
            let registration = OneSygnal.shared.on(eventName) { [weak self] data in
                var payload: [String: Any] = ["event_type": eventName]
                if let dict = data as? [String: Any] {
                    for (key, value) in dict { payload[key] = value }
                } else if let data {
                    payload["surveyId"] = data
                }
                self?.eventSink?(payload)
            }
            registrations.append(registration)
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        registrations.forEach { $0.cancel() }
        registrations.removeAll()
        eventSink = nil
        return nil
    }
}
