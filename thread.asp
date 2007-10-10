<%

use person;
use statement;


my $error_message = '';

my $path_info = $ENV{'PATH_INFO'};
my $pi_topic_num = 0;
my $pi_statement_num = 0;
my $pi_thread_num = 0;
my $pi_post_num = 0;
if ($path_info =~ m|/(\d+)/(\d+)/(\d+)/?(\d*)|) {
	$pi_topic_num = $1;
	$pi_statement_num = $2;
	$pi_thread_num = $3;
	if ($4) {
		$pi_thread_num = $4;
	}
}

my $topic_num = 0;
if ($Request->Form('topic_num')) {
	$topic_num = int($Request->Form('topic_num'));
} elsif ($pi_topic_num) {
	$topic_num = $pi_topic_num;
} elsif ($Request->QueryString('topic_num')) {
	$topic_num = int($Request->QueryString('topic_num'));
}
if (!$topic_num) {
	$error_message = "Must specify a topic_num.";
	&display_page('Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}


my $statement_num = 0;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($pi_statement_num) {
	$statement_num = $pi_statement_num;
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}
if (!$statement_num) {
	$error_message = "Must specify a statement_num.";
	&display_page('Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $thread_num = 0;
if ($Request->Form('thread_num')) {
	$thread_num = int($Request->Form('thread_num'));
} elsif ($pi_thread_num) {
	$thread_num = $pi_thread_num;
} elsif ($Request->QueryString('thread_num')) {
	$thread_num = int($Request->QueryString('thread_num'));
}
if (!$thread_num) {
	$error_message = "Must specify a thread_num.";
	&display_page('Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}


my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my ($topic_name, $msg) = topic::get_name($dbh, $topic_num);

my $subject = func::get_thread_subject($dbh, $topic_num, $statement_num, $thread_num);

if (length($subject) < 1) {
		$error_message = "Unknown thread for topic_num $topic_num, statement_num: $statement_num, thread_num: $thread_num.";
		&display_page('Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
}

my statement $tree = new_tree statement ($dbh, $topic_num, $statement_num);

my $header = "Topic: $topic_name<br>\nStatement: " . $tree->make_statement_path() . "<br>\nCamp Forum Thread: $subject\n";


&display_page($header, [\&identity, \&search, \&main_ctl], [\&display_thread]);


########
# subs #
########

sub display_thread {
	%>
	<div class="main_content_container">

	<p><a href="/topic.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Return to camp statement page</a></p>

	<p><a href="/forum.asp/<%=$topic_num%>/<%=$statement_num%>">Return to camp forum</a></p>

	<p><a href="/secure/email_camp.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&thread_num=<%=$thread_num%>">New post to thread</a></p>
	<%

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $min_max = 'max';		 # set to min for static ordered page from first thread.
	my $first_last = 'Last post by'; # set to first post by for static page.

	my $selstmt = "select nick_id, message, submit_time from post where topic_num=$topic_num and statement_num=$statement_num and thread_num=$thread_num";

	my $posts = 0;
	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	while ($rs = $sth->fetchrow_hashref()) {
		if (! $posts) {
			%>
			<table class=forum_table>
			<%
		}
		$posts++;

		my $nick_name = func::get_nick_name($dbh, $rs->{'nick_id'});
		my $message = $rs->{'message'};
		my $submit_time = $rs->{'submit_time'};
		%>
		<tr><td class=header colspan=2><%=func::to_local_time($submit_time)%></td></tr>
		<tr><td valign=top><br><br><br><%=$nick_name%></td><td><%=func::wikitext_to_html($message)%></td></tr>
		<tr><td class=separator colspan=2></td></tr>
		<%
	}
	$sth->finish();

	if ($posts) {
		%>
		</table>
		<p><a href="/topic.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Return to camp statement page</a></p>

		<p><a href="/forum.asp/<%=$topic_num%>/<%=$statement_num%>">Return to camp forum</a></p>

		<p><a href="/secure/email_camp.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&thread_num=<%=$thread_num%>">New post to thread</a></p>

		<%
	} else {
		%>
		<h1>No post made to this thread yet.</h1>
		<%
	}
	%>
	</div>
	<%
}

%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/must_login.asp"-->
<!--#include file = "includes/error_page.asp"-->
