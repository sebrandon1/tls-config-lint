using System.Net;
using System.Security.Authentication;

class SecureTls {
    void Configure() {
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
        var protocols = SslProtocols.Tls12;
    }
}
