<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%

sub register_warning {

%>

<div class="main_content_container">
     <div class="section_container">
     	  <div class="header_1"><span id="title">Registration</span></div>
     	  
<div class="content_1">
<p>You should read and thoroughly understand this before
registering:</p>

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

<p>On the search results page, there will be a link to register a new
identity page if the system doesn't already know about you.</p>

<form method = post>

<p>Legal First Name: <input type=text name=first_name></p>
<p>Legal Last Name: <input type=text name=last_name></p>
<p>Or</p>
<p>Canonizer ID Number: <input type=text name=search_cid></p>
<p><input type=submit name=submit value="Do Search"></p>

</div>

</form>

     <div class="footer_1">
     <span id="buttons">
     

&nbsp;    
     
     </span>
     </div>



</div>
</div>
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
		$ret_str = "<table class='identity_list' cellpadding='0' cellspacing='0'>\n" .
			   "<tr><td colspan=4>\n" .
			   "<p>The identities below already have a registered e-mail address and password.</p>\n" .
			   "<p>The send password link will send that person's password to that person's e-mail.</p>\n" .
			   "<p>If one of them represents you, it is considered cheating to register as another identity.</p>\n" .
			   "</td></tr>\n" .
			   "  <tr><td>First Name</td><td>Middle Name</td><td>Last Name</td><td>&nbsp</td></tr>\n" .
			   $ret_str .
			   "</table>\n";
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
			    '    <td>' . $users_hash_ref->{$cid}->{'last_name'} . "</td>\n"
#			    "    <td><a href = \"https://" . &func::get_host() . "/secure/profile_id.asp?takeover_cid=$cid\">Take Ownership</a></td></tr>\n";
	}

	if ($ret_str) {
		$ret_str = "<table class='identity_list' cellpadding='0' cellspacing='0'>\n" .
			   "<tr><td colspan=3>\n" .
			   "<p>If one of these identities represents you, \n" .
			   "and you don't know the password, contact stupport\@canonizer.com to get it reset.</p>\n" .
			   "</td></tr>\n" .
			   "<tr><td>First Name</td><td>Middle Name</td><td>Last Name</td></tr>\n" .
			   $ret_str .
			   "</table>\n";
	}
	return($ret_str);
}


sub search_results {

	# Can't register until this is set.
	$Session->{'did_warning_search'} = 1;

	my $cid = int($Request->Form('search_cid'));
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
					'first_name' => &func::hex_decode($rs->{'first_name'}),
					'middle_name' => &func::hex_decode($rs->{'middle_name'}),
					'last_name' => &func::hex_decode($rs->{'last_name'}),
					'email' => &func::hex_decode($rs->{'EMAIL'})
				};
			} else {
				$proxy_hash{$rs->{'CID'}} = {
					'first_name' => &func::hex_decode($rs->{'first_name'}),
					'middle_name' => &func::hex_decode($rs->{'middle_name'}),
					'last_name' => &func::hex_decode($rs->{'last_name'})
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
					'first_name' => &func::hex_decode($rs->{'first_name'}),
					'middle_name' => &func::hex_decode($rs->{'middle_name'}),
					'last_name' => &func::hex_decode($rs->{'last_name'}),
					'email' => &func::hex_decode($rs->{'email'})
				};
			} else {
				$proxy_hash{$rs->{'cid'}} = {
					'first_name' => &func::hex_decode($rs->{'first_name'}),
					'middle_name' => &func::hex_decode($rs->{'middle_name'}),
					'last_name' => &func::hex_decode($rs->{'last_name'})
				};
			}
		}
		$sth->finish();
	} else {
		$message = "<p>Nothing given to search for.</p>";
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

<p>Legal First Name:</p>
<p><input type = text name = first_name></p>
<p>Legal Last Name:</p>
<p><input type = text name = last_name></p>
<p>Or</p>
<p>Canonizer ID Number:</p>
<p><input type = text name = search_cid></p>
<p><input type = submit name = submit value = "Do Search"></p>

</form>

<p>Or if none of the found identities represent you and you are sure there are no identities on the system
that do represent you, you can go onto the Register New Identity page.</p>
<form action="https://<%=&func::get_host()%>/secure/profile_id.asp">

<p><input type=submit name = "submit" value = "Register New Identity"></p>


<form>

<%

#????  I've got to do something to fix the register button for msie.!!!!

}


########
# main #
########

if ($Request->Form("submit") eq "Do Search") {
	&display_page('Identity Search Results', 'Identity Search Results', [\&identity, \&search, \&main_ctl], [\&search_results]);
} else {
	&display_page('Registration', 'Registration', [\&identity, \&search, \&main_ctl], [\&register_warning]);
}
%>

