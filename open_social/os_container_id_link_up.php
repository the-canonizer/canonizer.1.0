<?php

require("authOrkut.php");

$ok = authOrkut();

$ok = 1;

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

echo("???? oauth_consumer_key, " . $oauth_consumer_key . " os_user_id_token: " . $os_user_id_token . ".\n");

if (! ((strlen($oauth_consumer_key) > 0) && (strlen($os_user_id_token) > 0)) ) {
    die ('Error: missing oauth_consumer_key or os_user_id_token');
}


if (isset( $_GET['canonizer_id'] )) {
    $canonizer_id = $_GET['canonizer_id'];
} else {
    $canonizer_id = $_POST['canonizer_id'];
}

if (isset( $_GET['canonizer_pw'] )) {
    $canonizer_pw = $_GET['canonizer_pw'];
} else {
    $canonizer_pw = $_POST['canonizer_pw'];
}


if (! ((strlen($canonizer_id) > 0) && (strlen($canonizer_pw) > 0)) ) {
    die ('Error: missing canonizer_id or canonizer_pw');
}

$perl = new Perl();

$perl->require("/usr/local/webtools/func.pm");
$perl->eval('use MIME::Base64;');

$canonizer_id = getVariable('canonizer_id');
$canonizer_pw = $perl->eval('func::canon_encode(' . getVariable('canonizer_pw') . ')');


# $link = mysql_connect('localhost:/var/lib/mysql/mysql.sock', 'canonizer', '1ularity');
$link = mysql_connect('cooler.canonizer.com', 'canonizer', '1ularity');
if (!$link) {
    die ('Error: Could not connect: ' . mysql_error());
}

$db_selected = mysql_select_db('canonizer', $link);
if (!$db_selected) {
    die  ('Can\'t use canonizer db : ' . mysql_error());
}

$sql = sprintf("select cid from person where email='%s' and password='%s'",
	       mysql_real_escape_string($canonizer_id, $link),
	       mysql_real_escape_string($canonizer_pw, $link) );

$result = mysql_query($sql, $link);

if (!$result) {
    echo "Error, could not query the database\n";
    die('MySQL Error: ' . mysql_error());
}

if ($row = mysql_fetch_assoc($result)) {
    $cid = $row['cid'];
} else {
    echo ("Error: invalid canonizer credentials.\n");
    exit;
}


$sql = sprintf("select id from open_social_link where os_container_id='%s' and os_user_id_token='%s'",
	       mysql_real_escape_string(getVariable('oauth_consumer_key'), $link),
	       mysql_real_escape_string(getVariable('os_user_id_token'), $link) );

$result = mysql_query($sql, $link);

if (!$result) {
    echo "Error, could not query the database\n";
    die('MySQL Error: ' . mysql_error());
}

if (mysql_fetch_assoc($result)) {
    die  ("Error: This user is already linked.\n");
}

$sql = "select max(id) from open_social_link";
$result = mysql_query($sql, $link);

if (!$result) {
    echo "Error, could not query the database\n";
    die('MySQL Error: ' . mysql_error());
}

if ($row = mysql_fetch_assoc($result)) {
    $next_id = $row['max(id)'];
} else {
    $next_id = 0;
}

$next_id++;

$sql = sprintf("insert into open_social_link (id, cid, os_container_id, os_user_id_token) values ($next_id, $cid, '%s', '%s')",
	       mysql_real_escape_string(getVariable('oauth_consumer_key'), $link),
	       mysql_real_escape_string(getVariable('os_user_id_token'), $link) );


mysql_query($sql, $link);

if (mysql_affected_rows($link) != 1) {
    die  ("Error: failed to insert into db.\n");
}

mysql_close($link);

echo "ok\n";

exit; # comment this out for debug

function getVariable( $var_name ){
  return isset( $_GET[ $var_name ] ) ? $_GET[ $var_name ] : $_POST[ $var_name ];
}


?>

<h2>canonizer_id: <?=$canonizer_id?></h2>
<h2>canonizer_pw: <?=$canonizer_pw?></h2>
<h2>cid: <?=$cid?></h2>
<h2>sql: <?=$sql?></h2>
<h2>next_id: <?=$next_id?></h2>
<h2>oauth_consumer_key: <?=$_GET['oauth_consumer_key']?></h2>
<h2>os_user_id_token: <?=$_GET['os_user_id_token']?></h2>
<h2>post array:</h2>
<pre>
<?
print_r ( $_POST );
?>
</pre>
</br>

<h2>get array:</h2>
<pre>
<?
print_r ( $_GET );
?>
</pre>

<hr>

