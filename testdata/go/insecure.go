package main

import (
	"crypto/tls"
	"net/http"
)

func createInsecureClient() *http.Client {
	// CRITICAL: Disables certificate verification
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}
	return &http.Client{Transport: tr}
}

func weakTLSConfig() *tls.Config {
	// HIGH: Using TLS 1.0
	return &tls.Config{
		MinVersion: tls.VersionTLS10,
		MaxVersion: tls.VersionTLS11,
	}
}

func cappedTLS() *tls.Config {
	// MEDIUM: Prevents TLS 1.3
	return &tls.Config{
		MaxVersion: tls.VersionTLS12,
	}
}

func strictTLS() *tls.Config {
	// INFO: Forces TLS 1.3
	return &tls.Config{
		MinVersion:               tls.VersionTLS13,
		PreferServerCipherSuites: true,
		CurvePreferences:         []tls.CurveID{tls.X25519},
	}
}

func hardcodedConfig() *tls.Config {
	// INFO: Hardcoded tls.Config
	return &tls.Config{
		MinVersion: tls.VersionTLS12,
	}
}
