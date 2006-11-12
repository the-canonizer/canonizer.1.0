
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->

<%

#
#	present a topic with a statement (default agreement statement)
#	?topic_num=#[&statement_num=#]
#
#	optional specification of long/short text:
#	&long_short=#
#		0	short only (default)
#		1	long only
#		2	both long and short
#

use managed_record;
use topic;
use statement;
use text;


sub error_page {
	%>
	<h1>Error: Unkown Topic Reference (<%=$topic_num%>:<%=$statement_num%>).</h1>
	<%
}


sub lookup_topic_data {
	my $topic_num     = $_[0];
	my $statement_num = $_[1];
	my $long_short    = $_[2];

	my $error_message = '';
	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";
	# ???? is this the right place for this?
	$dbh->{LongReadLen} = 1000000; # what and where should this really be ????

	my topic $topic = new_topic_num topic ($dbh, $topic_num);
	if ($topic->{error_message}) {
		$error_message .= $topic->{error_message};
	}

	my statement $statement = new_tree statement ($dbh, $topic_num, $statement_num);
	if ($statement->{error_message}) {
		$error_message .= $statement->{error_message};
	}

	my text $short_text = 0;
	if ($long_short == 0 || $long_short == 2) {
		$short_text = new_num text ($dbh, $topic_num, $statement_num, 0); # 0 -> short text;
		if ($short_text->{error_message}) {
			$short_text = 0;
		}
	}

	my text $long_text = 0;
	if ($long_short == 1 || $long_short == 2) {
		$long_text = new_num text ($dbh, $topic_num, $statement_num, 1); # 1 -> long text;
		if ($long_text->{error_message}) {
			$long_text = 0;
		}
	}

# I may want to convert back to something like this old way some day, since it reduced the number of DB queries by one...
#	$selstmt = "select value, text_size from text where topic_num=$topic_num and statement_num=$statement_num and proposed = 0 and replacement is null";
#	$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
#	$sth->execute() || die "Failed to execute " . $selstmt;
#	while ($rs = $sth->fetch()) {
#		if ($rs->[1] == 1) { # long text
#			if ($topic_data->{'long_text'}) {
#				print(STDERR "Warning evidently topic $topic_num and statement $statement_num has more than one active long text record.\n");
#			}
#			$topic_data->{'long_text'} = $rs->[0];
#		} else { # short text
#			if ($topic_data->{'short_text'}) {
#				print(STDERR "Warning evidently topic $topic_num and statement $statement_num has more than one active short text record.\n");
#			}
#			$topic_data->{'short_text'} = $rs->[0];
#		}
#	}

	my $topic_data = {
		'topic'		=> $topic,
		'statement'	=> $statement,
		'short_text'	=> $short_text,
		'long_text'	=> $long_text,
		'error_message'	=> $error_message
	} ;

	return($topic_data);
}


sub present_topic {

	my $short_sel_str = '';
	my $long_sel_str = '';
	my $long_short_sel_str = '';

	if ($long_short == 0) {
		$short_sel_str = 'selected';
	} elsif ($long_short == 1) {
		$long_sel_str = 'selected';
	} elsif ($long_short == 2) {
		$long_short_sel_str = 'selected';
	}

	%>

	<script language:javascript>
	function change_long_short(val) {
		var location_str = "topic.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>";
		if (val == 2) {
			location_str += "&long_short=2";
		} else if (val == 1) {
			location_str += "&long_short=1";
		}
		window.location = location_str;
	}
	</script>

	<hr>

	<%

	my $html_text;

	# short text:
	if ($long_short == 0 || $long_short == 2) {
		if ($topic_data->{'short_text'}) {

			$html_text = &func::wikitext_to_html($topic_data->{'short_text'}->{value});

			%>
			<%=$html_text%>
			<p align=right><font face=arial>
			<a href="http://<%=&func::get_host()%>/manage.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Manage <%=$topic_data->{'statement'}->{name}%> statement text</a></font></p>
			<hr>
			<%
		} else {
			%>
			<a href="https://<%=&func::get_host()%>/secure/edit.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Add <%=$topic_data->{'statement'}->{name}%> statement text</a>.
			<br>
			<hr>
			<%
		}
	}

	# long text:
	if ($long_short == 1 || $long_short == 2) {
		if ($topic_data->{'long_text'}) {

			$html_text = &func::wikitext_to_html($topic_data->{'long_text'}->{value});

			%>
			<%=$html_text%>
			<p align=right><font face=arial>
			<a href="http://<%=&func::get_host()%>/manage.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&long=1">Manage <%=$topic_data->{'statement'}->{name}%> long statement text</a></font></p>
			<hr>
			<%
		} else {
			%>
			<a href="https://<%=&func::get_host()%>/secure/edit.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&long=1">Add <%=$topic_data->{'statement'}->{name}%> statement long text.</a> For additional data that doesn't fit on the one page statement page (not recomended.)
			<br>
			<hr>
			<%
		}
	}
	%>

	<p><font face=arial><b>Canonizer Sorted Postion (POV) Statements below <%=$topic_data->{'statement'}->{name}%> statement:</b></font></p>

	<%
	if (!&display_statement_tree($topic_data->{'statement'})) {
		%>
		<p>&nbsp; &nbsp; &nbsp; &nbsp; None.</p>
		<%
	}
	%>

	<p align=right><font face=arial><a href="http://<%=&func::get_host()%>/secure/edit.asp?class=statement&topic_num=<%=$topic_num%>&parent_statement_num=<%=$statement_num%>">Add new position statement under <%=$topic_data->{'statement'}->{name}%> statement.</a></font></p>

	<hr>
	<table border=0>
	<tr><td colspan=3><font face=arial><b>Topic:</b></font></td></tr>
	<tr><td width=25></td><td width=100><font face=arial>Name:</font></td><td><font face=arial size=4><%=$topic_data->{'topic'}->{name}%></font></td></tr>
	<tr><td></td><td><font face=arial>Name Space:</font></td><td><font face=arial size=4><%=$topic_data->{'topic'}->{namespace}%></font></td></tr>
	</table>

	<p align=right><font face=arial><a href="http://<%=&func::get_host()%>/manage.asp?class=topic&topic_num=<%=$topic_num%>">Manage Topic.</a></font></p>

	<hr>

	<table border=0>
	<tr><td colspan=3><font face=arial><b>Statement:</b></font></td></tr>
	<tr><td width=25></td><td width=100><font face=arial>Name:</font></td><td><font face=arial size=4><%=$topic_data->{'statement'}->{name}%></font></td></tr>
	<tr><td></td><td><font face=arial>One Line:</font></td><td><font face=arial size=4><%=$topic_data->{'statement'}->{one_line}%></font></td></tr>
	<tr><td></td><td><font face=arial>Key Words:</font></td><td><font face=arial size=4><%=$topic_data->{'statement'}->{key_words}%></font></td></tr>
	</table>

	<p align=right><font face=arial><a href="http://<%=&func::get_host()%>/manage.asp?class=statement&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Manage Statement.</a></font></p>

	<hr>

	<p>
	<select name="long_short" onchange=javascript:change_long_short(value)>
		<option value=0 <%=$short_sel_str%>>Short Statement Only
		<option value=1 <%=$long_sel_str%>>Long Statement Only
		<option value=2 <%=$long_short_sel_str%>>Long and Short Statement
	</select>
	</p>

	<%
}


sub display_statement_tree {
	my statement $statement = $_[0];

	if ($statement->{children}) {
		%>
		<ol>
		<%
		my statement $child;
		foreach $child (@{$statement->{children}}) {
			%>
			<li><a href = "http://<%=&func::get_host()%>/topic.asp?topic_num=<%=$child->{topic_num}%>&statement_num=<%=$child->{statement_num}%>"><%=$child->{name}%></a></li>
			<%
			&display_statement_tree($child);
		}
		%>
		</ol>
		<%
		return(1);
	}
	return(0);
}


sub make_statement_path {
	my statement $statement = $_[0];

	my $statement_path = '<font size=6>' . $statement->{name} . '</font>';

	while ($statement->{statement_num} > 1) { # have more parents.
		$statement = $statement->{parent};
		$statement_path = '<a href="http://' . &func::get_host() . '/topic.asp?topic_num=' . $statement->{topic_num} . '&statement_num=' . $statement->{statement_num} . '">' . $statement->{name} . '</a> <b>/</b> ' . $statement_path
	}

	return($statement_path);
}


########
# main #
########

local $error_message = '';

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

local $long_short = 0;
if ($Request->Form('long_short')) {
	$long_short = int($Request->Form('long_short'));
} elsif ($Request->QueryString('long_short')) {
	$long_short = int($Request->QueryString('long_short'));
}


local $topic_data = &lookup_topic_data($topic_num, $statement_num, $long_short);

if ($error_message) {
	&display_page('Unknown Topic Number', [\&identity, \&search, \&main_ctl], [\&error_page]);
} else {
	&display_page('<font size=5>Topic: </font>' . $topic_data->{'topic'}->{name} . '<br><font size=4>Statement: ' . 
&make_statement_path($topic_data->{'statement'}) . '</font><br>', [\&identity, \&search, \&main_ctl], [\&present_topic]);
}

%>
