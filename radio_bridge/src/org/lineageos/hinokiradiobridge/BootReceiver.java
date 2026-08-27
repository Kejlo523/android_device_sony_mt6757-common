package org.lineageos.hinokiradiobridge;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public final class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "HinokiRadioBridge";

    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            context.startService(new Intent(context, HinokiRadioBridgeService.class));
        } catch (RuntimeException e) {
            Log.e(TAG, "Unable to start radio bridge", e);
        }
    }
}
