<%

use person;
use statement;

if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . &func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}

my $destination;

if (!$Session->{'logged_in'}) {
	$destination = '/secure/email_camp.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	&display_page('Send E-Mail to camp', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}


my $topic_num = 0;
if ($Request->Form('topic_num')) {
	$topic_num = int($Request->Form('topic_num'));
} elsif ($Request->QueryString('topic_num')) {
	$topic_num = int($Request->QueryString('topic_num'));
}

my $error_message = '';


if (!$topic_num) {
	$error_message = "Must specify a topic_num.";
	&display_page('Send E-Mail to camp', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}


my $statement_num = 1; # 1 is the default ageement statement;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my ($topic_name, $msg) = topic::get_name($dbh, $topic_num);

my statement $tree = new_tree statement ($dbh, $topic_num, $statement_num);

my $header = "Send E-Mail to camp<br>\nTopic: $topic_name - Statement: " . $tree->make_statement_path();


if ($Request->Form('submit_edit')) {
	&display_page($header, [\&identity, \&search, \&main_ctl], [\&email_sent_page]);
} else {
	&display_page($header, [\&identity, \&search, \&main_ctl], [\&email_camp_form]);
}


########
# subs #
########

sub email_camp_form {

	my $error_messasge = '';

	my %nick_names = func::get_nick_name_hash($Session->{'cid'}, $dbh);
	if ($nick_names{'error_message'}) {
		%>
		Error: <%=$nick_names{'error_message'}%>
		<%
	} else {
		%>

		<p><a href="/topic.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Return to statement</a></p>

		<form method=post>

		<p>Send e-mail to all direct supporters of this camp (including all sub camps)</p>

		<p>Subject: <input type=string name=subject maxlength=65 size=65></p>

		<p>Message:<br>
		<textarea NAME="message" ROWS="20" COLS="65"></textarea></p>

		<p>Attribution Nick Name:</p>

		<p><select name="sender">
		<%
		my $id;
		foreach $id (sort {$a <=> $b} (keys %nick_names)) {
			%>
			<option value="<%=$nick_names{$id}%>"><%=$nick_names{$id}%></option>
			<%
		}
		%>
		</select></p>

		<p><input type=reset value="Reset">
		   <input type=submit name=submit_edit value="send e-mail"></p>

		</form>
		<%
	}
}


sub email_sent_page {

	my %support_hash = ();
	$tree->get_support($dbh, \%support_hash);

	if (!$support_hash{$Session->{'cid'}}) { # sender should get a copy.
		$support_hash{$Session->{'cid'}} = 1;
	}

	if (!$support_hash{1}) { # and brent gets a copy, for now.
		$support_hash{1} = 1;
	}

	my $sender_nick_name = $Request->Form('sender');
	if (length($sender_nick_name) > 0) {

		my $message = $sender_nick_name . " has sent this message\n" .
			"to all the supporters of the $tree->{topic_name} statement on the topic: $topic_name.\n\n" .
			$Request->Form('message') .
			"\n\n\n" .
			"Please report any abuse to support@canonizer.com.\n";

		person::send_email_to_hash($dbh, \%support_hash, $Request->Form('subject'), $message);

		%>
		<p>Mail Successfully sent to supporters of this camp.

		<p><a href="/topic.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Return to statement</a></p>
		<%
	} else {

		%>
		Error: invalid sender.
		<%
	}
}


%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/must_login.asp"-->
<!--#include file = "includes/error_page.asp"-->
