<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/topic_tabs.asp"-->
<!--#include file = "includes/error_page.asp"-->

<%

use managed_record;
use topic;
use statement;
use text;

use history_class;

sub manage_record {

	my $record = $history->{record_array}->[0];

	my $topic_url = 'http://' . &func::get_host() . '/topic.asp?topic_num=' . $record->{'topic_num'};

	if ($class eq 'statement') {
		$topic_url .= ('&statement_num=' . $record->{statement_num});
	} elsif ($class eq 'text') {
		$topic_url .= ('&statement_num=' . $record->{statement_num});
		if ($record->{text_size}) { # specify the long to be displayed with the short.
			$topic_url .= '&long_short=2';
		}
	}

	%>
	<center>
	<a href="<%=$topic_url%>">Return to topic page</a>
	</center>
	<%
	$history->print_history($dbh);

}



########
# main #
########

local $error_message = '';

local $class;
if ($Request->Form('class')) {
	$class = $Request->Form('class');
} elsif ($Request->QueryString('class')) {
	$class = $Request->QueryString('class');
}

if (&managed_record::bad_managed_class($class)) {
	$error_message = "Error: '$class' is an invalid manage class.<br>\n";
	&display_page("Manage Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $args;

eval('$args = ' . $class . '::get_args($Request)');

if ($args->{'error_message'}) {
	$error_message = $args->{'error_message'};
	&display_page("<font size=5>Manage $class:</font><br>". $topic_num, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";

local $history = history_class->new($dbh, $class, $args);

if ($history->{error_message}) {
	$error_message = $history->{error_message};
	&display_page("<font size=5>Manage $class:</font><br>" . $history->{active}->{name}, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
} elsif ($history->{active} == 0) {
	$error_message = "Unknown Topic Number:&nbsp;" . $args->{'topic_num'} . ".<br>\n";
	&display_page("<font size=5>Manage $class:</font><br>" . $history->{active}->{name}, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

&display_page("<font size=5>Manage $class:</font><br>" . $history->{active}->{name}, [\&identity, \&search, \&main_ctl], [\&manage_record]);

%>

