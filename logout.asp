<%

########
# main #
########

my $destination;

# by default redirect back to where we came from.
my $referer = $ENV{'HTTP_REFERER'};
if ($referer =~ m|[^/]+//[^/]+(/.*)|) {
	$destination = $1;
}

# be sure to add a '/' at the beginning of the destination value (should be a full path uri)
if ($Request->QueryString('destination')) {
	$destination = $ENV{'QUERY_STRING'}; # get the destination arguments too.
	$destination =~ s|\&?clear=1||gi;
	$destination =~ s|\&?destination=||gi;  # remove the arguments to login (all others get passed on.)
}

if ($destination =~ m|^/secure|) {
	# Once logged out - cannot return to secure pages so go home.
	$destination = '';
}

$Session->{'logged_in'} = 0;

my $clear_flag = $Request->QueryString('clear');
if ($clear_flag) {

	# delete this cookie on client by setting Expires to the past.
	$Response->{Cookies}{canonizer} = {
			Value   => {
				cid => 0,
			},
			Expires => "Wed, 1 Mar 2006 00:00:00 GMT",
			Domain  => 'canonizer.com',
			Path    => '/'
		};

	# start a new session
	$Session->Abandon();
}

# no need to check for secure in destination here because that removed from $destination above.
# can't go there after logging out.

$Response->Redirect('http://' . &func::get_host() . $destination);

%>

