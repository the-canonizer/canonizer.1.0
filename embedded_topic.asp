<%

use Time::Local;
use managed_record;
use topic;
use camp;
use support;
use statement;

my $path_info = $ENV{'PATH_INFO'};
my $pi_topic_num = 0;
my $pi_camp_num = 0;
if ($path_info =~ m|/(\d+)/?(\d*)|) {
	$pi_topic_num = $1;
	if ($2) {
		$pi_camp_num = $2;
	}
}

my $topic_num = 0;
if ($Request->Form('topic_num')) {
	$topic_num = int($Request->Form('topic_num'));
} elsif ($pi_topic_num) {
	$topic_num = $pi_topic_num;
} elsif ($Request->QueryString('topic_num')) {
	$topic_num = int($Request->QueryString('topic_num'));
}
if (!$topic_num) {
	&embedded_error_page("Must specify a topic_num.");
	$Response->End();
}


my $help_camp = 0;
my $camp_num = 0; # 0 is the default help statmenet.
if ($Request->Form('camp_num')) {
	$camp_num = int($Request->Form('camp_num'));
} elsif ($pi_camp_num) {
	$camp_num = $pi_camp_num;
} elsif ($Request->QueryString('camp_num')) {
	$camp_num = int($Request->QueryString('camp_num'));
}

if (! $camp_num) {
	$help_camp = 1;
	$camp_num = 1;
}


my $dbh = func::dbh_connect(1) || die "unable to connect to database";

my $topic_data = lookup_topic_data($dbh, $topic_num, $camp_num, $help_camp);

if ($topic_data->{'error_message'}) {
	embedded_error_page($topic_data->{'error_message'});
} else {
  	present_topic();
}


sub lookup_topic_data {
	my $dbh            = $_[0];
	my $topic_num      = $_[1];
	my $camp_num       = $_[2];
	my $help_camp      = $_[3];

	my $error_message = '';

	my topic $topic = new_topic_num topic ($dbh, $topic_num);

	if ($topic->{error_message}) {
		$error_message .= $topic->{error_message};
	}

	my camp $camp = new_tree camp ($dbh, $topic_num, $camp_num);

	if ($camp->{error_message}) {
		$error_message .= $camp->{error_message};
	} else {
		$camp->canonize($dbh, $Session->{'canonizer'});
	}

	my statement $short_statement = 0;

	if ($help_camp) {
		$short_statement = new_num statement ($dbh, 58, 2);
	} else {
		$short_statement = new_num statement ($dbh, $topic_num, $camp_num);
	}

	if ($short_statement->{error_message}) {
		# $short_statement->{value} = $short_statement->{error_message} . " ($topic_num, $camp_num, $help_camp)";
	}

	my $topic_data = {
		'topic'		  => $topic,
		'camp'	          => $camp,
		'short_statement' => $short_statement,
		'error_message'	  => $error_message
	};

	return($topic_data);
}


sub present_topic {

	print page_header('Canonizer Embedded Topoc');
	my $cur_host = func::get_host();

	my $url = "http://$cur_host/change_canonizer.asp?destination=http://$cur_host/embedded_topic.asp/$topic_num/$camp_num?canonizer=";

	%>

	<script language:javascript>
	function change_canonizer(new_canonizer) {
		// alert('<%=$url%>' + new_canonizer);
		window.location = '<%=$url%>' + new_canonizer;
	}
	</script>

	<div class="embedded_content">

	<h1><a target="_blank" href=http://<%=func::get_host()%>>Canonized Feedback</a></h1>

	<br>

	<div class="main_content_container">

	<div class="section_container">
		<div class="header_1">
		<span id="title">Canonizer Sorted Camp Tree</span><br><br>
		<%
		if ($help_camp) {
				%>
				<span id="camp">Help / Introduction</span>
				<%
		} else {
				%>
				<a href="http://<%=func::get_host()%>/embedded_topic.asp/<%=$topic_num%>">Help / Introduction</a>
				<%
		}
		%>
		</div>

		<div class="camp_tree" id="camp_tree">
		<%
		my $no_active_link = 1;
		if ($help_camp) {
			$no_active_link = 0;
		}

		$Response->Write($topic_data->{'camp'}->display_camp_tree($topic_data->{'topic'}->{topic_name}, $topic_num, $no_active_link, '/embedded_topic.asp/', '/topic.asp/'));
		%>
		</div>

		<div class="embedded_footer">

		Canonizer:
		<select class=bar name = canonizer onchange = javascript:change_canonizer(value)>

		<%
		my $canonizer;
		my $count = 0;
		my $session_canonizer = $Session->{'canonizer'};

		foreach $canonizer (@canonizers::canonizer_array) {
			my $selected_str = '';
			if ($count == $session_canonizer) {
			$selected_str = 'selected';
			}
			%>
			<option value=<%=$count++%> <%=$selected_str%>><%=$canonizer->{'name'}%></option>
			<%
		}
		%>

		</select>

		</div>

	</div>

	<%

	my $html_statement_short;
	if (length($topic_data->{'short_statement'}->{value}) > 0) {
		$html_statement_short = func::wikitext_to_html($topic_data->{'short_statement'}->{value});
	} else {
		$html_statement_short  = '<p>No statement text has been provided for this camp yet.</p>' . "\n";
		$html_statement_short .= '<p><a target=TARGET="_blank" href="https://' . func::get_host() . "/secure/edit.asp?class=statement&topic_num=$topic_num&camp_num=$camp_num\">Add new camp statement text</a></p>\n";
	}

	my $camp_header = 'Camp Statement';
	if ($help_camp) {
		$camp_header = "Help / Introduction";
	} elsif ($camp_num == 1) {
		$camp_header = 'Agreement Statement';
	}

	%>
	<div class="section_container">
		<div class="header_1">
			<span id="title"><%=$camp_header%></span>
		</div>

		<div class="content_1">
		<%=$html_statement_short%>
		</div>

		<div class="footer_1">
		</div>
	</div>

	</div>

	<%
}


sub embedded_error_page {
	my $error_message = $_[0];
	%>
	<p><%=$error_message%></p>
	<%
}

%>

<!--#include file = "includes/page_sections.asp"-->
