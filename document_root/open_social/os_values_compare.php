<?php

require("authOrkut.php");

$ok = authOrkut();

# $ok = 1;

if (! $ok) {
    die ('Error: authOrkut failed');
}

if (isset( $_GET['oauth_consumer_key'] )) {
    $oauth_consumer_key = $_GET['oauth_consumer_key'];
} else {
    $oauth_consumer_key = $_POST['oauth_consumer_key'];
}

if (isset( $_GET['os_user_id_token'] )) {
    $os_user_id_token = $_GET['os_user_id_token'];
} else {
    $os_user_id_token = $_POST['os_user_id_token'];
}

if (isset( $_GET['open_social_friend_array'] )) {
    $open_social_friend_array = $_GET['open_social_friend_array'];
} else {
    $open_social_friend_array = $_POST['open_social_friend_array'];
}

if (! (strlen($oauth_consumer_key) > 0) && (strlen($os_user_id_token) > 0) ) {
  die ('Error: missing oauth_consumer_key or os_user_id_token');
}

$perl = new Perl();
$perl->eval('use open_social qw(os_values_compare)');

echo($perl->os_values_compare($oauth_consumer_key,
			      $os_user_id_token,
			      $open_social_friend_array) );

?>
