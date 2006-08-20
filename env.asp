<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub env {

	# be sure the db is working by counting the number of members:
	my $dbh = &func::dbh_connect(1);

	my $selstmt = 'select count(*) from person';
	my $sth = $dbh->prepare($selstmt) || die $selstmt;
	$sth->execute() || die $selstmt;

	my $rs;
	$rs = $sth->fetch();
	my $members = $rs->[0];
	$sth->finish();

	%>

	<table>

	<tr><th colspan = 2 align = left>Session and stuff values:</th></tr>

	<tr><td>members in db</td><td><%=$members%></td></tr>
	<tr><td>$mode</td><td><%=$mode%></td></tr>

	<tr><td>Session->{'gid'}</td><td><%=$Session->{'gid'}%></td></tr>
	<tr><td>Session->{'cid'}</td><td><%=$Session->{'cid'}%></td></tr>
	<tr><td>Session->{'email'}</td><td><%=$Session->{'email'}%></td></tr>
	<tr><td>Session->{'logged_in'}</td><td><%=$Session->{'logged_in'}%></td></tr>
	<tr><td>Session->{'page_count'}</td><td><%=$Session->{'page_count'}%></td></tr>
	<tr><td>Session->{'SessionID'}</td><td><%=$Session->{'SessionID'}%></td></tr>

	<%
	my $guests = $Application->{'guests'};
	my $idx;
	my $guests_str = '';
	for ($idx = 0; $idx <= $#{$guests}; $idx++) {
		if (length($guests_str)) {
			$guests_str .= ', ';
		}
		$guests_str .= $idx . "[" . $guests->[$idx] . "]";
	}
	my @foo = @$guests;

	%>
	<tr><td>Guests Array</td><td><%=$guests_str%></td></tr>

	<tr><th colspan = 2 height = 30>&nbsp;</th></tr>

	<tr><th colspan = 2 align = left>ENV values:</th></tr>

	<%

	foreach my $key (sort (keys %ENV)) {
	%>
		<tr><td><%=$key%></td><td><%=$ENV{$key}%></td></tr>
	<%
	}

	%>
	</table>
<%
}

########
# main #
########

&display_page('CANONIZER', 'Env and State info', [\&identity, \&search, \&main_ctl], [\&env]);

%>


