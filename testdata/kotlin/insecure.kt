import io.ktor.client.*
import okhttp3.OkHttpClient
import javax.net.ssl.SSLContext
import javax.net.ssl.X509TrustManager

val weakContext = SSLContext.getInstance("TLSv1")
val ktorManager = null as X509TrustManager?
val trustManager = null
val client = OkHttpClient.Builder()
    .hostnameVerifier { _, _ -> true }
    .sslSocketFactory(insecureFactory, TrustAllManager())
    .build()

class TrustAllManager : X509TrustManager {
    override fun checkServerTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}
    override fun checkClientTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}
}
