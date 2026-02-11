package main

import (
	"crypto/tls"
	"net/http"
)

func createInsecureClient() *http.Client {
	// Disables certificate verification
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}
	return &http.Client{Transport: tr}
}

func weakTLSConfig() *tls.Config {
	// Using TLS 1.0
	return &tls.Config{
		MinVersion: tls.VersionTLS10,
		MaxVersion: tls.VersionTLS11,
	}
}

func hardcodedConfig() *tls.Config {
	// Hardcoded tls.Config not using centralized profile
	return &tls.Config{
		MinVersion: tls.VersionTLS12,
	}
}
