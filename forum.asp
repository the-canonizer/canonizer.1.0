<%

my $num_posts_per_page = 10;

use person;
use statement;

my $path_info = $ENV{'PATH_INFO'};
my $pi_topic_num = 0;
my $pi_statement_num = 0;
my $pi_thread_num = 0;			# optional to specify what page.
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
	&display_page('Camp Forum', 'Camp Forum', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}


my $statement_num = 1; # 1 is the default ageement statement;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($pi_statement_num) {
	$statement_num = $pi_statement_num;
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my ($topic_name, $msg) = topic::get_name($dbh, $topic_num);

my statement $tree = new_tree statement ($dbh, $topic_num, $statement_num);

my $topic_camp = 'Camp';
if ($statement_num == 1) {
	$topic_camp = 'Topic';
}

my $title = "Topic: $topic_name - Statement: " . $tree->make_statement_path() . "$topic_camp Forum\n";

my $header .= '<table><tr><td class="label">Topic:</td>' .
				'<td class="topic">' . $topic_name . "</td></tr>\n" .
		     '<tr><td class="label">Statement:</td>' .
			 '<td class="statement">' . $tree->make_statement_path() . "</td></tr>\n" .
		     '<tr><td class="forum" colspan=2>' . $topic_camp . " Forum</td></tr>\n" .
	      "</table>\n";


&display_page($title, $header, [\&identity, \&search, \&main_ctl], [\&display_forum]);


########
# subs #
########

sub display_forum {
	%>
	<div class="main_content_container">

	<p><a href="/topic.asp/<%=$topic_num%>/<%=$statement_num%>">Return to camp statement page</a></p>

	<p><a href="/secure/email_camp.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Start new thread</a></p>
	<%

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $min_max = 'max_time';		 # set to min_time for static ordered page from first thread.

	my $selstmt = <<EOF;
select t.thread_num, min_post_num, min_nick_id, min_time, max_post_num, max_nick_id, max_time, subject, count from

(select a.thread_num, a.post_num as min_post_num, a.nick_id as min_nick_id, a.submit_time as min_time, z.post_num as max_post_num, z.nick_id as max_nick_id, z.submit_time as max_time from

(select p.post_num, p.nick_id, p.thread_num, p.submit_time from
(select thread_num, min(submit_time) as submit_time from post where topic_num = $topic_num and statement_num = $statement_num group by thread_num) b,
post p where topic_num=$topic_num and statement_num=$statement_num and p.thread_num=b.thread_num and p.submit_time = b.submit_time) a, 

(select p.post_num, p.nick_id, p.thread_num, p.submit_time from
(select thread_num, max(submit_time) as submit_time from post where topic_num = $topic_num and statement_num = $statement_num group by thread_num) y,
post p where topic_num=$topic_num and statement_num=$statement_num and p.thread_num=y.thread_num and p.submit_time = y.submit_time) z

where a.thread_num = z.thread_num) t,

(select t.subject, t.thread_num, p.count from thread t,
(select thread_num, count(*) as count from post p where topic_num=$topic_num and statement_num=$statement_num group by thread_num) p
where t.topic_num = $topic_num and statement_num = $statement_num and t.thread_num = p.thread_num) c

where t.thread_num = c.thread_num order by $min_max desc
EOF

	my $threads = 0;
	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	while ($rs = $sth->fetchrow_hashref()) {
		my $thread_num = $rs->{'thread_num'};
		if (! $threads) {
			%>
			<table class=forum_table>
			<tr><td class=header>Thread Subject</td><td class=header>Posts</td><td class=header>&nbsp;</td><tr>
			<%
		}
		$threads++;

		my $subject = $rs->{'subject'};
		my $count  = $rs->{'count'};
		my $min_nick_name = func::get_nick_name($dbh, $rs->{'min_nick_id'});
		my $min_time = $rs->{'min_time'};
		my $pagination = '';
		my $max_post_num = $rs->{'max_post_num'};
		if ($count > $num_posts_per_page) {
			$pagination = make_pagination_str($thread_num, $count);
		}
		my $post_url = 'http://' . func::get_host() . "/thread.asp/$topic_num/$statement_num/$thread_num";

		my $last_post_str = '';
		if ($count > 1) {
			my $max_nick_name = func::get_nick_name($dbh, $rs->{'max_nick_id'});
			my $max_time = $rs->{'max_time'};
			$last_post_str = "<hr>Last post: &nbsp; &nbsp; &nbsp;<a href=\"$post_url/$max_post_num#$max_post_num\">$max_nick_name<br>" .
				func::to_local_time($max_time) . "</a>\n";
		}

		%>
		<tr><td><%=$subject%><%=$pagination%></td><td><%=$count%></td><td nowrap>First post: &nbsp; &nbsp; &nbsp;<a href=\"$post_url\"><%=$min_nick_name%><br>
				<%=func::to_local_time($min_time)%></a><%=$last_post_str%></td></tr>
		<%
	}
	$sth->finish();

	if ($threads) {
		%>
		<tr><td class=header>Thread Subject</td><td class=header>Posts</td><td class=header>&nbsp;</td><tr>
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


sub make_pagination_str {
	my $thread_num = $_[0];
	my $num_posts  = $_[1];

	my $ret_val = '<br><br>&nbsp; &nbsp; Pages: ';

	my $num;
	for ($num = 0; ($num * $num_posts_per_page) < $num_posts; $num++) {
		$ret_val .= '<a href="http://' . func::get_host() . "/thread.asp/$topic_num/$statement_num/$thread_num/" . ($num * $num_posts_per_page + 1) . '">' . ($num + 1) . '</a>, ';
	}

	chop($ret_val);
	chop($ret_val);

	return($ret_val);
}





%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/must_login.asp"-->
<!--#include file = "includes/error_page.asp"-->
