package com.hoda.hoda

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity with a tiny «hoda/links» channel: opens external URLs (the
 * Eitaa channel page) without pulling in the url_launcher dependency.
 *
 * The https URL goes through startActivity; if nothing can handle it (no
 * browser, no Eitaa) we report failure back so Dart can fall back to copying
 * the link to the clipboard.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "hoda/links"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUrl" -> {
                        val url = call.arguments as? String
                        if (url.isNullOrBlank()) {
                            result.error("bad_args", "url missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // No activity found / disabled — let Dart fallback.
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
