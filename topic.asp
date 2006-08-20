
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/topic_tabs.asp"-->

<%

#
#	present a topic
#

sub error_page {
	%>
	<h1>Error: Unkown Topic number: <%=$num%>.</h1>
	<%
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
		&display_page('<font size=5>Topic:</font><br>'. $topic_name, [\&identity, \&search, \&main_ctl], [\&error_page]);
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

One Line Descriton:<br>
<font size=4><%=$topic_rec{'one_line'}%></font>

<h2>Agreement Statement:</h2>

<h2>Canonizer Sorted Postion (POV) Statements:</h2>

<%
}



########
# main #
########

local $topic_name = '';

local $num = 0;
if ($Request->Form('number')) {
	$num = int($Request->Form('number'));
} elsif ($Request->QueryString('number')) {
	$num = int($Request->QueryString('number'));
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";


my $selstmt = 'select name, namespace, one_line, submitter, go_live_time, replacement, objector, object_time, object_reason from topic where replacement is null and proposed = 0 and num = ' . $num;

my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;

$sth->execute() || die "Failed to execute " . $selstmt;

my $rs = $sth->fetchrow_hashref();

local %topic_rec;

if (! $rs) {
	&display_page('Unknown Topic Number', [\&identity, \&search, \&main_ctl], [\&error_page]);
} else {

	$topic_rec{'name'} = $rs->{'NAME'};
	$topic_rec{'namespace'} = $rs->{'NAMESPACE'};
	$topic_rec{'one_line'} = $rs->{'ONE_LINE'};
	$topic_rec{'submitter'} = $rs->{'SUBMITTER'};
	$topic_rec{'go_live_time'} = $rs->{'GO_LIVE_TIME'};
	$topic_rec{'replacement'} = $rs->{'REPLACEMENT'};
	$topic_rec{'objector'} = $rs->{'OBJECTOR'};
	$topic_rec{'object_time'} = $rs->{'OBJECT_TIME'};
	$topic_rec{'object_reason'} = $rs->{'OBJECT_REASON'};

	&display_page('<font size=5>Topic:</font><br>' . $topic_rec{'name'}, [\&identity, \&search, \&main_ctl], [\&present_topic], \&topic_tabs);
}

%>

