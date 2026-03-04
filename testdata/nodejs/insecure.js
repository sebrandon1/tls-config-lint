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

// HIGH: Weak cipher configuration
const options6 = {
  ciphers: 'DES-CBC3-SHA:RC4-SHA:NULL-SHA:EXPORT',
};

// MEDIUM: Server doesn't enforce cipher preference
const options7 = {
  honorCipherOrder: false,
};

// MEDIUM: axios global HTTPS agent override
const axios = require('axios');
axios.defaults.httpsAgent = new https.Agent({ rejectUnauthorized: false });

// CRITICAL: request strictSSL disabled
const request = require('request');
request({ url: 'https://example.com', strictSSL: false });

// HIGH: Weak secureProtocol
const options8 = {
  secureProtocol: 'TLSv1_method',
};
