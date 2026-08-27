package org.lineageos.hinokiradiobridge;

import android.app.Service;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.os.IHwBinder;
import android.os.Looper;
import android.os.RemoteException;
import android.util.Log;

import com.mediatek.internal.telephony.HinokiRadioIndication;
import java.util.NoSuchElementException;
import java.util.concurrent.atomic.AtomicInteger;

import vendor.mediatek.hardware.radio.V1_1.IRadio;

/** Registers the MTK-only callback channel missing from the AOSP telephony stack. */
public final class HinokiRadioBridgeService extends Service {
    private static final String TAG = "HinokiRadioBridge";
    private static final String RADIO_INSTANCE = "slot1";
    private static final long DEATH_COOKIE = 0x48494e4fL;

    private final Handler mHandler = new Handler(Looper.getMainLooper());
    private final AtomicInteger mSerial = new AtomicInteger(0x48490000);
    private final Runnable mConnect = this::connect;
    private final IHwBinder.DeathRecipient mDeathRecipient = cookie -> {
        Log.w(TAG, "MTK radio service died; reconnecting");
        scheduleReconnect(1000);
    };

    private IRadio mRadio;

    @Override
    public void onCreate() {
        super.onCreate();
        mHandler.post(mConnect);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (mRadio == null) {
            mHandler.post(mConnect);
        }
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        mHandler.removeCallbacks(mConnect);
        mRadio = null;
        super.onDestroy();
    }

    private void connect() {
        mHandler.removeCallbacks(mConnect);
        try {
            final IRadio radio = IRadio.getService(RADIO_INSTANCE);
            if (radio == null) {
                throw new NoSuchElementException("MTK radio slot1 is unavailable");
            }

            radio.linkToDeath(mDeathRecipient, DEATH_COOKIE);
            // Do not install MtkRadioResponseBase here. It deliberately contains no-op
            // implementations, while this legacy proxy also routes some standard radio
            // responses (notably GET_CURRENT_CALLS) through the MTK response callback
            // whenever it is non-null. Leaving only the MTK indication callback keeps
            // normal responses connected to Android's real RadioResponse instance.
            radio.setResponseFunctionsMtk(
                    null, new HinokiRadioIndication(radio, mHandler, mConnect, mSerial));
            mRadio = radio;
            Log.i(TAG, "Registered MTK radio callbacks for incoming calls");
        } catch (RemoteException | RuntimeException e) {
            Log.e(TAG, "Unable to register MTK radio callbacks", e);
            mRadio = null;
            scheduleReconnect(2000);
        }
    }

    private void scheduleReconnect(long delayMillis) {
        mHandler.removeCallbacks(mConnect);
        mHandler.postDelayed(mConnect, delayMillis);
    }
}
