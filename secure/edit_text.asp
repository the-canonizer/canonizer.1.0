<%


# provide either ?copy_record_id=# to make a copy to edit
# or
# ?topic_num=#&statement_num=# for a new text record.

# in the copy case, the long/short ness is determined from the copy record
# else if &long=1 then long else short (the default)


if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect("https://" . $ENV{"SERVER_NAME"} . $ENV{"SCRIPT_NAME"} . $qs);
}
%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->


<%


sub error_page {
	%>
	<h1>Error:.</h1>
	<h2>
	<%=$message%>
	</h2>
	<%
}


sub get_state_from_form {
	my $record_state = $_[0];

	$record_state->{'note'} = $Request->Form('note');
	if (length($record_state->{'note'}) < 1) {
		$message .= "A Note is required.<br>\n";
	}

	if ($Request->Form('record_num')) {
		$record_state->{'record_num'} = int($Request->Form('record_num'));
	} else {
		$record_state->{'record_num'} = 0;
	}

	$record_state->{'submitter'} = int($Request->Form('submitter'));
	# ???? should validate submitter nick name here!!!!

	$record_state->{'text_value'} = $Request->Form('text_value');
	if (length($record_state->{'text_value'}) < 1) {
		$message .= "Text is required.<br>\n";
	}
}


sub save_record {
	my $dbh = $_[0];
	my $record_state = $_[1];

	my $selstmt;
	my $sth;
	my $rs;

	$record_state->{'new_record_id'} = &func::get_next_id($dbh, 'STATEMENT_TEXT', 'RECORD_ID');

	my $proposed;
	my $now_time = time;
	my $go_live_time;

	if ($record_state->{'copy_record_id'}) {
		$proposed = 1;
		$go_live_time = $now_time + (60 * 60 * 24 * 7); # 7 days.
	} else {
		$record_state->{'record_num'} = &func::get_next_id($dbh, 'STATEMENT_TEXT', 'NUM');
		$proposed = 0;
		$go_live_time = $now_time;
	}

	$selstmt = "insert into statement_text  (value, text_size,               topic_num,                    statement_num,                    record_id,                        num,                           note,                    submit_time, submitter,                    go_live_time,  proposed) " .
					"values (?,     $record_state->{'long'}, $record_state->{'topic_num'}, $record_state->{'statement_num'}, $record_state->{'new_record_id'}, $record_state->{'record_num'}, ?, $now_time,   $record_state->{'submitter'}, $go_live_time, $proposed)";

	# why does this 'do' not work?
	# $dbh->do($sestmt, $record_state->{'text_value'}, $record_state->{'note'}) || die "Failed to create new record with " . $selstmt;
	$sth = $dbh->prepare($selstmt) || die $selstmt;
	$sth->execute($record_state->{'text_value'}, $record_state->{'note'});
	$sth->finish();
	$message .= "selstmt: $selstmt.<br>\n";

	return(1);
}


sub lookup_topic {
	my $dbh = $_[0];
	my $record_state = $_[1];

	my $selstmt = "select num, name, namespace, one_line, key_words, note from topic where record_id = $record_state->{'copy_record_id'}";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs = $sth->fetchrow_hashref();

	if (! $rs) {
		$message .= "Unknown copy record_id: " . $record_state->{'copy_record_id'} . ".<br>\n";
		return(0);
	}

	# ???? got to finish this !!!!

}

sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/secure/edit_text.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $query_string);
	}
%>

	<br>
	<h2>You must register and or login before you can edit statements.</h2>
	<center>
	<h2><a href="http://<%=&func::get_host()%>/register.asp">Register</a><h2>
	<h2><a href="<%=$login_url%>">Login</a><h2>
	</center>
<%
}


sub new_record_form {

	my $submit_value = 'Create Statement Text';
	if ($record_state->{'copy_record_id'}) {
		$submit_value = 'Propose Statement Text Modification';
	}

	my %nick_names = ();
	my $no_nick_name = 1;
	my $owner_code = &func::canon_encode($Session->{'cid'});
	my $selstmt = "select nick_name_id, nick_name from nick_name where owner_code = '$owner_code'";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	while($rs = $sth->fetch()) {
		$no_nick_name = 0;
		$nick_names{$rs->[0]} = $rs->[1];
	}
	$sth->finish();

	if ($no_nick_name) {
		%>
		<h2>You must have a Nick Name before you can contribute.</h2>
		<h3>You can create a Nick Name on the <a href = "https://<%=&func::get_host()%>/secure/profile_id.asp">
		Personal Info Identity Page</a>.</h3>
		<%
		return();
	}

	if (!$record_state->{'num'}) { # new topic (with no copy) case
		$record_state->{'num'} = 0;
	}

	%>

	<br>
	<%=$message%>
	<br>

	<form method=post>
	<input type=hidden name=record_id value=<%=$record_state->{'copy_record_id'}%>>
	<input type=hidden name=record_num value=<%=$record_state->{'record_num'}%>>
	<input type=hidden name=topic_num value=<%=$record_state->{'topic_num'}%>>
	<input type=hidden name=statement_num value=<%=$record_state->{'statement_num'}%>>

	<b>Text: <font color = red>*</font></b><br>

	<textarea NAME="text_value" ROWS="30" COLS="40"><%=$record_state->{'text_value'}%></textarea>

	<table>
	<tr>
	  <td><b>Edit Note: <font color = red>*</font> </b></td><td>Reason for submission. Maximum 65 characters.<br>
	<input type=string name=note value="<%=$record_state->{'note'}%>" maxlength=65 size=65></td></tr>

	<tr height = 20></tr>

	<tr>
	  <td><b>Attribution Nick Name:</b></td>
	  <td>
	    <select name="submitter">
	    <%
	    my $id;
	    foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $record_state{'submitter'}) {
			%>
			<option value=<%=$id%> selected><%=$nick_names{$id}%>
			<%
		} else {
			%>
			<option value=<%=$id%>><%=$nick_names{$id}%>
			<%
		}
	    }
	    %>
	    </select>
	</td></tr>

	<tr height = 20></tr>

	</table>

	<input type=reset value="Reset">
	<input type=submit name=submit value="<%=$submit_value%>">

	</form>

	<%
}



########
# main #
########

if (!$Session->{'logged_in'}) {
	&display_page('New Topic', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";	

local $record_state = {
		'text_value' => '',
		'note' => 'First Version',
		'record_num' => 0,
		'text_type' => 1 # it is always this wikitext value for now.
		};

local $message = '';

my $title = 'Create New Statement Text';

if ($Request->Form('copy_record_id')) {
	$record_state->{'copy_record_id'} = $Request->Form('copy_record_id');
} elsif ($Request->QueryString('copy_record_id')) {
	$record_state->{'copy_record_id'} = $Request->QueryString('copy_record_id');
} else {
	if ($Request->Form('topic_num')) {
		$record_state->{'topic_num'} = $Request->Form('topic_num');
	} elsif ($Request->QueryString('topic_num')) {
		$record_state->{'topic_num'} = $Request->QueryString('topic_num');
	} else {
		$message .= "With no copy_record_id, you must have a topic_num.<br>\n";
	}
	if ($Request->Form('statement_num')) {
		$record_state->{'statement_num'} = $Request->Form('statement_num');
	} elsif ($Request->QueryString('statement_num')) {
		$record_state->{'statement_num'} = $Request->QueryString('statement_num');
	} else {
		$message .= "With no copy_record_id, you must have a statement_num.<br>\n";
	}
}

if ($Request->Form('long')) {
	$record_state->{'long'} = int($Request->Form('long'));
} elsif ($Request->QueryString('long')) {
	$record_state->{'long'} = int($Request->QueryString('long'));
} else {
	$record_state->{'long'} = 0;
}



if ($message) {
	&display_page('Edit Topic: error', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();

} elsif ($Request->Form('submit')) {
	&get_state_from_form($record_state);

	if (!$message) {
		if (&save_record($dbh, $record_state)) {

			if ($record_state->{'copy_record_id'}) {
				# ???? $Response->Redirect('http://' . &func::get_host() . '/manage_text.asp?number=' . $record_state{'num'});
			} else {
				$Response->Redirect('http://' . &func::get_host() . '/topic.asp?topic_num=' . $record_state->{'topic_num'} . '&statement_num=' . $record_state->{'statement_num'});
			}
			$Response->End();
		}
	}
} elsif ($copy_record_id) {
	if (&lookup_topic($dbh, $record_state)) {
		&display_page('Edit Topic: error', [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
	$title = 'Propose Statement Text Modification';
}

&display_page($title, [\&identity, \&search, \&main_ctl], [\&new_record_form]);

%>

