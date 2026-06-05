package main

import "crypto/tls"

func insecureColon() {
	// This file has a colon in its name to test grep output parsing
	cfg := &tls.Config{InsecureSkipVerify: true}
	_ = cfg
}
