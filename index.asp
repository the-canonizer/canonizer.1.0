<%

use managed_record;
use statement;

%>

<%

my $header = 'CANONIZER <br><font size=5>Top 10</font>';

&display_page($header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&top_10]);



##############
# start subs #
##############


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
<hr>

<p>For a brief description of the Canonizer see the "What is the
Canonizer" link on the side bar.  </p>

<p>Enough of the canonization process is now completed to do "Blind
Popularity" (one person, one vote) canonization.  Since there are
still so few topics, all are now being displayed here rather than just
the top 10.  Once there are more topics, only the top 10 topics in the
primary name space will be included here.  Once a user attribute
system is completed, along with more canonizers using these attributes
you will be able to canonize this page in different ways giving more
influence to people you choose to respect.  </p>

<hr>
	<ol>
	<%

	my @topic_array = ();

	my %topic_names = ();

	my $topic_num;
	my statement $statement;
	my $no_data = 1;
	while ($rs = $sth->fetch()) {
		$no_data = 0;
		$topic_num = $rs->[0];
		$topic_names{$topic_num} = $rs->[1];
		$statement = new_tree statement ($dbh, $topic_num, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
		if (!$statement) {
			next;
		}
		$statement->canonize();
		push(@topic_array, $statement);
	}
	$sth->finish();

	my $topic_name;
	foreach $statement (sort {(($a->{score} <=> $b->{score}) * -1)} @topic_array) {
		$topic_num = $statement->{topic_num};
		$topic_name = $topic_names{$statement->{topic_num}};
		$Response->Write($statement->display_statement_tree($topic_name, $topic_num));
		$Response->Write("<br>\n");
	}

	%>
	</ol>
	<%
}


%>


<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/canonizer.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

