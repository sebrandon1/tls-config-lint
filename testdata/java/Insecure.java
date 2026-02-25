import javax.net.ssl.*;
import java.security.cert.X509Certificate;
import java.security.SecureRandom;

public class Insecure {

    // CRITICAL: Allow all hostnames
    public void disableHostnameVerification(HttpsURLConnection conn) {
        conn.setHostnameVerifier(ALLOW_ALL_HOSTNAME_VERIFIER);
    }

    // CRITICAL: Trust all certificates
    public TrustManager[] createTrustAllCerts() {
        return new TrustManager[]{
            new X509TrustManager() {
                public void checkClientTrusted(X509Certificate[] chain, String authType) {}
                public void checkServerTrusted(X509Certificate[] chain, String authType) {}
                public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
            }
        };
    }

    // CRITICAL: Custom SSLSocketFactory bypass
    public void setCustomFactory(HttpsURLConnection conn, SSLSocketFactory factory) {
        conn.setSSLSocketFactory(factory);
    }

    // HIGH: Unversioned SSLContext (defaults to old TLS)
    public SSLContext getDefaultContext() throws Exception {
        SSLContext ctx = SSLContext.getInstance("TLS");
        return ctx;
    }

    // HIGH: TLS 1.0
    public SSLContext getTls10Context() throws Exception {
        SSLContext ctx = SSLContext.getInstance("TLSv1");
        return ctx;
    }

    // HIGH: TLS 1.1
    public SSLContext getTls11Context() throws Exception {
        SSLContext ctx = SSLContext.getInstance("TLSv1.1");
        return ctx;
    }

    // MEDIUM: Enable weak protocols
    public void enableWeakProtocols(SSLSocket socket) {
        socket.setEnabledProtocols(new String[]{"TLSv1", "TLSv1.1", "TLSv1.2"});
    }

    // INFO: TLS 1.3 only
    public SSLContext getTls13Context() throws Exception {
        SSLContext ctx = SSLContext.getInstance("TLSv1.3");
        return ctx;
    }
}
