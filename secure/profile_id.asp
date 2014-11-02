<%

use bad_email;

if(!$ENV{"HTTPS"}) {
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}

my $message = '';
my $errors = 0;
my %form_state = ();

#
# see comments at head of includes/identity.asp for info about modes (0, 1, 2)
#

#
# profile_id.asp has two modes:
#	register new user (?register=1).
#		Any mode OK, just ignore and register new user.
#		Set to new user, log them in to mode 2, when registered.
#	update info from existing user (when logged in)
#		0	no link for this case, but if we get here, redirect to login.
#				navigation link to here removed when in guest 0 mode.
#		1	redirect to login with destination back to profile_id.asp
#		2	update existing info.
#

my $cid = 0;

# When I do 0, it seems to leave a lock active if it crashes.
# restarting httpd cleans it up.
# don't want to risk this for now, should probably clean this up some day.
# probably need to do some kind of timeout or something in the asp daemons,
# so it cleans up the lock and does a rollback if the asp script crashes.
# my $dbh = func::dbh_connect(0) || die "unable to connect to database";
my $dbh = func::dbh_connect(1) || die "unable to connect to database";

my $register = 0; # registering a new user.
if ($Request->QueryString('register') or $Request->Form('register')) {
	$register = 1;
} else {
	$cid = $Session->{'cid'};
}

my %nick_names = (); # this is only set if not $register and $cid (updating data.)
my $have_nick_name = 0;

if ($cid && ! $register) {
	%nick_names = func::get_nick_name_hash($cid, $dbh);
	if (! $nick_names{'error_message'}) {
		$have_nick_name = 1;
	}
}

if ($cid and ! $Session->{'logged_in'}) {
	$Response->Redirect("login.asp?destination=/secure/profile_id.asp");
}




if ($Request->Form('submit')) {
	save_values();
}

my $title = 'Account Info';
if ($register) {
	$title = 'Register';
}

display_page($title, $title, [\&identity, \&search, \&main_ctl], [\&profile_id], \&profile_tabs);



########
# subs #
########


sub format_error {
	$errors++;
	return('<p class="error_message">' . $_[0] . '</p>');
}


sub format_success {
	return('<p class="success_message">' . $_[0] . '</p>');
}


sub save_values {

	my $selstmt;
	my $sth;
	my %dummy = ();

	if (length($form_state{'first_name'} = $Request->Form('canon_first_name')) < 1) {
		$message .= format_error("First Name is required.");
	}
	$form_state{'middle_name'} = $Request->Form('canon_middle_name');
	if (length($form_state{'last_name'} = $Request->Form('canon_last_name')) < 1) {
		$message .= format_error("Last Name is required.");
	}
	if (length($form_state{'email'} = $Request->Form('canon_email')) < 1) {
		$message .= format_error("E-mail is required.");
	} else { # check for unique e-mail
		$selstmt = 'select cid from person where email = ?';
		if ($cid && !$register) {
			$selstmt .= " and not cid = $cid";
		}
		$sth = $dbh->prepare($selstmt) || die "Failed to prepare " . $selstmt;
		$sth->execute($form_state{'email'}) || die "Failed to prepare " . $selstmt;
		if ($sth->fetch()) {
			$message .= format_error("An identity with email " . $form_state{'email'} . " already exists.");
		}
		$sth->finish();
	}

	my $birthday = $Request->Form('canon_birthday');
	if (length($birthday) > 1) {
		$form_state{'birthday'} = $birthday;
		if ($birthday !~ m|^\d\d\d\d/\d\d/\d\d$|) {
			$message .= format_error("($birthday) is an improperly formatted birthday, must be yyyy/mm/dd");
		}
	} else {
		$form_state{'birthday'} = '';
	}

	$form_state{'address_1'}   = $Request->Form('canon_address_1');
	$form_state{'address_2'}   = $Request->Form('canon_address_2');
	$form_state{'city'}        = $Request->Form('canon_city');
	$form_state{'state'}       = $Request->Form('canon_state');
	$form_state{'postal_code'} = $Request->Form('canon_postal_code');
	$form_state{'country'}     = $Request->Form('canon_country');

	my $private_flags_str = '';

	if ($Request->Form('canon_first_name_private')) {
		$form_state{'first_name_private'}  = 1;
		$private_flags_str .= 'first_name,';
	} else {
		$form_state{'first_name_private'}  = 0;
	}

	if ($Request->Form('canon_middle_name_private')) {
		$form_state{'middle_name_private'} = 1;
		$private_flags_str .= 'middle_name,';
	} else {
		$form_state{'middle_name_private'} = 0;
	}

	if ($Request->Form('canon_last_name_private')) {
		$form_state{'last_name_private'} = 1;
		$private_flags_str .= 'last_name,';
	} else {
		$form_state{'last_name_private'} = 0;
	}

	if ($Request->Form('canon_email_private')) {
		$form_state{'email_private'} = 1;
		$private_flags_str .= 'email,';
	} else {
		$form_state{'email_private'} = 0;
	}

	if ($Request->Form('canon_birthday_private')) {
		$form_state{'birthday_private'} = 1;
		$private_flags_str .= 'birthday,';
	} else {
		$form_state{'birthday_private'} = 0;
	}
 
	if ($Request->Form('canon_address_1_private')) {
		$form_state{'address_1_private'} = 1;
		$private_flags_str .= 'address_1,';
	} else {
		$form_state{'address_1_private'} = 0;
	}

	if ($Request->Form('canon_address_2_private')) {
		$form_state{'address_2_private'} = 1;
		$private_flags_str .= 'address_2,';
	} else {
		$form_state{'address_2_private'} = 0;
	}

	if ($Request->Form('canon_city_private')) {
		$form_state{'city_private'} = 1;
		$private_flags_str .= 'city,';
	} else {
		$form_state{'city_private'} = 0;
	}

	if ($Request->Form('canon_state_private')) {
		$form_state{'state_private'} = 1;
		$private_flags_str .= 'state,';
	} else {
		$form_state{'state_private'} = 0;
	}

	if ($Request->Form('canon_postal_code_private')) {
		$form_state{'postal_code_private'} = 1;
		$private_flags_str .= 'postal_code,';
	} else {
		$form_state{'postal_code_private'} = 0;
	}

	if ($Request->Form('canon_country_private')) {
		$form_state{'country_private'} = 1;
		$private_flags_str .= 'country,';
	} else {
		$form_state{'country_private'} = 0;
	}

	if ($private_flags_str) {
		chop($private_flags_str); # remove last ','
	}

	my $pass_val = '';
	my $password = $Request->Form('canon_password');
	if (length($password) > 0) {
		if ($password ne $Request->Form('canon_password_confirm') ) {
			$message .= format_error('Password and Confirmation Password did not match.');
		}
		$pass_val = func::canon_encode($password);
	} elsif ($register) {
		$message .= format_error('Password is required when registering.');
	}

	if ($cid && ! $register) {
		foreach my $nick_name_id (keys %nick_names) {
			if ($Request->Form("private_nick_id_$nick_name_id")) { # will be 'on' if it exists / checked.
				$nick_names{$nick_name_id}->{'private'} = 1;
			} else {
				$nick_names{$nick_name_id}->{'private'} = 0;
			}
		}
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
		if ($register or (func::nick_name_count($dbh, $cid) < 1)) {
			$message .= format_error("Nick Name required. (You must have at least one.)");
		}
	}

	if ($errors) {
		return()
	};

	if ($register) { # create new entry and log them in.

		$cid = func::get_next_id($dbh, 'person', 'cid');

		my $now_time = time;

		$selstmt = "insert into person (cid, first_name, middle_name, last_name, email, password, birthday, address_1, address_2, city, state, postal_code, country, create_time, join_time) values ($cid, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, $now_time, $now_time)";

		if ($dbh->do($selstmt, \%dummy,
				$form_state{'first_name'},
				$form_state{'middle_name'},
				$form_state{'last_name'},
				$form_state{'email'},
				$pass_val,
				$form_state{'birthday'},
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
	} else { # update existing entry

		if (length($password) > 0) {
			$selstmt = 'update person set password = ? where cid = ' . $cid;
			if (! $dbh->do($selstmt, \%dummy, func::canon_encode($password)) ) {
				$message .= format_error("Sorry, the database is currently having problems.");
			}
		}

		if (!$errors) {

			$selstmt = "update person set first_name = ?, middle_name = ?, last_name = ?, email = ?, birthday = ?, address_1 = ?, address_2 = ?, city = ?, state = ?, postal_code = ?, country = ?, private_flags = ? where cid = $cid";

			if ($dbh->do($selstmt, \%dummy,
					$form_state{'first_name'},
					$form_state{'middle_name'},
					$form_state{'last_name'},
					$form_state{'email'},
					$form_state{'birthday'},
					$form_state{'address_1'},
					$form_state{'address_2'},
					$form_state{'city'},
					$form_state{'state'},
					$form_state{'postal_code'},
					$form_state{'country'},
					$private_flags_str          )) {

				$Session->{'email'} = $form_state{'email'};

				if ($have_nick_name) {
					my $private_nick_clause = '';
					my $public_nick_clause  = '';
					foreach my $nick_name_id (keys %nick_names) {
						if ($nick_names{$nick_name_id}->{'private'}) {
							$private_nick_clause .= "nick_name_id = $nick_name_id or ";
						} else {
							$public_nick_clause .= "nick_name_id = $nick_name_id or ";
						}
					}
					if ($private_nick_clause) {
						chop($private_nick_clause); # get rid of last ' or ';
						chop($private_nick_clause);
						chop($private_nick_clause);
						chop($private_nick_clause);
						$selstmt = "update nick_name set private = 1 where $private_nick_clause";
						if (! $dbh->do($selstmt)) {
							$message .= format_error("Sorry, the database is currently having problems.");
						}
					}
					if ($public_nick_clause) {
						chop($public_nick_clause); # get rid of last ' or ';
						chop($public_nick_clause);
						chop($public_nick_clause);
						chop($public_nick_clause);
						$selstmt = "update nick_name set private = 0 where $public_nick_clause";
						if (! $dbh->do($selstmt)) {
							$message .= format_error("Sorry, the database is currently having problems.");
						}
					}
				}

				if (! $errors) {
					$message .= format_success("Update Completed.");
				}
			} else {
				$message .= format_error("Sorry, the database is currently having problems.");
			}
		}
	}

	if ((! $errors) and (length($new_nick_name) > 0)) {

		my $nick_name_id = func::get_next_id($dbh, 'nick_name', 'nick_name_id');

		$owner_code = func::canon_encode($cid);

		my $now_time = time;

		my $private = 0;
		if ($Request->Form('new_nick_name_private')) { # will be 'yes' if it exists.
			$private = 1;
		}

		$selstmt = "insert into nick_name (nick_name_id, owner_code, nick_name, private, create_time) values ($nick_name_id, '$owner_code', ?, ?, $now_time)";

		# may want to convert this to dbh->do some day
		my %dummy = ();
		if (! $dbh->do($selstmt, \%dummy, $new_nick_name, $private)) {
			$message .= format_error("Sorry, the database is currently having problems.");
		}
	}

	# See comment on dbh_connect(0) above.
	# if ($errors) {
	# 	$dbh->rollback();
	# } else {
	# 	$dbh->commit();
	# }
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

	if ($register) {
		$submit_value = 'Register';
	} elsif (! $errors) { # user form values when there are errors, else db values.
		if ($dbh) {

			if ($cid) { # just to be sure we have real db values.
				%nick_names = func::get_nick_name_hash($cid, $dbh);
			}

			my $selstmt = "select first_name, middle_name, last_name, email, birthday, address_1, address_2, city, state, postal_code, country, private_flags+0 from person where cid = $cid";

			$sth = $dbh->prepare($selstmt) || die $selstmt;
			$sth->execute() || die $selstmt;

			$rs = $sth->fetchrow_hashref;

			my $private_flags = 0;
			if ($rs) {
				$form_state{'first_name'}  = $rs->{'first_name'};
				$form_state{'middle_name'} = $rs->{'middle_name'};
				$form_state{'last_name'}   = $rs->{'last_name'};
				$form_state{'email'}       = $rs->{'email'};
				$form_state{'birthday'}    = $rs->{'birthday'};
				$form_state{'address_1'}   = $rs->{'address_1'};
				$form_state{'address_2'}   = $rs->{'address_2'};
				$form_state{'city'}        = $rs->{'city'};
				$form_state{'state'}       = $rs->{'state'};
				$form_state{'postal_code'} = $rs->{'postal_code'};
				$form_state{'country'}     = $rs->{'country'};
				$private_flags             = $rs->{'private_flags+0'};

				if ($private_flags & 1) {
					$form_state{'first_name_private'} = 1;
				} else {
					$form_state{'first_name_private'} = 0;
				}

				if ($private_flags & 2) {
					$form_state{'middle_name_private'} = 1;
				} else {
					$form_state{'middle_name_private'} = 0;
				}

				if ($private_flags & 4) {
					$form_state{'last_name_private'} = 1;
				} else {
					$form_state{'last_name_private'} = 0;
				}

				if ($private_flags & 8) {
					$form_state{'email_private'} = 1;
				} else {
					$form_state{'email_private'} = 0;
				}

				if ($private_flags & 16) {
					$form_state{'birthday_private'} = 1;
				} else {
					$form_state{'birthday_private'} = 0;
				}

				if ($private_flags & 32) {
					$form_state{'address_1_private'} = 1;
				} else {
					$form_state{'address_1_private'} = 0;
				}

				if ($private_flags & 64) {
					$form_state{'address_2_private'} = 1;
				} else {
					$form_state{'address_2_private'} = 0;
				}

				if ($private_flags & 128) {
					$form_state{'city_private'} = 1;
				} else {
					$form_state{'city_private'} = 0;
				}

				if ($private_flags & 256) {
					$form_state{'state_private'} = 1;
				} else {
					$form_state{'state_private'} = 0;
				}

				if ($private_flags & 512) {
					$form_state{'postal_code_private'} = 1;
				} else {
					$form_state{'postal_code_private'} = 0;
				}

				if ($private_flags & 1024) {
					$form_state{'country_private'} = 1;
				} else {
					$form_state{'country_private'} = 0;
				}


			} else {
				$Response->Write("<h2>For some reason we can't look up your cid.  Please contact <a href=\"mailto:support\@canonizer.com\">support\@canonizer.com</a></h2>\n");
				return();
			}
			$sth->finish();

		} else {
			$Response->Write("<h2>A database error occurred, please try again latter.</h2>\n");
			return();
		}
	}

	my $pass_star = '';
	my $pass_comment = '';
	if ($register) {
		$pass_star = '*';
	} else { # registring for the first time so required
		$pass_comment = '<br>(Only if changeing)';
	}


if (bad_email::is_bad_email($form_state{'email'})) {
%>
<h1><font color="red">

NOTE: The e-mail adress <%= $form_state{'email'} %> has been deactivated.  
Contact support@canonizer.com to fix this or if you have any questions.

</font></h1>
<%
}
%>

<div class="main_content_container">

<%= $message %>
<br>
<br>

<form method=post>

<input type=hidden name=register value="<%=$register%>">

<table>

<tr><td colspan=3>Checks from any advertisement revenue earned will be dispersed to this name and address</td><td>&nbsp; &nbsp;</td><td>Private</tr></tr>

<tr><td class=separator></td></tr>

<tr><td>Legal First Name: </td>
    <td class="required_field">*</td>
    <td><input type=text name=canon_first_name value="<%=$form_state{'first_name'}%>">
    <td></td>
    </td><td><input type=checkbox name=canon_first_name_private <%=$form_state{'first_name_private'} ? 'checked' : ''%>></td></tr>

<tr><td>Legal Middle Name:</td>
    <td class="required_field">&nbsp;</td>
    <td><input type=string name=canon_middle_name value="<%=$form_state{'middle_name'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_middle_name_private <%=$form_state{'middle_name_private'} ? 'checked' : ''%>></td></tr>

<tr><td>Legal Last Name: </td>
    <td class="required_field">*</td>
    <td><input type=text name=canon_last_name value="<%=$form_state{'last_name'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_last_name_private <%=$form_state{'last_name_private'} ? 'checked' : ''%>></td></tr>

<tr><td class=separator></td></tr>

<tr><td>E-Mail: </td>
    <td class="required_field">*</td>
    <td><input type=text name=canon_email size=40 value="<%=$form_state{'email'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_email_private <%=$form_state{'email_private'} ? 'checked' : ''%>></td></tr>

<tr><td class=separator></td></tr>

<tr><td>Password:<%=$pass_comment%></td>
    <td class="required_field"><%=$pass_star%></td>
    <td><input type=password name=canon_password></td></tr>

<tr><td>Password Confirmation:<%=$pass_comment%></td>
    <td class="required_field"><%=$pass_star%></td>
    <td><input type=password name=canon_password_confirm></td></tr>

<tr><td class=separator></td></tr>

<tr><td>Birthday (yyyy/mm/dd):</td>
    <td>*</td>
    <td><input type=text name=canon_birthday value="<%=$form_state{'birthday'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_birthday_private <%=$form_state{'birthday_private'} ? 'checked' : ''%>></td></tr>

<tr><td>Address 1:</td>
    <td>*</td>
    <td><input type=text name=canon_address_1 value="<%=$form_state{'address_1'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_address_1_private <%=$form_state{'address_1_private'} ? 'checked' : ''%>></td></tr>

<tr><td>Address 2:</td>
    <td>*</td>
    <td><input type=text name=canon_address_2 value="<%=$form_state{'address_2'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_address_2_private <%=$form_state{'address_2_private'} ? 'checked' : ''%>></td></tr>

<tr><td>City:</td>
    <td>*</td>
    <td><input type=text name = canon_city value = "<%=$form_state{'city'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_city_private <%=$form_state{'city_private'} ? 'checked' : ''%>></td></tr>

<tr><td>Region (state, province, etc):</td>
    <td>*</td>
    <td><input type=text name=canon_state value="<%=$form_state{'state'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_state_private <%=$form_state{'state_private'} ? 'checked' : ''%>></td></tr>

<tr><td>Postal Code:</td>
    <td>*</td>
    <td><input type=text name=canon_postal_code value="<%=$form_state{'postal_code'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_postal_code_private <%=$form_state{'postal_code_private'} ? 'checked' : ''%>></td></tr>

<tr><td>Country:</td>
    <td>*</td>
    <td><input type=text name=canon_country value="<%=$form_state{'country'}%>"></td>
    <td></td>
    <td><input type=checkbox name=canon_country_private <%=$form_state{'country_private'} ? 'checked' : ''%>></td></tr>

</table>

<p><font color=red>*</font> These fields are required simply to help
prevent dual identity sock puppet cheating.  No information provided
will be used for anything else.  If you check the 'Private' box, this
information will never be publicly displayed on any page.</p>

<p>* These fields are not required to register and participate with
the Canonizer.  In the future, there may be canonizer algorithms that
require this info be provided, and there may be some financial reward
offered for participating, so this info may be used for that purpose.
For example, if you own Canonizer.com coins, we may use this
information to contact you to distribute your shares if we go
"cryptographically public"</p>

<p>&nbsp;</p>

<p class="section_heading">Permanent Nick Names:</p>

<p>Normally, nick names have public links back to their owners
providing public access to relevant non private information about you.
If you check the anonymous box for a nick name, no information tying
that nick name to you will be provided.  Only the canonizers will know
who owns them for canonization purposes.</p>

<table>
<tr><td class=separator></td></tr>
<tr><td class=separator></td></tr>


<%
if (!$register) {

	if ($have_nick_name) {
		%>
		<tr><td colspan=2>Current nick names:</td><td>Anonymous</td></tr>
		<%

		my $nick_name_id;
		foreach $nick_name_id (keys %nick_names) {
			my $checked_str = '';
			if ($nick_names{$nick_name_id}->{'private'}) {
				$checked_str = 'checked';
			}
			%>
			<tr><td><%=$nick_names{$nick_name_id}->{'nick_name'}%></td>
			    <td></td>
			    <td><input type=checkbox <%=$checked_str%> name=private_nick_id_<%=$nick_name_id%>></td></tr>
			<%
		}
	} else {
		%>
		<tr><td colspan=3>No Nick Names Specified Yet.</td></tr>
		<%
	}
}

%>

<tr><td class=separator></td></tr>
<tr><td class=separator></td></tr>

<tr><td>Add New Permanent Nick Name:</td><td>&nbsp;</td><td>Anonymous</td></tr>

<tr><td>

	<%
	if (! $have_nick_name) {
		%>
		<span class="required_field">* </span>
		<%
	}
	%>



                  <input type = string name = new_nick_name maxlength=25 size=25 value="<%=$form_state{'new_nick_name'}%>"></p></td>
    <td></td>
    <td><input type=checkbox name=new_nick_name_private></td></tr>

</table>


<p><input type=reset value="Reset Form"></p>
<p><input type = submit name = submit value = "<%=$submit_value%>"></p>



</form>

</div>

<%
}



%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/profile_tabs.asp"-->
