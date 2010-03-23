<%

#######################
#
# new_topic.asp creates both a new topic record and a new camp record.
#	(Each topic must have at least one "agreement" camp.)
# To create a new version of a topic or create a camp (new version or within an already
# existing topic) alone, use edit.asp
#
#######################

if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect("https://" . $ENV{"SERVER_NAME"} . $ENV{"SCRIPT_NAME"} . $qs);
}


########
# main #
########

if (!$Session->{'logged_in'}) {
	display_page('New Topic', 'New Topic', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

my $dbh = func::dbh_connect(1) || die "unable to connect to database";	

my %form_state = ();

my $new_topic_num = 0;

my $message = '';

my $subtitle = 'Create New Topic';

if ($Request->Form('submit')) {
	%form_state = save_topic($dbh);
	if (!$message) {
		func::send_email("New Topic Submitted", "nick id $form_state{'submitter'} added a new topic num $new_topic_num.\nfrom new_topic.asp.\n");
		sleep(1);
		$Response->Redirect('http://' . func::get_host() . '/topic.asp/' . $new_topic_num);
		$Response->End();
	}
}

my %nick_names = func::get_nick_name_hash($Session->{'cid'}, $dbh);

if ($nick_names{'error_message'}) {
	$error_message = $nick_names{'error_message'};
	display_page($subtitle, $subtitle, [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

display_page($subtitle, $subtitle, [\&identity, \&search, \&main_ctl], [\&new_topic_form]);



########
# subs #
########

sub save_topic {
	my $dbh = $_[0];

	my $selstmt;
	my $sth;
	my $rs;

	my %form_state = ();

	$form_state{'topic_name'} = $Request->Form('canon_topic_name');
	if (length($form_state{'topic_name'}) < 1) {
		$message .= format_error("A Topic Name is required.\n");
	}

	my $namespace = $Request->Form('canon_namespace');
	if (length($namespace) > 0) {
		$form_state{'namespace'} = $Request->Form('canon_namespace');
		$selstmt = "select count(*) from topic where namespace = ?";
		$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
		$sth->execute($namespace) || die "Failed to execute " . $selstmt;
		if ($rs = $sth->fetch()) {
			if ($rs->[0] < 1) {
				$message .= format_error("The namespace '$namespace' does not yet exist.\n");
				$message .= format_error("please contact support\@canonizer.com to create a new name space.\n");
			}
		}
		$sth->finish();
	} else {
		$form_state{'namespace'} = '';
	}

	$form_state{'title'}  = $Request->Form('canon_title');
	if (length($form_state{'title'}) < 1) {
		$message .= format_error("A Title is required.\n");
	}

	$form_state{'key_words'} = $Request->Form('canon_key_words');

	$form_state{'url'} = $Request->Form('canon_url');

	$form_state{'submitter'} = int($Request->Form('canon_submitter'));
	# should validate submitter nick name here!!!!

	$messsage .= "???? $namespace.<br>\n";

	if (!$message) {

		$new_topic_num = func::get_next_id($dbh, 'topic', 'topic_num');
		my $new_topic_id = func::get_next_id($dbh, 'topic', 'record_id');
		my $new_camp_num = 1; # first one (agreement camp) is always 1.
		my $new_camp_id = func::get_next_id($dbh, 'camp', 'record_id');
		my $now_time = time;
		my $go_live_time = $now_time;

		$selstmt = "insert into topic (record_id,     topic_num,      topic_name, namespace, note,                     submitter,                submit_time, go_live_time) values " .
					     "($new_topic_id, $new_topic_num, ?,          ?,         'First Version of Topic', $form_state{'submitter'}, $now_time,   $go_live_time)";

		my %dummy = ();
		$dbh->do($selstmt, \%dummy, $form_state{'topic_name'}, $form_state{'namespace'}) || die "Failed to create new record with " . $selstmt;

		$selstmt = "insert into camp (topic_num,      camp_name,        title, key_words, url, record_id,    camp_num,      note,                              submitter,                submit_time, go_live_time) values " .
					   "($new_topic_num, 'Agreement',       ?,     ?,         ?,   $new_camp_id, $new_camp_num, 'First Version of Agreement Camp', $form_state{'submitter'}, $now_time,   $go_live_time)";

		$dbh->do($selstmt, \%dummy, $form_state{'title'}, $form_state{'key_words'}, $form_state{'url'} ) || die "Failed to create new record with " . $selstmt;

	}

	return(%form_state);
}

sub must_login {

	my $login_url = 'https://' . func::get_host() . '/secure/login.asp?destination=/secure/new_topic.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $query_string);
	}
%>
<p>You must register and/or login before you can edit topics.</p>
<p><a href="http://<%=func::get_host()%>/register.asp">Register</a></p>
<p><a href="<%=$login_url%>">Login</a></p>
<%
}


sub new_topic_form {

%>

<p>Anything about a topic can be changed at any time, by anyone.  So
don't worry about making mistakes.  Just get any thoughts you have out
there to get things started and moving in the right direction.  That
is the way wiki's work - lots of easy steps by lots of people.</p>

<p>This page is for creating a topic.  The camps, statements, and
support of camps are done on other pages.  Remember that non supported
camps more or less indicate nobody is in this camp or topic, or that
nobody holds this POV.  Like wikipedia articles, anyone can change
anything about a non supported topic, at any time.  Such goes live
instantly.</p>

<p>If someone is supporting any camp in a topic, submitted changes go
into a review mode for 1 week before going live.  All direct
supporters will be notified of any proposed changes.  If anyone
objects to any proposed changes they will be rejected and not go live.
All such differing POV can always be added to a forked topic.  The
most supported topics will be the most popular.</p>

<p><font color='red'>Important: By default, topics with no support are
filtered out in topic lists.  So before creating a camp, it is
suggested that you go back to the main page and turn the filter on the
side bar off (set it to zero) so your new topic will not be invisible
till you have a chance to support it.  Having the filter turned off,
also displays topics marked for recycle, or other abandoned or useless
unsupported topics.  It is always better to recycle and clean up such,
than to create an entirely new topic.  (And by doing so, you get a
more prestigious lower topic id number!)  If you ever want to delete a
topic, just get all support removed and change its name to recycle
this.</font></p>

<div class="main_content_container">

<div class="section_container">
<div class="header_1">

     <span id="title"><%=$subtitle%></span>

</div>

<div class="content_1">

<%
if (length($message) > 0) {
%>
	<%=$message%>
	<hr>
<%
}

my $namespace_select_str = func::make_namespace_select_str($dbh, $namespace, 1); # 1 -> no submit

%>


<form method=post>
<p>Name: <span class="required_field">*</span></p>
<p>Maximum 25 characters.</p>

<p><input type=string name=canon_topic_name
value="<%=func::escape_double($form_state{'topic_name'})%>"
maxlength=25 size=28 /></p>

<hr>

<p>Namespace:</p>

<p>Most all topics should use the general name space.  Name spaces are
for special purpose topics or to separate topics not of interest to
the general population.  You can request new namespaces, such as for
use by a particular organization, by contacting support.</p>

<p><%=$namespace_select_str%></p>

<br>

<hr>
<%
# <p>Agreement Camp Values:</p>
#AKA: Comma separated - symbolic link created for each one.
#<input type = string name = AKA maxlength = 255 size = 65>
%>

<p>Title: <span class="required_field">*</span></p>
<p>Maximum 65 characters.</p>
<p><input type=string name=canon_title value="<%=func::escape_double($form_state{'title'})%>" maxlength=65 size=75></p>

<hr>

<p>Key Words:</p>
<p>Maximum 65 characters, comma seperated.</p>
<p><input type=string name=canon_key_words value="<%=func::escape_double($form_state{'key_words'})%>" maxlength=65 size=75></p>

<hr>

<p>URL:</p>

<p>Maximum 65 characters.  This field is normally not used unless
there is a specific web page this particular topic is about.  The
/www/ name space is for canonized POV information about specific web
sites.</p>

<p><input type=string name=canon_url
value="<%=func::escape_double($form_state{'url'})%>" maxlength=256
size=75></p>

<hr>

<p>Attribution Nick Name:</p>
<p><select name="canon_submitter">
	<%
	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $form_state{'submitter'}) {
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
<p><input type=submit name=submit value="Create Topic"></p>

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


sub format_error {
	$errors++;
	return('<p class="error_message">' . $_[0] . '</p>');
}



%>
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->
