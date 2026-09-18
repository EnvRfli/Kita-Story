package com.example.kita_story

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kita_story/finance_widget"
    private var pendingWidgetAction: String? = null
    private var methodChannel: MethodChannel? = null

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

        // If there was a pending action before engine initialized, send it now
        pendingWidgetAction?.let { action ->
            methodChannel?.invokeMethod("onWidgetAction", action)
        }
    }
}
