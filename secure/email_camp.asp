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

my $dest_args = '';

if ($path_info) {
	$dest_args = $path_info;
}

if ($ENV{'QUERY_STRING'}) {
	$dest_args .= ('?' . $ENV{'QUERY_STRING'});
}


if (!$ENV{"HTTPS"}) {
        $Response->Redirect('https://' . func::get_host() . $ENV{"SCRIPT_NAME"} . $dest_args);
}

my $destination;

if (!$Session->{'logged_in'}) {
	$destination = '/secure/email_camp.asp' . $dest_args;
	display_page('Send E-Mail to camp', 'Send E-Mail to camp', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}


my $error_message = '';


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
	display_page('Send E-Mail to camp', 'Send E-Mail to camp', [\&identity, \&search, \&main_ctl], [\&error_page]);
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

my $thread_num = 0; # 1 is the default ageement statement;
if ($Request->Form('thread_num')) {
	$thread_num = int($Request->Form('thread_num'));
} elsif ($pi_thread_num) {
	$thread_num = $pi_thread_num;
} elsif ($Request->QueryString('thread_num')) {
	$thread_num = int($Request->QueryString('thread_num'));
}

my $dbh = func::dbh_connect(1) || die "unable to connect to database";

my ($topic_name, $msg) = topic::get_name($dbh, $topic_num);



my statement $tree = new_tree statement ($dbh, $topic_num, $statement_num);

my $topic_camp = 'Camp';
if ($statement_num == 1) {
	$topic_camp = 'Topic';
}

my $subject = '';

my $subject_line = '';
if ($Request->Form('canon_subject')) {
	$subject = $Request->Form('canon_subject');
	$subject_line = '<tr><td class="label">' . $topic_camp . ' Forum Thread:</td>' .
			'<td class="statement">' . $subject    . "</td></tr>\n";
} elsif ($thread_num) {
	$subject = func::get_thread_subject($dbh, $topic_num, $statement_num, $thread_num);
	$subject_line = '<tr><td class="label">' . $topic_camp . ' Forum Thread:</td>' .
			'<td class="statement">' . $subject . "</td></tr>\n";
}


my $title = "Topic: $topic_name Statement: " . $tree->make_statement_path();


my $header .= '<table><tr><td class="label">Topic:</td>' .
				'<td class="topic">' . $topic_name . "</td></tr>\n" .
			    '<tr><td class="label">Statement:</td>' .
			        '<td class="statement">' . $tree->make_statement_path() . "</td></tr>\n" .
			    $subject_line .
	      "</table>\n";


my $message = '';
if (length($Request->Form('canon_message')) >0) {
	$message = $Request->Form('canon_message');
}

if ($Request->Form('preview_post')) {
	if (length($message) < 1) {
		$error_message .= "No message supplied.<br>\n";
	}
	if (! $thread_num) {
		if (length($subject) < 1) {
			$error_message .= "No subject supplied.<br>\n";
		}
	}
	if (! $error_message) {
		display_page($title, $header, [\&identity, \&search, \&main_ctl], [\&preview_post_page]);
		$Response->End();
	}

} elsif ($Request->Form('submit_post')) {
	if (length($message) < 1) {
		$error_message .= "No message supplied.<br>\n";
	}
	if (! $thread_num) {
		if (length($subject) < 1) {
			$error_message .= "No subject supplied.<br>\n";
		}
	}
	if (! $error_message) {
		display_page($title, $header, [\&identity, \&search, \&main_ctl], [\&send_email_page]);
		$Response->End();
	}
}

if (length(message) > 0) { # re editing from preview
	$message = func::hex_decode($message);
}


display_page($title, $header, [\&identity, \&search, \&main_ctl], [\&email_camp_form]);



########
# subs #
########

sub email_camp_form {

	my $subject_disable_str = '';
	if ($thread_num) {
		$subject_disable_str = 'disabled';
	}

	my %nick_names = func::get_nick_name_hash($Session->{'cid'}, $dbh);
	if ($nick_names{'error_message'}) {
		%>
		Error: <%=$nick_names{'error_message'}%>
		<%
	} else {
		%>

		<p><a href="http://<%=func::get_host()%>/topic.asp/<%=$topic_num%>/<%=$statement_num%>">Return to statement</a></p>

		<%
		if ($error_message) {
		%>
			<p><font color=red><%=$error_message%></font></p>
		<%
		}
		%>

		<form method=post>
		<%
		if ($thread_num) {
			%>
			<input type=hidden name=thread_num value=<%=$thread_num%>>
			<%
		}
		%>

		<p>Send e-mail to all direct supporters of this camp (including all sub camps)</p>

		<p>Subject: <input type=string name=canon_subject maxlength=65 size=65 value="<%=func::escape_double($subject)%>" <%=$subject_disable_str%>></p>

		<p>Message:<br>
		<textarea NAME="canon_message" ROWS="20" COLS="65"><%=$message%></textarea></p>

		<p>Attribution Nick Name:</p>

		<p><select name="canon_sender">
		<%
		my $id;
		foreach $id (sort {$a <=> $b} (keys %nick_names)) {
			%>
			<option value="<%=$id%>,<%=$nick_names{$id}%>"><%=$nick_names{$id}%></option>
			<%
		}
		%>
		</select></p>

		<p><input type=reset value="Reset">
		   <input type=submit name=preview_post value="Preview post"></p>
		</form>
		<%
	}
}


sub preview_post_page {

	my $sender_nick_name = $Request->Form('canon_sender');
	$sender_nick_name =~ s|(\d*),||;
	my $sender_nick_id = $1;

	my $now_time = time;

	%>
	<div class="main_content_container">

	<p><a href="/topic.asp/<%=$topic_num%>/<%=$statement_num%>">Return to <%=$statement_num==1 ? 'agreement' : 'camp'%> statement page</a></p>

	<p><a href="/forum.asp/<%=$topic_num%>/<%=$statement_num%>">Return to <%=$statement_num==1 ? 'topic' : 'camp'%> forum</a></p>

	<center>
	<h1><b>Preview Post</b></h1>

	<form method=post>
		<input type=hidden name=canon_subject value="<%=$subject%>">
		<input type=hidden name=canon_sender  value="<%=$sender_nick_id%>,<%=$sender_nick_name%>">
		<input type=hidden name=canon_message value="<%=func::hex_encode($message)%>">
		<input type=submit name=edit_post value="Edit post">
		<input type=submit name=submit_post value="Send e-mail">
	</form>
	</center>
	<br>

	<table class=forum_table>
	<tr><td class=header><%=$sender_nick_name%></td><td class=header align=right><%=func::to_local_time($now_time)%></td></tr>
	<tr><td colspan=2><%=func::wikitext_to_html($message)%></td></tr>

	<tr><td class=header><%=$sender_nick_name%></td><td class=header align=right><%=func::to_local_time($now_time)%></td></tr>
	</table>
	</div>
	<%
}


sub send_email_page {

	my %support_hash = ();
	$tree->get_support($dbh, \%support_hash);

	if (!$support_hash{$Session->{'cid'}}) { # sender should get a copy.
		$support_hash{$Session->{'cid'}} = 1;
	}

	if (!$support_hash{1}) { # and brent gets a copy, for now.
		$support_hash{1} = 1;
	}

	my $sender_nick_name = $Request->Form('canon_sender');
	$sender_nick_name =~ s|(\d*),||;
	my $sender_nick_id = $1;

	if ($sender_nick_id and length($sender_nick_name) > 0) {

		$thread_num = save_post($dbh, $subject, $message, $topic_num, $statement_num, $thread_num, $sender_nick_id);

		$message = func::wikitext_to_text($message);
		# $message = func::wikitext_to_html($message);  # you've somehow got to set the mime type if you want this.

		$message = $sender_nick_name . " has sent this message " .
			"to all the supporters of the $tree->{statement_name} camp on the topic: $topic_name.\n\n" .
			"Rather than reply to this e-mail (which only goes to canonizer\@canonizer.com) " .
			"please post all replies to the camp forum thread page this message was sent from here:\n" .
			"http://" . func::get_host() . "/thread.asp/$topic_num/$statement_num/$thread_num" .
			"\n\n\n----------------------------------" .
			"\n\n" .
			$message .
			"\n\n----------------------------------" .
			"\n\n" .
			"Please report any abuse to support\@canonizer.com.\n";

		person::send_email_to_hash($dbh, \%support_hash, $subject, $message);
		# person::send_email_to_cid($dbh, 1, $subject, $message); # for debugging.

		%>
		<p>Mail successfully sent to supporters of this camp.

		<p><a href="/topic.asp/<%=$topic_num%>/<%=$statement_num%>">Return to statement</a></p>
		<%
	} else {
		%>
		Error: invalid sender.
		<%
	}
}


sub save_post {
	my $dbh            = $_[0];
	my $subject        = $_[1];
	my $message        = $_[2];
	my $topic_num      = $_[3];
	my $statement_num  = $_[4];
	my $thread_num     = $_[5];
	my $sender_nick_id = $_[6];

	my $selstmt;

	my %dummy = ();

	if (!$thread_num) {
		my $thread_id = func::get_next_id($dbh, 'thread', 'thread_id');
		$thread_num = func::get_next_id($dbh, 'thread', 'thread_num', "where topic_num=$topic_num and statement_num = $statement_num");

		$selstmt = 'insert into thread ( thread_id,  thread_num,  topic_num,  statement_num, subject) values ' .
					      "($thread_id, $thread_num, $topic_num, $statement_num, ?      )";

		if (! $dbh->do($selstmt, \%dummy, $subject)) {
			%>
			<h1><font color=red>Error: Failed to save thread in DB.</font></h1>
			<%
			$Response->End();
		}
	}

	my $post_id = func::get_next_id($dbh, 'post', 'post_id');
	my $post_num = func::get_next_id($dbh, 'post', 'post_num', "where topic_num=$topic_num and statement_num=$statement_num and thread_num=$thread_num");
	my $now_time = time;

	$selstmt = 'insert into post ( post_id,  post_num,  thread_num,  topic_num,  statement_num, nick_id,         submit_time, message) values ' .
				    "($post_id, $post_num, $thread_num, $topic_num, $statement_num, $sender_nick_id, $now_time,   ?      )";

	if (! $dbh->do($selstmt, \%dummy, $message)) {
			%>
			<h1><font color=red>Error: Failed to save post in DB.</font></h1>
			<%
			$Response->End();
	}
	return($thread_num);
}


%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/must_login.asp"-->
<!--#include file = "includes/error_page.asp"-->
