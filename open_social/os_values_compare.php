<?php

require("authOrkut.php");

$ok = authOrkut();

# $ok = 1;

if (! $ok) {
    die ('Error: authOrkut failed');
}

if (! (isset($_GET['oauth_consumer_key']) && isset($_GET['os_user_id_token']))) {
    die ('Error: missing oauth_consumer_key or os_user_id_token');
}

$perl = new Perl();
$perl->eval('use open_social qw(os_values_compare)');

echo($perl->os_values_compare($_GET['oauth_consumer_key'],
			      $_GET['os_user_id_token'],
			      $_GET['open_social_friend_array']));
?>
