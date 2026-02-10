import ssl
import requests

# CRITICAL: Disables certificate verification
response = requests.get("https://example.com", verify=False)

# CRITICAL: ssl.CERT_NONE
ctx = ssl.create_default_context()
ctx.verify_mode = ssl.CERT_NONE

# CRITICAL: Creates unverified context
ctx2 = ssl._create_unverified_context()

# CRITICAL: Disables hostname verification
ctx3 = ssl.create_default_context()
ctx3.check_hostname = False

# HIGH: TLS 1.0
ctx4 = ssl.SSLContext(ssl.PROTOCOL_TLSv1)

# HIGH: TLS 1.1
ctx5 = ssl.SSLContext(ssl.PROTOCOL_TLSv1_1)

# MEDIUM: Caps at TLS 1.2
ctx6 = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx6.maximum_version = ssl.TLSVersion.TLSv1_2

# INFO: Forces TLS 1.3
ctx7 = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx7.minimum_version = ssl.TLSVersion.TLSv1_3
