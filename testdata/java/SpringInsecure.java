import org.springframework.web.client.RestTemplate;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.context.annotation.Bean;

class SpringInsecure {
    RestTemplate restTemplate = new RestTemplate(NoopHostnameVerifier.INSTANCE);
    WebClient client = WebClient.builder().clientConnector(InsecureTrustManagerFactory.INSTANCE).build();
    void protocols() { httpSecurity.setSSLProtocols("TLSv1", "TLSv1.1"); }
    @Bean SSLSocketFactory trustAllFactory() { return InsecureTrustManagerFactory.INSTANCE; }
}
