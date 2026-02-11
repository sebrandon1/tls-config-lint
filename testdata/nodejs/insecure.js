const https = require('https');
const tls = require('tls');

// Disables certificate verification
const agent = new https.Agent({
  rejectUnauthorized: false,
});

// Disables TLS verification via env var
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// TLS 1.0
const options1 = {
  secureProtocol: 'TLSv1_method',
};

// TLS 1.1
const options2 = {
  secureProtocol: 'TLSv1_1_method',
};

// Allows weak TLS versions
const options3 = {
  minVersion: 'TLSv1',
};
