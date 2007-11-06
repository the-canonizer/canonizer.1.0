<%

use person;
use statement;

my $num_posts_per_page = 10;

my $error_message = '';

my $path_info = $ENV{'PATH_INFO'};
my $pi_topic_num = 0;
my $pi_statement_num = 0;
my $pi_thread_num = 0;
my $pi_post_num = 0;			# optional to specify what page.
if ($path_info =~ m|/(\d+)/(\d+)/(\d+)/?(\d*)|) {
	$pi_topic_num = $1;
	$pi_statement_num = $2;
	$pi_thread_num = $3;
	if ($4) {
		$pi_post_num = $4;
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
	&display_page('Camp Forum Thread', 'Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
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
	&display_page('Camp Forum Thread', 'Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
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
	&display_page('Camp Forum Thread', 'Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $post_num = 0; # optional value to specify page of thread.
if ($Request->Form('post_num')) {
	$post_num = int($Request->Form('post_num'));
} elsif ($pi_post_num) {
	$post_num = $pi_post_num;
} elsif ($Request->QueryString('post_num')) {
	$post_num = int($Request->QueryString('post_num'));
}


my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my ($topic_name, $msg) = topic::get_name($dbh, $topic_num);

my $subject = func::get_thread_subject($dbh, $topic_num, $statement_num, $thread_num);

if (length($subject) < 1) {
		$error_message = "Unknown thread for topic_num $topic_num, statement_num: $statement_num, thread_num: $thread_num.";
		&display_page('Camp Forum Thread', 'Camp Forum Thread', [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
}

my statement $tree = new_tree statement ($dbh, $topic_num, $statement_num);

my $topic_camp = 'Camp';
if ($statement_num == 1) {
	$topic_camp = 'Topic';
}

my $title = "Topic: $topic_name Statement: " . $tree->{statement_name} . " - $topic_camp Forum Thread: $subject\n";

my $header .= '<table><tr><td class="label">Topic:</td>' .
				'<td class="topic">' . $topic_name . "</td></tr>\n" .
			    '<tr><td class="label">Statement:</td>' .
			        '<td class="statement">' . $tree->make_statement_path() . "</td></tr>\n" .
			    '<tr><td class="label">' . $topic_camp . ' Forum Thread:</td>' .
			        '<td class="statement">' . $subject . "</td></tr>\n" .
	      "</table>\n";


&display_page($title, $header, [\&identity, \&search, \&main_ctl], [\&display_thread]);


########
# subs #
########

sub display_thread {
	%>
	<div class="main_content_container">

	<p><a href="/topic.asp/<%=$topic_num%>/<%=$statement_num%>">Return to <%=$statement_num==1 ? 'agreement' : 'camp'%> statement page</a></p>

	<p><a href="/forum.asp/<%=$topic_num%>/<%=$statement_num%>">Return to <%=$statement_num==1 ? 'topic' : 'camp'%> forum</a></p>

	<p><a href="/secure/email_camp.asp/<%=$topic_num%>/<%=$statement_num%>/<%=$thread_num%>">New post to thread</a></p>
	<%

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $min_max = 'max';		 # set to min for static ordered page from first thread.
	my $first_last = 'Last post by'; # set to first post by for static page.

	my $selstmt = "select post_num, nick_id, message, submit_time from post where topic_num=$topic_num and statement_num=$statement_num and thread_num=$thread_num";

	my @posts = ();
	my $num_posts = 0;
	my $start_post = 0;
	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;

	while ($rs = $sth->fetchrow_hashref()) {
		$posts[$num_posts] = {'nick_name'   => func::get_nick_name($dbh, $rs->{'nick_id'}),
				      'message'     => $rs->{'message'},
				      'submit_time' => $rs->{'submit_time'},
				      'post_num'    => $rs->{'post_num'}       };
		if ($rs->{'post_num'} eq $post_num) {
			$start_post = int($num_posts / $num_posts_per_page) * $num_posts_per_page;
		}
		$num_posts++;
	}
	$sth->finish();

	if ($num_posts) {
		if ($num_posts > $num_posts_per_page) {
			%>
			<p>Thread Page: <%=make_pagination_str($start_post, $num_posts, \@posts)%></p>
			<%
		}
		%>
		<table class=forum_table>
		<%
	}

	my $print_post;
	for ($print_post = 0; $print_post < $num_posts; $print_post++) {
		next if $print_post < $start_post;
		last if $print_post >= ($start_post + $num_posts_per_page);
		my $post_ref = $posts[$print_post];
		%>
		<tr><td class=header><%=$post_ref->{'nick_name'}%></td><td class=header align=right><%=func::to_local_time($post_ref->{'submit_time'})%></td></tr>
		<tr><td colspan=2><%=func::wikitext_to_html($post_ref->{'message'})%></td></tr>
		<tr><td class=header><%=$post_ref->{'nick_name'}%></td><td class=header align=right><%=func::to_local_time($post_ref->{'submit_time'})%></td></tr>
		<tr><td class=separator colspan=2><a name="<%=($post_ref->{'post_num'} + 1)%>"></td></tr>
		<%
	}

	if ($num_posts) {
		%>
		</table>
		<p><a href="/topic.asp/<%=$topic_num%>/<%=$statement_num%>">Return to camp statement page</a></p>

		<p><a href="/forum.asp/<%=$topic_num%>/<%=$statement_num%>">Return to camp forum</a></p>

		<p><a href="/secure/email_camp.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&thread_num=<%=$thread_num%>">New post to thread</a></p>

		<%

		if ($num_posts > $num_posts_per_page) {
			%>
			<p>Thread Page: <%=make_pagination_str($start_post, $num_posts, \@posts)%></p>
			<%
		}
	} else {
		%>
		<h1>No post made to this thread yet.</h1>
		<%
	}
	%>
	</div>
	<%
}


sub make_pagination_str {
	my $post_num  = $_[0];
	my $num_posts = $_[1];
	my $posts_ref = $_[2];

	my $ret_val = '<span id="pagination">';

	my $num;
	for ($num = 0; ($num * $num_posts_per_page) < $num_posts; $num++) {
		if (($num * $num_posts_per_page) == $post_num) {
			$ret_val .= '<font color=green>' . ($num + 1) . '</font>, ';
		} else {
			$ret_val .= '<a href="http://' . func::get_host() . "/thread.asp/$topic_num/$statement_num/$thread_num/" . $posts_ref->[($num * $num_posts_per_page)]->{'post_num'} . '">' . ($num + 1) . '</a>, ';
		}
	}

	chop($ret_val);
	chop($ret_val);
	$ret_val .= ".</span>";

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
