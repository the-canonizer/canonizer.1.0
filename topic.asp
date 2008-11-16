<%

use Time::Local;
use managed_record;
use topic;
use camp;
use support;
use statement;

#
#	present a topic with a camp (default agreement camp)
#	?topic_num=#[&camp_num=#]
#
#	optional specification of long/short statement:
#	&long_short=#
#		0	short only (default)
#		1	long only
#		2	both long and short
#

# print(STDERR 'If_Modified_Since: ', $Request->ServerVariables('HTTP_IF_MODIFIED_SINCE'), ".\n");

my $error_message = '';

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
	$error_message = "Must specify a topic_num.";
	&display_page('Topic Page', 'Topic Page', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $camp_num = 1; # 1 is the default ageement camp;
if ($Request->Form('camp_num')) {
	$camp_num = int($Request->Form('camp_num'));
} elsif ($pi_camp_num) {
	$camp_num = $pi_camp_num;
} elsif ($Request->QueryString('camp_num')) {
	$camp_num = int($Request->QueryString('camp_num'));
}

my $long_short = 0;
if ($Request->Form('long_short')) {
	$long_short = int($Request->Form('long_short'));
} elsif ($Request->QueryString('long_short')) {
	$long_short = int($Request->QueryString('long_short'));
}

if ($Request->QueryString('as_of_mode')) {
	$Session->{'as_of_mode'} = $Request->QueryString('as_of_mode');
}
if ($Request->QueryString('as_of_date')) {
	$Session->{'as_of_date'} = $Request->QueryString('as_of_date');
}

my $dbh = func::dbh_connect(1) || die "unable to connect to database";
# ???? is this the right place for this?  Was this only for oracle?
$dbh->{LongReadLen} = 1000000; # what and where should this really be ????

my $topic_data = lookup_topic_data($dbh, $topic_num, $camp_num, $long_short);

if ($topic_data->{'error_message'}) {
	$error_message = $topic_data->{'error_message'};
	display_page('Unknown Topic Number', 'Unknown Topic Number', [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&error_page]);
} else {

	# this makes browsers and such cach pages.
	# messes up changing canonizer and everything.
	# add_modified_header($topic_data);

	my $title = 'Topic: ' . $topic_data->{'topic'}->{topic_name} . ' ' .
		    'Camp: ' . $topic_data->{'camp'}->{camp_name};

	my $header = '<table><tr><td class="label">Topic:</td>' .
				'<td class="topic">' . $topic_data->{'topic'}->{topic_name} . '</td></tr>' .
			    '<tr><td class="label">Camp:</td>' .
			        '<td class="camp">' . $topic_data->{'camp'}->make_camp_path() . "</td></tr></table>\n";

	if ($Request->Form('submit_edit')) {		# preview mode

		display_page($title, $header, [\&identity, \&search, \&main_ctl], [\&present_topic]);
	} else {					# normal mode
		display_page($title, $header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&present_topic]);
	}
}


sub add_modified_header {
	my $topic_data = $_[0];

	my $modified_time;
	if ($topic_data->{'short_statement'}) {
		$modified_time = $topic_data->{'short_statement'}->{go_live_time};
	} else {
		$modified_time = $topic_data->{'camp'}->{go_live_time};
	}
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($modified_time);
	my $modified_str = POSIX::strftime("%a, %d %b %Y %H:%M:%S GMT", $sec, $min, $hour, $mday, $mon, $year, $wday);
	$Response->AddHeader('Last-Modified', $modified_str);
}


sub lookup_topic_data {
	my $dbh        = $_[0];
	my $topic_num  = $_[1];
	my $camp_num   = $_[2];
	my $long_short = $_[3];

	my $error_message = '';

	my topic $topic = new_topic_num topic ($dbh, $topic_num, $Session->{'as_of_mode'}, $Session->{'as_of_date'});

	if ($topic->{error_message}) {
		$error_message .= $topic->{error_message};
	}

	my camp $camp = new_tree camp ($dbh, $topic_num, $camp_num, $Session->{'as_of_mode'}, $Session->{'as_of_date'});

	if ($camp->{error_message}) {
		$error_message .= $camp->{error_message};
	} else {
		$camp->canonize($dbh, $Session->{'canonizer'}, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
	}

	my statement $short_statement = 0;
	my statement $long_statement = 0;

	if ($Request->Form('submit_edit')) {

		if ($Request->Form('statement_size')) {	# long statement
			$long_statement = new_form statement ($Request);
			if ($long_statement->{error_message}) {
				$long_statement = 0;
			}
		} else {				# short statement
			$short_statement = new_form statement ($Request);
			if ($short_statement->{error_message}) {
				$short_statement = 0;
			}
		}

	} else {

		if ($long_short == 0 || $long_short == 2) {		       # 0 -> short statement;
			$short_statement = new_num statement ($dbh, $topic_num, $camp_num, 0, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
			if ($short_statement->{error_message}) {
				$short_statement = 0;
			}
		}

		if ($long_short == 1 || $long_short == 2) {		      # 1 -> long statement;
			$long_statement = new_num statement ($dbh, $topic_num, $camp_num, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
			if ($long_statement->{error_message}) {
				$long_statement = 0;
			}
		}
	}

# I may want to convert back to something like this old way some day, since it reduced the number of DB queries by one...
#	$selstmt = "select value, text_size from text where topic_num=$topic_num and statement_num=$camp_num and proposed = 0 and replacement is null";
#	$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
#	$sth->execute() || die "Failed to execute " . $selstmt;
#	while ($rs = $sth->fetch()) {
#		if ($rs->[1] == 1) { # long text
#			if ($topic_data->{'long_text'}) {
#				print(STDERR "Warning evidently topic $topic_num and camp $camp_num has more than one active long text record.\n");
#			}
#			$topic_data->{'long_text'} = $rs->[0];
#		} else { # short text
#			if ($topic_data->{'short_text'}) {
#				print(STDERR "Warning evidently topic $topic_num and camp $camp_num has more than one active short text record.\n");
#			}
#			$topic_data->{'short_text'} = $rs->[0];
#		}
#	}

	my $topic_data = {
		'topic'		  => $topic,
		'camp'	          => $camp,
		'short_statement' => $short_statement,
		'long_statement'  => $long_statement,
		'any_short'	  => statement::any_statement_check($dbh, $topic_num, $camp_num, 0),
		'any_long'	  => statement::any_statement_check($dbh, $topic_num, $camp_num, 1),
		'error_message'	  => $error_message
	};

	return($topic_data);
}


sub present_topic {

	my $short_sel_str = '';
	my $long_sel_str = '';
	my $long_short_sel_str = '';

	if ($long_short == 0) {
		$short_sel_str = 'selected';
	} elsif ($long_short == 1) {
		$long_sel_str = 'selected';
	} elsif ($long_short == 2) {
		$long_short_sel_str = 'selected';
	}

	%>

	<script language:javascript>
	function change_long_short(val) {
		var location_str = "/topic.asp/<%=$topic_num%>/<%=$camp_num%>";
		if (val == 2) {
			location_str += "?long_short=2";
		} else if (val == 1) {
			location_str += "?long_short=1";
		}
		window.location = location_str;
	}
	</script>

<div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title">Canonizer Sorted Camp Tree</span>

</div>

<div class="camp_tree" id="camp_tree">
	<%
	$Response->Write($topic_data->{'camp'}->display_camp_tree($topic_data->{'topic'}->{topic_name}, $topic_num, 1)); # 1 -> no_active_link

	my $score = func::c_num_format($topic_data->{'camp'}->{score});

	%>
</div>

     <div class="footer_1">
     <span id="buttons">

<p>Note: This section is a table of contents for this topic. It is in
outline form, with supporting sub camps indented from the parent camp.
If you are in a sub camp, you are also counted in all parent camps
including the agreement camp at the top.  The numbers are canonized
scores derived from the people in the camps based on your currently
selected canonizer.  The camps are sorted according to these canonized
scores.  Each entry is a link to the camp page which can contain a
statement of belief.  The green link indicates the camp page you are
currently on and the statement below is for that camp.</p>

     </span>
     </div>

</div>

	<%

	if ($Request->Form('submit_edit')) {
		%>
		Preview Statement Only
		<form method=post action='https://<%=func::get_host()%>/secure/edit.asp?class=statement&topic_num=<%=$topic_num%>&camp_num=<%=$camp_num%>'>
			<input type=hidden name=topic_num value="<%=$Request->Form('topic_num')%>">
			<input type=hidden name=camp_num value="<%=$Request->Form('camp_num')%>">
			<input type=hidden name=record_id value="<%=$Request->Form('record_id')%>">
			<input type=hidden name=value value="<%=func::hex_encode($Request->Form('value'))%>">
			<input type=hidden name=statement_size value="<%=$Request->Form('statement_size')%>">
			<input type=hidden name=proposed value="<%=$Request->Form('proposed')%>">
			<input type=hidden name=note value="<%=func::hex_encode($Request->Form('note'))%>">
			<input type=hidden name=submitter value="<%=$Request->Form('submitter')%>">

			<input type=submit name=submit_edit value="Edit Statement">
			<input type=submit name=submit_edit value="Commit Statement">

		</form>

		<%
	}
	%>



	<%

	my $html_statement_short = '<p>No camp statement has been provided yet.</p>';
        my $html_statement_long = '<p>No long camp statement has been provided yet.</p>';

	my $camp_agreement = 'Camp';
	if ($camp_num == 1) {
		$camp_agreement = "Agreement";
	}

	# short statement:
	if ($long_short == 0 || $long_short == 2) {
				%>

                        <div class="section_container">

			<div class="header_1">
     <span id="title"><%=$camp_agreement%> Statement</span>
 </div>


<%
if ($topic_data->{'short_statement'}) {

			$html_statement_short = func::wikitext_to_html($topic_data->{'short_statement'}->{value});

			my $num_clause = '';

			my $replace_str = '&amp;canonized_topic_list\(([^\)]*)\)';
			if ($html_statement_short =~ m|$replace_str|) {
				my @topic_nums = split(', ', $1);
				my $topic_num;
				foreach $topic_num (@topic_nums) {
					if ($num_clause) {
						$num_clause .= ' or ';
					} else {
						$num_clause = '(';
					}
					$num_clause .= "topic_num=$topic_num";
				}

				if ($num_clause) {
					$num_clause .= ')';

					my $selstmt = "select topic_num, topic_name from topic where $num_clause and objector is null $as_of_clause and go_live_time in (select max(go_live_time) from topic where objector is null $as_of_clause group by topic_num)";

					my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
					$sth->execute() || die "Failed to execute $selstmt";
					my $canonize_list_str = 
						'<div class="camp_tree" id="camp_tree">' . "\n" .
						topic::canonized_list($dbh, $sth, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $Session->{'canonizer'}) . "\n" .
						"</div>\n";

					$html_statement_short =~ s|$replace_str|$canonize_list_str|;
				}
			}




} %>


<div class="content_1"><%=$html_statement_short%></div>		


<div class="footer_1">
     <span id="buttons">

     			<%

		if ($topic_data->{'any_short'}) {

			if (! $Request->Form('submit_edit')) {		# turn off in preview mode
				%>
				<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>/<%=$camp_num%>?class=statement">Manage/Edit Camp Statement</a><br><br>
				<%
			}
		} else {
			%>
			<a href="https://<%=func::get_host()%>/secure/edit.asp?class=statement&topic_num=<%=$topic_num%>&camp_num=<%=$camp_num%>">Add Camp Statement</a><br><br>
			<%
		}

		%>
		<a href="http://<%=func::get_host()%>/forum.asp/<%=$topic_num%>/1">Topic Forum</a><br>
		<%

		if ($camp_num > 1) {
			%>
			<br><a href="http://<%=func::get_host()%>/forum.asp/<%=$topic_num%>/<%=$camp_num%>">Camp Forum</a><br><br>
			<%
		}
		%>
     </span>
     </div>


		</div><%
	}

	# long statement:
	if ($long_short == 1 || $long_short == 2) {
	
	           			%>
			                       <div class="section_container">
						<div class="header_1">
     <span id="title"><%=$camp_agreement%> Long Statement</span>
     </div>
     
       	<%
	
		if ($topic_data->{'long_statement'}) {

			$html_statement_long = func::wikitext_to_html($topic_data->{'long_statement'}->{value});
		
			    
		}%>
                      <div class="content_1"><%=$html_statement_long%></div>
                      
     <div class="footer_1">
     <span id="buttons">


			<%

		if ($topic_data->{'any_long'}) {

			$html_statement_long = func::wikitext_to_html($topic_data->{'long_statement'}->{value});


			if (! $Request->Form('submit_edit')) {		# turn off in preview mode
				%>
				<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>/<%=$camp_num%>?class=statement&long=1">Manage/Edit Long Statement</a>
			         
				<%
			}
			%>

			<%
		} else {
			%>
			<a href="https://<%=func::get_host()%>/secure/edit.asp?class=statement&topic_num=<%=$topic_num%>&camp_num=<%=$camp_num%>&long=1">Add Long Statement</a>
                          	
                
			<%
		}
		%>

		</span></div></div><%
	}
	%>



<div class="section_container">
<div class="header_1">

     <span id="title">Support Tree for "<%=$topic_data->{'camp'}->{camp_name}%>" Camp</span>

</div>
	
  <div class="content_1">

	<p>Total Support for This Camp (including sub-camps): <%=$score%></p>
	
	<%
	my %nick_names = func::get_nick_name_hash($Session->{'cid'}, $dbh);
	$Response->Write($topic_data->{'camp'}->display_support_tree($topic_num, $camp_num, \%nick_names));
	%>



</div>


     <div class="footer_1">
     <span id="buttons">
     


     	<%
	if (! $Request->Form('submit_edit')) {		# turn off in preview mode
		if (($Session->{'cid'}) && $topic_data->{'camp'}->is_supporting(\%nick_names)) {
			%>
			<a href="https://<%=func::get_host()%>/secure/support.asp?topic_num=<%=$topic_num%>&camp_num=<%=$camp_num%>">Modify Support for This Camp</a>
			<%
		} else {
			%>
			<a href="https://<%=func::get_host()%>/secure/support.asp?topic_num=<%=$topic_num%>&camp_num=<%=$camp_num%>">Join or Directly Support This Camp</a>
			<%
		}
		%>

<p>Note: Supporters can delegate their support to others.  Direct
supporters receive e-mail notifications of proposed camp changes,
while for delegated supporters, such is not required.  People
delegating their support to others are shown below and indented from
their delegates in an outline form.  If your delegate changes camp,
you and everyone with you as a delegate will also change camps with
them.</p>

		<%
	}
	%>

     </span>
     </div>
</div>

<div class="section_container">
<div class="header_1">

     <span id="title">Current Topic Record:</span>

</div>
 <div class="content_1">
<p>Topic Name: <%=$topic_data->{'topic'}->{topic_name}%></p>
<p>Name Space: <%=$topic_data->{'topic'}->{namespace}%></p>

    </div>

     <div class="footer_1">
     <span id="buttons">
     
      	<%
	if (! $Request->Form('submit_edit')) {		# turn off in preview mode
		%>
		<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>?class=topic">Manage/Edit This Topic</a>
		<%
	}
	%>
     
     
     </span>
     </div>


</div>

<div class="section_container">
<div class="header_1">


     <span id="title">Current Camp Record:</span>


</div>

<div class="content_1">
<p>Camp Name: <%=$topic_data->{'camp'}->{camp_name}%> </p>
<p>Title: <%=$topic_data->{'camp'}->{title}%></p>
<p>Key Words: <%=$topic_data->{'camp'}->{key_words}%></p>
<p>URL: <%=$topic_data->{'camp'}->{url}%></p>
	<%
	if ($topic_data->{'camp'}->{parent_camp_num}) {
		%>
		<p>Parent Camp: <%=$topic_data->{'camp'}->{parent}->{camp_name}%></p>
		<%
	}
	%>
 </div>

     <div class="footer_1">
     <span id="buttons">
     

	<%
	if (! $Request->Form('submit_edit')) {		# turn off in preview mode
		%>
		<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>/<%=$camp_num%>?class=camp">Manage/Edit This Camp</a>
		<%
	}
	%>     
     
     </span>
     </div>

</div>



</div>



		<%
	if (! $Request->Form('submit_edit')) {		# turn off in preview mode
		%>

		<select name="long_short" onchange=javascript:change_long_short(value)>
			<option value=0 <%=$short_sel_str%>>Short Statement Only
			<option value=1 <%=$long_sel_str%>>Long Statement Only
			<option value=2 <%=$long_short_sel_str%>>Long and Short Statement
		</select>



		<%
	} %>



<%
}
%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/canonizer.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->

