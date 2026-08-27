package com.mediatek.internal.telephony;

import android.os.Handler;
import android.os.RemoteException;
import android.util.Log;

import java.util.concurrent.atomic.AtomicInteger;

import vendor.mediatek.hardware.radio.V1_1.IRadio;
import vendor.mediatek.hardware.radio.V1_1.IncomingCallNotification;

/** Accepts the MTK pre-alert so the modem exposes the call through standard CLCC. */
public final class HinokiRadioIndication extends MtkRadioIndicationBase {
    private static final String TAG = "HinokiRadioBridge";

    private final IRadio mRadio;
    private final Handler mHandler;
    private final Runnable mReconnect;
    private final AtomicInteger mSerial;

    public HinokiRadioIndication(IRadio radio, Handler handler, Runnable reconnect,
            AtomicInteger serial) {
        super(null);
        mRadio = radio;
        mHandler = handler;
        mReconnect = reconnect;
        mSerial = serial;
    }

    @Override
    public void incomingCallIndication(int indicationType,
            IncomingCallNotification notification) {
        if (notification == null) {
            Log.e(TAG, "MTK incoming call indication without payload");
            return;
        }

        try {
            final int callId = Integer.parseInt(notification.callId);
            final int seqNo = Integer.parseInt(notification.seqNo);
            final int serial = mSerial.incrementAndGet();

            // mode 0 is the stock MTK framework's allow/accept decision.
            mRadio.setCallIndication(serial, 0, callId, seqNo);
            Log.i(TAG, "Accepted MTK incoming call indication (callId=" + callId
                    + ", seqNo=" + seqNo + ")");
        } catch (NumberFormatException e) {
            Log.e(TAG, "Invalid MTK incoming call identifiers", e);
        } catch (RemoteException | RuntimeException e) {
            Log.e(TAG, "Failed to acknowledge MTK incoming call", e);
            mHandler.removeCallbacks(mReconnect);
            mHandler.postDelayed(mReconnect, 1000);
        }
    }
}
