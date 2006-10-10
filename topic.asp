
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

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

sub error_page {
	%>
	<h1>Error: Unkown Topic Reference (<%=$topic_num%>:<%=$statement_num%>).</h1>
	<%
}

sub lookup_topic_data {
	my $topic_num = $_[0];
	my $statement_num = $_[1];

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";
	my $selstmt = "select t.name, t.namespace, t.submitter, s.name, s.one_line, s.key_words, s.submitter from topic t, statement s where t.replacement is null and t.proposed = 0 and s.replacement is null and t.topic_num = $topic_num and s.topic_num = $topic_num and s.statement_num = $statement_num";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;

	$sth->execute() || die "Failed to execute " . $selstmt;

	my $rs = $sth->fetch() || return(0); # unknown topic

	my $topic_data = {
		't.name'	=> $rs->[0],
		't.namespace'	=> $rs->[1],
		't.submitter'	=> $rs->[2],
		's.name'	=> $rs->[3],
		's.one_line'	=> $rs->[4],
		's.key_words'	=> $rs->[5],
		't.submitter'	=> $rs->[6]
	} ;
	$sth->finish();


	$dbh->{LongReadLen} = 1000000; # what and where should this really be ????


	$selstmt = "select value, text_size from text where topic_num=$topic_num and statement_num=$statement_num and proposed = 0 and replacement is null";

	$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;

	$sth->execute() || die "Failed to execute " . $selstmt;

	while ($rs = $sth->fetch()) {

		if ($rs->[1] == 1) { # long text
			if ($topic_data->{'long_text'}) {
				print(STDERR "Warning evidently topic $topic_num and statement $statement_num has more than one active long text record.\n");
			}
			$topic_data->{'long_text'} = $rs->[0];
		} else { # short text
			if ($topic_data->{'short_text'}) {
				print(STDERR "Warning evidently topic $topic_num and statement $statement_num has more than one active short text record.\n");
			}
			$topic_data->{'short_text'} = $rs->[0];
		}
	}

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

	<br>

	Name Space: <font size=4><%=$topic_data->{'t.namespace'}%></font><br>

	<a href="http://<%=&func::get_host()%>/manage.asp?class=topic&topic_num=<%=$topic_num%>">Manage Topic</a> (Topic Name and Namespace).<br><br>

	One Line Description:<br>
	<font size=4><%=$topic_data->{'s.one_line'}%></font><br>

	<a href="http://<%=&func::get_host()%>/manage.asp?class=statement&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Manage Statement</a> (Statement Name, Key Words, and One Line Description).<br><br>

	<br>

	<%

	my $html_text;

	# short text:
	if ($long_short == 0 || $long_short == 2) {
		if (length($topic_data->{'short_text'}) > 0) {

			$html_text = &func::wikitext_to_html($topic_data->{'short_text'});

			%>
			<hr>
			<%=$html_text%>
			<hr>
			<br>
			<a href="http://<%=&func::get_host()%>/manage.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Manage <%=$topic_data->{'s.name'}%> statement text</a>.
			<br><br>
			<%
		} else {
			%>
			<a href="https://<%=&func::get_host()%>/secure/edit.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Add <%=$topic_data->{'s.name'}%> statement text</a>.
			<br><br>
			<%
		}
	}

	# long text:
	if ($long_short == 1 || $long_short == 2) {
		if (length($topic_data->{'long_text'}) > 0) {

			$html_text = &func::wikitext_to_html($topic_data->{'long_text'});

			%>
			<%=$html_text%>
			<br>
			<a href="http://<%=&func::get_host()%>/manage.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&long=1">Manage <%=$topic_data->{'s.name'}%> long statement text</a>.
			<br><br>
			<%
		} else {
			%>
			<a href="https://<%=&func::get_host()%>/secure/edit.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&long=1">Add <%=$topic_data->{'s.name'}%> statement long text.</a> For additional data that doesn't fit on the one page statement page (not recomended.)
			<br><br>
			<%
		}
	}
	%>

	<select name="long_short" onchange=javascript:change_long_short(value)>
		<option value=0 <%=$short_sel_str%>>Short Statement Only
		<option value=1 <%=$long_sel_str%>>Long Statement Only
		<option value=2 <%=$long_short_sel_str%>>Long and Short Statement
	</select>


	<h2>Canonizer Sorted Postion (POV) Statement tree:</h2>

	<%

}



########
# main #
########

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

local $topic_data = &lookup_topic_data($topic_num, $statement_num);

my $statement_name;
if ($statement_num eq 1) {
	$statement_name = 'Agreement Statement';
} else {
	$statement_name = 'POV Statement: ' . $topic_data->{'s.name'};
}

if ($topic_data == 0) {
	&display_page('Unknown Topic Number', [\&identity, \&search, \&main_ctl], [\&error_page]);
} else {
	&display_page('<font size=5>Topic: ' . $topic_data->{'t.name'} . '</font><br><font size=4>' . $statement_name . '</font>', [\&identity, \&search, \&main_ctl], [\&present_topic]);
}

%>

