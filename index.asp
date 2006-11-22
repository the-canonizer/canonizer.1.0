<%

use managed_record;
use statement;

%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/canonizer.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub display_statement_tree {
	my statement $statement = $_[0];

	if ($statement->{children}) {
		%>
		<ol>
		<%
		my statement $child;
		foreach $child (@{$statement->{children}}) {
			%>
			<li><a href="http://<%=&func::get_host()%>/topic.asp?topic_num=<%=$child->{topic_num}%>&statement_num=<%=$child->{statement_num}%>"><%=$child->{name}%> (<%=$child->{one_line}%>)</a></li>
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


sub top_10 {

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $as_of_mode = $Session->{'as_of_mode'};
	my $as_of_date = $Session->{'date'};
	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		$as_of_clause = 'where go_live_time < ' . &func::parse_as_of_date($as_of_date);
	} else {
		$as_of_clause = 'where go_live_time < ' . time;
	}

	my $selstmt = "select topic_num, name from topic $as_of_clause group by topic_num";
	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
	$sth->execute() || die "Failed to execute $selstmt";
	my $rs;

	%>
	<ol>
	<%

	my $topic_num;
	my $topic_name;
	my statement $statement;
	my $no_data = 1;
	while ($rs = $sth->fetch()) {
		$no_data = 0;
		$topic_num = $rs->[0];
		$topic_name = $rs->[1];
		$statement = new_tree statement ($dbh, $topic_num, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
		if (!$statement) {
			next;
		}
		%>
		<li><a href="http://<%=&func::get_host()%>/topic.asp?topic_num=<%=$topic_num%>&statement_num=1"><b><%=$rs->[1]%></b> (<%=$statement->{one_line}%>)</a>
		<%
		&display_statement_tree($statement);
		%>
		<br><br>
		<%
	}
	$sth->finish();

	if ($no_data) {
		%>
		<h2>No topics YET.</h2>
		<%
	}

	%>
	</ol>
	<%
}


########
# main #
########

my $header = 'CANONIZER <br><font size=5>Top 10</font>';

&display_page($header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&top_10]);

%>
