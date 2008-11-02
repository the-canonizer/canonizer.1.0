<%
if(!$ENV{"HTTPS"}){
	my $qs = '';
	if ($ENV{'QUERY_STRING'}) {
		$qs = '?' . $ENV{'QUERY_STRING'};
	}
        $Response->Redirect('https://' . &func::get_host() . $ENV{"SCRIPT_NAME"} . $qs);
}

use history_class;
use managed_record;
use topic;
use camp;
use statement;


########
# main #
########

my $error_message = '';

if (!$Session->{'logged_in'}) {
	&display_page('Object to Modification', 'Object to Modification', [\&identity, \&search, \&main_ctl], [\&must_login]);
	$Response->End();
}

my $class;
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

my $record_id = '';
my $submit = 0;

if ($Request->Form('submit') eq 'Yes, I want to object.') {
	$record_id = int($Request->Form('record_id'));
	$submit = 1;
} elsif ($Request->QueryString('record_id')) {
	$record_id = int($Request->QueryString('record_id'));
}


my $message = '';

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

if (!$record_id) {
	&display_page('Object to Modification', 'Object to Modification', [\&identity, \&search, \&main_ctl], [\&unknown_record_page]);
	$Response->End();
}

my $record = new_record_id $class ($dbh, $record_id);

if ($record->{error_message}) {
	$error_message = $record->{error_message};
	&display_page('Object to Modification', 'Object to Modification', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}

my camp $camp = undef;
my $topic_num = $record->{topic_num};
my $camp_num;
if ($class eq 'topic') {
	$camp_num = 1;
} else {
	$camp_num = $record->{camp_num};
}

if (! can_object($dbh, $topic_num, $camp_num, $record)) {
	# can_object must set error mesage if can't object.
	&display_page('Object to Modification', 'Object to Modification', [\&identity, \&search, \&main_ctl], [\&error_page]);
	$Response->End();
}


if (time > $record->{go_live_time}) {
	$message = &after_go_live_message();
} elsif ($submit) {
	$message = &do_object($dbh, $record, $class); # does not return (redirects) if successful.
} else {
	$message = &object_form_message($record, $class);
}


&display_page('Object to Modification', 'Object to Modification', [\&identity, \&search, \&main_ctl], [\&object_to_topic_page]);



########
# subs #
########

sub must_login {
	my $login_url = 'https://' . &func::get_host() . '/secure/login.asp?destination=/secure/object.asp';
	if (my $query_string = $ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $query_string);
	}
%>

<p>You must register and/or login before you can object to a change.</p>
<p><a href="http://<%=&func::get_host()%>/register.asp">Register</a></p>
<p><a href="<%=$login_url%>">Login</a></p>

<%
}


sub unknown_record_page {

	if ($record_id) {
		%>
		Unknown Record ID:&nbsp;<%=$record_id%>.
		<%
	} else {
		%>
		No Record ID specified.
		<%
	}
}


sub after_go_live_message {
	return ("You can't object to a record after its go live time.\n" );
}


#######################################
# What a mess.
# This isn't perfect.
# If a sub record was ever supported, count that time, even if not at that time for now.
# and there are probably ways to spoof this by quickly delegating to lots of different people?
#
# also I need to figure the start and stop times 
# of when each camp is under a parent camp based on 
# painful analasys of start time for each camp record.
# and analyze the inverted tree structure based on this and
# the start and stop time of the support.
#
# first get the 'some_support' hash indicating how many hours I've ever supported each camp.
# then make an inverted_camp_tree structure indicating all parent camps all camps in this topic have ever been under.

sub can_object {
	my $dbh       = $_[0];
	my $topic_num = $_[1];
	my $camp_num  = $_[2];
	my $record    = $_[3];

	my $submitter     = $record->{submitter};
	my $go_live_time  = $record->{go_live_time};

	my $cid = $Session->{'cid'};
	my %nick_names = func::get_nick_name_hash($cid, $dbh);

	if ($nick_names{'error_message'}) {
		$error_message = $nick_names{'error_message'};
		return(0);
	}

	if (exists($nick_names{$submitter})) { # I submitted this guy so I can object at any time.
		return(1);
	}

	my $nick_name_clause = func::get_nick_name_clause(\%nick_names);

	# key: camp_num	value: total time supporting this camp.
	my %support_time_hash = ();
	my %recorded_support_ids = ();
	my $some_support = get_camp_support_times($dbh, $nick_name_clause, \%support_time_hash, \%recorded_support_ids, $go_live_time);

	# if a user has ever supported a camp, that has ever been under this record, count that support time.
	my %inverted_camp_tree = ();
	my $support_time = 0;
	my $required_support_time = 60 * 60 * 24 * 7; # 7 days of seconds.

	if ($some_support) {
		$selstmt = "select camp_num, parent_camp_num from camp where topic_num = $topic_num";

		$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
		$sth->execute() || die "Failed to execute " . $selstmt;
		$rs;
		while ($rs = $sth->fetchrow_hashref()) {
			if ($rs->{'parent_camp_num'}) {
				$inverted_camp_tree{$rs->{'camp_num'}}->{$rs->{'parent_camp_num'}} = 1;
			}
		}
		$sth->finish();

		# debug stuff:
		# print(STDERR "inverted_camp_tree:\n");
		# my $key;
		# foreach $key (keys %inverted_camp_tree) {
		# 	print(STDERR "\tcamp $key parents: (");
		# 	my $parent_str = '';
		# 	foreach $parent (keys %{$inverted_camp_tree{$key}}) {
		# 		$parent_str .= "$parent, ";
		# 	}
		# 	chop($parent_str);
		# 	chop($parent_str);
		# 	print(STDERR "$parent_str)\n");
		# }

		my $supported_camp_num;
		foreach $supported_camp_num (keys %support_time_hash) {
			# print(STDERR "I once supported $supported_camp_num.\n");
			if (once_was_sub_camp($supported_camp_num, $camp_num, \%inverted_camp_tree)) {
				$support_time += $support_time_hash{$supported_camp_num};
				if ($support_time > $required_support_time) {
					return(1);
				}
			}
		}
	}

        my $manage_url = make_manage_url($record, $class);

	$error_message .= qq{
<p>Only original submitters of a record, or someone that has supported it for more than 1 week, can object to and there by prevent it from going live.<p>
<p><a href="$manage_url">Return to $class management page</a>.</p>
};

	return(0);

}


##################################################
# produces the 'some_support' hash.
# key: camp number
# val: number of hours supporting till go live time of proposed change.

sub get_camp_support_times {
	my $dbh                  = $_[0];
	my $nick_name_clause     = $_[1];
	my $support_time_hash    = $_[2];
	my $recorded_support_ids = $_[3];
	my $go_live_time         = $_[4];

	my $some_support = 0;

	my @support_array = ();

	my $selstmt = "select * from support where topic_num = $topic_num and ($nick_name_clause)";

	my support $support;
	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	while ($rs = $sth->fetchrow_hashref()) {
		$some_support = 1;
		$support = new_rs support ($rs);
		push(@support_array, $support);
	}
	$sth->finish();

	my $delegate_nick_name_id;
	foreach $support (@support_array) {
		if ($support) { # this could be null if deleted.
			$delegate_nick_name_id = $support->{delegate_nick_name_id};
			if ($delegate_nick_name_id) {
				get_camp_support_times($dbh,
						    "nick_name_id = $delegate_nick_name_id",
						    $support_time_hash,
						    $recorded_support_ids,
						    $go_live_time                            );
			} else {
				my $support_id = $support->{support_id};
				if (!$recorded_support_ids->{$support_id}) {
					$recorded_support_ids->{$support_id} = 1;
					my $support_start = $support->{start};
					my $support_end = $support->{end};
					if (!$support_end) {
						$support_end = $go_live_time;
					}
					$support_time_hash->{$support->{camp_num}} += ($support_end - $support_start);
				}
			}
		}
	}

	# debug stuff:
	# print(STDERR "After nick_name_clause: $nick_name_clause:\n");
	# my $key;
	# foreach $key (keys %{$support_time_hash}) {
	# 	my $hours = $support_time_hash->{$key} / (60 * 60);
	# 	print(STDERR "\t$key: $hours.\n");
	# }

	return($some_support);
}



sub once_was_sub_camp {
	my $sub = $_[0];
	my $sup = $_[1];
	my $inverted_camp_tree = $_[2];

	# for debug:
	# print(STDERR "once_was_sub_camp sub: $sub, sup: $sup.\n");

	if ($sub == $sup) {
		return(1);
	}
	my $parent;
	foreach $parent (keys %{$inverted_camp_tree->{$sub}}) {
		if (once_was_sub_camp($parent, $sup, $inverted_camp_tree)) {
		   return(1);
		}
	}
	return(0);
}


sub object_form_message {
	my $record = $_[0];
	my $class  = $_[1];

	my %nick_names = &func::get_nick_name_hash($Session->{'cid'}, $dbh);

	if ($nick_names{'error_message'}) {
		return($nick_names{'error_message'});
	}

	my $ret_val =
"
	<form method=post>
	If anyone objects to a change the change will not go live.
	Are you sure you want to object to this proposed change?

	<p>Objector Attribution Nick Name:
	<select name=\"submitter\">
";

	my $id;
	foreach $id (sort {$a <=> $b} (keys %nick_names)) {
		if ($id == $Request->Form('submitter')) {
			$ret_val .= "<option value=$id selected>" . $nick_names{$id}->{'nick_name'} . "\n";
		} else {
			$ret_val .= "<option value=$id>" . $nick_names{$id}->{'nick_name'} . "\n";
		}
	}

	$ret_val .=
"	</select><br><br>
	Reason for objection: *
	<input type=string name=object_reason maxlength=65 size=65>

	<input type=hidden name=topic_num value=" . $record->{topic_num} . ">
	<input type=hidden name=record_id value=" . $record->{record_id} . ">

	<br><br>

	<input type=submit name=submit value=\"Yes, I want to object.\">
	<input type=button value=\"No, take me back to the $class record manager.\" onClick='location=\"" . &make_manage_url($record, $class) . "\"'>

	</form>
	<br><br>

";
	return($ret_val);
}


sub object_to_topic_page {

	%>
	<%=$message%>

	<div class="main_content_container">

	<p>Selected Record:</p>

	<%
	$record->print_record($dbh, $history_class::proposed_color);
	%>

	</div>

	<%
}


sub do_object {
	my $dbh    = $_[0];
	my $record = $_[1];
	my $class  = $_[2];

	my $message = '';

	my $object_reason = $Request->Form('object_reason');

	if (length($object_reason) < 1) {
		$message = 'Must have a reason!';
	}

	my $objector = int($Request->Form('submitter'));
	my $objector_nick_name = func::get_nick_name($dbh, $objector);
	if ($objector == $objector_nick_name) {
		$message .= "$objector is an invalid submitter id.<br>\n";
	}

	if (! $message) {
		my $now_time = time;
		my $selstmt = "update $class set objector = $objector, object_time = $now_time, go_live_time = $now_time, object_reason = ? where record_id = " . $record->{record_id};
		# what a pain!! if ($dbh->do($selstmt, $object_reason))
		my $sth = $dbh->prepare($selstmt);
		if ($sth->execute($object_reason)) {
			notify_of_cancel($dbh, $objector_nick_name, $record, $class, $object_reason);
			$Response->Redirect(&make_manage_url($record, $class));
		} else {
			$message = "Failed to update for some reason.\n";
		}
	}
	return ($message . &object_form_message($record, $class));
}


sub notify_of_cancel {
	my $dbh                = $_[0];
	my $objector_nick_name = $_[1];
	my $record             = $_[2];
	my $class              = $_[3];
	my $object_reason      = $_[4];

	my $record_url = make_manage_url($record, $class);

	my ($proposer_name, $proposer_cid) = get_nick_info($dbh, $record->{submitter});

	my $notify_msg = qq{

Dear $proposer_name,

$objector_nick_name has objected to your proposed change listed here:

$record_url

This reason was given for the objection: $object_reason.

Sincerely,

The Canonizer

};

	my $subject = 'Your proposed change was canceled';

	person::send_email_to_cid($dbh, 1, $subject,  $notify_msg); # send one to brent.
	person::send_email_to_cid($dbh, $proposer_cid, $subject,  $notify_msg);
}



sub get_nick_info {
	my $dbh = $_[0];
	my $id = $_[1];

	my $nick_name = '';
	my $ownder_cid = 0;

	my $selstmt = 'select nick_name, owner_code from nick_name where nick_name_id = ' . $id;

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	if ($rs = $sth->fetch()) {
		$nick_name  = $rs->[0];
		$owner_cid = func::canon_decode($rs->[1]);
	}
	$sth->finish();
	return($nick_name, $owner_cid);
}





sub make_manage_url {
	my $record = $_[0];
	my $class  = $_[1];

	my $url = 'http://' . &func::get_host() . '/manage.asp?class=' . $class . '&topic_num=' . $record->{topic_num};
	if ($class eq 'camp') {
		$url .= '&camp_num=' . $record->{camp_num};
	} elsif ($class eq 'statement') {
		$url .= '&camp_num=' . $record->{camp_num};
		if ($record->{statement_size}) {
			$url .= '&long=' . $record->{statement_size};
		}
	}
	return($url);
}




%>

<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->

