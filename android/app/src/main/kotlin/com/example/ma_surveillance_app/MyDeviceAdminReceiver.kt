// android/app/src/main/java/com/example/ma_surveillance_app/MyDeviceAdminReceiver.kt

package com.example.ma_surveillance_app

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.EventChannel

class MyDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        // Cette variable statique va maintenir une référence à l'EventSink de Flutter
        // pour envoyer des données au code Dart.
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d("MyDeviceAdminReceiver", "Device Admin Enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d("MyDeviceAdminReceiver", "Device Admin Disabled")
    }

    // Cette méthode est appelée quand le mot de passe est entré incorrectement
    override fun onPasswordFailed(context: Context, intent: Intent) {
        super.onPasswordFailed(context, intent)
        Log.d("MyDeviceAdminReceiver", "Password Failed!")
        // Envoyez un événement à Flutter pour lui indiquer qu'une tentative a échoué
        eventSink?.success("password_failed")
    }

    // La méthode onFailedAttempts a été supprimée car elle n'est plus à override directement
    // dans les versions récentes de DeviceAdminReceiver et est redondante avec onPasswordFailed
}