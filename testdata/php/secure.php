<?php
$context = stream_context_create(['ssl' => [
    'verify_peer' => true,
    'verify_peer_name' => true,
]]);

curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
$client = new GuzzleHttp\Client(['verify' => true]);
