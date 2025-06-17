package com.shamilTechnologies.shamil_mobile_app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ComponentName
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.util.Log

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "shamil_nfc_service"
    private val TAG = "MainActivity"
    private lateinit var channel: MethodChannel
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "🔧 Configuring Flutter engine with NFC method channel")
        
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            Log.d(TAG, "📞 Received method call: ${call.method}")
            
            when (call.method) {
                "enableCardEmulation" -> {
                    try {
                        enableCardEmulation(call.arguments as? Map<String, Any>, result)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error in enableCardEmulation: ${e.message}", e)
                        result.error("METHOD_ERROR", "Error in enableCardEmulation: ${e.message}", null)
                    }
                }
                "disableCardEmulation" -> {
                    try {
                        disableCardEmulation(result)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error in disableCardEmulation: ${e.message}", e)
                        result.error("METHOD_ERROR", "Error in disableCardEmulation: ${e.message}", null)
                    }
                }
                "updateCardData" -> {
                    try {
                        updateCardData(call.arguments as? Map<String, Any>, result)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error in updateCardData: ${e.message}", e)
                        result.error("METHOD_ERROR", "Error in updateCardData: ${e.message}", null)
                    }
                }
                "checkNFCAvailability" -> {
                    try {
                        checkNFCAvailability(result)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error in checkNFCAvailability: ${e.message}", e)
                        result.error("METHOD_ERROR", "Error in checkNFCAvailability: ${e.message}", null)
                    }
                }
                else -> {
                    Log.w(TAG, "⚠️ Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        Log.d(TAG, "✅ Method channel configured successfully")
    }
    
    private fun enableCardEmulation(arguments: Map<String, Any>?, result: MethodChannel.Result) {
        Log.d(TAG, "🔄 enableCardEmulation called with arguments: $arguments")
        
        try {
            val userData = arguments?.get("userData") as? String
            if (userData != null) {
                Log.d(TAG, "📋 User data received, length: ${userData.length}")
                
                // Update user data in the NFC service
                ShamIlNFCService.updateUserData(userData)
                Log.d(TAG, "📝 User data updated in NFC service")
                
                // Enable the service
                ShamIlNFCService.enableService()
                Log.d(TAG, "🔛 NFC service enabled")
                
                // Enable the service component
                val componentName = ComponentName(this, ShamIlNFCService::class.java)
                packageManager.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
                Log.d(TAG, "⚙️ Service component enabled")
                
                Log.d(TAG, "✅ NFC Card Emulation enabled successfully")
                result.success(true)
            } else {
                Log.e(TAG, "❌ User data is null or invalid")
                result.error("INVALID_ARGUMENTS", "User data is required", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error enabling card emulation: ${e.message}", e)
            result.error("ENABLE_ERROR", e.message, null)
        }
    }
    
    private fun disableCardEmulation(result: MethodChannel.Result) {
        Log.d(TAG, "🔄 disableCardEmulation called")
        
        try {
            // Disable the NFC service
            ShamIlNFCService.disableService()
            Log.d(TAG, "🔚 NFC service disabled")
            
            // Disable the service component
            val componentName = ComponentName(this, ShamIlNFCService::class.java)
            packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            Log.d(TAG, "⚙️ Service component disabled")
            
            Log.d(TAG, "✅ NFC Card Emulation disabled successfully")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error disabling card emulation: ${e.message}", e)
            result.error("DISABLE_ERROR", e.message, null)
        }
    }
    
    private fun updateCardData(arguments: Map<String, Any>?, result: MethodChannel.Result) {
        Log.d(TAG, "🔄 updateCardData called with arguments: $arguments")
        
        try {
            val requestData = arguments?.get("requestData") as? String
            if (requestData != null) {
                Log.d(TAG, "📋 Request data received, length: ${requestData.length}")
                
                ShamIlNFCService.updateUserData(requestData)
                Log.d(TAG, "📝 Card data updated in NFC service")
                
                Log.d(TAG, "✅ Card data updated successfully")
                result.success(true)
            } else {
                Log.e(TAG, "❌ Request data is null or invalid")
                result.error("INVALID_ARGUMENTS", "Request data is required", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error updating card data: ${e.message}", e)
            result.error("UPDATE_ERROR", e.message, null)
        }
    }
    
    private fun checkNFCAvailability(result: MethodChannel.Result) {
        Log.d(TAG, "🔄 checkNFCAvailability called")
        
        try {
            val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
            val isAvailable = nfcAdapter != null && nfcAdapter.isEnabled
            
            Log.d(TAG, "📱 NFC Adapter available: ${nfcAdapter != null}")
            Log.d(TAG, "📱 NFC Enabled: ${nfcAdapter?.isEnabled ?: false}")
            Log.d(TAG, "📱 Overall NFC Availability: $isAvailable")
            
            result.success(isAvailable)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking NFC: ${e.message}", e)
            result.error("NFC_CHECK_ERROR", e.message, null)
        }
    }
    
    // Handle NFC intent when app is opened via NFC
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "🔄 MainActivity onResume")
        
        // Notify Flutter that NFC might be triggered
        if (::channel.isInitialized) {
            try {
                channel.invokeMethod("onNFCDetected", mapOf(
                    "triggered" to true,
                    "timestamp" to System.currentTimeMillis()
                ))
                Log.d(TAG, "📡 Sent onNFCDetected to Flutter")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending onNFCDetected: ${e.message}", e)
            }
        } else {
            Log.w(TAG, "⚠️ Method channel not initialized in onResume")
        }
    }
} 