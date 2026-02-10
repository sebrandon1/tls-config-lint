const https = require('https');
const tls = require('tls');

// CRITICAL: Disables certificate verification
const agent = new https.Agent({
  rejectUnauthorized: false,
});

// CRITICAL: Disables TLS verification via env var
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// HIGH: TLS 1.0
const options1 = {
  secureProtocol: 'TLSv1_method',
};

// HIGH: TLS 1.1
const options2 = {
  secureProtocol: 'TLSv1_1_method',
};

// HIGH: Allows weak TLS versions
const options3 = {
  minVersion: 'TLSv1',
};

// MEDIUM: Caps at TLS 1.2
const options4 = {
  maxVersion: 'TLSv1.2',
};

// INFO: Forces TLS 1.3
const options5 = {
  minVersion: 'TLSv1.3',
};
