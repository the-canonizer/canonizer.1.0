
<!--#include file = "includes/default/page.asp"-->

<%

local $message = '';

sub login_form {

	if ($message) {
		$Response->Write($message);
	}

	my $email = $Session->{'email'};
	my $password = $Session->{'password'};

%>

<form method = post action = 'login.asp'>
  <input type = hidden name = destination value = "<%=$destination%>">
  <table>
    <tr><td>e-mail:</td><td><input type = text name = email value = "<%=$email%>" id = "email"></td></tr>
    <tr><td>password:</td><td><input type = password name = password value = "<%=$password%>"></td></tr>
    <tr><td>&nbsp;</td><td><input type = submit name = submit value = login></td></tr>
    <tr><td>&nbsp;</td><td><a href = "http://<%=&func::get_host()%>/register.asp">Register</a> if you haven't yet.
  </table>
</form>

<script language="JavaScript">
    	document.getElementById("email").focus();
</script>

<%
}

sub do_login {

	my $email = '';
	if ($Request->Form('email')) {
		$email = $Request->Form('email');
	}
	my $password = '';
	if ($Request->Form('password')) {
		$password = $Request->Form('password');
	}

	if ($email && $password) {
		my $dbh = &func::dbh_connect(1);
		if ($dbh) {

			my $enc_password = &func::canon_encode($password);

			my $selstmt = 'select cid from person where email = ? and password = ?';

			my $sth = $dbh->prepare($selstmt) || die $selstmt;
			$sth->execute($email, $enc_password) || die $selstmt;

			my $rs;
			if ($rs = $sth->fetch()) { # log them in
				if (my $cid = $rs->[0]) { # should always be true!
					if ($Session->{'gid'}) { # got a cid so free the guest id if not already cleared
						&free_gid($Session->{'gid'});
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
				$message = "<h2><font color = red>Invalid e-mail or password.</font></h2>";
			}
			$sth->finish();
		} else {
			$message = "<h2><font color = red>A database problem occured.  Please try again later $dbh.</font></h2>";
		}

	} else {
		$message = '<h2><font color = red>Invalid e-mail or password.</font></h2>';
	}

	if (!$message) { # login failed so don't redirect.
		my $protocol = 'http://';
		if ($destination =~ m|secure|) {
			$protocol = 'https://';
		}
		$Response->Redirect($protocol . &func::get_host() . $destination);
	}
}

########
# main #
########

local $destination = ''; # make this globally accessible so subs can access it.

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
	&do_login();
}

&display_page('CANONIZER', 'Login', [], [\&login_form]);

%>

