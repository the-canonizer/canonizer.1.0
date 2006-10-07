

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub browse {
	%>
	<p>This is the top level browse page.</p>

	<p>Currently, this page only lists all topics in all namespaces, alphabetically.<p>

	<p>When there are more topics more browsing abilities will be added including:</p>

	<ul>
	    <li>An automatic hierarchical category system.</li>

	    <li>An ability to include and exclude namespaces from listings.
		(Only the main namespace will be listed by default.)</li>

	    <li>A link to a hierarchical "list of lists" topic pages
		(in the /topic/ namespace) which may include such things as a link to
		a hierarchical scientific taxonomy classification set of topics or
		listings of elements and so on.</li>

	</ul>

	<br><br>

	<ol>

	<%

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $selstmt = "select t.namespace, t.name, s.one_line, t.topic_num from topic t, statement s where t.replacement is null and t.proposed = 0 and s.replacement is null and s.proposed = 0 and t.topic_num = s.topic_num";
;
#	my $selstmt = 'select namespace, name, one_line, topic_num from topic where proposed = 0 and replacement is null order by namespace, name';

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	while ($rs = $sth->fetch()) {
		print('<li><a href="/topic.asp?topic_num=' . $rs->[3] . '">', $rs->[0], $rs->[1], '</a><br>', $rs->[2], "</li>\n");
	}
	%>
	</ol>
	<%
}


########
# main #
########

&display_page('Browse', [\&identity, \&search, \&main_ctl], [\&browse]);

%>

