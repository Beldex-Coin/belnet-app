package network.beldex.belnet;

import android.util.Log;

import java.text.DecimalFormat;

public class ConnectionTools {
    public static String bytesToSize(long sizeInBytes) {
        String readableSize;

        double b = sizeInBytes;
        double k = (sizeInBytes / 1024.0)*8;
        double m = (((sizeInBytes / 1024.0) / 1024.0)* 8);
        double g = ((((sizeInBytes / 1024.0) / 1024.0) / 1024.0)*8);
        double t = (((((sizeInBytes / 1024.0) / 1024.0) / 1024.0) / 1024.0)*8);

        DecimalFormat dec = new DecimalFormat("0.00");

        if (t > 1) {
            readableSize = dec.format(t).concat(" Tb");
//            Log.d("Test",readableSize);
            return readableSize;
        }
        else if (g > 1) {
            readableSize = dec.format(g).concat(" Gb");
//            Log.d("Test",readableSize);
            return readableSize;
        }
        else if (m > 1) {
            readableSize = dec.format(m).concat(" Mb");
//            Log.d("Test",readableSize);
            return readableSize;
        }
        else if (k > 1) {
            readableSize = dec.format(k).concat(" Kb");
//            Log.d("Test",readableSize);
            return readableSize;
        }
        else {
            readableSize = dec.format(b).concat(" b");
//            if(readableSize == "0.00 b")
//                return "3.00 b";
//            else
                return readableSize;
        }

        // return readableSize;
    }
}
