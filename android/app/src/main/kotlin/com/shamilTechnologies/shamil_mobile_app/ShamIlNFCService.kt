package com.shamilTechnologies.shamil_mobile_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import org.json.JSONObject
import java.nio.charset.StandardCharsets

/**
 * Shamil NFC Card Emulation Service
 * 
 * This service allows the phone to act as an NFC card that can be read by ESP32 devices.
 * It responds to APDU commands with user authentication data.
 */
class ShamIlNFCService : HostApduService() {

    companion object {
        private const val TAG = "ShamIlNFCService"
        
        // AID (Application Identifier) for Shamil Access Control
        private val SHAMIL_AID = byteArrayOf(
            0xF0.toByte(), 0x53.toByte(), 0x48.toByte(), 0x41.toByte(), 
            0x4D.toByte(), 0x49.toByte(), 0x4C.toByte()  // F0534841D494C = "SHAMIL"
        )
        
        // APDU Commands
        private const val SELECT_APDU_HEADER = "00A40400"
        private const val GET_USER_DATA_INS = 0x01.toByte()
        private const val GET_ACCESS_TOKEN_INS = 0x02.toByte()
        private const val VERIFY_USER_INS = 0x03.toByte()
        
        // Response codes
        private val SUCCESS_SW = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val ERROR_SW = byteArrayOf(0x6F.toByte(), 0x00.toByte())
        private val NOT_FOUND_SW = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        
        // Shared user data (set by Flutter)
        @Volatile
        var currentUserData: String? = null
        
        @Volatile
        var isServiceEnabled: Boolean = true
        
        /**
         * Update user data from Flutter side
         */
        fun updateUserData(userData: String) {
            currentUserData = userData
            Log.d(TAG, "🔄 User data updated")
        }
        
        fun enableService() {
            isServiceEnabled = true
            Log.d(TAG, "✅ NFC Service enabled")
        }
        
        fun disableService() {
            isServiceEnabled = false
            currentUserData = null
            Log.d(TAG, "❌ NFC Service disabled")
        }
    }

    override fun onStartCommand(intent: android.content.Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "🚀 Shamil NFC Service started")
        return super.onStartCommand(intent, flags, startId)
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (!isServiceEnabled) {
            Log.w(TAG, "⚠️ NFC Service is disabled")
            return ERROR_SW
        }
        
        if (commandApdu == null || commandApdu.size < 4) {
            Log.w(TAG, "❌ Invalid APDU command")
            return ERROR_SW
        }

        try {
            val apduHex = commandApdu.joinToString("") { "%02X".format(it) }
            Log.d(TAG, "📨 Received APDU: $apduHex")

            return when {
                isSelectAidApdu(commandApdu) -> handleSelectAid(commandApdu)
                isGetUserDataApdu(commandApdu) -> handleGetUserData()
                isGetAccessTokenApdu(commandApdu) -> handleGetAccessToken()
                isVerifyUserApdu(commandApdu) -> handleVerifyUser(commandApdu)
                else -> handleUnknownCommand(commandApdu)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing APDU: ${e.message}", e)
            return ERROR_SW
        }
    }

    override fun onDeactivated(reason: Int) {
        val reasonText = when (reason) {
            DEACTIVATION_LINK_LOSS -> "Link Loss"
            DEACTIVATION_DESELECTED -> "Deselected"
            else -> "Unknown ($reason)"
        }
        Log.d(TAG, "📱 NFC Service deactivated: $reasonText")
    }

    private fun isSelectAidApdu(commandApdu: ByteArray): Boolean {
        if (commandApdu.size < 4) return false
        
        return commandApdu[0] == 0x00.toByte() &&  // CLA
               commandApdu[1] == 0xA4.toByte() &&  // INS (SELECT)
               commandApdu[2] == 0x04.toByte() &&  // P1
               commandApdu[3] == 0x00.toByte()     // P2
    }

    private fun isGetUserDataApdu(commandApdu: ByteArray): Boolean {
        return commandApdu.size >= 4 && 
               commandApdu[1] == GET_USER_DATA_INS
    }

    private fun isGetAccessTokenApdu(commandApdu: ByteArray): Boolean {
        return commandApdu.size >= 4 && 
               commandApdu[1] == GET_ACCESS_TOKEN_INS
    }

    private fun isVerifyUserApdu(commandApdu: ByteArray): Boolean {
        return commandApdu.size >= 4 && 
               commandApdu[1] == VERIFY_USER_INS
    }

    private fun handleSelectAid(commandApdu: ByteArray): ByteArray {
        Log.d(TAG, "🎯 Handling SELECT AID command")
        
        if (commandApdu.size < 5) {
            Log.w(TAG, "⚠️ SELECT command too short")
            return ERROR_SW
        }
        
        val lc = commandApdu[4].toInt() and 0xFF
        if (commandApdu.size < 5 + lc) {
            Log.w(TAG, "⚠️ SELECT command data incomplete")
            return ERROR_SW
        }
        
        val aid = commandApdu.sliceArray(5 until 5 + lc)
        
        return if (aid.contentEquals(SHAMIL_AID)) {
            Log.d(TAG, "✅ Shamil AID selected successfully")
            
            // Return app info as response
            val appInfo = JSONObject().apply {
                put("app_name", "Shamil Access Control")
                put("version", "1.0")
                put("protocol", "ENHANCED_NFC_v1")
                put("timestamp", System.currentTimeMillis())
            }
            
            val response = appInfo.toString().toByteArray(StandardCharsets.UTF_8)
            response + SUCCESS_SW
        } else {
            Log.w(TAG, "⚠️ Unknown AID: ${aid.joinToString("") { "%02X".format(it) }}")
            NOT_FOUND_SW
        }
    }

    private fun handleGetUserData(): ByteArray {
        Log.d(TAG, "👤 Handling GET USER DATA command")
        
        val userData = currentUserData
        if (userData == null) {
            Log.w(TAG, "⚠️ No user data available")
            return NOT_FOUND_SW
        }
        
        try {
            val userJson = JSONObject(userData)
            Log.d(TAG, "📤 Sending user data: ${userJson.getString("userName")}")
            
            // Create enhanced response for ESP32
            val response = JSONObject().apply {
                put("type", "USER_DATA_RESPONSE")
                put("firebase_uid", userJson.optString("firebaseUid"))
                put("user_name", userJson.optString("userName"))
                put("email", userJson.optString("email"))
                put("access_level", userJson.optString("accessLevel", "standard"))
                put("timestamp", System.currentTimeMillis())
                put("device_type", "mobile")
            }
            
            val responseBytes = response.toString().toByteArray(StandardCharsets.UTF_8)
            return responseBytes + SUCCESS_SW
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing user data: ${e.message}")
            return ERROR_SW
        }
    }

    private fun handleGetAccessToken(): ByteArray {
        Log.d(TAG, "🔑 Handling GET ACCESS TOKEN command")
        
        val userData = currentUserData
        if (userData == null) {
            Log.w(TAG, "⚠️ No user data for token generation")
            return NOT_FOUND_SW
        }
        
        try {
            val userJson = JSONObject(userData)
            
            // Create access token response
            val tokenResponse = JSONObject().apply {
                put("type", "ACCESS_TOKEN_RESPONSE")
                put("token", generateAccessToken(userJson))
                put("expires_at", System.currentTimeMillis() + (24 * 60 * 60 * 1000)) // 24 hours
                put("timestamp", System.currentTimeMillis())
            }
            
            val responseBytes = tokenResponse.toString().toByteArray(StandardCharsets.UTF_8)
            return responseBytes + SUCCESS_SW
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error generating access token: ${e.message}")
            return ERROR_SW
        }
    }

    private fun handleVerifyUser(commandApdu: ByteArray): ByteArray {
        Log.d(TAG, "🔐 Handling VERIFY USER command")
        
        val userData = currentUserData
        if (userData == null) {
            Log.w(TAG, "⚠️ No user data for verification")
            return NOT_FOUND_SW
        }
        
        try {
            val userJson = JSONObject(userData)
            
            // Create verification response
            val verificationResponse = JSONObject().apply {
                put("type", "USER_VERIFICATION_RESPONSE")
                put("verified", true)
                put("firebase_uid", userJson.optString("firebaseUid"))
                put("user_name", userJson.optString("userName"))
                put("verification_time", System.currentTimeMillis())
                put("device_verified", true)
            }
            
            val responseBytes = verificationResponse.toString().toByteArray(StandardCharsets.UTF_8)
            return responseBytes + SUCCESS_SW
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error verifying user: ${e.message}")
            return ERROR_SW
        }
    }

    private fun handleUnknownCommand(commandApdu: ByteArray): ByteArray {
        val ins = if (commandApdu.size > 1) commandApdu[1] else 0x00
        Log.w(TAG, "❓ Unknown APDU command - INS: 0x${"%02X".format(ins)}")
        return ERROR_SW
    }

    private fun generateAccessToken(userJson: JSONObject): String {
        // Simple token generation (in production, use proper JWT or similar)
        val firebaseUid = userJson.optString("firebaseUid")
        val timestamp = System.currentTimeMillis()
        return "SHAMIL_${firebaseUid}_$timestamp".take(64) // Limit token length
    }

} 