
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub register_warning {

%>

<br>

<p><b>You should read and thoroughly understand this before
registering:</b></p>

<p>There is a strict single identity per user policy at canonizer.  If
you have ever registered with canonizer before, you must use that same
identity.  It is considered cheating to have multiple identities
either intentional or unintentional.  When signing up you must first
do a search of the system to ensure the system, perhaps through proxy
registration by someone else, doesn't already know about you.  If we
already know about you, you can take ownership and manage this
information.  We make our best effort to prevent all cheating and
lying at canonizer.  If you are ever caught lying, allowing multiple
identities for yourself, bogus advertisement clicks or cheating in any
way, we intend to indelibly record this information with your
identity.  Some canonizers may eventually be forgiving of such
information and ignore it after a period time - but others may never
ignore it and forever discriminate based on it.  Reputation is a big
deal at canonizer and we intend to make as much reputation information
available to canonizers as possible.  One of our goals is to record
all participations and contributions to the canonizer system as it
grows and improves forever.</p>

<p>For the initial identity search, please enter your legal first and
last name (or commonly identifiable portions of those names).  Or if
you know the system already knows about you and you have a canonizer
id number, enter it so we can give you ownership of this information.
You can repeat this search multiple times, and it is your
responsibility not to have multiple identities on the system.</p>

<form method = post>

<table border = 0>
<tr><td>Legal First Name:</td><td><input type = text name = first_name></td></tr>
<tr><td>Legal Last Name:</td><td><input type = text name = last_name></td></tr>
<tr><th colspan = 2 align = center>Or</th></tr>
<tr><td>Canonizer ID Number:</td><td><input type = text name = cid></td></tr>
<tr><td colspan = 2 align = center><input type = submit name = submit value = "Do Search"></td></tr>
</table>

</form>

<%
}

sub make_found_users_str {
	my $users_hash_ref = $_[0];

	my $ret_str = '';

	my $cid;
	foreach $cid (sort(keys(%{$users_hash_ref}))) {  # fix this sort ????
		my ($middle_name) = $users_hash_ref->{$cid}->{'middle_name'};
		if (length($middle_name) < 1) {$middle_name = '&nbsp';}
		$ret_str .= '<tr><td>' . $users_hash_ref->{$cid}->{'first_name'} . "</td>\n" .
 			    '    <td>' . $middle_name . "</td>\n" .
			    '    <td>' . $users_hash_ref->{$cid}->{'last_name'} . "</td>\n" .
			    "    <td>send password</td></tr>\n";
	}

	if ($ret_str) {
		$ret_str = "<table border = 1>\n" .
			   "<tr><td colspan=4>\n" .
			   "The identities below already have a registered e-mail address and password.<br>\n" .
			   "The send password link will send that person's password to that person's e-mail.<br>\n" .
			   "If one of them represents you, it is considered cheating to register as another identity.\n" .
			   "</td></tr>\n" .
			   "  <tr><th>First Name</th><th>Middle Name</th><th>Last Name</th><th>&nbsp</th></tr>\n" .
			   $ret_str .
			   "</table><br><br>\n";
	}
	return($ret_str);
}

sub make_found_proxies_str {
	my $users_hash_ref = $_[0];

	my $ret_str = '';

	my $cid;
	foreach $cid (sort(keys(%{$users_hash_ref}))) {  # fix this sort ????
		my ($middle_name) = $users_hash_ref->{$cid}->{'middle_name'};
		if (length($middle_name) < 1) {$middle_name = '&nbsp';}
		$ret_str .= '<tr><td>' . $users_hash_ref->{$cid}->{'first_name'} . "</td>\n" .
 			    '    <td>' . $middle_name . "</td>\n" .
			    '    <td>' . $users_hash_ref->{$cid}->{'last_name'} . "</td>\n" .
			    "    <td><a href = \"https://" . &func::get_host() . "/secure/profile_id.asp?takeover_cid=$cid\">Take Ownership</a></td></tr>\n";
	}

	if ($ret_str) {
		$ret_str = "<table border = 1>\n" .
			   "<tr><td colspan=4>\n" .
			   "If one of these identities represents you, " .
			   "you can take ownership of the information by following the Take Ownership link, " .
			   "attaching your e-mail with the information and adding a password.\n" .
			   "</td></tr>\n" .
			   "  <tr><th>First Name</th><th>Middle Name</th><th>Last Name</th><th>&nbsp</th></tr>\n" .
			   $ret_str .
			   "</table><br><br>\n";
	}
	return($ret_str);
}


sub search_results {

	# Can't register until this is set.
	$Session->{'did_warning_search'} = 1;

	my $cid = int($Request->Form('cid'));
	my $first_name = $Request->Form('first_name');
	my $last_name = $Request->Form('last_name');

	my $dbh;
	my $selstmt;
	my $sth;
	my $rs;

	my %email_hash = ();
	my %proxy_hash = ();

	my $message = '';

	if ($cid) {
		$dbh = &func::dbh_connect(1) || die "unable to connect to database";
		$selstmt = "select first_name, middle_name, last_name, email from person where cid = $cid";
		$sth = $dbh->prepare($selstmt) || die 'prepare failed with ' . $selstmt;
		$sth->execute() || die 'execute failed with ' . $selstmt;
		$rs = $sth->fetchrow_hashref();
		$sth->finish();
		if ($rs) {
			if (length ($rs->{'EMAIL'}) > 0) {
				$email_hash{$rs->{'CID'}} = {
					'first_name' => &func::hex_decode($rs->{'FIRST_NAME'}),
					'middle_name' => &func::hex_decode($rs->{'MIDDLE_NAME'}),
					'last_name' => &func::hex_decode($rs->{'LAST_NAME'}),
					'email' => &func::hex_decode($rs->{'EMAIL'})
				};
			} else {
				$proxy_hash{$rs->{'CID'}} = {
					'first_name' => &func::hex_decode($rs->{'FIRST_NAME'}),
					'middle_name' => &func::hex_decode($rs->{'MIDDLE_NAME'}),
					'last_name' => &func::hex_decode($rs->{'LAST_NAME'})
				};
			}
		}
	} elsif ((length($first_name) > 0) or (length($last_name) > 0)) {
		my $like_clause = '';
		if (length($first_name = &func::hex_encode(uc($first_name)))) {
			# $like_clause = "upper(first_name) like '%$first_name%'";
			$like_clause = "upper(first_name) like ?";
		}
		if (length($last_name = &func::hex_encode(uc($last_name)))) {
			if ($like_clause) {
				$like_clause .= ' and ';
			}
			$like_clause .= "upper(last_name) like ?";
		}

		$last_name = &func::hex_encode($last_name);
		$dbh = &func::dbh_connect(1) || die "unable to connect to database";
		$selstmt = "select cid, first_name, middle_name, last_name, email from person where $like_clause";
		$sth = $dbh->prepare($selstmt) || die 'prepare failed with ' . $selstmt;
		if ((length($first_name) > 0) and (length($last_name) > 0)) {
			$sth->execute("\%$first_name\%", "\%$last_name\%") || die 'execute failed with ' . $selstmt;
		} elsif (length($first_name) > 0) {
			$sth->execute("\%$first_name\%") || die 'execute failed with ' . $selstmt;
		} else {
			$sth->execute("\%$last_name\%") || die 'execute failed with ' . $selstmt;
		}
		while ($rs = $sth->fetchrow_hashref()) {
			if (length ($rs->{'EMAIL'}) > 0) {
				$email_hash{$rs->{'CID'}} = {
					'first_name' => &func::hex_decode($rs->{'FIRST_NAME'}),
					'middle_name' => &func::hex_decode($rs->{'MIDDLE_NAME'}),
					'last_name' => &func::hex_decode($rs->{'LAST_NAME'}),
					'email' => &func::hex_decode($rs->{'EMAIL'})
				};
			} else {
				$proxy_hash{$rs->{'CID'}} = {
					'first_name' => &func::hex_decode($rs->{'FIRST_NAME'}),
					'middle_name' => &func::hex_decode($rs->{'MIDDLE_NAME'}),
					'last_name' => &func::hex_decode($rs->{'LAST_NAME'})
				};
			}
		}
		$sth->finish();
	} else {
		$message = "<h3><font color = red>Nothing given to search for.</font></h3>";
	}


my $found_str = &make_found_users_str(\%email_hash);
$found_str .= &make_found_proxies_str(\%proxy_hash);

if ($found_str) {
	$Response->Write($found_str);
} elsif ($message) {
	$Response->Write($message);
} elsif ($cid) {
%>
	<p>There is no person with cid <%=$cid%>.</p>
<%
} else {
%>
	<p>There is no identity that has the string
	"<%=$first_name%>" in the first name and
	"<%=$last_name%>" in the second name.</p>
<%
}
%>


<p>You can repeat the search here:</p>

<form method = post>

<table border = 0>
<tr><td>Legal First Name:</td><td><input type = text name = first_name></td></tr>
<tr><td>Legal Last Name:</td><td><input type = text name = last_name></td></tr>
<tr><th colspan = 2 align = center>Or</th></tr>
<tr><td>Canonizer ID Number:</td><td><input type = text name = cid></td></tr>
<tr><td colspan = 2 align = center><input type = submit name = submit value = "Do Search"></td></tr>
</table>

</form>

<br>
<br>

<p>Or if none of the found identities represent you and you are sure there are no identities on the system
that do represent you, you can go onto the registration page.</p>

<p><a href = "https://<%=&func::get_host()%>/secure/profile_id.asp"><input type = button value = register></a></p>

<br>

<p>And as always, if there is a problem please contact <a href = 
"mailto:support@canonizer.com">support@canonzier.com</a>.</p>

<%
}


########
# main #
########

if ($Request->Form("submit") eq "Do Search") {
	&display_page('CANONIZER', 'Identity Search Results', [\&identity, \&search, \&main_ctl], [\&search_results]);
} else {
	&display_page('CANONIZER', 'Registration', [\&identity, \&search, \&main_ctl], [\&register_warning]);
}
%>

