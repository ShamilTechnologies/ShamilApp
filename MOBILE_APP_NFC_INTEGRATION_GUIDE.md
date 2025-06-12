# Mobile App NFC Integration Guide
## ESP32 Access Control System Integration

### Overview
This guide explains how mobile applications can integrate with the ESP32 NFC Access Control System to provide seamless access validation. The system works by reading the mobile device's NFC UID, validating it against cached user data, and providing immediate feedback to both the mobile app and physical hardware.

### System Architecture

```
Mobile App (UID) → ESP32 NFC Reader → Desktop App (Validation) → Response
                                   ↓
                              Buzzer/LED Feedback
                                   ↓
Mobile App ← NFC Response ← ESP32 NFC Reader ← Desktop App
```

## NFC Communication Protocol

### 1. Mobile App Requirements

#### Prerequisites
- NFC-enabled device (Android/iOS)
- NFC read/write capabilities
- Unique device UID access
- JSON parsing capabilities

#### Required Permissions

**Android (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="true" />

<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.nfc.action.NDEF_DISCOVERED" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="application/esp32-access-control" />
    </intent-filter>
</activity>
```

**iOS (Info.plist):**
```xml
<key>NFCReaderUsageDescription</key>
<string>This app uses NFC to communicate with access control systems</string>
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
</array>
```

### 2. UID Transmission Process

#### Step 1: Prepare UID Data Structure
When approaching the ESP32 NFC reader, your mobile app should prepare the following data structure:

```json
{
  "type": "mobile_uid_access_request",
  "app_id": "YOUR_APP_IDENTIFIER",
  "mobile_uid": "DEVICE_UNIQUE_IDENTIFIER", 
  "request_id": "UNIQUE_REQUEST_ID",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "app_version": "1.0.0",
  "device_info": {
    "platform": "android|ios",
    "model": "Device Model",
    "os_version": "OS Version"
  }
}
```

#### Step 2: Generate Unique Request ID
```javascript
// Example: Generate unique request ID
function generateRequestId() {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}
```

#### Step 3: Get Device UID
```javascript
// Android Example (React Native)
import { NfcManager } from 'react-native-nfc-manager';

async function getDeviceUID() {
    try {
        // Get device's NFC UID or generate unique identifier
        const uid = await NfcManager.getDeviceUID();
        return uid || generateFallbackUID();
    } catch (error) {
        console.log('Error getting UID:', error);
        return generateFallbackUID();
    }
}

function generateFallbackUID() {
    // Generate deterministic UID based on device characteristics
    const deviceId = DeviceInfo.getUniqueId();
    return `mobile_${deviceId}`;
}
```

#### Step 4: Write UID to NFC
```javascript
// React Native NFC Write Example
import { NfcManager, NdefParser, Ndef } from 'react-native-nfc-manager';

async function writeUIDToNFC() {
    try {
        // Prepare the access request
        const accessRequest = {
            type: "mobile_uid_access_request",
            app_id: "com.yourcompany.yourapp",
            mobile_uid: await getDeviceUID(),
            request_id: generateRequestId(),
            timestamp: new Date().toISOString(),
            app_version: "1.0.0",
            device_info: {
                platform: Platform.OS,
                model: DeviceInfo.getModel(),
                os_version": DeviceInfo.getSystemVersion()
            }
        };

        // Convert to NDEF record
        const bytes = Ndef.encodeMessage([
            Ndef.textRecord(JSON.stringify(accessRequest), 'en', 'esp32-access')
        ]);

        // Write to NFC tag/reader
        await NfcManager.requestTechnology([NfcTech.Ndef]);
        await NfcManager.ndefHandler.writeNdefMessage(bytes);
        
        console.log('✅ UID sent to ESP32 successfully');
        
        // Start listening for response
        await listenForAccessResponse();
        
    } catch (error) {
        console.error('❌ Error writing UID to NFC:', error);
        handleNFCError(error);
    }
}
```

### 3. Response Handling

#### Expected Response Structure
After validation, the mobile app will receive the following response structure:

```json
{
  "type": "nfc_access_response",
  "app_id": "ESP32_ACCESS_CONTROL",
  "request_id": "MATCHING_REQUEST_ID",
  "mobile_uid": "YOUR_DEVICE_UID",
  "access_granted": true,
  "decision": "granted|denied",
  "reason": "Valid subscription|Access denied - No valid access|System error",
  "user_name": "John Doe",
  "access_type": "subscription|reservation|guest",
  "valid_until": "2024-01-15T18:00:00.000Z",
  "timestamp": "2024-01-15T10:30:05.123Z",
  "processing_time": 87,
  "service_provider": "Access Control System",
  "additional_data": {
    "location": "Main Entrance",
    "facility": "Gym Center",
    "access_level": "standard"
  }
}
```

#### Response Listening Implementation
```javascript
// Listen for NFC response
async function listenForAccessResponse(timeoutMs = 10000) {
    return new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
            NfcManager.cancelTechnologyRequest();
            reject(new Error('Response timeout'));
        }, timeoutMs);

        // Set up NFC listener
        NfcManager.setEventListener(NfcEvents.DiscoverTag, (tag) => {
            clearTimeout(timeout);
            
            try {
                const response = parseNFCResponse(tag);
                if (response && response.type === 'nfc_access_response') {
                    handleAccessResponse(response);
                    resolve(response);
                } else {
                    reject(new Error('Invalid response format'));
                }
            } catch (error) {
                reject(error);
            }
        });
    });
}

function parseNFCResponse(tag) {
    try {
        if (tag.ndefMessage && tag.ndefMessage.length > 0) {
            const textRecord = tag.ndefMessage[0];
            const text = Ndef.text.decodePayload(textRecord.payload);
            return JSON.parse(text);
        }
        return null;
    } catch (error) {
        console.error('Error parsing NFC response:', error);
        return null;
    }
}
```

### 4. Complete Integration Example

#### React Native Implementation
```javascript
import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, Alert } from 'react-native';
import { NfcManager, NfcTech, Ndef, NfcEvents } from 'react-native-nfc-manager';

const NFCAccessControl = () => {
    const [isProcessing, setIsProcessing] = useState(false);
    const [accessResult, setAccessResult] = useState(null);

    useEffect(() => {
        // Initialize NFC
        NfcManager.start();
        return () => {
            NfcManager.setEventListener(NfcEvents.DiscoverTag, null);
            NfcManager.cancelTechnologyRequest().catch(() => 0);
        };
    }, []);

    const requestAccess = async () => {
        setIsProcessing(true);
        setAccessResult(null);

        try {
            // Step 1: Prepare access request
            const accessRequest = {
                type: "mobile_uid_access_request",
                app_id: "com.yourcompany.yourapp",
                mobile_uid: await getDeviceUID(),
                request_id: generateRequestId(),
                timestamp: new Date().toISOString(),
                app_version: "1.0.0"
            };

            console.log('🔵 Requesting access with UID:', accessRequest.mobile_uid);

            // Step 2: Write request to NFC
            await NfcManager.requestTechnology([NfcTech.Ndef]);
            
            const bytes = Ndef.encodeMessage([
                Ndef.textRecord(JSON.stringify(accessRequest), 'en', 'esp32-access')
            ]);

            await NfcManager.ndefHandler.writeNdefMessage(bytes);
            console.log('📤 Access request sent to ESP32');

            // Step 3: Listen for response
            const response = await listenForAccessResponse(15000);
            
            // Step 4: Handle response
            setAccessResult(response);
            showAccessResult(response);

        } catch (error) {
            console.error('❌ Access request failed:', error);
            Alert.alert('Access Error', error.message);
        } finally {
            setIsProcessing(false);
            NfcManager.cancelTechnologyRequest().catch(() => 0);
        }
    };

    const showAccessResult = (response) => {
        const title = response.access_granted ? '✅ Access Granted' : '❌ Access Denied';
        const message = response.access_granted 
            ? `Welcome, ${response.user_name}!\nAccess Type: ${response.access_type}\nValid until: ${new Date(response.valid_until).toLocaleString()}`
            : `Access denied: ${response.reason}`;

        Alert.alert(title, message);
    };

    return (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 }}>
            <TouchableOpacity 
                onPress={requestAccess}
                disabled={isProcessing}
                style={{
                    backgroundColor: isProcessing ? '#ccc' : '#007AFF',
                    padding: 20,
                    borderRadius: 10,
                    width: '100%',
                    alignItems: 'center'
                }}
            >
                <Text style={{ color: 'white', fontSize: 18, fontWeight: 'bold' }}>
                    {isProcessing ? 'Processing...' : '🔑 Request Access'}
                </Text>
            </TouchableOpacity>

            {accessResult && (
                <View style={{ marginTop: 20, padding: 15, backgroundColor: '#f0f0f0', borderRadius: 8 }}>
                    <Text style={{ fontWeight: 'bold', marginBottom: 5 }}>
                        Last Access Result:
                    </Text>
                    <Text>Status: {accessResult.access_granted ? 'Granted' : 'Denied'}</Text>
                    <Text>User: {accessResult.user_name}</Text>
                    <Text>Processing Time: {accessResult.processing_time}ms</Text>
                </View>
            )}
        </View>
    );
};
```

### 5. Error Handling

#### Common Error Scenarios
```javascript
const handleNFCError = (error) => {
    switch (error.code) {
        case 'NFC_DISABLED':
            Alert.alert('NFC Disabled', 'Please enable NFC in your device settings');
            break;
        case 'NFC_NOT_SUPPORTED':
            Alert.alert('NFC Not Supported', 'This device does not support NFC');
            break;
        case 'TIMEOUT':
            Alert.alert('Connection Timeout', 'Please try again and hold your device closer to the reader');
            break;
        case 'INVALID_RESPONSE':
            Alert.alert('Invalid Response', 'Received invalid response from access control system');
            break;
        case 'ACCESS_DENIED':
            Alert.alert('Access Denied', 'You do not have permission to access this resource');
            break;
        default:
            Alert.alert('Error', `Unknown error: ${error.message}`);
    }
};
```

#### Response Validation
```javascript
const validateAccessResponse = (response) => {
    const requiredFields = [
        'type', 'request_id', 'mobile_uid', 'access_granted', 
        'decision', 'reason', 'timestamp'
    ];
    
    for (const field of requiredFields) {
        if (!response.hasOwnProperty(field)) {
            throw new Error(`Missing required field: ${field}`);
        }
    }
    
    if (response.type !== 'nfc_access_response') {
        throw new Error('Invalid response type');
    }
    
    return true;
};
```

### 6. iOS Implementation Notes

#### Core NFC Implementation
```swift
import CoreNFC

class NFCAccessManager: NSObject, NFCNDEFReaderSessionDelegate {
    private var nfcSession: NFCNDEFReaderSession?
    
    func requestAccess() {
        guard NFCNDEFReaderSession.readingAvailable else {
            showAlert(title: "NFC Error", message: "NFC is not available on this device")
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Hold your device near the access control reader"
        nfcSession?.begin()
    }
    
    // NDEF Reader Delegate Methods
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Handle NFC detection and response
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Handle NFC errors
    }
}
```

### 7. Testing and Debugging

#### Debug Logging
```javascript
const debugLog = (message, data = null) => {
    if (__DEV__) {
        console.log(`[NFC-ACCESS] ${message}`, data ? JSON.stringify(data, null, 2) : '');
    }
};

// Usage examples:
debugLog('Preparing access request', accessRequest);
debugLog('NFC write successful');
debugLog('Received response', response);
```

#### Testing Checklist
- [ ] NFC is enabled on test device
- [ ] App has NFC permissions
- [ ] ESP32 is powered and running
- [ ] Desktop app is connected to ESP32
- [ ] User exists in system with valid subscription/reservation
- [ ] Test both granted and denied scenarios
- [ ] Test timeout scenarios
- [ ] Test invalid UID scenarios

### 8. Performance Optimization

#### Best Practices
- **Minimize Data Size**: Keep NFC payloads under 8KB
- **Quick Timeouts**: Use 10-15 second timeouts for responses
- **Error Recovery**: Implement automatic retry with exponential backoff
- **User Feedback**: Provide immediate visual feedback during processing
- **Background Processing**: Handle NFC operations on background threads

#### Timeout Configuration
```javascript
const NFC_TIMEOUTS = {
    WRITE_TIMEOUT: 5000,      // 5 seconds to write UID
    RESPONSE_TIMEOUT: 15000,  // 15 seconds to receive response
    RETRY_DELAY: 2000,        // 2 seconds between retries
    MAX_RETRIES: 3            // Maximum retry attempts
};
```

### 9. Security Considerations

#### Data Protection
- Never store sensitive user data in NFC messages
- Use HTTPS for any additional API calls
- Validate all response data before processing
- Implement request/response encryption if required

#### UID Security
```javascript
// Example: Hash UID for additional security
const crypto = require('crypto');

function hashUID(uid) {
    return crypto.createHash('sha256').update(uid + 'secret_salt').digest('hex');
}
```

### 10. Integration Checklist

#### Pre-Integration
- [ ] ESP32 hardware is properly configured
- [ ] Desktop app is running and connected
- [ ] User data is cached in desktop app
- [ ] NFC permissions are granted

#### During Development
- [ ] Test UID generation and uniqueness
- [ ] Verify JSON data structure
- [ ] Test NFC read/write operations
- [ ] Implement proper error handling
- [ ] Add user feedback mechanisms

#### Pre-Production
- [ ] Test with multiple devices
- [ ] Verify performance under load
- [ ] Test edge cases and error scenarios
- [ ] Implement analytics and logging
- [ ] Create user documentation

### Support and Troubleshooting

For additional support:
1. Check ESP32 connection status
2. Verify desktop app is processing requests
3. Ensure user exists in system database
4. Test with known working device UID
5. Check NFC hardware functionality

### Sample Response Times
- UID Transmission: ~50ms
- Desktop Validation: ~87ms
- ESP32 Feedback: ~25ms
- Total Process: ~200-500ms

This guide provides everything needed to integrate your mobile app with the ESP32 NFC Access Control System. The system is designed for speed and reliability, typically processing access requests in under 500ms. 