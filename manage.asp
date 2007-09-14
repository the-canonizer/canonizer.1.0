<%

use managed_record;
use topic;
use statement;
use text;

use history_class;

########
# main #
########

my $error_message = '';

my $class;
if ($Request->Form('class')) {
	$class = $Request->Form('class');
} elsif ($Request->QueryString('class')) {
	$class = $Request->QueryString('class');
}

if (&managed_record::bad_managed_class($class)) {
	$error_message = "Error: '$class' is an invalid manage class.\n";
	&display_page("Manage Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $args;

eval('$args = ' . $class . '::get_args($Request)');

if ($args->{'error_message'}) {
	$error_message = $args->{'error_message'};
	&display_page("Manage $class:" . $topic_num, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my $history = history_class->new($dbh, $class, $args);

if ($history->{error_message}) {
	$error_message = $history->{error_message};
	&display_page("Manage " . $history->{ident_str}, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
} elsif ($history->{active} == 0) {
	$error_message = "Unknown Topic Number: " . $args->{'topic_num'};
	&display_page("Manage " . $history->{ident_str}, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

display_page('Manage ' . $history->{ident_str}, [\&identity, \&search, \&main_ctl], [\&manage_record]);



########
# subs #
########

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
	<div class="main_content_container">

	<p><a href="<%=$topic_url%>">Return to topic page</a></p>
	<%
	$history->print_history($dbh);
	%>
		</div>
	<%

}



%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->
