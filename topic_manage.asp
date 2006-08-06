
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/topic_tabs.asp"-->

<%

sub error_page {
	%>
	<h1>Error: Unkown topic_id: <%=$topic_id%>.</h1>
	<%
}

sub unknown_num_page {

	if ($num) {
		%>
		<br>
		<h1>Unknown Topic Number:&nbsp;<%=$num%>.</h1>
		<%
	} else {
		%>
		<br>
		<h1>No topic number specified.</h1>
		<%
	}
}

# don't use this, people can browse history without logging in! ????
sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/topic_manage.asp';
	my $present_url = 'topic.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $query_string);
		$present_url .= ('?' . $query_string);
	}

	%>
	<br>

	<h2>You must register and or login before you can manage topics.</h2>
	<center>
	<h2><a href=register.asp>Register</a><h2>
	<h2><a href="<%=$login_url%>">Login</a><h2>
	<h2><a href="<%=$present_url%>">Return to topic presentation page</a></h2>
	</center>
	<%
}


sub print_topic_record {
	my $topic_rec_ref = $_[0];
	%>
	<tr><th><%=$topic_rec_ref->{'go_live_time'}%></th>
	    <th><%=$topic_rec_ref->{'name'}%></th>
	    <th><%=$topic_rec_ref->{'note'}%></th>
	</tr>
	<tr><td>
		<a href="https://<%=&func::get_host()%>/secure/new_topic.asp?record_id=<%=$topic_rec_ref->{'record_id'}%>">Propose Modification</a>
</td><td>Submitter:</td><td><%=&func::get_nick_name($dbh, $topic_rec_ref->{'submitter'})%></td></tr>
	<tr><td>&nbsp;</td><td>One Line Description:</td><td><%=$topic_rec_ref->{'one_line'}%></td></tr>
	<%
	if ($topic_rec_ref->{'objector'}) {
		%>
		<tr><td>&nbsp;</td><td colspan=2><%=$topic_rec_ref->{'objector'}%> objected to this change because:<br>
				<%=$topic_rec_ref->{'object_reason'}%> at <%=$topic_rec_ref->{'object_time'}%></td>
		</tr>
		<%
	}
	%>
	<tr><td colspan = 3>&nbsp</td></tr>
	<%
}


sub manage_topic {

	%>
	<br>
	<table>
	<%

	my $rec_index = $#record_array;
	my $topic_rec_ref;

	my $proposed_header_displayed = 0;
PROPOSED: while ($rec_index >= 0) {
		$topic_rec_ref = $record_array[$rec_index];
		if ($topic_rec_ref->{'proposed'}) {
			if (! $proposed_header_displayed) {
				%>
				<tr><td colspan = 3>Proposed Versions of this topic:</td></tr>
				<%
				$proposed_header_displayed = 1;
			}
			&print_topic_record($record_array[$rec_index]);
		} else {
			last PROPOSED;
		}
		$rec_index--;
	}

	my $active_header_displayed = 0;
ACTIVE: while ($rec_index >= 0) {
		$topic_rec_ref = $record_array[$rec_index];
		if ($topic_rec_ref->{'objector'}) {
			&print_topic_record($topic_rec_ref);
			$rec_index--;
		} else {
			if (! $active_header_displayed) {
				%>
				<tr><td colspan = 3>Currently Activbe Record:</td></tr>
				<%
				$proposed_header_displayed = 1;
			}
			&print_topic_record($record_array[$rec_index]);
			$rec_index--;
			last ACTIVE;
		}
	}

	my $history_header_displayed = 0;
	while ($rec_index >= 0) {
		if (! $history_header_displayed) {
			%>
			<tr><td colspan = 3>History:</td></tr>
			<%
			$history_header_displayed = 1;
		}
		$topic_rec_ref = $record_array[$rec_index];
		&print_topic_record($record_array[$rec_index]);
		$rec_index--;
	}

	%>
	</table>
	<%
}



########
# main #
########

local $topic_name = '';

local $num = '';
if ($Request->Form('number')) {
	$num = int($Request->Form('number'));
} elsif ($Request->QueryString('number')) {
	$num = int($Request->QueryString('number'));
}


if (!$num) {
	&display_page('CANONIZER', 'Manage Topic: '. $num, [\&identity, \&search, \&main_ctl], [\&unknown_num_page]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";
local @record_array = ();

my $invalid_num = 1;

my $selstmt = 'select record_id, name, namespace, one_line, note, submitter, go_live_time, proposed, replacement, objector, object_time, object_reason from topic where num = ' . $num . ' order by go_live_time'; #???? should this be descending or something?

my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
$sth->execute() || die "Failed to prepair " . $selstmt;
my $rs;

my $rec_index = -1;
local $active_rec_index = -1;

# order starts with the first record.
while ($rs = $sth->fetchrow_hashref()) {
	my %topic_rec = ();
	$rec_index++;

	$topic_rec{'name'} = $rs->{'NAME'};
	$topic_rec{'record_id'} = $rs->{'RECORD_ID'};
	$topic_rec{'namespace'} = $rs->{'NAMESPACE'};
	$topic_rec{'one_line'} = $rs->{'ONE_LINE'};
	$topic_rec{'note'} = $rs->{'NOTE'};
	$topic_rec{'submitter'} = $rs->{'SUBMITTER'};
	$topic_rec{'go_live_time'} = $rs->{'GO_LIVE_TIME'};
	$topic_rec{'proposed'} = $rs->{'PROPOSED'};
	$topic_rec{'replacement'} = $rs->{'REPLACEMENT'};
	$topic_rec{'objector'} = $rs->{'OBJECTOR'};
	$topic_rec{'object_time'} = $rs->{'OBJECT_TIME'};
	$topic_rec{'object_reason'} = $rs->{'OBJECT_REASON'};

	if ((! $topic_rec{'objector'}) && (! $topic_rec{'proposed'})) {
		$invalid_num = 0;
		$topic_name = $topic_rec{'name'};
		$active_rec_index = $topic_rec;
	}

	$record_array[$rec_index] = \%topic_rec;

}


if ($invalid_num) {
	&display_page('CANONIZER', 'Manage Topic: '. $num, [\&identity, \&search, \&main_ctl], [\&unknown_num_page]);
	$Response->End();
}


&display_page('CANONIZER', 'Topic: '. $topic_name, [\&identity, \&search, \&main_ctl], [\&manage_topic], \&topic_tabs);



%>
