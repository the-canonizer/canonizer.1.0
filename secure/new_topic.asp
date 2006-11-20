<%

#######################
#
# new_topic.asp creates both a new topic record and a new statement record.
#	(Each topic must have at least one "agreement" statement.)
# to create a new version of a topic or create a statement (new version or within an already
# existing topic) alone, use edit_topic.asp or edit_statement.asp
#
#######################

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
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->
<%


sub save_topic {
	my $dbh = $_[0];

	my %form_state = ();

	$form_state{'topic_name'} = $Request->Form('topic_name');
	if (length($form_state{'topic_name'}) < 1) {
		$message .= "<h2><font color=red>A Topic Name is required.</font></h2>\n";
	}

	$form_state{'namespace'} = $Request->Form('namespace');

	$form_state{'one_line'}  = $Request->Form('one_line');
	if (length($form_state{'one_line'}) < 1) {
		$message .= "<h2><font color=red>A One Line Description is required.</font></h2>\n";
	}

	$form_state{'key_words'} = $Request->Form('key_words');

	$form_state{'submitter'} = int($Request->Form('submitter'));
	# should validate submitter nick name here!!!!

	my $selstmt;
	my $sth;
	my $rs;

	if (!$message) {

		$new_topic_num = &func::get_next_id($dbh, 'topic', 'topic_num');
		my $new_topic_id = &func::get_next_id($dbh, 'topic', 'record_id');
		my $new_statement_num = 1; # first one (agreement statement) is always 1.
		my $new_statement_id = &func::get_next_id($dbh, 'statement', 'record_id');
		my $now_time = time;
		my $go_live_time = $now_time;

		$selstmt = "insert into topic (record_id,     topic_num,      name, namespace, note,                     submitter,                submit_time, go_live_time) values " .
					     "($new_topic_id, $new_topic_num, ?,    ?,         'First Version of Topic', $form_state{'submitter'}, $now_time,   $go_live_time)";

		$dbh->do($selstmt, \{}, $form_state{'topic_name'}, $form_state{'namespace'}) || die "Failed to create new record with " . $selstmt;

		$selstmt = "insert into statement (topic_num,      name,        one_line, key_words, record_id,         statement_num,      note,                                   submitter,                submit_time, go_live_time) values " .
						 "($new_topic_num, 'Agreement', ?,        ?,         $new_statement_id, $new_statement_num, 'First Version of Agreement Statement', $form_state{'submitter'}, $now_time,   $go_live_time)";

		$dbh->do($selstmt, \{}, $form_state{'one_line'}, $form_state{'key_words'} ) || die "Failed to create new record with " . $selstmt;

	}

	return(%form_state);
}

sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/secure/new_topic.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $query_string);
	}
%>

	<br>
	<h2>You must register and or login before you can edit topics.</h2>
	<center>
	<h2><a href="http://<%=&func::get_host()%>/register.asp">Register</a><h2>
	<h2><a href="<%=$login_url%>">Login</a><h2>
	</center>
<%
}


sub new_topic_form {

%>

<%=$message%>
<br>

<form method=post>

<table>

  <tr height = 20><td colspan=2><hr><p><font color=blue>Topic Values:</font></p></td></tr>
  <tr height = 20></tr>

<tr>
  <td><b>Name: <font color = red>*</font> </b></td><td>Mazimum 25 characters.<br>
	<input type=string name=topic_name value="<%=$form_state{'topic_name'}%>" maxlength=25 size=25></td></tr>

  <tr height = 20></tr>

  <td><b>Namespace:</b></td><td>Nothing for main default namespace.  Path that begins, seperated by, and ends with '/'.  Maximum 65 characters.<br>
	<input type=string name=namespace value="<%=$form_state{'namespace'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>
  <tr height = 20><td colspan=2><hr><p><font color=blue>Agreement Statement Values:</font></p></td></tr>
  <tr height = 20></tr>

<%
#  <td><b>AKA:</b></td><td>Comma separated - symbolic link created for each one.<br>
#	<input type = string name = AKA maxlength = 255 size = 65></td></tr>
#
#  <tr height = 20></tr>
%>


  <td><b>One Line Description: <font color = red>*</font> </b></td><td>Maximum 65 characters.<br>
	<input type=string name=one_line value="<%=$form_state{'one_line'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

  <td><b>Key Words:</b></td><td>Maximum 65 characters, comma seperated.<br>
	<input type=string name=key_words value="<%=$form_state{'key_words'}%>" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>
  <tr height = 20><td colspan=2><hr></td></tr>

  <td><b>Attribution Nick Name:</b></td>
  <td>
	<select name="submitter">
	<%
	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $form_state{'submitter'}) {
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
<input type=submit name=submit value="Create Topic">

</form>

<%
}



########
# main #
########

if (!$Session->{'logged_in'}) {
	&display_page('New Topic', [\&identity, \&as_of, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";	

local %form_state = ();

local $new_topic_num = 0;

local $message = '';

my $subtitle = 'Create New Topic';

if ($Request->Form('submit')) {
	%form_state = &save_topic($dbh);
	if (!$message) {
		$Response->Redirect('http://' . &func::get_host() . '/topic.asp?topic_num=' . $new_topic_num);
		$Response->End();
	}
}

local %nick_names = &func::get_nick_name_hash($Session->{'cid'}, $dbh);

if ($nick_names{'error_message'}) {
	$error_message = $nick_names{'error_message'};
	&display_page($subtitle, [\&identity, \&as_of, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

&display_page($subtitle, [\&identity, \&as_of, \&search, \&main_ctl], [\&new_topic_form]);

%>
