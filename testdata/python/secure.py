"""Properly configured TLS - should not trigger critical/high findings."""

import ssl

# Certificate verification must always be enabled.
# Use PROTOCOL_TLS_CLIENT instead of legacy protocol constants.

def create_secure_context():
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ctx.verify_mode = ssl.CERT_REQUIRED
    ctx.check_hostname = True
    ctx.load_default_certs()
    return ctx

def log_status():
    print("TLS verification is active")
    print("Using secure cipher configuration")
