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
use camp;
use statement;
use person;


local $destination = '';

if (!$Session->{'logged_in'}) {
	$destination = '/secure/edit.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$destination .= ('?' . $query_string);
	}
	&display_page('Edit', 'Edit', [\&identity, \&search, \&main_ctl], [\&must_login]);
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
	&display_page('Edit Error', 'Edit Error', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my $subtitle = "Create new $class";

if ($Request->Form('record_id')) {
	$copy_record_id = $Request->Form('record_id');
} elsif ($Request->QueryString('record_id')) {
	$copy_record_id = $Request->QueryString('record_id');
}

if ($Request->Form('submit_edit') eq 'Edit Statement') {	# edit command from topic preview page.
	$record = new_form $class ($Request);
	if ($record->{error_message}) {
		$error_message = $record->{error_message};
		&display_page('Edit Error', 'Edit Error', [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
	$record->{value} = func::hex_decode($record->{value});
	$record->{note} = func::hex_decode($record->{note});
} elsif ($Request->Form('submit_edit')) {

	$record = new_form $class ($Request);

	if ($record->{error_message}) {
		$error_message = $record->{error_message};
	} else {
		if ($Request->Form('submit_edit') eq 'Commit Statement') { # from topic preview page.
			$record->{value} = func::hex_decode($record->{value});
			$record->{note} = func::hex_decode($record->{note});
		}
		$record->save($dbh, $Session->{'cid'});
		my $any_record = $record;
		my $url = 'http://' . func::get_host() . '/manage.asp?class=' . $class . '&topic_num=' . $any_record->{topic_num};

		if ($class eq 'camp' || $class eq 'statement') {
			$url .= ('&camp_num=' . $any_record->{'camp_num'});
		}

		if ($class eq 'statement' && $any_record->{'statement_size'}) {
			$url .= ('&long=' . $any_record->{'statement_size'});
		}

		sleep(1); # or else it goes to the next page before the new data is live.

		$Response->Redirect($url);
		$Response->End();
	}
} elsif ($copy_record_id) {
	$record = new_record_id $class ($dbh, $copy_record_id);
	if ($record->{error_message}) {
		$error_message = $record->{error_message};
		&display_page('Edit Error', 'Edit Error', [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
	$record->{proposed} = 1;
	$record->{note} = ''; # we don't want to copy the old note.
	$subtitle = $record->get_edit_ident($dbh, $record->{topic_num}, $record->{camp_num});

} else { # create a first version of a managed record (not a topic)

	if (! int($Request->QueryString('topic_num'))) {
		$error_message .= "Must have a topic_num in order to create a $class.\n";
	}

	if ($class eq 'camp') {
		if ($Request->QueryString('parent_camp_num')) {
			$record = new_blank camp ();
			$record->{topic_num} = int($Request->QueryString('topic_num'));
			$record->{camp_num} = 0; # a new one will be created on insert.
			$record->{parent_camp_num} = $Request->QueryString('parent_camp_num');
			$record->{note} = 'First Version';
			$record->{proposed} = 0;
		} else {
			$error_message .= "Must have a prent_camp_num in order to create a new camp.\n";
		}
	} else {  # I am assuming 'topic' class will never come through this create new block so this is 'statement' case.
		if ($Request->QueryString('camp_num')) {
			$record = new_blank statement ();
			$record->{topic_num} = $Request->QueryString('topic_num');
			$record->{camp_num} = $Request->QueryString('camp_num');
			$record->{note} = 'First Version';
			$record->{proposed} = 0;
			if ($Request->QueryString('long')) {
				$record->{statement_size} = int($Request->QueryString('long'));
			} else {
				$record->{statement_size} = 0; # default to small statement size.
			}
		} else {
			$error_message .= "Must have a camp_num in order to create a statement record.\n";
		}
	}
	if ($error_message) {
		&display_page('Edit Error', 'Edit Error', [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
}

my %nick_names = func::get_nick_name_hash($Session->{'cid'}, $dbh);

if ($nick_names{'error_message'}) {
	$error_message = $nick_names{'error_message'};
	&display_page('Edit Error', 'Edit Error', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

&display_page($subtitle, $subtitle, [\&identity, \&search, \&main_ctl], [\&display_form]);


########
# subs #
########

# it would be nice to object orient this, but alas, we must have asp ability to do html.
sub display_form {
	my $url = 'http://' . func::get_host() . "/topic.asp/" . $record->{topic_num};
	if ($record->{camp_num}) {
		$url .= '/' . $record->{camp_num};
	}
	%>
	<p><a href="<%=$url%>">Return to camp (no change)</a></p>
	<%
	if ($class eq 'statement') {
		&display_statement_form();
	} elsif ($class eq 'camp') {
		&display_camp_form();
	} else {
		&display_topic_form();
	}
}


sub display_topic_form {

	my $submit_value = 'Create Topic';
	if ($record->{proposed}) {
		$submit_value = 'Propose Topic Modification';
	}

	my @namespaces = func::get_name_spaces($dbh);
	my $namespace = $record->{namespace};

	my $namespace_select_str = "<select name=\"namespace\">\n";

	my $cur_namespace;
	foreach $cur_namespace (@namespaces) {
		$namespace_select_str .= "\t<option value=\"$cur_namespace\" " . (($namespace eq $cur_namespace) ? 'selected' : '') . ">$cur_namespace</option>\n";
	}

	$namespace_select_str .= "</select>\n";



%>

<p>Anything about a topic can be changed at any time, by anyone.  So
don't worry about making mistakes.  Just get any thoughts you have out
there to get things started and moving in the right direction.  That
is the way wiki's work - lots of easy steps by lots of people.</p>

<p>This page is for creating and managing a topic.  The camps,
statements, and support of camps are done on other pages.  Remember
that non supported camps more or less indicate nobody is in this camp
or topic, or that nobody holds this POV.  Like wikipedia articles,
anyone can change anything about a non supported topic, at any time.
Such goes live instantly.</p>

<p>If someone is supporting any camp in a topic, submitted changes go
into a review mode for 1 week before going live.  All direct
supporters will be notified of any proposed changes.  If anyone
objects to any proposed changes they will be rejected and not go live.
All such differing POV can always be added to a forked topic.  The
most supported topics will be the most popular.</p>

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
<p><input type=string name=topic_name value="<%=func::escape_double($record->{topic_name})%>" maxlength=25 size=25></p>

<hr>

<p>Namespace:</p>

<%=$namespace_select_str%>

<%
# AKA: Comma separated - symbolic link created for each one.
# <input type = string name = AKA maxlength = 255 size = 65>
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
		if ($id == $record->{submitter}) {
			%>
			<option value=<%=$id%> selected><%=$nick_names{$id}->{'nick_name'}%></option>
			<%
		} else {
			%>
			<option value=<%=$id%>><%=$nick_names{$id}->{'nick_name'}%></option>
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


sub display_camp_form{

	my $submit_value = 'Create Camp';
	if ($record->{proposed}) {
		$submit_value = 'Propose Camp Modification';
	}

	my camp $camp_tree = '';

	my $agreement_disable_str = '';
	if ($record->{camp_num} == 1) {
		$agreement_disable_str = 'disabled';
	} else {
		$camp_tree = new_tree camp ($dbh, $record->{topic_num}, 1);
	}



%>


<p>Anything about a camp, including its parent, can be changed at any
time, by anyone.  So don't worry about making mistakes.  Just get any
thoughts you have out there to get things started and moving in the
right direction.  That is the way wiki's work - lots of easy steps by
lots of people.</p>

<p>This page is for creating and managing the camp itself.  The text
or camp statement and support of the camp are done on other pages
after the camp is created.  Remember that non supported camps more or
less indicate nobody is in this camp, or that nobody holds this POV.
Like wikipedia articles, anyone can change anything about a non
supported camp, at any time.  Such goes live instantly.</p>

<p>If someone is supporting a camp, changes go into a review mode for
1 week before going live.  All direct supporters will be notified of
any proposed changes.  If anyone objects to any proposed changes they
will be rejected and not go live.  All such differing POV can always
be added to a supporting sub camp or competing sibling camp as a
fork.</p>



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
<input type=hidden name=camp_num value=<%=$record->{camp_num}%>>
<input type=hidden name=proposed value=<%=$record->{proposed}%>>

<p>Camp Name: <span class="required_field">*</span></p>
<p>Maximum 25 characters.  Very short abbreviation used in limited places like paths.  Spaces are not recommended.</p>
<p><input type=string name=camp_name value="<%=func::escape_double($record->{'camp_name'})%>" maxlength=25 size=25 <%=$agreement_disable_str%>></p>

<hr>

<p>Title: <span class="required_field">*</span></p>
<p>Maximum 65 characters.</p>
<p><input type=string name=title value="<%=func::escape_double($record->{'title'})%>" maxlength=65 size=65></p>

<hr>

<p>Key Words:</p>
<p>Maximum 65 characters, comma seperated.</p>
<p><input type=string name=key_words value="<%=func::escape_double($record->{'key_words'})%>" maxlength=65 size=65></p>

<hr>
<p>URL:</p>

<p>Maximum 65 characters.  The /www/ name space is for canonized POV
information about web sites.  This URL field is a place to formally
specify such a link and is not required.  Normally, only the agreement
statement of a topic is used to link an entire canoninzed reputation
topic to any particular web page</p>

<p><input type=string name=canon_url
value="<%=func::escape_double($record->{'url'})%>" maxlength=65
size=65></p>

<%
if ($camp_tree) { # if not then it is the agreement camp (no parent)
	%>
	<hr>
	Parent:
	<p><select name="parent_camp_num">
	<%
	&print_parent_option($camp_tree, $record->{'parent_camp_num'}, $record->{camp_num}, '');
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
			<option value=<%=$id%> selected><%=$nick_names{$id}->{'nick_name'}%></option>
			<%
		} else {
			%>
			<option value=<%=$id%>><%=$nick_names{$id}->{'nick_name'}%></option>
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

sub display_statement_form {

	my $submit_value = 'Create Statement';
	if ($record->{proposed}) {
		$submit_value = 'Propose Statement Modification';
	}

	my $agreement_disable_str = '';
	if ($record->{camp_num} == 1) {
		$agreement_disable_str = 'disabled';
	}

%>

	<script language:javascript>
	function xyz() {
		return false;
	}

	function preview_statement() {
		if (document.edit_statement.value.value == '') {
			alert("Must have some text.");
			return false;
		}
		if (document.edit_statement.note.value == '') {
			alert("Must have a note.");
			return false;
		}
		document.edit_statement.action = 'https://<%=func::get_host()%>/topic.asp';
		// document.edit_statement.action = 'https://<%=func::get_host()%>/env.asp'; // for testing.
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

	<form method=post name=edit_statement>
	<input type=hidden name=record_id value=<%=$copy_record_id%>>
	<input type=hidden name=topic_num value=<%=$record->{'topic_num'}%>>
	<input type=hidden name=camp_num value=<%=$record->{'camp_num'}%>>
	<input type=hidden name=statement_size value=<%=$record->{statement_size}%>>
	<input type=hidden name=proposed value=<%=$record->{proposed}%>>

	<p>Statement: <span class="required_field">*</span></p>

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
			<option value=<%=$id%> selected><%=$nick_names{$id}->{'nick_name'}%></option>
			<%
		} else {
			%>
			<option value=<%=$id%>><%=$nick_names{$id}->{'nick_name'}%></option>
			<%
		}
	    }
	    %>
	    </select></p>

	<hr>

	<p><input type=reset value="Reset"></p>
	<!-- we want to force a preview before commit. -->
	<p><input type=submit name=submit_edit value="Preview" onClick="return preview_statement()"></p>
	<!-- <p><input type=submit name=submit_edit value="<%=$submit_value%>"></p> -->

	</form>

	</div>

     <div class="footer_1">
     <span id="buttons">
     
	<p>The Canonizer currently uses the Purple Wiki text parser/formatter. For a reference see
	this <a href="http://canonizer.com/topic.asp/73" target="_blank">
	Purple Wiki Text topic</a></p>

&nbsp;

     </span>
     </div>

</div>

</div>

	<%
}


sub print_parent_option {
	my camp $camp_tree   = $_[0];
	my $selected         = $_[1];
	my $current_camp_num = $_[2];
	my $indent	     = $_[3];

	my $num = $camp_tree->{camp_num};

	if ($current_camp_num == $num) { # can't set self, or any children, to my parent.
		return();
	}

	if ($num == $selected) {
		%>
		<option value=<%=$num%> selected><%=$indent . $camp_tree->{camp_name}%></option>
		<%
	} else {
		%>
		<option value=<%=$num%>><%=$indent . $camp_tree->{camp_name}%></option>
		<%
	}

	my camp $child;
	foreach $child (@{$camp_tree->{children}}) {
		&print_parent_option($child, $selected, $current_camp_num, $indent);
	}
}


%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->
<!--#include file = "includes/must_login.asp"-->
