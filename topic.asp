<%

use Time::Local;
use managed_record;
use topic;
use statement;
use support;
use text;

#
#	present a topic with a statement (default agreement statement)
#	?topic_num=#[&statement_num=#]
#
#	optional specification of long/short text:
#	&long_short=#
#		0	short only (default)
#		1	long only
#		2	both long and short
#

my $error_message = '';

my $path_info = $ENV{'PATH_INFO'};
my $pi_topic_num = 0;
my $pi_statement_num = 0;
if ($path_info =~ m|/(\d+)/?(\d*)|) {
	$pi_topic_num = $1;
	if ($2) {
		$pi_statement_num = $2;
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

my $statement_num = 1; # 1 is the default ageement statement;
if ($Request->Form('statement_num')) {
	$statement_num = int($Request->Form('statement_num'));
} elsif ($pi_statement_num) {
	$statement_num = $pi_statement_num;
} elsif ($Request->QueryString('statement_num')) {
	$statement_num = int($Request->QueryString('statement_num'));
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

my $topic_data = lookup_topic_data($dbh, $topic_num, $statement_num, $long_short);

if ($topic_data->{'error_message'}) {
	$error_message = $topic_data->{'error_message'};
	display_page('Unknown Topic Number', 'Unknown Topic Number', [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&error_page]);
} else {

	my $title = 'Topic: ' . $topic_data->{'topic'}->{topic_name} . ' ' .
		    'Statement: ' . $topic_data->{'statement'}->{statement_name};

	my $header = '<table><tr><td class="label">Topic:</td>' .
				'<td class="topic">' . $topic_data->{'topic'}->{topic_name} . '</td></tr>' .
			    '<tr><td class="label">Statement:</td>' .
			        '<td class="statement">' . $topic_data->{'statement'}->make_statement_path() . "</td></tr></table>\n";

	if ($Request->Form('submit_edit')) {		# preview mode

		display_page($title, $header, [\&identity, \&search, \&main_ctl], [\&present_topic]);
	} else {					# normal mode
		display_page($title, $header, [\&identity, \&canonizer, \&as_of, \&search, \&main_ctl], [\&present_topic]);
	}
}


sub lookup_topic_data {
	my $dbh           = $_[0];
	my $topic_num     = $_[1];
	my $statement_num = $_[2];
	my $long_short    = $_[3];

	my $error_message = '';

	my topic $topic = new_topic_num topic ($dbh, $topic_num, $Session->{'as_of_mode'}, $Session->{'as_of_date'});

	if ($topic->{error_message}) {
		$error_message .= $topic->{error_message};
	}

	my statement $statement = new_tree statement ($dbh, $topic_num, $statement_num, $Session->{'as_of_mode'}, $Session->{'as_of_date'});

	if ($statement->{error_message}) {
		$error_message .= $statement->{error_message};
	} else {
		$statement->canonize();
	}

	my text $short_text = 0;
	my text $long_text = 0;

	if ($Request->Form('submit_edit')) {

		if ($Request->Form('text_size')) {	# long text
			$long_text = new_form text ($Request);
			if ($long_text->{error_message}) {
				$long_text = 0;
			}
		} else {				# short text
			$short_text = new_form text ($Request);
			if ($short_text->{error_message}) {
				$short_text = 0;
			}
		}

	} else {

		if ($long_short == 0 || $long_short == 2) {			    # 0 -> short text;
			$short_text = new_num text ($dbh, $topic_num, $statement_num, 0, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
			if ($short_text->{error_message}) {
				$short_text = 0;
			}
		}

		if ($long_short == 1 || $long_short == 2) {			   # 1 -> long text;
			$long_text = new_num text ($dbh, $topic_num, $statement_num, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'});
			if ($long_text->{error_message}) {
				$long_text = 0;
			}
		}
	}

# I may want to convert back to something like this old way some day, since it reduced the number of DB queries by one...
#	$selstmt = "select value, text_size from text where topic_num=$topic_num and statement_num=$statement_num and proposed = 0 and replacement is null";
#	$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
#	$sth->execute() || die "Failed to execute " . $selstmt;
#	while ($rs = $sth->fetch()) {
#		if ($rs->[1] == 1) { # long text
#			if ($topic_data->{'long_text'}) {
#				print(STDERR "Warning evidently topic $topic_num and statement $statement_num has more than one active long text record.\n");
#			}
#			$topic_data->{'long_text'} = $rs->[0];
#		} else { # short text
#			if ($topic_data->{'short_text'}) {
#				print(STDERR "Warning evidently topic $topic_num and statement $statement_num has more than one active short text record.\n");
#			}
#			$topic_data->{'short_text'} = $rs->[0];
#		}
#	}

	my $topic_data = {
		'topic'		=> $topic,
		'statement'	=> $statement,
		'short_text'	=> $short_text,
		'long_text'	=> $long_text,
		'error_message'	=> $error_message
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
		var location_str = "/topic.asp/<%=$topic_num%>/<%=$statement_num%>";
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

     <span id="title">Canonizer Sorted Position (POV) Statement Tree</span>

</div>

<div class="statement_tree" id="statement_tree">
	<%
	$Response->Write($topic_data->{'statement'}->display_statement_tree($topic_data->{'topic'}->{topic_name}, $topic_num, 1)); # 1 -> no_active_link

	my $score = func::c_num_format($topic_data->{'statement'}->{score});

	%>
</div>

     <div class="footer_1">
     <span id="buttons">

          	<%
		if (! $Request->Form('submit_edit')) {		# turn off in preview mode
		%>
		<a href="http://<%=func::get_host()%>/secure/edit.asp?class=statement&topic_num=<%=$topic_num%>&parent_statement_num=<%=$statement_num%>">Add New Position Statement Under "<%=$topic_data->{'statement'}->{statement_name}%>" Statement</a>
		<% } %>

<p>Note: This section is like the Table of Contents for this topic.
It has links to the agreement statement always on the top, and all
other sub statement in a hierarchical order, along with how much
support each statement has, sorted according to your current
Canonizer.  The green one, that is not the link, is the POV statement
you are currently viewing.</p>

     </span>
     </div>

</div>

	<%

	if ($Request->Form('submit_edit')) {
		%>
		Preview Text Only
		<form method=post action='https://<%=func::get_host()%>/secure/edit.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>'>
			<input type=hidden name=topic_num value="<%=$Request->Form('topic_num')%>">
			<input type=hidden name=statement_num value="<%=$Request->Form('statement_num')%>">
			<input type=hidden name=record_id value="<%=$Request->Form('record_id')%>">
			<input type=hidden name=value value="<%=func::hex_encode($Request->Form('value'))%>">
			<input type=hidden name=text_size value="<%=$Request->Form('text_size')%>">
			<input type=hidden name=proposed value="<%=$Request->Form('proposed')%>">
			<input type=hidden name=note value="<%=$Request->Form('note')%>">
			<input type=hidden name=submitter value="<%=$Request->Form('submitter')%>">

			<input type=submit name=submit_edit value="Edit Text">
			<input type=submit name=submit_edit value="Commit Text">

		</form>

		<%
	}
	%>



	<%

	my $html_text_short = '<p>No short statement has been provided.</p>';
        my $html_text_long = '<p>No long statement has been provided.</p>';

	my $camp_agreement = 'Camp';
	if ($statement_num == 1) {
		$camp_agreement = "Agreement";
	}

	# short text:
	if ($long_short == 0 || $long_short == 2) {
				%>

                        <div class="section_container">

			<div class="header_1">
     <span id="title"><%=$camp_agreement%> Statement</span>
 </div>


<%		
if ($topic_data->{'short_text'}) {

			$html_text_short = func::wikitext_to_html($topic_data->{'short_text'}->{value});
		                              
		           
		          } %>


<div class="content_1"><%=$html_text_short%></div>		


<div class="footer_1">
     <span id="buttons">

     			<%

		if ($topic_data->{'short_text'}) {

			if (! $Request->Form('submit_edit')) {		# turn off in preview mode
				%>
				<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>/<%=$statement_num%>?class=text">Manage Statement Text</a><br><br>
				<%
			}
		} else {
			%>
			<a href="https://<%=func::get_host()%>/secure/edit.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Add Statement Text</a><br><br>
			<%
		}

		%>
		<a href="http://<%=func::get_host()%>/forum.asp/<%=$topic_num%>/1">Topic Forum</a><br>
		<%

		if ($statement_num > 1) {
			%>
			<br><a href="http://<%=func::get_host()%>/forum.asp/<%=$topic_num%>/<%=$statement_num%>">Camp Forum</a><br><br>
			<%
		}
		%>
     </span>
     </div>


		</div><%
	}

	# long text:
	if ($long_short == 1 || $long_short == 2) {
	
	           			%>
			                       <div class="section_container">
						<div class="header_1">
     <span id="title"><%=$camp_agreement%> Long Statement</span>
     </div>
     
       	<%
	
		if ($topic_data->{'long_text'}) {

			$html_text_long = func::wikitext_to_html($topic_data->{'long_text'}->{value});
		
			    
		}%>
                      <div class="content_1"><%=$html_text_long%></div>
                      
     <div class="footer_1">
     <span id="buttons">
     
			
			<%
	
		if ($topic_data->{'long_text'}) {

			$html_text_long = func::wikitext_to_html($topic_data->{'long_text'}->{value});


			if (! $Request->Form('submit_edit')) {		# turn off in preview mode
				%>
				<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>/<%=$statement_num%>?class=text&long=1">Manage Long Statement Text</a>
			         
				<%
			}
			%>

			<%
		} else {
			%>
			<a href="https://<%=func::get_host()%>/secure/edit.asp?class=text&topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>&long=1">Add Long Statement Text</a>
                          	
                
			<%
		}
		%>

		</span></div></div><%
	}
	%>



<div class="section_container">
<div class="header_1">

     <span id="title">Support Tree for "<%=$topic_data->{'statement'}->{statement_name}%>" Statement</span>

</div>
	
  <div class="content_1">

	<p>Total Support for This Statement (including sub-statements): <%=$score%></p>
	
	<%
	my %nick_names = func::get_nick_name_hash($Session->{'cid'}, $dbh);
	$Response->Write($topic_data->{'statement'}->display_support_tree($topic_num, $statement_num, \%nick_names));
	%>



</div>


     <div class="footer_1">
     <span id="buttons">
     


     	<%
	if (! $Request->Form('submit_edit')) {		# turn off in preview mode
		if (($Session->{'cid'}) && $topic_data->{'statement'}->is_supporting(\%nick_names)) {
			%>
			<a href="https://<%=func::get_host()%>/secure/support.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Modify Support for This Statement</a>
			<%
		} else {
			%>
			<a href="https://<%=func::get_host()%>/secure/support.asp?topic_num=<%=$topic_num%>&statement_num=<%=$statement_num%>">Directly Support This Statement</a>
			<%
		}
		%>

<p>Note: If you directly support a
statement, you are expected to be involved in the improvement of that
and all super statements.  This includes receiving e-mail
notifications of proposed modifications, reviewing such, and so on.
If you are not interested in being this involved, please just delegate
your support to anyone already in this camp you trust.  In that case,
if the delegate moves their support to a statement that they believe
is better; your delegated support and all support delegated to you
will follow that delegate.  Such delegates may periodically decide to
inform their constituents of significant new events such as camp
consolidations, improvements, conversions, information moving up or
down the structure, and so on as they see fit.</p>

		<%
	}
	%>

     </span>
     </div>	
</div>

<div class="section_container">
<div class="header_1">

     <span id="title">Topic</span>
    
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
		<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>?class=topic">Manage This Topic</a>
		<%
	}
	%>
     
     
     </span>
     </div>


</div>

<div class="section_container">
<div class="header_1">


     <span id="title">Statement</span>


</div>

<div class="content_1">
<p>Statement Name: <%=$topic_data->{'statement'}->{statement_name}%> </p>
<p>Title: <%=$topic_data->{'statement'}->{title}%></p>
<p>Key Words: <%=$topic_data->{'statement'}->{key_words}%></p>
	<%
	if ($topic_data->{'statement'}->{parent_statement_num}) {
		%>
		<p>Parent Statement: <%=$topic_data->{'statement'}->{parent}->{statement_name}%></p>
		<%
	}
	%>
 </div>

     <div class="footer_1">
     <span id="buttons">
     

	<%
	if (! $Request->Form('submit_edit')) {		# turn off in preview mode
		%>
		<a href="http://<%=func::get_host()%>/manage.asp/<%=$topic_num%>/<%=$statement_num%>?class=statement">Manage This Statement</a>
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

