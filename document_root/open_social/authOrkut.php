<?php

require("oAuth.php");

function authOrkut(){

  //Determine the URL of the request
  $url = ( $_SERVER['HTTPS'] ? "https://" : "http://" ) .
         $_SERVER['HTTP_HOST'] .
         $_SERVER['PHP_SELF'];
 

  //Orkut's public key certificate

  $cert = <<<EOD
-----BEGIN CERTIFICATE-----
MIIDHDCCAoWgAwIBAgIJAMbTCksqLiWeMA0GCSqGSIb3DQEBBQUAMGgxCzAJBgNV
BAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIG
A1UEChMLR29vZ2xlIEluYy4xDjAMBgNVBAsTBU9ya3V0MQ4wDAYDVQQDEwVscnlh
bjAeFw0wODAxMDgxOTE1MjdaFw0wOTAxMDcxOTE1MjdaMGgxCzAJBgNVBAYTAlVT
MQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIGA1UEChML
R29vZ2xlIEluYy4xDjAMBgNVBAsTBU9ya3V0MQ4wDAYDVQQDEwVscnlhbjCBnzAN
BgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAseBXZ4NDhm24nX3sJRiZJhvy9eDZX12G
j4HWAMmhAcnm2iBgYpAigwhVHtOs+ZIUIdzQHvHeNd0ydc1Jg8e+C+Mlzo38OvaG
D3qwvzJ0LNn7L80c0XVrvEALdD9zrO+0XSZpTK9PJrl2W59lZlJFUk3pV+jFR8NY
eB/fto7AVtECAwEAAaOBzTCByjAdBgNVHQ4EFgQUv7TZGZaI+FifzjpTVjtPHSvb
XqUwgZoGA1UdIwSBkjCBj4AUv7TZGZaI+FifzjpTVjtPHSvbXqWhbKRqMGgxCzAJ
BgNVBAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEU
MBIGA1UEChMLR29vZ2xlIEluYy4xDjAMBgNVBAsTBU9ya3V0MQ4wDAYDVQQDEwVs
cnlhboIJAMbTCksqLiWeMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEA
CETnhlEnCJVDXoEtSSwUBLP/147sqiu9a4TNqchTHJObwTwDPUMaU6XIs2OTMmFu
GeIYpkHXzTa9Q6IKlc7Bt2xkSeY3siRWCxvZekMxPvv7YTcnaVlZzHrVfAzqNsTG
P3J//C0j+8JWg6G+zuo5k7pNRKDY76GxxHPYamdLfwk=
-----END CERTIFICATE-----
EOD;

  //Compute the raw form of the signed request using the OAuth library.
  $req = new OAuthRequest("GET", $url, $_REQUEST);
  $sig = array(
    urlencode($req->get_normalized_http_method()),
    urlencode($req->get_normalized_http_url()),
    urlencode($req->get_signable_parameters()),
  );
  $raw = implode("&", $sig);

 

  //Get the signature passed in the query and urldecode it

  $signature = base64_decode($_REQUEST["oauth_signature"]);

 

  //Pull the public key ID from the certificate
  $publickeyid = openssl_get_publickey($cert);

 

  //Check the computer signature against the one passed in the query
  $ok = openssl_verify($raw, $signature, $publickeyid);   

 

  //Release the key resource
  openssl_free_key($publickeyid);

  //Pass boolean data back

  return $ok;
  
  }
  
?>