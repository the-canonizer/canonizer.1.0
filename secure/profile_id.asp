<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/profile_tabs.asp"-->


<%

local $message = '';
local %form_state = ();

sub must_search_first {

%>

<p>This is where you go to edit your personal identity data or to
enter it the first time when you register.  If you are already a
member you must first <a href =
"login.asp?destination=/secure/profile_id.asp">login</a>.</p>

<p>If you are attempting to register for the first time, you must
first read the registration warning and do a search to ensure there is
no existing record for you at canonizer.  We have no record of you
doing this.  You can do all this <a href =
"http://<%=&func::get_host()%>/register.asp">here</a>.</p>

<%
}

sub format_error {
	return('<h3><font color = red>' . $_[0] . "</font></h3>\n");
}
sub format_success {
	return('<h3><font color = green>' . $_[0] . "</font></h3>\n");
}

sub save_values {

	if (length($form_state{'first_name'} = $Request->Form('first_name')) < 1) {
		$message .= &format_error("First Name is required.");
	}
	$form_state{'middle_name'} = $Request->Form('middle_name');
	if (length($form_state{'last_name'} = $Request->Form('last_name')) < 1) {
		$message .= &format_error("Last Name is required.");
	}
	if (length($form_state{'email'} = $Request->Form('email')) < 1) {
		$message .= &format_error("e-mail is required.");
	}

	if (length($form_state{'address_1'} = $Request->Form('address_1')) < 1) {
		$message .= &format_error("Address_1 is required.");
	}
	$form_state{'address_2'} = $Request->Form('address_2');
	if (length($form_state{'city'} = $Request->Form('city')) < 1) {
		$message .= &format_error("City is required.");
	}
	if (length($form_state{'state'} = $Request->Form('state')) < 1) {
		$message .= &format_error("State is required.");
	}
	if (length($form_state{'postal_code'} = $Request->Form('postal_code')) < 1) {
		$message .= &format_error("Polstal Code is required.");
	}
	if (length($form_state{'country'} = $Request->Form('country')) < 1) {
		$message .= &format_error("Country is required.");
	}

	my $cid;
	if($Session->{'takeover_cid'}) {
		$cid = $Session->{'takeover_cid'};
	} else {
		$cid = $Session->{'cid'};
	}

	my $pass_key = '';
	my $pass_val = '';
	my $password = $Request->Form('password');
	if (length($password) > 0) {
		if ($password ne $Request->Form('password_confirm') ) {
			$message .= &format_error('Password and Confirmation Password did not match.');
		}
		$pass_key = 'password,';
		$pass_val = "'" . &func::encrypt($password) . "', ";
	} elsif (! $Session->{'cid'}) {
		$message .= &format_error('Password is required when registering.');
	}

	if ($message) {return()};

	my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

	my $selstmt;

 	if (! $cid) { # create new entry and log them in.
		$selstmt = 'select cid_seq.nextval from dual';
		my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
		$sth->execute() || die "Failed to execute " . $selstmt;
		my $rs = $sth->fetch() || die "Failed to fetch with " . $selstmt;
		$cid = $rs->[0];
		$sth->finish();

		$selstmt = "insert into person (cid, first_name, middle_name, last_name, email, $pass_key address_1, address_2, city, state, postal_code, country, create_time, join_time) values ($cid, '" . &func::hex_encode($form_state{'first_name'}) . "', '" . &func::hex_encode($form_state{'middle_name'}) . "', '" . &func::hex_encode($form_state{'last_name'}) . "', '" . &func::hex_encode($form_state{'email'}) . "', " . $pass_val . "'" . &func::hex_encode($form_state{'address_1'}) . "', '" . &func::hex_encode($form_state{'address_2'}) . "', '" . &func::hex_encode($form_state{'city'}) . "', '" . &func::hex_encode($form_state{'state'}) . "', '" . &func::hex_encode($form_state{'postal_code'}) . "', '" . &func::hex_encode($form_state{'country'}) . "', sysdate, sysdate)";

# 		$dbh->do($sestmt) || die "Failed to create new record with " . $selstmt;
		my $sth = $dbh->prepare($selstmt) || die $selstmt;
		$sth->execute() || die "execute error: " . $selstmt;
		$sth->finish();
#????  Why does this work and the do doesn't ????
		if ($Session->{'gid'}) { # got a cid so free the guest id if not already cleared
			&free_gid($Session->{'gid'});
			$Session->{'gid'} = 0;
		}
		$Session->{'cid'} = $cid;
		$Session->{'email'} = $form_state{'email'};
		$Session->{'logged_in'} = 1;
		$Response->{Cookies}{canonizer} = {
			Value   => {
				cid => $cid,
			},
			Expires => "Fri, 1 Jan 2010 00:00:00 GMT",
			Domain  => 'canonizer.com',
			Path    => '/'
		};

		$message .= &format_success("Registration Completed.");

	} else { # update existing entry

		my $pass_clause = '';
		if ($password) {
			$pass_clause =  "password = '" . &func::encrypt($password) . "', ";
		}

		$selstmt = "update person set first_name = '" . &func::hex_encode($form_state{'first_name'}) . "', middle_name = '" . &func::hex_encode($form_state{'middle_name'}) . "', last_name = '" . &func::hex_encode($form_state{'last_name'}) . "', email = '" . &func::hex_encode($form_state{'email'}) . "', " . $pass_clause . "address_1 = '" . &func::hex_encode($form_state{'address_1'}) . "', address_2 = '" . &func::hex_encode($form_state{'address_2'}) . "', city = '" . &func::hex_encode($form_state{'city'}) . "', state = '" . &func::hex_encode($form_state{'state'}) . "', postal_code = '" . &func::hex_encode($form_state{'postal_code'}) . "', country = '" . &func::hex_encode($form_state{'country'}) . "' where cid = $cid";
		$dbh->do($selstmt) || die "Failed to update record with " . $selstmt;

		$message .= &format_success("Update Completed.");
	}
}


sub profile_id {

	my $spacer = 30;
	my $cid;
	if ($Session->{'takeover_cid'}) {
		$cid = $Session->{'takeover_cid'};
	} else {
		$cid = $Session->{'cid'};
	}
	my $submit_value = 'Update';

	if ($cid and (length($form_state{'email'}) < 1)) {

		my $dbh = &func::dbh_connect(1);
		if ($dbh) {
			my $selstmt = "select first_name, middle_name, last_name, email, address_1, address_2, city, state, postal_code, country from person where cid = $cid";

			my $sth = $dbh->prepare($selstmt) || die $selstmt;
			$sth->execute() || die $selstmt;

			my $rs = $sth->fetchrow_hashref;

			if ($rs) {
				$form_state{'first_name'} = &func::hex_decode($rs->{'FIRST_NAME'});
				$form_state{'middle_name'} = &func::hex_decode($rs->{'MIDDLE_NAME'});
				$form_state{'last_name'} = &func::hex_decode($rs->{'LAST_NAME'});
				$form_state{'email'} = &func::hex_decode($rs->{'EMAIL'});
				$form_state{'address_1'} = &func::hex_decode($rs->{'ADDRESS_1'});
				$form_state{'address_2'} = &func::hex_decode($rs->{'ADDRESS_2'});
				$form_state{'city'} = &func::hex_decode($rs->{'CITY'});
				$form_state{'state'} = &func::hex_decode($rs->{'STATE'});
				$form_state{'postal_code'} = &func::hex_decode($rs->{'POSTAL_CODE'});
				$form_state{'country'} = &func::hex_decode($rs->{'COUNTRY'});
			} else {
				$Response->Write("<h2>For some reason we can't look up your cid.  Please contact <a href=\"mailto:support\@canonizer.com\">support\@canonizer.com</a></h2>\n");
				return();
			}
			$sth->finish();
		} else {
			$Response->Write("<h2>A database error occurred, please try again latter.</h2>\n");
			return();
		}
	} elsif (length($form_state{'email'}) < 1) { # then we are registering for the first time.
		$submit_value = 'Register';
	}

	my $pass_comment;
	if ($Session->{'cid'}) {
		$pass_comment = '(if changing)';
	} else { # registring for the first time so required
		$pass_comment = '<font color = red>*</font>';
	}

%>

<%=$message%>

<form method=post>
<table border = 0>

<tr><td colspan = 2><b>Name:</b> Checks will be made out to this name.</td></tr>
<tr><td>Legal First Name: <font color = red>*</font> </td><td><input type = string name = first_name value = "<%=$form_state{'first_name'}%>"></td></td></tr>
<tr><td>Legal Middle Name:</td><td><input type = string name = middle_name value = "<%=$form_state{'middle_name'}%>"></td></td></tr>
<tr><td>Legal Last Name: <font color = red>*</font> </td><td><input type = string name = last_name value = "<%=$form_state{'last_name'}%>"></td></td></tr>

<tr height = <%=$spacer%>><td colspan = 2></td></tr>
<tr><td>e-mail: <font color = red>*</font> </td><td><input type = string name = email value = "<%=$form_state{'email'}%>"></td></td></tr>
<tr><td>Password: <%=$pass_comment%> </td><td><input type = password name = password></td></td></tr>
<tr><td>Password: (confirmation)</td><td><input type = password name = password_confirm></td></td></tr>


<tr height = <%=$spacer%>><td colspan = 2></td></tr>

<tr><td colspan = 2><b>Nick Names:</b> Used (anonymously if desired)
	for comunication and participation attribution.</td></tr>
<tr><td>Nick Name 1:</td><td><input type = string name = nick_name_1 value = "Brent_Allsop"></td></td></tr>
<tr><td>Nick Name 2:</td><td><input type = string name = nick_name_2 value = ""></td></td></tr>

<tr height = <%=$spacer%>><td colspan = 2></td></tr>

<tr><td colspan = 2><b>Address: <font color = red>*</font> </b> Checks will be mailed to this address.</td></tr>
<tr><td>Address 1: <font color = red>*</font> </td><td><input type = string name = address_1 value = "<%=$form_state{'address_1'}%>"></td></td></tr>
<tr><td>Address 2:</td><td><input type = string name = address_2 value = "<%=$form_state{'address_2'}%>"></td></td></tr>
<tr><td>City: <font color = red>*</font> </td><td><input type = string name = city value = "<%=$form_state{'city'}%>"></td></td></tr>
<tr><td>State: <font color = red>*</font> </td><td><input type = string name = state value = "<%=$form_state{'state'}%>"></td></td></tr>
<tr><td>Postal Code: <font color = red>*</font> </td><td><input type = string name = postal_code value = "<%=$form_state{'postal_code'}%>"></td></td></tr>
<tr><td>Country: <font color = red>*</font> </td><td><input type = string name = country value = "<%=$form_state{'country'}%>"></td></td></tr>

<tr height = <%=$spacer%>><td colspan = 2></td></tr>

<tr><td colspan = 2 align = center><input type=reset value="Reset">&nbsp; &nbsp; &nbsp;<input type = submit name = submit value = "<%=$submit_value%>"></td></tr>
</table>
</form>

<%
}

########
# main #
########

# there are several cases comming into this page:
# logged in - setting personal information
# cid but not logged in - must go to login with this page as destination.
# click on the page after going to registration/search page. (searched flag set)
#	But could get here after session expires  (display must_search_first page)
# Go hear as guest from profile_prefs
#
# when we visit this page as a guest from another prefs page
# we want an advertizement page saying:
#	This is where you go to edit your personal identity data
#	or to enter it the first time when you do register.
#	But before that can take place, you must
#

if ($Request->QueryString('takeover_cid')) {
	$Session->{'takeover_cid'} = int($Request->QueryString('takeover_cid'));
}


if ($Session->{'cid'} and ! $Session->{'logged_in'}) {
	$Response->Redirect("login.asp?destination=/secure/profile_id.asp");
} elsif (!$Session->{'did_warning_search'} and ! $Session->{'logged_in'}) {
	&display_page('CANONIZER', 'Personal Info', [\&identity, \&search, \&main_ctl], [\&must_search_first], \&profile_tabs);
} elsif ($Session->{'logged_in'} or $Session->{'did_warning_search'}) {
	if ($Request->Form('submit')) {
		&save_values();
	}
	&display_page('CANONIZER', 'Personal Info', [\&identity, \&search, \&main_ctl], [\&profile_id], \&profile_tabs);
} else {
%>
	<h1>How did you get here anyway???</h1>
<%
}
%>

