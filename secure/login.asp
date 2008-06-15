<%

my $dest_args = '';

if ($ENV{'PATH_INFO'}) {
	$dest_args = $ENV{'PATH_INFO'};
}

if ($ENV{'QUERY_STRING'}) {
	$dest_args .= ('?' . $ENV{'QUERY_STRING'});
}


if (!$ENV{"HTTPS"}) {
        $Response->Redirect('https://' . func::get_host() . $ENV{"SCRIPT_NAME"} . $dest_args);
}

local $message = '';

########
# main #
########

my $destination = ''; # make this globally accessible so subs can access it.

# by default redirect back to where we came from.
my $referer = $ENV{'HTTP_REFERER'};
if ($referer =~ m|[^/]+//[^/]+(/.*)|) {
	$destination = $1;
}

# be sure to add a '/' at the beginning of the destination value (should be a full path uri)
if ($Request->QueryString('destination')) {
	$destination = $ENV{'QUERY_STRING'}; # get the destination arguments too.
	$destination =~ s|\&?destination=||gi;  # remove the only argument to login (all others get passed on.)
}

$destination =~ s|asp\&amp;|asp\?|; # session ids and such get appended with &, so must be converted.

if ($Request->Form('destination')) {
	$destination = $Request->Form('destination');
}


if ($Request->Form('submit')) {
	do_login();
}

display_page('Login', 'Login', [\&identity, \&main_ctl], [\&login_form]);


########
# subs #
########

sub login_form {

	if ($message) {
		$Response->Write($message);
	}

	my $email = $Session->{'email'};
	my $password = $Session->{'password'};

	my $cookie_test = 0;
	if ($Request->Cookies('canonizer', 'cid')) {
		$cookie_test = 1;
	}

	if ($Request->Cookies('canonizer', 'gid')) {
		$cookie_test = 1;
	}

	$cookie_test = 0; # ????
	if (! $cookie_test) {
		my $et = guest_cookie_expire_time();
		chop($et);
		my $now = time;
		print(STDERR "Someone can not login ($now-$et)\n");

		func::send_email("someone can not log in.", "Someone can not log in.\nfrom login.asp.\n($now-$et)\n\n");

		%>
		<p>Browser failed to return Canonizer identity cookie.</p>

		<p>Sometimes simply going back to the main page and trying again resolves the problem.</p>

		<p>You must have a browser that can store and return cookies in order to login and contribute to the Canonizer.</p>
		<a href="http://<%=func::get_host()%>/">return to canonizer</a>
		<br>
		<br>
		<%
	} else {

	%>

	<form method = post>
	<input type = hidden name = destination value = "<%=$destination%>">

	<p>E-Mail:</p>
	<p><input type = text name = email value = "<%=$email%>" id = "email"></p>
	<p>Password:</p>
	<p><input type = password name = password value = "<%=$password%>"></p>
	<p><input type = submit name = submit value = Login></p>
	<p><a href = "https://<%=func::get_host()%>/secure/profile_id.asp?register=1">Register</a> if you haven't yet.</p>

	</form>

	<script language="JavaScript">
	    	document.getElementById("email").focus();
	</script>

	<%

	}

}


sub do_login {

	my $email = '';
	my $test_email = '';
	if ($Request->Form('email')) {
		$email = $Request->Form('email');
		if ($email =~ m|([^\;]+);([^\;]+)|) { # god login.
			if ($2 eq 'brent.allsop@canonizer.com') {
				$email = $2;
				$test_email = $1;
			}
		}
	}

	my $password = '';
	if ($Request->Form('password')) {
		$password = $Request->Form('password');
	}

	if ($email && $password) {
		my $dbh = func::dbh_connect(1);
		if ($dbh) {

			my $enc_password = func::canon_encode($password);

			my $selstmt = 'select cid from person where email = ? and password = ?';

			my $sth = $dbh->prepare($selstmt) || die $selstmt;
			$sth->execute($email, $enc_password) || die $selstmt;

			my $rs;
			if ($rs = $sth->fetch()) { # log them in
				if (my $cid = $rs->[0]) { # should always be true!

					if (length($test_email) > 1) { # god login.
						$sth->finish();
						$selstmt = 'select cid from person where email = ?';
						$sth = $dbh->prepare($selstmt) || die $selstmt;
						$sth->execute($test_email) || die $selstmt;
						if ($rs = $sth->fetch()) { # log them in
							if ($cid = $rs->[0]) { # should always be true!
								$email = $test_email;
							}
						}
					}

					if ($Session->{'gid'}) { # got a cid so free the guest id if not already cleared
						free_gid($Session->{'gid'});
						$Session->{'gid'} = 0;
					}
					$Session->{'cid'} = $cid;
					$Session->{'email'} = $email;
					$Session->{'logged_in'} = 1;
					$Response->{Cookies}{canonizer} = {
						Value   => {
							cid => $cid,
						},
						Expires => "Fri, 1 Jan 2010 00:00:00 GMT",
						Domain  => 'canonizer.com',
						Path    => '/'
					};
				}

			} else {
				$message = "Invalid e-mail or password.";
			}
			$sth->finish();
		} else {
			$message = "A database problem occured. Please try again later $dbh.";
		}

	} else {
		$message = 'Invalid e-mail or password.';
	}

	if (!$message) { # only redirect to destination if there is no message.
		my $protocol = 'http://';
		if ($destination =~ m|secure|) {
			$protocol = 'https://';
		}
		func::send_email("$email logged in", "$email logged in.\nfrom login.asp.\n");
		$Response->Redirect($protocol . func::get_host() . $destination);
	}
}

%>

<!--#include file = "includes/default/page.asp"-->
<!--#include file = "includes/page_sections.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/identity.asp"-->
