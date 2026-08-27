package com.mediatek.internal.telephony;

import com.android.internal.telephony.RIL;
import vendor.mediatek.hardware.radio.V1_1.IRadioIndication;
import vendor.mediatek.hardware.radio.V1_1.IncomingCallNotification;

public class MtkRadioIndicationBase implements IRadioIndication {
    MtkRadioIndicationBase(RIL ril) {
    }

    public void incomingCallIndication(int indicationType,
            IncomingCallNotification notification) {
    }
}
