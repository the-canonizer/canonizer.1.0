<%

########
# main #
########


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
<!-- num db members: <%=$members%> -->
<!-- gid: <%=$Session->{'gid'}%> -->

<%


display_page('Env and State info', 'Env and State info', [\&identity, \&search, \&canonizer, \&as_of, \&main_ctl], [\&env]);



########
# subs #
########


sub env {

	%>

	<table>

	<tr><th colspan = 2 align = left>Session and stuff values:</th></tr>

	<tr><td>members in db</td><td><%=$members%></td></tr>
	<tr><td>$mode</td><td><%=$mode%></td></tr>

	<%
	my $key;
	foreach $key (sort (keys %{$Session})) {
		%>
		<tr><td>Session->{<%=$key%>}</td><td><%=$Session->{$key}%></td></tr>
		<%
	}
	%>
	<tr><th colspan = 2 height = 30>&nbsp;</th></tr>
	<tr><td>--------------</td><td>----------------</td></tr>

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

	<tr><td>--------------</td><td>----------------</td></tr>

	<tr><th colspan = 2 align = left>ENV values:</th></tr>

	<%
	my $key;
	foreach $key (sort (keys %ENV)) {
	%>
		<tr><td><%=$key%></td><td><%=$ENV{$key}%></td></tr>
	<%
	}
	%>

	<tr><th colspan = 2 height = 30>&nbsp;</th></tr>

	<tr><td>--------------</td><td>----------------</td></tr>

	<tr><th colspan = 2 align = left>$Request->Form() values:</th></tr>

	<%
	foreach $key (keys %{$Request->Form}) {
	%>
		<tr><td><%=$key%></td><td><%=$Request->Form($key)%></td></tr>
	<%
	}
	%>
	</table>
<%
}
%>


<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/canonizer.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

