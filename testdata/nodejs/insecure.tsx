import React from 'react';
import https from 'https';

// CRITICAL: Disables certificate verification
export const insecureAgent = new https.Agent({
  rejectUnauthorized: false,
});

// HIGH: TLS 1.0
export const insecureProtocol = {
  secureProtocol: 'TLSv1_method',
};

// MEDIUM: Caps at TLS 1.2
export const cappedVersion = {
  maxVersion: 'TLSv1.2',
};

export function InsecureBadge(): React.JSX.Element {
  return <span>insecure</span>;
}
