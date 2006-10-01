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
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->

<%


sub error_page {
	%>
	<h1>Error: Unkown topic_id: <%=$copy_topic_id%>.</h1>
	<%
}

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

		$new_topic_num = &func::get_next_id($dbh, 'topics', 'topic_num');
		my $new_topic_id = &func::get_next_id($dbh, 'topics', 'record_id');
		my $new_statement_num = 1; # first one (agreement statement) is always 1.
		my $new_statement_id = &func::get_next_id($dbh, 'statements', 'record_id');
		my $proposed = 0; # first one goes live immediately.
		my $now_time = time;
		my $go_live_time = $now_time;

		$selstmt = "insert into topics (record_id, topic_num, name, namespace, note, submitter, submit_time, go_live_time, proposed) values ($new_topic_id, $new_topic_num, ?, ?, 'First Version of Topic', ?, $now_time, $go_live_time, $proposed)";
		# print(STDERR "topic selstmt: $selstmt.\n");
		# why doesn't the do work?
		# $dbh->do($sestmt, $form_state{'namespace'}, $form_state{'one_line'}, $form_state{'submitter'} ) || die "Failed to create new record with " . $selstmt;
		$sth = $dbh->prepare($selstmt) || die $selstmt;
		$sth->execute($form_state{'topic_name'}, $form_state{'namespace'}, $form_state{'submitter'} );

		$selstmt = "insert into statements (topic_num, name, one_line, key_words, record_id, statement_num, note, submitter, submit_time, go_live_time, proposed) values ($new_topic_num, 'Agreement', ?, ?, $new_statement_id, $new_statement_num, 'First Version of Agreement Statement', ?, $now_time, $go_live_time, $proposed)";
		# print(STDERR "statement selstmt: $selstmt.\n");
		# why doesn't the do work?
		# $dbh->do($sestmt, $form_state{'one_line'}, $form_state{'key_words'}, $form_state{'submitter'} ) || die "Failed to create new record with " . $selstmt;
		$sth = $dbh->prepare($selstmt) || die $selstmt;
		$sth->execute($form_state{'one_line'}, $form_state{'key_words'}, $form_state{'submitter'} );
#		$message .= "selstmt: ($selstmt)[" . $form_state{'submitter'} . "]<br>\n";

		$sth->finish();
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

	my %nick_names = ();
	my $no_nick_name = 1;
	my $owner_code = &func::canon_encode($Session->{'cid'});
	my $selstmt = "select nick_name_id, nick_name from nick_names where owner_code = '$owner_code'";

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
	&display_page('New Topic', [\&identity, \&search, \&main_ctl], [\&must_login]);
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

&display_page($subtitle, [\&identity, \&search, \&main_ctl], [\&new_topic_form]);

%>

