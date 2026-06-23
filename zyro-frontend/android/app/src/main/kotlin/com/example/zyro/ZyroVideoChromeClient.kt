package com.example.zyro

import android.graphics.Bitmap
import android.net.Uri
import android.os.Message
import android.view.View
import android.webkit.ConsoleMessage
import android.webkit.GeolocationPermissions
import android.webkit.JsPromptResult
import android.webkit.JsResult
import android.webkit.PermissionRequest
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.util.Log

class ZyroVideoChromeClient(
    private val delegate: WebChromeClient,
    private val pipManager: FloatingVideoPipManager
) : WebChromeClient() {

    override fun onShowCustomView(view: View?, callback: CustomViewCallback?) {
        Log.d("FloatingVideo", "onShowCustomView received actual video view")
        pipManager.customVideoView = view
        Log.d("FloatingVideo", "Fullscreen video view stored")
        Log.d("FloatingVideo", "Floating Videos ready for PiP")
        delegate.onShowCustomView(view, callback)
    }

    override fun onShowCustomView(view: View?, requestedOrientation: Int, callback: CustomViewCallback?) {
        Log.d("FloatingVideo", "onShowCustomView received actual video view")
        pipManager.customVideoView = view
        Log.d("FloatingVideo", "Fullscreen video view stored")
        Log.d("FloatingVideo", "Floating Videos ready for PiP")
        delegate.onShowCustomView(view, requestedOrientation, callback)
    }

    override fun onHideCustomView() {
        Log.d("FloatingVideo", "onHideCustomView called")
        pipManager.customVideoView = null
        delegate.onHideCustomView()
        Log.d("FloatingVideo", "Browser restored")
    }

    override fun onCreateWindow(view: WebView?, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message?): Boolean {
        return delegate.onCreateWindow(view, isDialog, isUserGesture, resultMsg)
    }

    override fun onCloseWindow(window: WebView?) {
        delegate.onCloseWindow(window)
    }

    override fun onProgressChanged(view: WebView?, newProgress: Int) {
        delegate.onProgressChanged(view, newProgress)
    }

    override fun onReceivedTitle(view: WebView?, title: String?) {
        delegate.onReceivedTitle(view, title)
    }

    override fun onReceivedIcon(view: WebView?, icon: Bitmap?) {
        delegate.onReceivedIcon(view, icon)
    }

    override fun onReceivedTouchIconUrl(view: WebView?, url: String?, precomposed: Boolean) {
        delegate.onReceivedTouchIconUrl(view, url, precomposed)
    }

    override fun onJsAlert(view: WebView?, url: String?, message: String?, result: JsResult?): Boolean {
        return delegate.onJsAlert(view, url, message, result)
    }

    override fun onJsConfirm(view: WebView?, url: String?, message: String?, result: JsResult?): Boolean {
        return delegate.onJsConfirm(view, url, message, result)
    }

    override fun onJsPrompt(view: WebView?, url: String?, message: String?, defaultValue: String?, result: JsPromptResult?): Boolean {
        return delegate.onJsPrompt(view, url, message, defaultValue, result)
    }

    override fun onJsBeforeUnload(view: WebView?, url: String?, message: String?, result: JsResult?): Boolean {
        return delegate.onJsBeforeUnload(view, url, message, result)
    }

    override fun onGeolocationPermissionsShowPrompt(origin: String?, callback: GeolocationPermissions.Callback?) {
        delegate.onGeolocationPermissionsShowPrompt(origin, callback)
    }

    override fun onGeolocationPermissionsHidePrompt() {
        delegate.onGeolocationPermissionsHidePrompt()
    }

    override fun onPermissionRequest(request: PermissionRequest?) {
        delegate.onPermissionRequest(request)
    }

    override fun onPermissionRequestCanceled(request: PermissionRequest?) {
        delegate.onPermissionRequestCanceled(request)
    }

    override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
        return delegate.onConsoleMessage(consoleMessage)
    }

    override fun getDefaultVideoPoster(): Bitmap? {
        return delegate.getDefaultVideoPoster()
    }

    override fun getVideoLoadingProgressView(): View? {
        return delegate.getVideoLoadingProgressView()
    }

    override fun getVisitedHistory(callback: ValueCallback<Array<String>>?) {
        delegate.getVisitedHistory(callback)
    }

    override fun onShowFileChooser(webView: WebView?, filePathCallback: ValueCallback<Array<Uri>>?, fileChooserParams: FileChooserParams?): Boolean {
        return delegate.onShowFileChooser(webView, filePathCallback, fileChooserParams)
    }
}
