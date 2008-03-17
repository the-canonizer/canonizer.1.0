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


#
# What a mess.
# This isn't perfect.
# If a sub record was ever supported, count that time, even if not at that time for now.
# and there are probably ways to spoof this by quickly delegating to lots of different people?
#
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

	$error_message .= 'Only original submitters of a record, or someone that has supported it for more than 1 week, can object to and there by cancel it.';

	return(0);

}


sub get_camp_support_times {
	my $dbh                  = $_[0];
	my $nick_name_clause     = $_[1];
	my $support_time_hash    = $_[2];
	my $recorded_support_ids = $_[3];
	my $go_live_time         = $_[4];

	my $some_support = 0;

	my @support_array = ();

# 	my $selstmt = "select support_id, camp_num, start, end, delegate_nick_name_id from support where topic_num = $topic_num and ($nick_name_clause)";
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

	print(STDERR "???? sub: $sub, sup: $sup.\n");

	if ($sub == $sup) {
		return(1);
	}
	my $parent;
	foreach $parent (keys %{$inverted_camp_tree->{$sub}}) {
		once_was_sub_camp($parent, $sup, $inverted_camp_tree);
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
	if ($objector < 1) {
		$message .= "Invalid submitter id.\n";
	}

	if (! $message) {
		my $now_time = time;
		my $selstmt = "update $class set objector = $objector, object_time = $now_time, go_live_time = $now_time, object_reason = ? where record_id = " . $record->{record_id};
		# what a pain!! if ($dbh->do($selstmt, $object_reason))
		my $sth = $dbh->prepare($selstmt);
		if ($sth->execute($object_reason)) {
			my $notify_msg = "Proposal objected to.\n" .
					"Topic: $record->{'topic_num'}.\n" .
					"Class: $class.\n";
			func::send_email('Canonizer Objection', $notify_msg);
			$Response->Redirect(&make_manage_url($record, $class));
		} else {
			$message = "Failed to update for some reason.\n";
		}
	}
	return ($message . &object_form_message($record, $class));
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

