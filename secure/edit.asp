<%
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
<!--#include file = "includes/error_page.asp"-->
<!--#include file = "includes/must_login.asp"-->

<%

#
# query string cases:
#	(copy) record_id=# (proposed case)
#	new record cases:
#		case=statement&topic_num=#&parent_statement_num=$
#		case=text&topic_num=#&statement_num=#[&long=1]
# else $Request->Form('submit_edit');
#

use managed_record;
use topic;
use statement;
use text;

# it would be nice to object orient this, but alas, we must have asp ability to do html.
sub display_form {
	if ($class eq 'text') {
		&display_text_form();
	} elsif ($class eq 'statement') {
		&display_statement_form();
	} else {
		&display_topic_form();
	}
}


sub display_topic_form {

	my $submit_value = 'Create Topic';
	if ($record->{proposed}) {
		$submit_value = 'Propose Topic Modification';
	}

%>

<br>
<%=$error_message%>
<br>

<form method=post>
<input type=hidden name=record_id value=<%=$copy_record_id%>>
<input type=hidden name=topic_num value=<%=$record->{topic_num}%>>
<input type=hidden name=proposed value=<%=$record->{proposed}%>>

<table>
<tr>
  <td><b>Topic Name: <font color = red>*</font> </b></td><td>Mazimum 25 characters.<br>
	<input type=string name=name value="<%=$record->{name}%>" maxlength=25 size=25></td></tr>

  <tr height = 20></tr>

  <td><b>Namespace:</b></td><td>Nothing for main default namespace.  Begins and Ends with '/'.  Maximum 65 characters.<br>
	<input type=string name=namespace value="<%=$record->{namespace}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

<%
#  <td><b>AKA:</b></td><td>Comma separated - symbolic link created for each one.<br>
#	<input type = string name = AKA maxlength = 255 size = 65></td></tr>
#
#  <tr height = 20></tr>
%>

  <tr height = 20></tr>

  <td><b>Note: <font color = red>*</font> </b></td><td>Reason for submission. Maximum 65 characters.<br>
	<input type=string name=note value="<%=$record->{note}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

  <td><b>Attribution Nick Name:</b></td>
  <td>
	<select name="submitter">
	<%
	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $record->{submitter}) {
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
<input type=submit name=submit_edit value="<%=$submit_value%>">

</form>

<%
}


sub print_parent_option {
	my statement $statement_tree = $_[0];
	my $selected                 = $_[1];
	my $indent	             = $_[2];

	my $num = $statement_tree->{statement_num};

	if ($num == $selected) {
		%>
		<option value=<%=$num%> selected><%=$indent . $statement_tree->{name}%>
		<%
	} else {
		%>
		<option value=<%=$num%>><%=$indent . $statement_tree->{name}%>
		<%
	}

	my $index;
	my @children = @{$statement_tree->{children}};
	for ($index = 0; $index <= $#children; $index++) {
		&print_parent_option($children[$index], $selected, $indent . ' &nbsp; &nbsp; ');
	}
}


sub display_statement_form {

	my $submit_value = 'Create Statement';
	if ($record->{proposed}) {
		$submit_value = 'Propose Statement Modification';
	}

	my $agreement_disable_str = '';
	if ($record->{statement_num} == 1) {
		$agreement_disable_str = 'disabled';
	}

	my statement $statement_tree;

	if (($record->{proposed}) && ($record->{statement_num} > 1)) {
		$statement_tree = new_tree statement ($dbh, $record->{topic_num}, 1);
	}

%>

<br>
<%=$error_message%>
<br>

<form method=post>
<input type=hidden name=record_id value=<%=$copy_record_id%>>
<input type=hidden name=topic_num value=<%=$record->{topic_num}%>>
<%
if (!$statement_tree) {
	%>
	<input type=hidden name=parent_statement_num value=<%=$record->{parent_statement_num}%>>
	<%
}
%>
<input type=hidden name=statement_num value=<%=$record->{statement_num}%>>
<input type=hidden name=proposed value=<%=$record->{proposed}%>>

<table>
<tr>
  <td><b>Statement Name: <font color = red>*</font> </b></td><td>Mazimum 25 characters.<br>
	<input type=string name=name value="<%=$record->{'name'}%>" maxlength=25 size=25 <%=$agreement_disable_str%>></td></tr>

  <tr height = 20></tr>

  <tr><td><b>One Line Description: <font color = red>*</font> </b></td><td>Maximum 65 characters, end with period.<br>
	<input type=string name=one_line value="<%=$record->{'one_line'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

  <tr><td><b>Key Words:</b></td><td>Maximum 65 characters, comma seperated.<br>
	<input type=string name=key_words value="<%=$record->{'key_words'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

<%
if ($statement_tree) {
	%>
	<tr><td><b>Parent:</b></td><td>
	<select name="parent_statement_num">
	<%
	&print_parent_option($statement_tree, $record->{'parent_statement_num'}, '');
	%>
	</select>
	</td></tr>
	<tr height = 20></tr>
<%
}
%>

  <tr><td><b>Note: <font color = red>*</font> </b></td><td>Reason for submission. Maximum 65 characters.<br>
	<input type=string name=note value="<%=$record->{note}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

  <tr><td><b>Attribution Nick Name:</b></td>
  <td>
	<select name="submitter">
	<%
	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $record->{'submitter'}) {
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
<input type=submit name=submit_edit value="<%=$submit_value%>">

</form>

<%
}

sub display_text_form {

	my $submit_value = 'Create Text';
	if ($record->{proposed}) {
		$submit_value = 'Propose Statement Modification';
	}

	my $agreement_disable_str = '';
	if ($record->{statement_num} == 1) {
		$agreement_disable_str = 'disabled';
	}

%>

	<script language:javascript>
	function xyz() {
		return false;
	}

	function preview_text() {
		if (document.edit_text.value.value == '') {
			alert("Must have some text.");
			return false;
		}
		if (document.edit_text.note.value == '') {
			alert("Must have a note.");
			return false;
		}
		document.edit_text.action = 'https://<%=&func::get_host()%>/topic.asp';
		// document.edit_text.action = 'https://<%=&func::get_host()%>/env.asp'; // for testing.
		return true;
	}
	</script>

	<br>
	<%=$error_message%>
	<br>

	<form method=post name=edit_text>
	<input type=hidden name=record_id value=<%=$copy_record_id%>>
	<input type=hidden name=topic_num value=<%=$record->{'topic_num'}%>>
	<input type=hidden name=statement_num value=<%=$record->{'statement_num'}%>>
	<input type=hidden name=text_size value=<%=$record->{text_size}%>>
	<input type=hidden name=proposed value=<%=$record->{proposed}%>>

	<b>Text: <font color = red>*</font></b><br>

	<textarea NAME="value" ROWS="30" COLS="65"><%=$record->{'value'}%></textarea>

	<table>
	<tr>
	  <td><b>Edit Note: <font color = red>*</font> </b></td><td>Reason for submission. Maximum 65 characters.<br>
	<input type=string name=note value="<%=$record->{'note'}%>" maxlength=65 size=65></td></tr>

	<tr height = 20></tr>

	<tr>
	  <td><b>Attribution Nick Name:</b></td>
	  <td>
	    <select name="submitter">
	    <%
	    my $id;
	    foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $record->{'submitter'}) {
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
	<input type=submit name=submit_edit value="Preview" onClick="return preview_text()">
	<input type=submit name=submit_edit value="<%=$submit_value%>">

	</form>

	<p>
	The Canonizer currently uses the Purple Wiki text parser/formatter.  For a reference see
	<a href="http://purplewiki.blueoxen.net/cgi-bin/wiki.pl?TextFormattingRules" target="_blank">
	Purple Wiki TextFormattingRules</a>
	</p>

	<%
}


########
# main #
########

local $destination = '';

if (!$Session->{'logged_in'}) {
	$destination = '/secure/edit.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	&display_page('Edit', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";

local $error_message = '';

local $record = null;

local $message = '';
local $copy_record_id = 0;

local $class = '';

if ($Request->Form('class')) {
	$class = $Request->Form('class');
} elsif ($Request->QueryString('class')) {
	$class = $Request->QueryString('class');
}

if (&managed_record::bad_managed_class($class)) {
	$error_message = "Error: '$class' is an invalid edit class.<br>\n";
	&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $subtitle = "Create new $class";

if ($Request->Form('record_id')) {
	$copy_record_id = $Request->Form('record_id');
} elsif ($Request->QueryString('record_id')) {
	$copy_record_id = $Request->QueryString('record_id');
}

if ($Request->Form('submit_edit') eq 'Edit Text') {	# edit command from topic preview page.
	$record = new_form $class ($Request);
	if ($record->{error_message}) {
		$error_message = $record->{error_message};
		&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
	$record->{value} = &func::hex_decode($record->{value});
} elsif ($Request->Form('submit_edit')) {

	$record = new_form $class ($Request);

	if ($record->{error_message}) {
		$error_message = $record->{error_message};
	} else {
		if ($Request->Form('submit_edit') eq 'Commit Text') { # from topic preview page.
			$record->{value} = &func::hex_decode($record->{value});
		}
		$record->save($dbh);
		my $any_record = $record;
		my $url = 'http://' . &func::get_host() . '/manage.asp?class=' . $class . '&topic_num=' . $any_record->{topic_num};

		if ($class eq 'statement' || $class eq 'text') {
			$url .= ('&statement_num=' . $any_record->{'statement_num'});
		}

		if ($class eq 'text' && $any_record->{'text_size'}) {
			$url .= ('&long=' . $any_record->{'text_size'});
		}

		sleep(1); # or else it goes to the next page before the new data is live.

		$Response->Redirect($url);
		$Response->End();
	}
} elsif ($copy_record_id) {
	$record = new_record_id $class ($dbh, $copy_record_id);
	if ($record->{error_message}) {
		$error_message = $record->{error_message};
		&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
	$record->{proposed} = 1;
	$record->{note} = ''; # we don't want to copy the old note.
	$subtitle = "Propose $class Modification";

} else { # create a first version of a managed record (not a topic)

	if (! int($Request->QueryString('topic_num'))) {
		$error_message .= "Must have a topic_num in order to create a $class.<br>\n";
	}

	if ($class eq 'statement') {
		if ($Request->QueryString('parent_statement_num')) {
			$record = new_blank statement ();
			$record->{topic_num} = int($Request->QueryString('topic_num'));
			$record->{statement_num} = 0; # a new one will be created on insert.
			$record->{parent_statement_num} = $Request->QueryString('parent_statement_num');
			$record->{note} = 'First Version';
			$record->{proposed} = 0;
		} else {
			$error_message .= "Must have a prent_statement_num in order to create a new statement.<br>\n";
		}
	} else {  # I am assuming 'topic' class will never come through this create new block so this is 'text' case.
		if ($Request->QueryString('statement_num')) {
			$record = new_blank text ();
			$record->{topic_num} = $Request->QueryString('topic_num');
			$record->{statement_num} = $Request->QueryString('statement_num');
			$record->{note} = 'First Version';
			$record->{proposed} = 0;
			if ($Request->QueryString('long')) {
				$record->{text_size} = int($Request->QueryString('long'));
			} else {
				$record->{text_size} = 0; # default to small text size.
			}
		} else {
			$error_message .= "Must have a statement_num in order to create a text record.<br>\n";
		}
	}
	if ($error_message) {
		&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
}

local %nick_names = &func::get_nick_name_hash($Session->{'cid'}, $dbh);

if ($nick_names{'error_message'}) {
	$error_message = $nick_names{'error_message'};
	&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

&display_page($subtitle, [\&identity, \&search, \&main_ctl], [\&display_form]);

%>

