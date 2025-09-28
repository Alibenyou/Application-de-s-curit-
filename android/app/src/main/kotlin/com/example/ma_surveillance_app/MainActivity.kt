// android/app/src/main/java/com/example/ma_surveillance_app/MainActivity.kt

package com.example.ma_surveillance_app

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Noms des canaux de communication
    private val METHOD_CHANNEL = "com.example.ma_surveillance_app/device_admin_method"
    private val EVENT_CHANNEL = "com.example.ma_surveillance_app/unlock_attempts_event"

    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var compName: ComponentName

    private val REQUEST_CODE_ENABLE_ADMIN = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        compName = ComponentName(this, MyDeviceAdminReceiver::class.java)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Configuration du MethodChannel pour activer l'administrateur d'appareil
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "activateDeviceAdmin" -> {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
                    intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Cette application a besoin des droits d'administrateur d'appareil pour détecter les tentatives de déverrouillage échouées et prendre des photos de sécurité.")
                    startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
                    result.success("Request sent to activate Device Admin.")
                }
                "isDeviceAdminActive" -> {
                    result.success(devicePolicyManager.isAdminActive(compName))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Configuration de l'EventChannel pour envoyer les événements de déverrouillage à Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d("MainActivity", "EventChannel onListen")
                    // Stocke la référence à l'EventSink dans le DeviceAdminReceiver pour qu'il puisse envoyer des événements
                    MyDeviceAdminReceiver.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d("MainActivity", "EventChannel onCancel")
                    MyDeviceAdminReceiver.eventSink = null
                }
            }
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d("MainActivity", "Device Admin Activated Successfully!")
                // Ici, vous pourriez envoyer un autre événement à Flutter si besoin
            } else {
                Log.d("MainActivity", "Failed to activate Device Admin.")
            }
        }
    }
}