<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . &func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}
%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

use history_class;
use topic_class;


sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/secure/object_topic.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $query_string);
	}
%>

	<br>
	<h2>You must register and or login before you can object to a change.</h2>
	<center>
	<h2><a href="http://<%=&func::get_host()%>/register.asp">Register</a><h2>
	<h2><a href="<%=$login_url%>">Login</a><h2>
	</center>
<%
}


sub unknown_record_page {

	if ($record_id) {
		%>
		<br>
		<h1>Unknown Record ID:&nbsp;<%=$record_id%>.</h1>
		<%
	} else {
		%>
		<br>
		<h1>No Record ID specified.</h1>
		<%
	}
}


sub after_go_live_message {
	return ("\t<br><h2 color=red>You can't object to a topic after its go live time.</h2>\n" );
}


sub object_form_message {

	my %nick_names = ();
	my $no_nick_name = 1;
	my $owner_code = &func::canon_encode($Session->{'cid'});
	my $selstmt = "select nick_name_id, nick_name from nick_names where owner_code = '$owner_code'";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	while($rs = $sth->fetch()) {
		$no_nick_name = 0;
		$nick_names{$rs->[0]} = $rs->[1];
	}
	$sth->finish();

	my $ret_val =
"	<center>
	<form method=post>
	<p><b>If anyone objects to a change the change will not go live.</b></p>
	<p><b>Are you sure you want to object to this proposed change?</b></p>

	<p>Objector Attribution Nick Name:
	<select name=\"submitter\">
";

	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $Request->Form('submitter')) {
			$ret_val .= "\t\t<option value=$id selected>" . $nick_names{$id} . "\n";
		} else {
			$ret_val .= "\t\t<option value=$id>" . $nick_names{$id} . "\n";
		}
	}

	$ret_val .=
"	</select></p>
	<p>Reason for objection: <font color = red>*</font><br>
	<input type=string name=object_reason maxlength=65 size=65></p>

	<input type=hidden name=topic_num value=$topic_num>
	<input type=submit name=submit value=\"Yes, I want to object.\">
	<input type=button value=\"No, take me back to the topic manager.\" onClick='location=\"http://" . &func::get_host() . "/topic_manage.asp?topic_num=" . $record->{topic_num} . "\"'>

	</form>

	</center>
";
	return($ret_val);
}


sub object_to_topic_page {

	%>
	<%=$message%>
	<br><br>
	<table>
	<%
	$record->print_record($dbh, $history_class::proposed_color);
	%>
	</table>
	<%
}


sub do_object {
	my $dbh = $_[0];

	my $message = '';

	my $object_reason = $Request->Form('object_reason');

	if (length($object_reason) < 1) {
		$message = '<center><font size=5 color=red>Must have a reason!</font></center>';
	}

	my $objector = int($Request->Form('submitter'));
	if ($objector < 1) {
		$message .= "Invalid submitter id.<br>\n";
	}

	if (! $message) {
		my $selstmt = "update topics set objector = $objector, object_time = " . time . ", object_reason = ? where record_id = $record_id";
		# what a pain!! if ($dbh->do($selstmt, $object_reason)) {
		my $sth = $dbh->prepare($selstmt);
		if ($sth->execute($object_reason)) {
			$Response->Redirect('http://' . &func::get_host() . '/topic_manage.asp?topic_num=' . $topic_num);
		} else {
			$message = "Failed to update for some reason.\n";
		}
	}
	return ($message . &object_form_message());
}



########
# main #
########

if (!$Session->{'logged_in'}) {
	&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $record_id = '';

my $submit = 0;

if ($Request->Form('record_id')) {
	$record_id = int($Request->Form('record_id'));
	$submit = 1;
} elsif ($Request->QueryString('record_id')) {
	$record_id = int($Request->QueryString('record_id'));
}


if (!$record_id) {
	&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&unknown_record_page]);
	$Response->End();
}

local $message = '';

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my $selstmt = "select * from topics where record_id = $record_id";
my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
$sth->execute() || die "Failed to prepair " . $selstmt;
my $rs;

local $record;

local $topic_num;

if ($rs = $sth->fetchrow_hashref()) {
	$record = new_rs topic_class ($rs);
	$topic_num = $record->{topic_num};
	if (time > $record->{go_live_time}) {
		$message = &after_go_live_message();
	} elsif ($Request->Form('submit') eq 'Yes, I want to object.') {
		$message = &do_object($dbh, $record_id); # does not return (redirects) if successful.
	} else {
		$message = &object_form_message();
	}
} else {
	&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&unknown_record_page]);
	$Response->End();
}


&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&object_to_topic_page]);

%>

