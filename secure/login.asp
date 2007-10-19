<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
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

if ($Request->Form('destination')) {
	$destination = $Request->Form('destination');
}


if ($Request->Form('submit')) {
	do_login();
}

display_page('Login', 'Login', [], [\&login_form]);


########
# subs #
########

sub login_form {

	if ($message) {
		$Response->Write($message);
	}

	my $email = $Session->{'email'};
	my $password = $Session->{'password'};

%>

<form method = post>
<input type = hidden name = destination value = "<%=$destination%>">

<p>E-Mail:</p>
<p><input type = text name = email value = "<%=$email%>" id = "email"></p>
<p>Password:</p>
<p><input type = password name = password value = "<%=$password%>"></p>
<p><input type = submit name = submit value = Login></p>
<p><a href = "http://<%=func::get_host()%>/register.asp">Register</a> if you haven't yet.</p>

</form>

<script language="JavaScript">
    	document.getElementById("email").focus();
</script>

<%
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

