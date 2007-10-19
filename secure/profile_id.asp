<%

if(!$ENV{"HTTPS"}) {
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}

my $message = '';
my %form_state = ();

########
# main #
########

# there are several cases leading into this page:
# logged in - setting personal information
# cid but not logged in - must go to login with this page as destination.
# click on the page after going to registration/search page. (searched flag set)
#	But could get here after session expires  (display must_search_first page)
# Go hear as guest from profile_prefs
# 	when we visit this page as a guest from another prefs page
# 	we want an advertizement page saying:
#		This is where you go to edit your personal identity data
#		or to enter it the first time when you do register.
#		But before that can take place, you must register.
#

if ($Request->QueryString('takeover_cid')) {
	$Session->{'takeover_cid'} = int($Request->QueryString('takeover_cid'));
}


if ($Session->{'cid'} and ! $Session->{'logged_in'}) {
	$Response->Redirect("login.asp?destination=/secure/profile_id.asp");
} elsif (!$Session->{'did_warning_search'} and ! $Session->{'logged_in'}) {
	display_page('Personal Info', 'Personal Info', [\&identity, \&search, \&main_ctl], [\&must_search_first], \&profile_tabs);
} elsif ($Session->{'logged_in'} or $Session->{'did_warning_search'}) {
	if ($Request->Form('submit')) {
		save_values();
	}
	display_page('Personal Info', 'Personal Info', [\&identity, \&search, \&main_ctl], [\&profile_id], \&profile_tabs);
} else {
%>
	How did you get here anyway?
<%
}


########
# subs #
########

sub must_search_first {

%>

This is where you go to edit your personal identity data or to
enter it the first time when you register.  If you are already a
member you must first <a href = "login.asp?destination=/secure/profile_id.asp">login</a>

If you are attempting to register for the first time, you must
first read the registration warning and do a search to ensure there is
no existing record for you at canonizer.  We have no record of you
doing this.  You can do all this <a href = "http://<%=func::get_host()%>/register.asp">here</a>

<%
}

sub format_error {
	return('<p class="error_message">' . $_[0] . '</p>');
}
sub format_success {
	return($_[0]);
}

sub save_values {

	my $cid;
	if($Session->{'takeover_cid'}) {
		$cid = $Session->{'takeover_cid'};
	} else {
		$cid = $Session->{'cid'};
	}

	my $dbh = func::dbh_connect(1) || die "unable to connect to database";

	my $selstmt;
	my $sth;

	if (length($form_state{'first_name'} = $Request->Form('first_name')) < 1) {
		$message .= format_error("First Name is required.");
	}
	$form_state{'middle_name'} = $Request->Form('middle_name');
	if (length($form_state{'last_name'} = $Request->Form('last_name')) < 1) {
		$message .= format_error("Last Name is required.");
	}
	if (length($form_state{'email'} = $Request->Form('email')) < 1) {
		$message .= format_error("E-mail is required.");
	} else { # check for unique e-mail
		$selstmt = 'select cid from person where email = ?';
		if ($cid) {
			$selstmt .= " and not cid = $cid";
		}
		$sth = $dbh->prepare($selstmt) || die "Failed to prepare " . $selstmt;
		$sth->execute($form_state{'email'}) || die "Failed to prepare " . $selstmt;
		if ($sth->fetch()) {
			$message .= format_error("Duplicate e-mail and or duplicate identities are not allowed.");
		}
		$sth->finish();
	}

	if (length($form_state{'address_1'} = $Request->Form('address_1')) < 1) {
		$message .= format_error("Address_1 is required.");
	}
	$form_state{'address_2'} = $Request->Form('address_2');
	if (length($form_state{'city'} = $Request->Form('city')) < 1) {
		$message .= format_error("City is required.");
	}
	if (length($form_state{'state'} = $Request->Form('state')) < 1) {
		$message .= format_error("State is required.");
	}
	if (length($form_state{'postal_code'} = $Request->Form('postal_code')) < 1) {
		$message .= format_error("Polstal Code is required.");
	}
	if (length($form_state{'country'} = $Request->Form('country')) < 1) {
		$message .= format_error("Country is required.");
	}

	my $pass_val = '';
	my $password = $Request->Form('password');
	if (length($password) > 0) {
		if ($password ne $Request->Form('password_confirm') ) {
			$message .= format_error('Password and Confirmation Password did not match.');
		}
		$pass_val = func::canon_encode($password);
	} elsif (! $Session->{'cid'}) {
		$message .= format_error('Password is required when registering.');
	}

	my $new_nick_name = $Request->Form('new_nick_name');
	if (length($new_nick_name) > 0) {
		$form_state{'new_nick_name'} = $new_nick_name;
		$selstmt = 'select nick_name_id from nick_name where nick_name = ?';
		$sth = $dbh->prepare($selstmt) || die "Failed to prepare " . $selstmt;
		$sth->execute($new_nick_name) || die "Failed to execute " . $selstmt;
		if ($sth->fetch()) {
			$message .= format_error("The nick name '$new_nick_name' is already taken.");
		}
		$sth->finish();
	} else {
		if ($cid) {
			if (func::nick_name_count($dbh, $cid) < 1) {
				$message .= format_error("Nick Name required. (You must have at least one.)");
			}
		} else {
			$message .= format_error("Nick Name required. (You must have at least one.)");
		}
	}

	if ($message) {return()};

	if (! $cid) { # create new entry and log them in.

		$cid = func::get_next_id($dbh, 'person', 'cid');

		my $now_time = time;

		$selstmt = "insert into person (cid, first_name, middle_name, last_name, email, password, address_1, address_2, city, state, postal_code, country, create_time, join_time) values ($cid, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, $now_time, $now_time)";

		# may want to convert this to dbh->do some day
		$sth = $dbh->prepare($selstmt) || die $selstmt;

		if ($sth->execute(
				$form_state{'first_name'},
				$form_state{'middle_name'},
				$form_state{'last_name'},
				$form_state{'email'},
				$pass_val,
				$form_state{'address_1'},
				$form_state{'address_2'},
				$form_state{'city'},
				$form_state{'state'},
				$form_state{'postal_code'},
				$form_state{'country'}      )) {

			if ($Session->{'gid'}) { # got a cid so free the guest id if not already cleared
				free_gid($Session->{'gid'});
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
			func::send_email($form_state{'first_name'} . ' registered.', "from profile_id.asp.\n");
			$message .= format_success("Registration Completed.");
		} else {
			$message .= format_error("DB Insert Failed.\n");
		}

		$sth->finish();

	} else { # update existing entry

		if (length($password) > 0) {
			$selstmt = 'update person set password = ? where cid = ' . $cid;
			# may want to convert this to dbh->do some day
			$sth = $dbh->prepare($selstmt);
			if (! $sth->execute(func::canon_encode($password)) ) {
				$message .= format_error("Sorry, the database is currently having problems.");
			}
		}

		if (!$message) {

			$selstmt = "update person set first_name = ?, middle_name = ?, last_name = ?, email = ?, address_1 = ?, address_2 = ?, city = ?, state = ?, postal_code = ?, country = ? where cid = $cid";

			# may want to convert this to dbh->do some day
			$sth = $dbh->prepare($selstmt);

			if ($sth->execute(
					$form_state{'first_name'},
					$form_state{'middle_name'},
					$form_state{'last_name'},
					$form_state{'email'},
					$form_state{'address_1'},
					$form_state{'address_2'},
					$form_state{'city'},
					$form_state{'state'},
					$form_state{'postal_code'},
					$form_state{'country'}      )) {

				$Session->{'email'} = $form_state{'email'};
				$message .= format_success("Update Completed.");
			} else {
				$message .= format_error("Sorry, the database is currently having problems.");
			}
		}
	}

	if (length($new_nick_name) > 0) {

		my $nick_name_id = func::get_next_id($dbh, 'nick_name', 'nick_name_id');

		$owner_code = func::canon_encode($cid);

		my $now_time = time;

		$selstmt = "insert into nick_name (nick_name_id, owner_code, nick_name, create_time) values ($nick_name_id, '$owner_code', ?, $now_time)";

		# may want to convert this to dbh->do some day
		$sth = $dbh->prepare($selstmt);
		if($sth->execute($new_nick_name)) {
			$form_state{'new_nick_name'} = ''; # can't submit this value again.
		} else {
			$message .= format_error("Sorry, the database is currently having problems.");
		}
		$sth->finish();
	}
}


sub profile_id {

	my $dbh = func::dbh_connect(1);
	my $sth;
	my $rs;

	my $spacer = 30;
	my $cid = 0;
	if ($Session->{'takeover_cid'}) {
		$cid = $Session->{'takeover_cid'};
	} else {
		$cid = $Session->{'cid'};
	}
	my $submit_value = 'Update';

	if ($cid and (length($form_state{'email'}) < 1)) {

		if ($dbh) {
			my $selstmt = "select first_name, middle_name, last_name, email, address_1, address_2, city, state, postal_code, country from person where cid = $cid";

			$sth = $dbh->prepare($selstmt) || die $selstmt;
			$sth->execute() || die $selstmt;

			$rs = $sth->fetchrow_hashref;

			if ($rs) {
				$form_state{'first_name'}  = $rs->{'first_name'};
				$form_state{'middle_name'} = $rs->{'middle_name'};
				$form_state{'last_name'}   = $rs->{'last_name'};
				$form_state{'email'}       = $rs->{'email'};
				$form_state{'address_1'}   = $rs->{'address_1'};
				$form_state{'address_2'}   = $rs->{'address_2'};
				$form_state{'city'}        = $rs->{'city'};
				$form_state{'state'}       = $rs->{'state'};
				$form_state{'postal_code'} = $rs->{'postal_code'};
				$form_state{'country'}     = $rs->{'country'};
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
		$pass_comment = '';
	}

	my @nick_names = ();

	if ($cid) {
		my $owner_code = func::canon_encode($cid);

		$selstmt = "select nick_name from nick_name where owner_code = '$owner_code' order by nick_name_id";

		$sth = $dbh->prepare($selstmt) || die $selstmt;
		$sth->execute() || die $selstmt;

		while ($rs = $sth->fetch()) {
			if ($rs->[0]) {
				push(@nick_names, $rs->[0]);
			}
		}
		$sth->finish();
	}


%>

<%=$message%>

<form method=post>
<p>Name:</p>
<p>Checks will be made out to this name.</p>
<p>Legal First Name: <span class="required_field">*</span></p>
<p><input type = string name = first_name value = "<%=$form_state{'first_name'}%>"></p>
<p>Legal Middle Name:</p>
<p><input type = string name = middle_name value = "<%=$form_state{'middle_name'}%>"></p>
<p>Legal Last Name: <span class="required_field">*</span></p>
<p><input type = string name = last_name value = "<%=$form_state{'last_name'}%>"></p>
<p>E-Mail: <span class="required_field">*</span></p>
<p><input type = string name = email value = "<%=$form_state{'email'}%>"></p>
<p>Password: <span class="required_field">*</span><%=$pass_comment%></p>
<p><input type = password name = password></p>
<p>Password Confirmation: <span class="required_field">*</span></p>
<p><input type = password name = password_confirm></p>
<p>Address: <span class="required_field">*</span></p>
<p>Checks will be mailed to this address.</p>
<p>Address 1: <span class="required_field">*</span></p>
<p><input type = string name = address_1 value = "<%=$form_state{'address_1'}%>"></p>
<p>Address 2:</p>
<p><input type = string name = address_2 value = "<%=$form_state{'address_2'}%>"></p>
<p>City: <span class="required_field">*</span></p>
<p><input type = string name = city value = "<%=$form_state{'city'}%>"></p>
<p>State: <span class="required_field">*</span></p>
<p><input type = string name = state value = "<%=$form_state{'state'}%>"></p>
<p>Postal Code: <span class="required_field">*</span></p>
<p><input type = string name = postal_code value = "<%=$form_state{'postal_code'}%>"></p>
<p>Country: <span class="required_field">*</span></p>
<p><input type = string name = country value = "<%=$form_state{'country'}%>"></p>
<p>Social Security Number: *</p>
<p><input type = string name = country value = ""></p>
<p>* A Social Security number is not required to register and fully
participate with the Canonizer.  However, if your contributions start
earning monetary rewards, we will not be able to pay you these until
you provide it here.</p>

<p>Permanent Nick Names:</p>

<p>You can have multiple Nick Names.  Some of them may obviously be you,
while others may be anonymous pen names possibly used to support
various controversial positions.  You must provide one to start.  You
may return to this page to add more.</p>

<%
if ($#nick_names >= 0) {
	my $idx;
	for ($idx = 0; $idx <= $#nick_names; $idx++) {
		%>
		<%=$nick_names[$idx]%>
		<%
	}
} else {
	%>
	<p>No Nick Names Specified Yet.</p>
	<%
}
%>

<p>Add New Permanent Nick Name:

<%
if (! ($#nick_names >= 0)) {
	%>
	<span class="required_field"> *</span>
	<%
}
</p>
%>

<p><input type = string name = new_nick_name maxlength=25 size=25 value="<%=$form_state{'new_nick_name'}%>"></p>

<p><input type=reset value="Reset Form"></p>
<p><input type = submit name = submit value = "<%=$submit_value%>"></p>

</form>

<%
}

sub temp_send_email {
	my $name = $_[0];

	open(MAIL, "| /bin/mail -s new_user brent\@canonizer.com") || die "can't open mail.\n";

	print(MAIL "A new user, $name, signed up!\n.\n\n");

	close(MAIL);

	print(STDERR "Sent e-mail.\n");

}


%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/profile_tabs.asp"-->
