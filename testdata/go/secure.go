package secure

import (
	"crypto/tls"
	"log"
)

// Properly configured TLS - none of these should trigger critical/high findings.

func secureTLS() *tls.Config {
	cfg := &tls.Config{
		MinVersion: tls.VersionTLS12,
	}
	return cfg
}

func strictTLS() *tls.Config {
	return &tls.Config{
		InsecureSkipVerify: false,
		MinVersion:         tls.VersionTLS12,
	}
}

func warnUser() {
	log.Println("Certificate verification is enabled")
	log.Println("Using modern TLS version")
}
