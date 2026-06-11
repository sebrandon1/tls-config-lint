// Properly configured TLS - should not trigger critical/high findings.

const tls = require("tls");
const https = require("https");

// Certificate verification is enabled by default.
// Always use modern TLS versions.

const secureOptions = {
  rejectUnauthorized: true,
  minVersion: "TLSv1.3",
};

function logStatus() {
  console.log("TLS verification is active");
  console.log("Using secure protocol version");
}

const server = tls.createServer(secureOptions);
