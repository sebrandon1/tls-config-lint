import okhttp3.OkHttpClient
import javax.net.ssl.SSLContext

val secureContext = SSLContext.getInstance("TLS")
val client = OkHttpClient.Builder().build()
