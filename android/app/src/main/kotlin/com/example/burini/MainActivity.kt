package com.example.burini

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import com.google.android.gms.security.ProviderInstaller
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import android.util.Log
import android.os.Parcelable
import kotlinx.android.parcel.Parcelize

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Google Play 서비스 보안 공급자 설치
        try {
            ProviderInstaller.installIfNeeded(context)
        } catch (e: GooglePlayServicesRepairableException) {
            Log.e("Security", "Google Play Services needs update or repair", e)
        } catch (e: GooglePlayServicesNotAvailableException) {
            // 그 외 모든 예외 처리
            Log.e("Security", "Google Play Services not available", e)
        }
    }
}