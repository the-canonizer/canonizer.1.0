<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

use topic_class;
use statement_class;

use history_class;


sub unknown_topic_num_page {

	if ($topic_num) {
		%>
		<br>
		<h1>Unknown Topic Number:&nbsp;<%=$topic_num%>.</h1>
		<%
	} else {
		%>
		<br>
		<h1>No topic number specified.</h1>
		<%
	}
}


sub manage_record {
	$history->print_history($dbh);
}



########
# main #
########

local $topic_num = '';
if ($Request->Form('topic_num')) {
	$topic_num = int($Request->Form('topic_num'));
} elsif ($Request->QueryString('topic_num')) {
	$topic_num = int($Request->QueryString('topic_num'));
}


if (!$topic_num) {
	&display_page('<font size=5>Manage Statement:</font><br>'. $topic_num, [\&identity, \&search, \&main_ctl], [\&unknown_topic_num_page]);
	$Response->End();
}

local $statement_num = 1; # default statement value
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}



local $dbh = &func::dbh_connect(1) || die "unable to connect to database";

local $history = history_class->new($dbh, 'statement_class', {'topic_num' => $topic_num, 'statement_num' => $statement_num});

if ($history->{active} == 0) {
	&display_page('<font size=5>Manage Statement:</font><br>' . $history->{active}->{name}, [\&identity, \&search, \&main_ctl], [\&unknown_topic_num_page]);
	$Response->End();
}


&display_page('<font size=5>Manage Statement:</font><br>' . $history->{active}->{name}, [\&identity, \&search, \&main_ctl], [\&manage_record]);


%>
