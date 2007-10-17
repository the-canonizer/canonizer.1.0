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
	&display_page("Manage " . $history->{manage_ident}, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

display_page('Manage ' . $history->{manage_ident}, [\&identity, \&search, \&main_ctl], [\&manage_record]);



########
# subs #
########

sub manage_record {

	my $record = $history->{record_array}->[0];

	my $topic_url = 'http://' . &func::get_host() . '/topic.asp/' . $record->{'topic_num'};

	if ($class eq 'statement') {
		$topic_url .= ('/' . $record->{statement_num});
	} elsif ($class eq 'text') {
		$topic_url .= ('/' . $record->{statement_num});
		if ($record->{text_size}) { # specify the long to be displayed with the short.
			$topic_url .= '?long_short=2';
		}
	}

	%>
	<div class="main_content_container">

	<p><a href="<%=$topic_url%>">Return to topic page</a></p>

<p>This record management page shows the history of this record with
the latest version on top.  To make a change to this <%=$class%>
record, select the record below you want to start with and take the
"Propose Modification" link.  This will take you to a form page with
the selected record values pre-populated in the fields where you can
make changes and submit them.</p>

<table>
<tr class=proposed_record><td>Yellow</td><td>Proposed version</td></tr>
<tr class=active_record><td>Green</td><td>Currently live or active version</td></tr>
<tr class=objected_record><td>Red</td><td>Supporter objected</td></tr>
<tr class=history_record><td>Blue</td><td>Replaced version</td></tr>
</table>
<br>

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
