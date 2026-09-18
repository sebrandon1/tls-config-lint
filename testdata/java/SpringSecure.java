import org.springframework.web.client.RestTemplate;
import org.springframework.web.reactive.function.client.WebClient;

class SpringSecure {
    RestTemplate restTemplate = new RestTemplate();
    WebClient client = WebClient.builder().build();
    void protocols() { httpSecurity.setSSLProtocols("TLSv1.2", "TLSv1.3"); }
}
