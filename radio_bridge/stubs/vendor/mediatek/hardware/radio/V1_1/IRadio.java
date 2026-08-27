package vendor.mediatek.hardware.radio.V1_1;

import android.os.IHwBinder;
import android.os.RemoteException;

public interface IRadio {
    static IRadio getService(String serviceName) throws RemoteException {
        throw new UnsupportedOperationException("compile-time stub");
    }

    boolean linkToDeath(IHwBinder.DeathRecipient recipient, long cookie) throws RemoteException;

    void setResponseFunctionsMtk(IRadioResponse response, IRadioIndication indication)
            throws RemoteException;

    void setCallIndication(int serial, int mode, int callId, int seqNo) throws RemoteException;
}
