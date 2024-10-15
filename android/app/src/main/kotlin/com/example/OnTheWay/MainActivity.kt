package com.ljj.OnTheWay

import android.os.Bundle
import android.webkit.WebSettings
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // GeneratedPluginRegistrant.registerWith(flutterEngine) // 더 이상 필요하지 않음
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // WebView 설정을 위한 코드
        val webView = WebView(this)
        val webSettings = webView.settings
//        webSettings.javaScriptEnabled = true  // JavaScript 활성화
        webSettings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW  // 혼합 콘텐츠 허용

        // 혼합 콘텐츠 설정 후, Flutter의 WebView와의 호환성 문제를 줄이기 위해 해당 설정 추가
//        setContentView(webView)
    }
}
