<%

########
# main #
########


my $nick_id = 0;
if ($Request->Form('nick_id')) {
	$nick_id = int($Request->Form('nick_id'));
} elsif ($Request->QueryString('nick_id')) {
	$nick_id = int($Request->QueryString('nick_id'));
}


display_page('Person Info', 'Person Info', [\&identity, \&search, \&as_of, \&main_ctl], [\&nick_names]);



########
# subs #
########


sub nick_names {

	my $as_of_mode = $Session->{'as_of_mode'};
	my $as_of_date = $Session->{'as_of_date'};

	if ($Session->{'cid'} != 1) {
		%>
		<h1> Only 1 can do this.
		<%
		$Response->End();
	}

	my $as_of_time = time;
	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		$as_of_time = &func::parse_as_of_date($as_of_date);
		$as_of_clause = "and go_live_time < $as_of_time";
	} else {
		$as_of_clause = 'and go_live_time < ' . $as_of_time;
	}


	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

#	my $selstmt = 'select nick_name, nick_name_id from nick_name';
	my $selstmt = 'select cid, first_name, middle_name, last_name, email, address_1, address_2, city, state, postal_code, country, birthday, gender from person';

	if ($nick_id) {
		$selstmt .= " where nick_name_id = $nick_id";
	}

	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	%>
	<ol>
	<%
	while ($rs = $sth->fetchrow_hashref()) {
		my $not_supporting = 1;
		# $selstmt = "select topic.name, support.name camp.delegate_id from suppo
		%>
		<li><%=$rs->{'first_name'} . ' ' . $rs->{'middle_name'} . ' ' . $rs->{'last_name'}%> [<%=$rs->{'cid'}%>] (<%=$rs->{'email'}%>)<br>
		<%=$rs->{'address_1'} . ' ' . $rs->{'address_2'} . ' ' . $rs->{'city'} . ' ' . $rs->{'state'} . ' ' . $rs->{'postal_code'} . ' ' . $rs->{'contry'}%></li>
		<ol>
		<%
		my %nick_name_hash = func::get_nick_name_hash($rs->{'cid'}, $dbh);
		my $nick_name_id;
		foreach $nick_name_id (keys %nick_name_hash) {
			%>
			<li><a href="http://<%=func::get_host()%>/support_list.asp?nick_name_id=<%=$nick_name_id%>"><%=$nick_name_hash{$nick_name_id}->{'nick_name'}%> [<%=$nick_name_id%>]</a></li>
			<%
		}
		%>
		</ol>
		<br>
		<%
	}
	%>
	</ol>
	<%
}

%>


<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

