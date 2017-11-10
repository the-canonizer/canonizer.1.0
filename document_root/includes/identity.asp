

<%

# Identity modes:
# 
# Identity line (and mode specification):
# 	0    Browsing as guest
# 	1    Browsing as e-mail
# 	2    Logged in as e-mail
# Acccount Info Line
#       1 , 2 Accont Info (link unless on page)
# Login line:
#       0	Login
#       1	Login (can do different user, but no mention of this.)
#       2	Login as different user
# Logout line:
#       2	Logout to browsing as
# Clear Browser line:
#       1, 2    Clear Browser (logout.asp?clear=1)
# Register line:
#	0, 1, 2	Register New User
#


my $mode = 0;


sub guest_cookie_expire_time {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(time + (60*60*24));
	my @days = (Sun, Mon, Tue, Wed, Thu, Fri, Sat);
	my @months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);

	$wday = @days[$wday];
	$mon  = $months[$mon];
	$year = $year + 1900;

	my $ret_val = sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT\n", $wday, $mday, $mon, $year, $hour, $min, $sec);

	return($ret_val);
}


sub identity {

	my $script_name = $ENV{'SCRIPT_NAME'};
	my $uri = $ENV{'REQUEST_URI'};

	if ($ENV{'PATH_INFO'}) {
		$script_name .= $ENV{'PATH_INFO'};
	}

	my $login_url = 'https://' . &func::get_host() . "/secure/login.asp?destination=$script_name";
	my $logout_url = 'http://' . &func::get_host() . "/logout.asp?destination=$script_name";
	my $clear_url = 'http://' . &func::get_host() . "/logout.asp?clear=1&destination=$script_name";

	if ($ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $ENV{'QUERY_STRING'});
		$logout_url .= ('?' . $ENV{'QUERY_STRING'});
		$clear_url .= ('?' . $ENV{'QUERY_STRING'});
	}

	$Session->{'page_count'}++;

	my $cid = 0; # canon id
	if ($Request->Form('cid')) {
		$cid = int($Request->Form('cid'));
	} elsif ($Request->QueryString('cid')) {
		$cid = int($Request->QueryString('cid'));
	} elsif ($Request->Cookies('canonizer', 'cid')) {
		$cid = int($Request->Cookies('canonizer', 'cid'));
	} elsif ($Session->{'cid'}) {
		$cid = $Session->{'cid'};
	}

	if ($cid != $Session->{'cid'}) { # lookup and reset personal session data.
		$Session->{'cid'} = $cid;
		$Session->{'logged_in'} = 0; # if cid changes - we must move to browsing as mode.
					     # till we login again.
		$Session->{'email'} = '';    # and reload session browsing settings.
	}

	my $logged_in_as;

	if ($cid) {

		if (! length($Session->{'email'})) { # reload browsing values into session and validate cid.
			my $dbh = &func::dbh_connect(1);
			if ($dbh) {
				my $selstmt = "select email from person where cid = $cid";
				my $sth = $dbh->prepare($selstmt) || die $selstmt;
				$sth->execute() || die $selstmt;
				my $rs = $sth->fetch();
				$sth->finish();
				if ($rs) {
					$Session->{'email'} = &func::hex_decode($rs->[0]);
					# must also set canonizer and stuff...
				} else { # invalid cid!
					goto NO_CID;
				}
			} #if no db just leave things as they are.
		}

		# I've got to query the DB here and get the email from the DB
		# especially if we are not logging in - but just returning with cid in cookie.
		# and don't clear the gid if we fail.
		if ($Session->{'gid'}) { # got a cid so free the guest id if not already cleared
			&free_gid($Session->{'gid'});
			$Session->{'gid'} = 0;
		}
		$Session->{'cid'} = $cid;
		$logged_in_as = $Session->{'email'};
		# $logged_in_as = "Canonizer_" . $cid;
		$mode = 1;

		# set cookie cid (and the compact_policy)
		my $compact_policy = 'CP="NON DSP COR LAW CURa CONa HISa TELa OTPa OUR DELa OTRa IND UNI STA"';
	        $Response->AddHeader('P3P', $compact_policy);

		$Response->{Cookies}{canonizer} = {
				Value   => {
					cid => $cid,
				},
				Expires => "Fri, 1 Jan 2020 00:00:00 GMT",
				Domain  => 'canonizer.com',
				Path    => '/'
		};
	} else {
NO_CID:		my $gid = $Session->{'gid'};
		if (! $gid) {  # for some reason, we don't always have a gid here.
			$gid = &get_gid();
			$Session->{'gid'} = $gid;
		}
		$logged_in_as = 'Guest_' . $Session->{'gid'};

		# set cookie gid (and the compact_policy)
		my $compact_policy = 'CP="NON DSP COR LAW CURa CONa HISa TELa OTPa OUR DELa OTRa IND UNI STA"';
	        $Response->AddHeader('P3P', $compact_policy);

		$Response->{Cookies}{canonizer} = {
				Value   => {
					gid => $gid,
				},
				Expires => guest_cookie_expire_time(),
				Domain  => 'canonizer.com',
				Path    => '/'
		};
	}

	my $mode_prompt = 'Browsing as:';
	if ($Session->{'logged_in'}) {
		$mode_prompt = 'Logged in as:';
		$mode = 2;
	}
%>

  	<div class="identity">

	<h1>Identity</h1>

	<p><%=$mode_prompt%> <%=$logged_in_as%></p>

	<%
	# account inf line:
	if ($Session->{'cid'}) { # mode 1 or 2
		if ($uri =~ '/secure/profile_') {
			    %>
			    <p id="selected">Account Info</p>
			    <%
		} else {
			    %>
			    <p><a href='https://<%=&func::get_host()%>/secure/profile_id.asp'>Account Info</a></p>
			    <%
		}
	}

	# login line:
	if ($mode == 2) {
		%>
		<p><a href = "<%=$login_url%>">Login as different user</a>
		<%
	} else {
		%>
		<p><a href = "<%=$login_url%>">Login</a>
		<%
	}

	if ($mode == 2) { # logout line:
		%>
		<p><a href = "<%=$logout_url%>">Logout (to browsing as)</a></p>
		<%
	}

	if (($mode == 1) or ($mode == 2)) { # clear browser line:
		%>
		<p><a href = "<%=$clear_url%>">Clear Browser</a></p>
		<%
	}

	# register new user line:
	%>
	<p><a href = "http://<%=&func::get_host()%>/secure/profile_id.asp?register=1">Register New User</a></p>
  	</div>
	<%
}

%>

