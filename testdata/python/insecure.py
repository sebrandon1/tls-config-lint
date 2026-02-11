import ssl
import requests

# Disables certificate verification
response = requests.get("https://example.com", verify=False)

# ssl.CERT_NONE
ctx = ssl.create_default_context()
ctx.verify_mode = ssl.CERT_NONE

# Creates unverified context
ctx2 = ssl._create_unverified_context()

# Disables hostname verification
ctx3 = ssl.create_default_context()
ctx3.check_hostname = False

# TLS 1.0
ctx4 = ssl.SSLContext(ssl.PROTOCOL_TLSv1)

# TLS 1.1
ctx5 = ssl.SSLContext(ssl.PROTOCOL_TLSv1_1)
