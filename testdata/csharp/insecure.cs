using System.Net;
using System.Net.Http;
using System.Net.Security;
using System.Security.Authentication;

class InsecureTls {
    void Configure() {
        ServicePointManager.ServerCertificateValidationCallback = (sender, cert, chain, errors) => true;
        var handler = new HttpClientHandler {
            ServerCertificateCustomValidationCallback = (request, cert, chain, errors) => true
        };
        var protocols = SslProtocols.Tls11;
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls11;
    }
}
