<?php
// PHP TLS anti-pattern fixtures.
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

$context = stream_context_create(['ssl' => [
    'verify_peer' => false,
    'verify_peer_name' => false,
]]);

$client = new GuzzleHttp\Client(['verify' => false]);
