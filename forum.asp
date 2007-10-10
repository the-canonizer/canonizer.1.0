<%

use person;
use statement;

my $path_info = $ENV{'PATH_INFO'};
my $pi_topic_num = 0;
my $pi_statement_num = 0;
my $pi_thread_num = 0;
if ($path_info =~ m|/(\d+)/(\d+)/?(\d*)|) {
	$pi_topic_num = $1;
	$pi_statement_num = $2;
	if ($3) {
		$pi_thread_num = $3;
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

my $error_message = '';


if (!$topic_num) {
	$error_message = "Must specify a topic_num.";
	&display_page('Camp Forum', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}


my $statement_num = 1; # 1 is the default ageement statement;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($pi_thread_num) {
	$statement_num = $pi_statement_num;
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my ($topic_name, $msg) = topic::get_name($dbh, $topic_num);

my statement $tree = new_tree statement ($dbh, $topic_num, $statement_num);

my $header = "Topic: $topic_name<br>Statement: " . $tree->make_statement_path() . "<br>Camp Forum\n";

&display_page($header, [\&identity, \&search, \&main_ctl], [\&display_forum]);


########
# subs #
########

sub display_forum {
	%>
	<div class="main_content_container">

	<p><a href="/topic.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Return to camp statement page</a></p>

	<p><a href="/secure/email_camp.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Start new thread</a></p>
	<%

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $min_max = 'max';		 # set to min for static ordered page from first thread.
	my $first_last = 'Last post by'; # set to first post by for static page.

	my $selstmt = "select subject, nick_id, p.thread_num, p.count, p.submit_time from thread t, (select thread_num, nick_id, count(*) as count, $min_max(submit_time) as submit_time from post where topic_num=$topic_num and statement_num=$statement_num group by thread_num) p where t.thread_num = p.thread_num order by p.submit_time desc";

	my $threads = 0;
	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	while ($rs = $sth->fetchrow_hashref()) {
		my $thread_num = $rs->{'thread_num'};
		if (! $threads) {
			%>
			<table class=forum_table>
			<tr><th>Subject</th><th>Posts</td><th><%=$first_last%></th><tr>
			<%
		}
		$threads++;

		my ($nick_name) = func::get_nick_name($dbh, $rs->{'nick_id'});
		my $subject = $rs->{'subject'};
		my $submit_time = $rs->{'submit_time'};
		my $count  = $rs->{'count'};
		%>
		<tr><td><a href="http://<%=func::get_host()%>/thread.asp/<%=$topic_num%>/<%=$statement_num%>/<%=$thread_num%>"><%=$subject%></a></td><td><%=$count%></td><td nowrap><%=$nick_name%><br><%=func::to_local_time($submit_time)%></td></tr>
		<%
	}
	$sth->finish();

	if ($threads) {
		%>
		</table>
		<%
	} else {
		%>
		<h1>No threads started yet in this camp</h1>
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
