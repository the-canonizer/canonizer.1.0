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

use topic_class;


sub error_page {
	%>
	<h1><%=$error_message%></h1>
	<%
}

sub bad_class {
	my $class = $_[0];

	if ($class eq 'topic_class') {
		return(0);
	} elsif ($class eq 'statement_class') {
		return(0);
	} elsif ($class eq 'text_class') {
		return(0);
	}
	return(1);
}


sub must_login {

	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/secure/edit.asp';
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


#???? can't I do without this and call it directly????
sub display_form {
	$record->display_form();
}


sub display_topic_form {

	my $submit_value = 'Create Topic';
	if ($submit->{proposed}) {
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
<input type=submit name=submit value="<%=$submit_value%>">

</form>

<%
}


sub get_nick_name_hash {

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

	my $profile_id_url = 'https://' . &func::get_host() . '/secure/profile_id.asp';

	if ($no_nick_name) {
		$error_message .= 
"		<h2>You must have a Nick Name before you can contribute.</h2>
		<h3>You can create a Nick Name on the <a href = \"$profile_id_url\">
		Personal Info Identity Page</a>.</h3>
";
		&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}

	return(%nick_names);
}



########
# main #
########

if (!$Session->{'logged_in'}) {
	&display_page('New Topic', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";	

local $error_message = '';

local $record = null;

local $message = '';
local $copy_record_id = 0;

my $subtitle = 'Create New Topic';

my $class;
if ($Request->Form('class')) {
	$class = $Request->Form('class');
} elsif ($Request->QueryString('class')) {
	$class = $Request->QueryString('class');
}

if (&bad_class($class)) {
	$error_message = "Error: '$class' is an invalid edit class.<br>\n";
	&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

if ($Request->Form('record_id')) {
	$copy_record_id = $Request->Form('record_id');
} elsif ($Request->QueryString('record_id')) {
	$copy_record_id = $Request->QueryString('record_id');
}

if ($Request->Form('submit')) {
	$record = new_form $class ($Request);

	if ($record->{error_message}) {
		$error_message = $record->{error_message};
	} else {
		$record->save($dbh);
		$Response->Redirect('http://' . &func::get_host() . '/manage_topic.asp?topic_num=' . $record->{topic_num});
		$Response->End();
	}
} elsif ($copy_record_id) {
	$record = new_record_id $class ($copy_record_id, $dbh);
	if ($record->{error_message}) {
		$error_message = $record->{error_message};
		&display_page("Edit Error", [\&identity, \&search, \&main_ctl], [\&error_page]);
		$Response->End();
	}
	$record->{proposed} = 1;
	$record->{note} = ''; # we don't want to copy the old note.
	$subtitle = 'Propose Topic Modification';
} else { # new record with new num and data from querystring
	# finish this up some day ????
}

local %nick_names = get_nick_name_hash($dbh);

&display_page($subtitle, [\&identity, \&search, \&main_ctl], [\&display_form]);

%>

