<?php

require("authOrkut.php");

$ok = authOrkut();

# $ok = 1;

if (! $ok) {
    die ('Error: authOrkut failed');
}

if (! (isset($_POST['oauth_consumer_key']) && isset($_POST['opensocial_ownerid']))) {
    die ('Error: missing oauth_consumer_key or opensocial_ownerid');
}

$perl = new Perl();
$perl->eval('use open_social qw(os_values_compare)');

echo($perl->os_values_compare($_POST['oauth_consumer_key'],
			      $_POST['opensocial_ownerid'],
			      $_POST['open_social_friend_array']));
?>
