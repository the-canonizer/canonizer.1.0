<%

use managed_record;
use statement;

my $header = 'CANONIZER Top 10';

&display_page($header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&top_10]);

##############
# start subs #
##############

sub top_10 {

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $as_of_mode = $Session->{'as_of_mode'};
	my $as_of_date = $Session->{'as_of_date'};
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

<div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title">Some information</span>

</div>

<div class="content_1">

<p>For a brief description of the Canonizer see the "What is the Canonizer" link on the side bar.</p>

<p>Enough of the canonization process is now completed to do "Blind Popularity" (one person, one vote) canonization.  Since there are still so few topics, all are now being displayed here rather than just the top 10.  Once there are more topics, only the top 10 topics in the primary name space will be included here.  Once a user attribute system is completed, along with more canonizers using these attributes you will be able to canonize this page in different ways giving more influence to people you choose to respect.</p>

</div>

     <div class="footer_1">
     <span id="buttons">
     

&nbsp;    
     
     </span>
     </div>

</div>

<div class="section_container">
<div class="header_1">

     <span id="title">Top 10</span>

</div>

<div class="statement_tree" id="statement_tree">

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
	}

%>

</div>

     <div class="footer_1">
     <span id="buttons">
     

&nbsp;  
     
     </span>
     </div>

</div>

</div>
	
<%

}
    
sub display_statement_tree {
	my statement $statement = $_[0];

	if ($statement->{children}) {
%>


		
<%
		my statement $child;
		foreach $child (@{$statement->{children}}) {

%>

<a href="http://<%=&func::get_host()%>/topic.asp?topic_num=<%=$child->{topic_num}%>&statement_num=<%=$child->{statement_num}%>"><%=$child->{name}%> (<%=$child->{one_line}%>)</a>

<%
			&display_statement_tree($child);
		}
%>


		
<%
		return(1);
	}
	return(0);
}

%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/canonizer.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

