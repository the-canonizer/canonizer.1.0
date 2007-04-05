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
<!--#include file = "includes/must_login.asp"-->

<%

local $message = '';

sub support_error {
%>
	<br>
	<br>
	<h1><font color=red><%=$message%></font></h1>
	<br>
	<br>
<%
}


########
# main #
########

local $destination = '';

if (!$Session->{'logged_in'}) {
	$destination = '/secure/support.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	&display_page('Edit', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $topic_num = 0;
if ($Request->Form('topic_num')) {
	$topic_num = int($Request->Form('topic_num'));
} elsif ($Request->QueryString('topic_num')) {
	$topic_num = int($Request->QueryString('topic_num'));
}

local $statement_num = 1; # 1 is the default ageement statement;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
}

local $message = "Not yet implemented ($topic_num:$statement_num)";

if ($message) {
	&display_page('Support Error', [], [\&support_error]);
} else {
	$Response->Redirect('http://' . &func::get_host() . "/topic.asp?=$topic_num&statement_num=$statement_num");
}

%>

