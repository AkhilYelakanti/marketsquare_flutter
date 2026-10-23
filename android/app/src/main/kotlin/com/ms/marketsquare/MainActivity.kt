package com.ms.marketsquare

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the Datalogic hardware scanner to Flutter via an [EventChannel].
 *
 * Datalogic MEMOR / Skorpio devices can emit each decode as an Android broadcast
 * ("Intent Wedge" output). We register a dynamic [BroadcastReceiver] for the DL
 * decode-wedge action while Flutter is listening and forward the barcode string
 * to the Dart stream. No Datalogic SDK AAR is required (the native app used a
 * compile-only AAR that isn't in the repo); this works off the firmware's
 * Intent Wedge, which must be enabled in the device's Scanner Settings.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "com.ms.marketsquare/datalogic"
    private val deviceChannelName = "com.ms.marketsquare/device"

    // Datalogic Intent Wedge defaults.
    private val dlAction = "com.datalogic.decodewedge.decode_action"
    private val extraBarcode = "com.datalogic.decode.intentwedge.barcode_string"
    private val extraBarcodeAlt = "com.datalogic.decode.intentwedge.barcode_data"

    private var receiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Device identity bridge. device_info_plus exposes Build.ID (e.g.
        // "1.07.15.20191227"), NOT the ANDROID_ID the native app sent to the
        // backend. Return Settings.Secure.ANDROID_ID for device-setup parity.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidId" -> {
                        val id = Settings.Secure.getString(
                            contentResolver, Settings.Secure.ANDROID_ID
                        )
                        result.success(id)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val r = object : BroadcastReceiver() {
                        override fun onReceive(context: Context, intent: Intent) {
                            val code = intent.getStringExtra(extraBarcode)
                                ?: intent.getStringExtra(extraBarcodeAlt)
                            if (!code.isNullOrBlank()) events.success(code)
                        }
                    }
                    receiver = r
                    ContextCompat.registerReceiver(
                        this@MainActivity, r, IntentFilter(dlAction),
                        ContextCompat.RECEIVER_EXPORTED
                    )
                }

                override fun onCancel(arguments: Any?) {
                    receiver?.let { runCatching { unregisterReceiver(it) } }
                    receiver = null
                }
            })
    }

    override fun onDestroy() {
        receiver?.let { runCatching { unregisterReceiver(it) } }
        receiver = null
        super.onDestroy()
    }
}
