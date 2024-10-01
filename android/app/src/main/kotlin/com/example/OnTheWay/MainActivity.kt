package com.example.OnTheWay

import android.os.Bundle
import android.webkit.WebSettings
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Flutter 엔진 구성 (기본 구성)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // WebView 설정
        val webView = WebView(this)
        val webSettings = webView.settings
        webSettings.javaScriptEnabled = true // JavaScript 활성화
        webSettings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        webSettings.setGeolocationEnabled(true)

        // WebChromeClient 설정
        webView.webChromeClient = object : WebChromeClient() {
            override fun onGeolocationPermissionsShowPrompt(origin: String, callback: GeolocationPermissions.Callback) {
                // 위치 권한 자동 승인
                callback.invoke(origin, true, false)
            }
        }

        // 레이아웃에 WebView 추가
        setContentView(webView)
        webView.loadUrl("https://ontheway-b2bdf.web.app/")
    }
}

