package com.example.kita_story

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kita_story/finance_widget"
    private val LOCATION_CHANNEL = "com.example.kita_story/location"
    private val LOCATION_PERMISSION_REQ_CODE = 4021

    private var pendingWidgetAction: String? = null
    private var methodChannel: MethodChannel? = null
    private var pendingLocationResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val extraAction = intent?.getStringExtra("action")
        val data = intent?.data
        val action = extraAction ?: if (data != null && data.scheme == "daytale" && data.host == "finance") {
            data.getQueryParameter("action") ?: "open"
        } else {
            null
        }

        if (action != null) {
            pendingWidgetAction = action
            methodChannel?.invokeMethod("onWidgetAction", action)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateFinanceWidget" -> {
                        val totalBalance = call.argument<String>("total_balance") ?: "Rp 0"
                        val remainingInfo = call.argument<String>("remaining_info") ?: "Sisa bulan ini: Rp 0"
                        val remainingAmount = call.argument<String>("remaining_amount") ?: "Rp 0"
                        val dateBadge = call.argument<String>("date_badge") ?: ""
                        val isVisible = call.argument<Boolean>("is_visible") ?: true

                        val prefs = context.getSharedPreferences(
                            FinanceWidgetProvider.PREFS_NAME,
                            Context.MODE_PRIVATE
                        )
                        prefs.edit()
                            .putString(FinanceWidgetProvider.KEY_TOTAL_BALANCE, totalBalance)
                            .putString(FinanceWidgetProvider.KEY_REMAINING_INFO, remainingInfo)
                            .putString(FinanceWidgetProvider.KEY_REMAINING_AMOUNT, remainingAmount)
                            .putString(FinanceWidgetProvider.KEY_DATE_BADGE, dateBadge)
                            .putBoolean(FinanceWidgetProvider.KEY_IS_VISIBLE, isVisible)
                            .apply()

                        FinanceWidgetProvider.updateAllWidgets(context)
                        result.success(true)
                    }
                    "getInitialWidgetAction" -> {
                        val action = pendingWidgetAction
                        pendingWidgetAction = null
                        result.success(action)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Location & GPS MethodChannel for Toilet (Poop Tracker)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkStatus" -> {
                    result.success(
                        mapOf(
                            "gpsEnabled" to isLocationServiceEnabled(),
                            "permissionGranted" to hasLocationPermission()
                        )
                    )
                }
                "openLocationSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openMaps" -> {
                    val lat = call.argument<Double>("latitude") ?: 0.0
                    val lng = call.argument<Double>("longitude") ?: 0.0
                    val label = call.argument<String>("label") ?: "Lokasi Toilet"
                    try {
                        val encodedLabel = Uri.encode(label)
                        val geoUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng($encodedLabel)")
                        val mapIntent = Intent(Intent.ACTION_VIEW, geoUri)
                        startActivity(mapIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val webUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng")
                            startActivity(Intent(Intent.ACTION_VIEW, webUri))
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }
                "getCurrentLocation" -> {
                    if (!hasLocationPermission()) {
                        pendingLocationResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            LOCATION_PERMISSION_REQ_CODE
                        )
                    } else {
                        fetchDeviceLocation(result)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // If there was a pending action before engine initialized, send it now
        pendingWidgetAction?.let { action ->
            methodChannel?.invokeMethod("onWidgetAction", action)
        }
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
        return fine == PackageManager.PERMISSION_GRANTED || coarse == PackageManager.PERMISSION_GRANTED
    }

    private fun isLocationServiceEnabled(): Boolean {
        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
        return try {
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        } catch (e: Exception) {
            false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_PERMISSION_REQ_CODE) {
            val pending = pendingLocationResult
            pendingLocationResult = null
            if (pending != null) {
                if (hasLocationPermission()) {
                    fetchDeviceLocation(pending)
                } else {
                    pending.success(
                        mapOf(
                            "success" to false,
                            "errorCode" to "PERMISSION_DENIED",
                            "message" to "Izin lokasi GPS ditolak. Berikan izin lokasi untuk mencatat posisi Toilet."
                        )
                    )
                }
            }
        }
    }

    @Suppress("MissingPermission")
    private fun fetchDeviceLocation(result: MethodChannel.Result) {
        if (!isLocationServiceEnabled()) {
            result.success(
                mapOf(
                    "success" to false,
                    "errorCode" to "GPS_DISABLED",
                    "message" to "GPS belum aktif. Nyalakan layanan lokasi/GPS di perangkat Anda."
                )
            )
            return
        }

        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (lm == null) {
            result.success(
                mapOf(
                    "success" to false,
                    "errorCode" to "UNAVAILABLE",
                    "message" to "Layanan lokasi tidak tersedia di perangkat ini."
                )
            )
            return
        }

        try {
            // Check fresh lastKnownLocation first across providers (within 5 minutes)
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )
            var bestLocation: Location? = null
            for (p in providers) {
                try {
                    if (lm.isProviderEnabled(p)) {
                        val loc = lm.getLastKnownLocation(p)
                        if (loc != null) {
                            if (bestLocation == null || loc.time > bestLocation!!.time) {
                                bestLocation = loc
                            }
                        }
                    }
                } catch (_: Exception) {}
            }

            val nowMs = System.currentTimeMillis()
            if (bestLocation != null && (nowMs - bestLocation!!.time) < 5 * 60 * 1000L) {
                returnLocationSuccess(bestLocation!!, result)
                return
            }

            // Otherwise request active current location with timeout fallback to bestLocation
            val activeProvider = when {
                lm.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
                lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
                else -> null
            }

            if (activeProvider == null) {
                if (bestLocation != null) {
                    returnLocationSuccess(bestLocation!!, result)
                } else {
                    result.success(
                        mapOf(
                            "success" to false,
                            "errorCode" to "GPS_DISABLED",
                            "message" to "Provider lokasi GPS tidak aktif."
                        )
                    )
                }
                return
            }

            var hasReplied = false
            val handler = Handler(Looper.getMainLooper())
            var listenerRef: LocationListener? = null

            val timeoutRunnable = Runnable {
                if (!hasReplied) {
                    hasReplied = true
                    listenerRef?.let {
                        try { lm.removeUpdates(it) } catch (_: Exception) {}
                    }
                    if (bestLocation != null) {
                        returnLocationSuccess(bestLocation!!, result)
                    } else {
                        result.success(
                            mapOf(
                                "success" to false,
                                "errorCode" to "TIMEOUT",
                                "message" to "Waktu pencarian sinyal GPS habis. Pastikan Anda berada di area dengan sinyal GPS."
                            )
                        )
                    }
                }
            }

            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (!hasReplied) {
                        hasReplied = true
                        handler.removeCallbacks(timeoutRunnable)
                        try { lm.removeUpdates(this) } catch (_: Exception) {}
                        returnLocationSuccess(location, result)
                    }
                }
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }
            listenerRef = listener

            handler.postDelayed(timeoutRunnable, 6500L)
            lm.requestLocationUpdates(activeProvider, 0L, 0f, listener, Looper.getMainLooper())
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "success" to false,
                    "errorCode" to "ERROR",
                    "message" to "Gagal membaca lokasi GPS: ${e.localizedMessage}"
                )
            )
        }
    }

    private fun returnLocationSuccess(location: Location, result: MethodChannel.Result) {
        var placeName = ""
        var fullAddress = ""
        try {
            val geocoder = Geocoder(this, Locale("id", "ID"))
            @Suppress("DEPRECATION")
            val addresses = geocoder.getFromLocation(location.latitude, location.longitude, 1)
            if (!addresses.isNullOrEmpty()) {
                val addr = addresses[0]
                val parts = mutableListOf<String>()
                if (!addr.thoroughfare.isNullOrBlank()) parts.add(addr.thoroughfare)
                if (!addr.subLocality.isNullOrBlank()) parts.add(addr.subLocality)
                if (!addr.locality.isNullOrBlank()) parts.add(addr.locality)
                if (!addr.subAdminArea.isNullOrBlank() && !parts.contains(addr.subAdminArea)) {
                    parts.add(addr.subAdminArea)
                }
                placeName = addr.featureName?.takeIf { it.length > 3 && !it.all { ch -> ch.isDigit() } }
                    ?: addr.subLocality
                    ?: addr.locality
                    ?: "Lokasi Saat Ini"
                fullAddress = if (parts.isNotEmpty()) {
                    parts.joinToString(", ")
                } else {
                    addr.getAddressLine(0) ?: ""
                }
            }
        } catch (_: Exception) {}

        result.success(
            mapOf(
                "success" to true,
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy.toDouble(),
                "placeName" to placeName,
                "address" to fullAddress
            )
        )
    }
}
