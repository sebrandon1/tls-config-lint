package secure;

import javax.net.ssl.SSLContext;
import javax.net.ssl.HttpsURLConnection;

// Properly configured TLS - should not trigger critical/high findings.
// Always use versioned SSLContext and default hostname verification.

public class Secure {
    public static SSLContext createSecureContext() throws Exception {
        SSLContext ctx = SSLContext.getInstance("TLSv1.3");
        ctx.init(null, null, null);
        return ctx;
    }

    public static void logStatus() {
        System.out.println("Certificate verification is enabled");
        System.out.println("Hostname verification is active");
    }
}
