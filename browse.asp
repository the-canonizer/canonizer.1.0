<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/canonizer.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub browse {
	%>
	
<div class="main_content_container">

<div class="section_container">
<div class="header_1"><span id="title">Browse</span></div>
<div class="content_1">
<p>This is the top level browse page. Currently, this page only lists all topics in all namespaces, alphabetically. When there are more topics more browsing abilities will be added; including an automatic hierarchical category system, an ability to include and exclude namespaces from listings (only the main namespace will be listed by default) and a link to a hierarchical "list of lists" topic pages  (in the /topic/ namespace) which may include such things as a link to a hierarchical scientific taxonomy classification set of topics or listings of elements and so on.</p>
	
	<%

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $as_of_mode = $Session->{'as_of_mode'};
	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		my $parsed_as_of_date = &func::parse_as_of_date($Session->{'as_of_date'});
		$as_of_clause = "and go_live_time < $parsed_as_of_date";
	} else {
		$as_of_clause = 'and go_live_time < ' . time;
	}

	my $selstmt = "select t.topic_num, t.namespace, t.name, s.one_line from (select topic_num, namespace, name from topic where objector is null $as_of_clause and go_live_time in (select max(go_live_time) from topic where objector is null $as_of_clause group by topic_num)) t, (select topic_num, one_line from statement where statement_num = 1 and objector is null $as_of_clause and go_live_time in (select max(go_live_time) from statement where statement_num = 1 and objector is null $as_of_clause group by topic_num)) s where t.topic_num = s.topic_num order by t.namespace, t.name";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	my $no_data = 1;
	while ($rs = $sth->fetch()) {
		$no_data = 0;
		print('<p class="browse_list"><a href="/topic.asp?topic_num=' . $rs->[0] . '">', $rs->[1], $rs->[2], '</a> ', $rs->[3], "</p>\n");
	}

	if ($no_data) {
		%>
		<p>No topics YET.</p>
		<%
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


########
# main #
########

&display_page('Browse', [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&browse]);

%>
