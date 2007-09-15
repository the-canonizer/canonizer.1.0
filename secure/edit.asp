<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect("https://" . $ENV{"SERVER_NAME"} . $ENV{"SCRIPT_NAME"} . $qs);
}

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


local $destination = '';

if (!$Session->{'logged_in'}) {
	$destination = '/secure/edit.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	&display_page('Edit', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $dbh = func::dbh_connect(1) || die "unable to connect to database";

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
	$error_message = "Error: '$class' is an invalid edit class.\n";
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
	$record->{value} = func::hex_decode($record->{value});
} elsif ($Request->Form('submit_edit')) {

	$record = new_form $class ($Request);

	if ($record->{error_message}) {
		$error_message = $record->{error_message};
	} else {
		if ($Request->Form('submit_edit') eq 'Commit Text') { # from topic preview page.
			$record->{value} = func::hex_decode($record->{value});
		}
		$record->save($dbh);
		my $any_record = $record;
		my $url = 'http://' . func::get_host() . '/manage.asp?class=' . $class . '&topic_num=' . $any_record->{topic_num};

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
	$subtitle = $record->get_edit_ident($dbh, $record->{topic_num}, $record->{statement_num});

} else { # create a first version of a managed record (not a topic)

	if (! int($Request->QueryString('topic_num'))) {
		$error_message .= "Must have a topic_num in order to create a $class.\n";
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
			$error_message .= "Must have a prent_statement_num in order to create a new statement.\n";
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
			$error_message .= "Must have a statement_num in order to create a text record.\n";
		}
	}
	if ($error_message) {
		&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
}

local %nick_names = func::get_nick_name_hash($Session->{'cid'}, $dbh);

if ($nick_names{'error_message'}) {
	$error_message = $nick_names{'error_message'};
	&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

&display_page($subtitle, [\&identity, \&search, \&main_ctl], [\&display_form]);


########
# subs #
########

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

<div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title"><%=$subtitle%></span>

</div>

<div class="content_1">

<%=$error_message%>

<form method=post>
<input type=hidden name=record_id value=<%=$copy_record_id%>>
<input type=hidden name=topic_num value=<%=$record->{topic_num}%>>
<input type=hidden name=proposed value=<%=$record->{proposed}%>>

<p>Topic Name: <span class="required_field">*</span></p>
<p>Maximum 25 characters.</p>
<p><input type=string name=name value="<%=func::escape_double($record->{topic_name})%>" maxlength=25 size=25></p>
<p>Namespace:</p>
<p>Nothing for main default namespace. Begins and Ends with '/'. Maximum 65 characters.</p>
<p><input type=string name=namespace value="<%=func::escape_double($record->{namespace})%>" maxlength=65 size=65></p>

<%
# AKA: Comma separated - symbolic link created for each one.
# <input type = string name = AKA maxlength = 255 size = 65>
%>

<p>Note: <span class="required_field">*</span></p>
<p>Reason for submission. Maximum 65 characters.</p>
<p><input type=string name=note value="<%=func::escape_double($record->{note})%>" maxlength=65 size=65></p>
<p>Attribution Nick Name:</p>

	<p><select name="submitter">
	<%
	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $record->{submitter}) {
			%>
			<option value=<%=$id%> selected><%=$nick_names{$id}%></option>
			<%
		} else {
			%>
			<option value=<%=$id%>><%=$nick_names{$id}%></option>
			<%
		}
	}
	%>
	</select></p>

<p><input type=reset value="Reset"></p>
<p><input type=submit name=submit_edit value="<%=$submit_value%>"></p>

</form>

</div>

     <div class="footer_1">
     <span id="buttons">
     

&nbsp;    
     
     </span>
     </div>

</div>

</div>

<%
}


sub print_parent_option {
	my statement $statement_tree = $_[0];
	my $selected                 = $_[1];
	my $current_statement_num    = $_[2];
	my $indent	             = $_[3];

	my $num = $statement_tree->{statement_num};

	if ($num == $selected) {
		%>
		<option value=<%=$num%> selected><%=$indent . $statement_tree->{statement_name}%></option>
		<%
	} elsif ($current_statement_num != $num) { # can't set self as parent.
		%>
		<option value=<%=$num%>><%=$indent . $statement_tree->{statement_name}%></option>
		<%
	}

	my statement $child;
	foreach $child (@{$statement_tree->{children}}) {
		&print_parent_option($child, $selected, $current_statement_num, $indent);
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

 <div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title"><%=$subtitle%></span>

</div>

<div class="content_1">

<%=$error_message%>

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

<p>Statement Name: <span class="required_field">*</span></p>
<p>Maximum 25 characters.</p>
<p><input type=string name=name value="<%=func::escape_double($record->{'statement_name'})%>" maxlength=25 size=25 <%=$agreement_disable_str%>></p>

<hr>

<p>Title: <span class="required_field">*</span></p>
<p>Maximum 65 characters.</p>
<p><input type=string name=one_line value="<%=func::escape_double($record->{'title'})%>" maxlength=65 size=65></p>

<hr>

<p>Key Words:</p>
<p>Maximum 65 characters, comma seperated.</p>
<p><input type=string name=key_words value="<%=func::escape_double($record->{'key_words'})%>" maxlength=65 size=65></p>

<%
if ($statement_tree) {
	%>
	Parent:
	<p><select name="parent_statement_num">
	<%
	&print_parent_option($statement_tree, $record->{'parent_statement_num'}, $record->{statement_num}, '');
	%>
	</select></p>
<%
}
	%>

<hr>

<p>Note: <span class="required_field">*</span></p>
<p>Reason for submission. Maximum 65 characters.</p>
<p><input type=string name=note value="<%=func::escape_double($record->{note})%>" maxlength=65 size=65></p>

<hr>

<p>Attribution Nick Name:</p>
<p><select name="submitter">
	<%
	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $record->{'submitter'}) {
			%>
			<option value=<%=$id%> selected><%=$nick_names{$id}%></option>
			<%
		} else {
			%>
			<option value=<%=$id%>><%=$nick_names{$id}%></option>
			<%
		}
	}
	%>
	</select></p>

<hr>

<p><input type=reset value="Reset"></p>
<p><input type=submit name=submit_edit value="<%=$submit_value%>"></p>

</form>

</div>

     <div class="footer_1">
     <span id="buttons">
     

&nbsp;    
     
     </span>
     </div>

</div>

</div>

<%
}

sub display_text_form {

	my $submit_value = 'Create Text';
	if ($record->{proposed}) {
		$submit_value = 'Propose Text Modification';
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
		document.edit_text.action = 'https://<%=func::get_host()%>/topic.asp';
		// document.edit_text.action = 'https://<%=func::get_host()%>/env.asp'; // for testing.
		return true;
	}
	</script>

        <div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title"><%=$subtitle%></span>

</div>

<div class="content_1">

	<%=$error_message%>

	<form method=post name=edit_text>
	<input type=hidden name=record_id value=<%=$copy_record_id%>>
	<input type=hidden name=topic_num value=<%=$record->{'topic_num'}%>>
	<input type=hidden name=statement_num value=<%=$record->{'statement_num'}%>>
	<input type=hidden name=text_size value=<%=$record->{text_size}%>>
	<input type=hidden name=proposed value=<%=$record->{proposed}%>>

	<p>Text: <span class="required_field">*</span></p>

	<p><textarea NAME="value" ROWS="20" COLS="90"><%=$record->{'value'}%></textarea></p>

	<hr>

	<p>Edit Note: <span class="required_field">*</span></p>
	<p>Reason for submission. Maximum 65 characters.</p>
	<p><input type=string name=note value="<%=func::escape_double($record->{'note'})%>" maxlength=65 size=65></p>

	<hr>

	<p>Attribution Nick Name:</p>
	
	    <p><select name="submitter">
	    <%
	    my $id;
	    foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $record->{'submitter'}) {
			%>
			<option value=<%=$id%> selected><%=$nick_names{$id}%></option>
			<%
		} else {
			%>
			<option value=<%=$id%>><%=$nick_names{$id}%></option>
			<%
		}
	    }
	    %>
	    </select></p>

	<hr>

	<p><input type=reset value="Reset"></p>
	<p><input type=submit name=submit_edit value="Preview" onClick="return preview_text()"></p>
	<p><input type=submit name=submit_edit value="<%=$submit_value%>"></p>

	</form>

	</div>

     <div class="footer_1">
     <span id="buttons">
     
	<p>The Canonizer currently uses the Purple Wiki text parser/formatter. For a reference see
	<a href="http://purplewiki.blueoxen.net/cgi-bin/wiki.pl?TextFormattingRules" target="_blank">
	Purple Wiki Text Formatting Rules</a></p>
	

&nbsp;    
     
     </span>
     </div>

</div>

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
<!--#include file = "includes/must_login.asp"-->
