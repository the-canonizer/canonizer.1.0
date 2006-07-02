<!--#include = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub tab_sub {

	if (!$topic_id) { # can't present or descuss a not yet created topic.
		$Response->Write("<br><br>\n");
		return();
	}

	my $url = "topic.asp?topic_id=$topic_id";

	%>
	<table cellpadding=10 border=1>
	    <tr>
		<%
		if ($mode eq 'present') {
		    %>
		    <th bgcolor="#FFFFFF"><font face=arial>Present</font></th>
		    <%
		} else {
		    %>
		    <th><font face=arial><a href="<%=$url%>">Present</a></font></th>
		    <%
		}

		if ($mode eq 'manage') {
		    %>
		    <th bgcolor="#FFFFFF"><font face=arial>Manage</font></th>
		    <%
		} else {
		    %>
		    <th><font face=arial><a href="<%=$url . '&mode=manage'%>">Manage</a></font></th>
		    <%
		}

		%>
	    <th><font face = arial>Discuss</font></th>

	    </tr>
	</table>
	<%
}

sub error_page {
	%>
	<h1>Error: Unkown topic_id: <%=$topic_id%>.</h1>
	<%
}

sub save_topic {
	my $dbh = $_[0];

	my %form_state = ();

	$form_state{'topic_name'} = $Request->Form('topic_name');
	if (length($form_state{'topic_name'}) < 1) {
		$message .= "<h2><font color=red>A Topic Name is required.</font></h2>\n";
	}

	$form_state{'namespace'} = $Request->Form('namespace');

	$form_state{'one_line'}  = $Request->Form('one_line');

	$form_state{'key_words'} = $Request->Form('key_words');

	my $selstmt;

	if (!$message) {
		if ($topic_id) {
		} else {
			$selstmt = 'select topic_id_seq.nextval from dual';
			my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
			$sth->execute() || die "Failed to execute " . $selstmt;
			my $rs = $sth->fetch() || die "Failed to fetch with " . $selstmt;
			$topic_id = $rs->[0];
			# ????
			print(STDERR "New topic_id: $topic_id.\n");
			$sth->finish();

			$selstmt = "insert into topic (topic_id, name, namespace, one_line, key_words, ) values ($topic_id, '" . &func::hex_encode($form_state{'topic_name'}) . "', '" . &func::hex_encode($form_state{'namespace'}) . "', '" . &func::hex_encode($form_state{'one_line'}) . "', '" . &func::hex_encode($form_state{'key_words'}) . "', sysdate)";

			# why doesn't the do work?
#	 		$dbh->do($sestmt) || die "Failed to create new record with " . $selstmt;
			my $sth = $dbh->prepare($selstmt) || die $selstmt;
			$sth->execute() || die "execute error: " . $selstmt;
			$sth->finish();
			$message .= "<h3><font color=green>Topic Created.</font></h3>\n";
		}
	}

	return(%form_state);
}

sub lookup_topic {
	my $dbh = $_[0];

	my %form_state = ();
	my $selstmt = "select name, namespace, submitter, one_line, key_words, submit_time from topic where topic_id = $topic_id";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	if (!($rs = $sth->fetchrow_hashref())) {
		$topic_name = 'invalid';
		&display_page('CANONIZER', 'Topic: '. $topic_name, [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}

	$form_state{'topic_name'} = &func::hex_decode($rs->{'NAME'});
	$form_state{'namespace'} = &func::hex_decode($rs->{'NAMESPACE'});
	$form_state{'one_line'} = &func::hex_decode($rs->{'ONE_LINE'});
	$form_state{'key_words'} = &func::hex_decode($rs->{'KEY_WORDS'});
	$form_state{'submit_time'} = $rs->{'key_words'};

	$sth->finish();
	return(%form_state);

}

sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/topic.asp';
	my $present_url = 'topic.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $query_string);
		$query_string =~ s|&?mode=manage||gi;
		$present_url .= ('?' . $query_string);
	}

%>

	<br>

	<h2>You must register and or login before you can manage topics.</h2>
	<center>
	<h2><a href=register.asp>Register</a><h2>
	<h2><a href="<%=$login_url%>">Login</a><h2>
	<h2><a href="<%=$present_url%>">Return to topic presentation page</a></h2>
	</center>
<%
}


sub present_topic {

%>


<br>

<h2>Agreement Statement:</h2>

<h2>Canonizer Sorted Postion (POV) Statements:</h2>

<%
}

sub manage_topic {

	my $present_url = "topic.asp?topic_id=$topic_id";
	my $submit_value = 'Create Topic';
	if ($topic_id) {
		$submit_value = 'Modify Topic';
	}

%>

<br>
<%=$message%>
<br>

<form method=post>
<input type=hidden name=topic_id value=<%=$topic_id%>>
<input type=hidden name=mode value=manage>
<input type=hidden topic_id=<%=$topic_id%>>

<table>
<tr>
  <td><b>Topic Name: <font color = red>*</font> </b></td><td>Mazimum 25 characters.<br>
	<input type=string name=topic_name value="<%=$form_state{'topic_name'}%>" maxlength=25 size=25></td></tr>

  <tr height = 20></tr>

  <td><b>Namespace:</b></td><td>Nothing for main default namespace.  Maximum 65 characters.<br>
	<input type=string name=namespace value="<%=$form_state{'namespace'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

<%
#  <td><b>AKA:</b></td><td>Comma separated - symbolic link created for each one.<br>
#	<input type = string name = AKA maxlength = 255 size = 65></td></tr>
#
#  <tr height = 20></tr>
%>

  <td><b>One Line Description:</b></td><td>Maximum 65 characters.<br>
	<input type=string name=one_line value="<%=$form_state{'one_line'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

  <td><b>Key Words:</b></td><td>Maximum 65 characters, comma seperated.<br>
	<input type=string name=key_words value="<%=$form_state{'key_words'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

</table>

<input type=reset value="Reset">
<input type=submit name=submit value="<%=$submit_value%>">

</form>

<%
}



########
# main #
########

local $message = '';

local $topic_name = "New Topic";

local $topic_id = 0;
if ($Request->Form('toic_id')) {
	$topic_id = $Request->Form('topic_id');
} elsif ($Request->QueryString('topic_id')) {
	$topic_id = $Request->QueryString('topic_id');
}

local $mode = 'present';
if ($Request->Form('mode')) {
	$mode = $Request->Form('mode');
} elsif ($Request->QueryString('mode')) {
	$mode = $Request->QueryString('mode');
}

my %valid_modes = (
	'present' => 1,
	'manage' => 1,
	'discuss' => 1
);


local %form_state = (
	'topic_name' => '',
	'namespace' => '',
	'one_line' => '',
	'key_words' => ''
);

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";	

if ($Session->{'logged_in'} && $Request->Form('submit')) {
	%form_state = &save_topic($dbh);
}

if ($topic_id) {
	if (!$valid_modes{$mode}) {
		$mode = 'present';
	}
} else { # new topic
	$mode = 'manage';
}

if ($topic_id && !$form_state{'topic_name'}) { # lookup topic data.
	%form_state = &lookup_topic($dbh);
}

if ($form_state{'topic_name'}) {
	$topic_name = $form_state{'topic_name'};
}

if ($mode eq 'manage') {
	if ($Session->{'logged_in'}) {
		&display_page('CANONIZER', 'Topic: '. $topic_name, [\&identity, \&search, \&main_ctl], [\&manage_topic], \&tab_sub);
	} else {
		&display_page('CANONIZER', 'Topic: '. $topic_name, [\&identity, \&search, \&main_ctl], [\&must_login], \&tab_sub);
	}
} else {
	&display_page('CANONIZER', 'Topic: '. $topic_name, [\&identity, \&search, \&main_ctl], [\&present_topic], \&tab_sub);
}

%>

