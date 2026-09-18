package com.example.kita_story

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class FinanceWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "FinanceWidgetPrefs"
        const val KEY_TOTAL_BALANCE = "total_balance"
        const val KEY_REMAINING_INFO = "remaining_info"
        const val KEY_REMAINING_AMOUNT = "remaining_amount"
        const val KEY_DATE_BADGE = "date_badge"
        const val KEY_IS_VISIBLE = "is_visible"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, FinanceWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                val provider = FinanceWidgetProvider()
                provider.onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val remainingAmount = prefs.getString(KEY_REMAINING_AMOUNT, null)
            ?: prefs.getString(KEY_REMAINING_INFO, "Rp 0")?.replace("Sisa bulan ini: ", "")
            ?: "Rp 0"

        val now = java.util.Calendar.getInstance()
        val defaultMonths = arrayOf(
            "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
            "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
        )
        val defaultBadge = "${defaultMonths[now.get(java.util.Calendar.MONTH)]} ${now.get(java.util.Calendar.YEAR)}"
        val dateBadge = prefs.getString(KEY_DATE_BADGE, defaultBadge) ?: defaultBadge
        val isVisible = prefs.getBoolean(KEY_IS_VISIBLE, true)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.finance_balance_widget)

            // Bind values (Privacy-first: Only Sisa Budget, no Saldo Keseluruhan)
            views.setTextViewText(R.id.tv_budget_title, "Sisa Budget")
            views.setTextViewText(
                R.id.tv_remaining_amount,
                if (isVisible) remainingAmount else "••••••••••"
            )
            views.setTextViewText(R.id.tv_budget_subtitle, "Bulan ini")
            views.setTextViewText(R.id.tv_date_badge, dateBadge)

            // 1. Root click -> Open Finance Dashboard
            val rootIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("daytale://finance?action=open")
                putExtra("action", "open")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val rootPendingIntent = PendingIntent.getActivity(
                context,
                101,
                rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, rootPendingIntent)

            // 2. "+ Pendapatan" click -> Open app & show Add Income form
            val incomeIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("daytale://finance?action=add_income")
                putExtra("action", "add_income")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val incomePendingIntent = PendingIntent.getActivity(
                context,
                102,
                incomeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add_income, incomePendingIntent)

            // 3. "+ Pengeluaran" click -> Open app & show Add Expense form
            val expenseIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("daytale://finance?action=add_expense")
                putExtra("action", "add_expense")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val expensePendingIntent = PendingIntent.getActivity(
                context,
                103,
                expenseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add_expense, expensePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
