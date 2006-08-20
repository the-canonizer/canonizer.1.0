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

	$form_state{'note'} = $Request->Form('note');
	if (length($form_state{'note'}) < 1) {
		$message .= "<h2><font color=red>A Note is required.</font></h2>\n";
	}

	if ($Request->Form('number')) {
		$form_state{'num'} = $Request->Form('number');
	}

	$form_state{'submitter'} = int($Request->Form('submitter'));
	# should validate submitter nick name here!!!!

	my $selstmt;
	my $sth;
	my $rs;

	if (!$message) {

		# ???? I probably want to drop the topic_id_seq until I convert these????
		$selstmt = 'select max(record_id) from topic';
		$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
		$sth->execute() || die "Failed to execute " . $selstmt;
		$rs = $sth->fetch() || die "Failed to fetch with " . $selstmt;
		my $new_record_id = $rs->[0] + 1;
		$sth->finish();

		my $num;
		my $proposed;
		my $now_time = time;
		my $go_live_time;

		if ($copy_record_id) {
			$num = $form_state{'num'} = $Request->Form('number');
			$proposed = 1;
			$go_live_time = $now_time + (60 * 60 * 24 * 7); # 7 days.
		} else {
			$selstmt = 'select max(num) from topic';
			$sth = $dbh->prepare($selstmt) || die $selstmt;
			$sth->execute() || die "can't get topic num.\n";
			$rs = $sth->fetch() || die "can't fetch topic num.\n";
			$num = $rs->[0] + 1;
			$sth->finish();
			$form_state{'num'} = $num;
			$proposed = 0;
			$go_live_time = $now_time;
		}

		$selstmt = "insert into topic (record_id, num, name, namespace, one_line, key_words, note, submitter, submit_time, go_live_time, proposed) values ($new_record_id, $num, ?, ?, ?, ?, ?, ?, $now_time, $go_live_time, $proposed)";
		# why doesn't the do work?
# 		$dbh->do($sestmt, $form_state{'namespace'}, $form_state{'one_line'}, $form_state{'key_words'}, $form_state{'note'}, $form_state{'submitter'} ) || die "Failed to create new record with " . $selstmt;
		$sth = $dbh->prepare($selstmt) || die $selstmt;
		$sth->execute($form_state{'topic_name'}, $form_state{'namespace'}, $form_state{'one_line'}, $form_state{'key_words'}, $form_state{'note'}, $form_state{'submitter'} );
		$sth->finish();
#		$message .= "selstmt: ($selstmt)[" . $form_state{'submitter'} . "]<br>\n";
	}

	return(%form_state);
}

sub lookup_topic {
	my $dbh = $_[0];
	my $copy_record_id = $_[1];

	my %form_state = ();
	my $selstmt = "select num, name, namespace, one_line, key_words, note from topic where record_id = $copy_record_id";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	if (!($rs = $sth->fetchrow_hashref())) {
		$topic_name = 'invalid';
		&display_page('CANONIZER', 'Topic: '. $topic_name, [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}

	$form_state{'num'} = &func::hex_decode($rs->{'NUM'});
	$form_state{'topic_name'} = &func::hex_decode($rs->{'NAME'});
	$form_state{'note'} = &func::hex_decode($rs->{'NOTE'});
	$form_state{'namespace'} = &func::hex_decode($rs->{'NAMESPACE'});
	$form_state{'one_line'} = &func::hex_decode($rs->{'ONE_LINE'});
	$form_state{'key_words'} = &func::hex_decode($rs->{'KEY_WORDS'});

	$sth->finish();
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

	my $submit_value = 'Create Topic';
	if ($copy_record_id) {
		$submit_value = 'Propose Topic Modification';
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

	if (!$form_state{'num'}) { # new topic (with no copy) case
		$form_state{'num'} = 0;
	}

%>

<br>
<%=$message%>
<br>

<form method=post>
<input type=hidden name=record_id value=<%=$copy_record_id%>>
<input type=hidden name=number value=<%=$form_state{'num'}%>>

<table>
<tr>
  <td><b>Topic Name: <font color = red>*</font> </b></td><td>Mazimum 25 characters.<br>
	<input type=string name=topic_name value="<%=$form_state{'topic_name'}%>" maxlength=25 size=25></td></tr>

  <tr height = 20></tr>

  <td><b>Namespace:</b></td><td>Nothing for main default namespace.  Begins and Ends with '/'.  Maximum 65 characters.<br>
	<input type=string name=namespace value="<%=$form_state{'namespace'}%>" maxlength=65 size=65></td></tr>

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

  <td><b>Note: <font color = red>*</font> </b></td><td>Reason for submission. Maximum 65 characters.<br>
	<input type=string name=note value="" maxlength=65 size=65></td></tr>

  <tr height = 20></tr>

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
<input type=submit name=submit value="<%=$submit_value%>">

</form>

<%
}



########
# main #
########

if (!$Session->{'logged_in'}) {
	&display_page('CANONIZER', 'New Topic', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";	

local %form_state = ();

local $message = '';
local $copy_record_id = 0;

my $subtitle = 'Create New Topic';

if ($Request->Form('record_id')) {
	$copy_record_id = $Request->Form('record_id');
} elsif ($Request->QueryString('record_id')) {
	$copy_record_id = $Request->QueryString('record_id');
}

if ($Request->Form('submit')) {
	%form_state = &save_topic($dbh);
	if (! $message) {
		$Response->Redirect('http://' . &func::get_host() . '/topic_manage.asp?number=' . $form_state{'num'});
		$Response->End();
	}
} else {
	if ($copy_record_id) {
		%form_state = &lookup_topic($dbh, $copy_record_id);
		$subtitle = 'Propose Topic Modification';
	}
}

&display_page('CANONIZER', $subtitle, [\&identity, \&search, \&main_ctl], [\&new_topic_form]);

%>

