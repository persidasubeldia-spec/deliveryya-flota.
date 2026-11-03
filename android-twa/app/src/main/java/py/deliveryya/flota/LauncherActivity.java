/*
 * Copyright 2020 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package py.deliveryya.flota;

import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;



public class LauncherActivity
        extends com.google.androidbrowserhelper.trusted.LauncherActivity {
    

    

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Setting an orientation crashes the app due to the transparent background on Android 8.0
        // Oreo and below. We only set the orientation on Oreo and above. This only affects the
        // splash screen and Chrome will still respect the orientation.
        // See https://github.com/GoogleChromeLabs/bubblewrap/issues/496 for details.
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.O) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER_PORTRAIT);
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
        }
    }

    @Override
    protected Uri getLaunchingUrl() {
        // Get the original launch Url.
        Uri uri = super.getLaunchingUrl();

        // Ubicación compartida (WhatsApp, Maps): abrir la Tienda en "Nuevo pedido" con ese destino.
        String mapa = null;
        Intent intent = getIntent();
        if (intent != null) {
            Uri data = intent.getData();
            if (Intent.ACTION_SEND.equals(intent.getAction())) {
                CharSequence t = intent.getCharSequenceExtra(Intent.EXTRA_TEXT);
                if (t != null) mapa = t.toString();
            } else if (data != null) {
                String host = data.getHost();
                boolean propio = host != null && host.equalsIgnoreCase(getString(R.string.hostName));
                if (!propio) mapa = data.toString();
            }
        }
        if (mapa != null && !mapa.trim().isEmpty()) {
            if (mapa.length() > 2000) mapa = mapa.substring(0, 2000);
            return Uri.parse("https://" + getString(R.string.hostName) + "/")
                    .buildUpon().appendQueryParameter("nuevo_pedido_mapa", mapa.trim()).build();
        }
        return uri;
    }
}
