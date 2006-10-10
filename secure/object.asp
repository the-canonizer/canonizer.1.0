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
<!--#include file = "includes/error_page.asp"-->

<%

use history_class;
use managed_record;
use topic;
use statement;
use text;


sub must_login {
	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/secure/object.asp';
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
	my $record = $_[0];
	my $class  = $_[1];

	my %nick_names = &func::get_nick_name_hash($Session->{'cid'}, $dbh);

	if ($nick_names{'error_message'}) {
		return($nick_names{'error_message'});
	}

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

	<input type=hidden name=topic_num value=" . $record->{topic_num} . ">
	<input type=hidden name=record_id value=" . $record->{record_id} . ">

	<input type=submit name=submit value=\"Yes, I want to object.\">
	<input type=button value=\"No, take me back to the topic manager.\" onClick='location=\"" . &make_manage_url($record, $class) . "\"'>

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
	my $dbh    = $_[0];
	my $record = $_[1];
	my $class  = $_[2];

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
		my $selstmt = "update $class set objector = $objector, object_time = " . time . ", object_reason = ? where record_id = " . $record->{record_id};
		# what a pain!! if ($dbh->do($selstmt, $object_reason))
		my $sth = $dbh->prepare($selstmt);
		if ($sth->execute($object_reason)) {
			$Response->Redirect(&make_manage_url($record, $class));
		} else {
			$message = "Failed to update for some reason.\n";
		}
	}
	return ($message . &object_form_message($record, $class));
}


sub make_manage_url {
	my $record = $_[0];
	my $class  = $_[1];

	my $url = 'http://' . &func::get_host() . '/manage.asp?class=' . $class . '&topic_num=' . $record->{topic_num};
	if ($class eq 'statement') {
		$url .= '&statement_num=' . $record->{statement_num};
	} elsif ($class eq 'text') {
		$url .= '&statement_num=' . $record->{statement_num};
		if ($record->{text_size}) {
			$url .= '&long=' . $record->{text_size};
		}
	}
	return($url);
}


########
# main #
########

local $error_message = '';

if (!$Session->{'logged_in'}) {
	&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

my $class;
if ($Request->Form('class')) {
	$class = $Request->Form('class');
} elsif ($Request->QueryString('class')) {
	$class = $Request->QueryString('class');
}

if (&managed_record::bad_managed_class($class)) {
	$error_message = "Error: '$class' is an invalid edit class.<br>\n";
	&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

local $record_id = '';
my $submit = 0;

if ($Request->Form('submit') eq 'Yes, I want to object.') {
	$record_id = int($Request->Form('record_id'));
	$submit = 1;
} elsif ($Request->QueryString('record_id')) {
	$record_id = int($Request->QueryString('record_id'));
}


local $message = '';

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";

if (!$record_id) {
	&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&unknown_record_page]);
	$Response->End();
}

local $record = new_record_id $class ($record_id, $dbh);

if ($record->{error_message}) {
	$error_message = $record->{error_message};
	&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}


if (time > $record->{go_live_time}) {
	$message = &after_go_live_message();
} elsif ($submit) {
	$message = &do_object($dbh, $record, $class); # does not return (redirects) if successful.
} else {
	$message = &object_form_message($record, $class);
}


&display_page('<font size=6>Object to Modification</font>', [\&identity, \&search, \&main_ctl], [\&object_to_topic_page]);

%>

