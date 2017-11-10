package topic;

use strict;

use base   qw( managed_record );
use fields qw( topic_name namespace topic_num camp_num); # camp_num is not used, but required for poly calls.

use camp;

# this block markes static or class methods.
{

sub get_args {
	my $Request = $_[0];

	my %args = ();

	my $path_info = $ENV{'PATH_INFO'};
	my $pi_topic_num = 0;
	my $pi_camp_num = 0;
	if ($path_info =~ m|/(\d+)|) {
		$pi_topic_num = $1;
	}

	if ($Request->Form('topic_num')) {
		$args{'topic_num'} = int($Request->Form('topic_num'));
	} elsif ($pi_topic_num) {
		$args{'topic_num'} = $pi_topic_num;
	} elsif ($Request->QueryString('topic_num')) {
		$args{'topic_num'} = int($Request->QueryString('topic_num'));
	} else {
		$args{'error_message'} .= "Must have a valid topic_num to manage a topic.<br>\n";
	}

	return(\%args);
}


sub get_record_info {
	my $dbh  = $_[0];
	my $args = $_[1];

    my $topic_num     = $args->{'topic_num'};

	my $error_message = '';
	my $selstmt;
	my $manage_ident = 'Uknown';

    if (! $topic_num) {
		$error_message .= "Error: invalid topic_num.\n";
	}

	if (! $error_message) {
		$manage_ident = get_manage_ident($dbh, $topic_num);
		if ($manage_ident =~ m|error|i) {
			$error_message = $manage_ident;
			$manage_ident = 'Unknown';
		} else {
			$selstmt = "select record_id, topic_name, namespace, topic_num, note, submitter, go_live_time, proposed, replacement, objector, object_time, object_reason from topic where topic_num = $topic_num order by go_live_time";
		}
	}

	if ($error_message) {
		return ($error_message, '');
    } else {
		return($selstmt, $manage_ident);
	}
}


sub get_selstmt {
    my $args = $_[0];

	my $topic_num = $args->{'topic_num'};
    return "select record_id, topic_name, namespace, topic_num, note, submitter, go_live_time, proposed, replacement, objector, object_time, object_reason from topic where topic_num = $topic_num order by go_live_time";
}

sub canonized_list {
	my $dbh        = $_[0];
	my $sth        = $_[1]; # list of topics to canonize
	my $as_of_mode = $_[2];
	my $as_of_date = $_[3];
	my $canonizer  = $_[4];
	my $filter     = $_[5];

	my $rs;

	my @topic_array = ();

	my %topic_names = ();

	my $topic_num;
	my camp $camp;
	my $no_data = 1;
	while ($rs = $sth->fetch()) {
		$no_data = 0;
		$topic_num = $rs->[0];
		$topic_names{$topic_num} = $rs->[1];
		$camp = new_tree camp ($dbh, $topic_num, 1, $as_of_mode, $as_of_date);
		if (!$camp) {
			next;
		}
		$camp->canonize($dbh, $canonizer, $as_of_mode, $as_of_date);
		push(@topic_array, $camp);
	}
	$sth->finish();

	my $return_val = '';

	my $topic_name;
	foreach $camp (sort {(($a->{score} <=> $b->{score}) * -1)} @topic_array) {
		if ($camp->{score} < $filter) { next };
		$topic_num = $camp->{topic_num};
		$topic_name = $topic_names{$camp->{topic_num}};
		$return_val .= $camp->display_camp_tree($topic_name, $topic_num, '', '', '', $filter);
	}

	return($return_val);
}


}


sub get_manage_ident {
	my $dbh           = $_[0];
	my $topic_num     = $_[1];

	my ($topic_name, $error_message) = get_name($dbh, $topic_num);

	my $manage_ident;

	if ($error_message) {
		$manage_ident = $error_message;
	} else {
		$manage_ident = "topic: $topic_name";
	}

	return($manage_ident);
}


sub get_edit_ident {
	my $caller        = $_[0];
	my $dbh           = $_[1];
	my $topic_num     = $_[2];

	my ($topic_name, $error_message) = get_name($dbh, $topic_num);

	my $edit_ident;

	if ($error_message) {
		$edit_ident = $error_message;
	} else {
		$edit_ident = "Propose modification for topic: $topic_name";
	}

	return($edit_ident);
}


sub get_name {
	my $dbh            = $_[0];
	my $topic_num      = $_[1];

	my $topic_name     = 'Unknown';
	my $error_message  = '';

	my $now_time = time();

	my $selstmt = "select topic_name from topic where topic_num = $topic_num and objector is null and go_live_time in (select max(go_live_time) from topic where topic_num = $topic_num and objector is null and go_live_time < $now_time)";

	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	if ($rs = $sth->fetch()) {
		$topic_name     = $rs->[0];
	} else {
		$error_message = "Error: can't find topic name.\n";
	}

	return($topic_name, $error_message);
}


sub new_blank {
	my $caller = $_[0];

    my $class = ref($caller) || $caller;
    no strict "refs";
    my topic $self = [ \%{"${class}::FIELDS"} ];
    bless $self, $class;

	return($self);
}


sub new_rs {
    my ($caller, $rs) = @_;

	my topic $self = new_blank topic ();

    $self->{record_id}     = $rs->{'record_id'};
    $self->{topic_name}    = $rs->{'topic_name'};
    $self->{namespace}     = $rs->{'namespace'};
    $self->{topic_num}     = $rs->{'topic_num'};
    $self->{note}          = $rs->{'note'};
    $self->{submitter}     = $rs->{'submitter'};
    $self->{go_live_time}  = $rs->{'go_live_time'};
    $self->{proposed}      = $rs->{'proposed'};
    $self->{replacement}   = $rs->{'replacement'};
    $self->{objector}      = $rs->{'objector'};
    $self->{object_time}   = $rs->{'object_time'};
    $self->{object_reason} = $rs->{'object_reason'};

    return($self);
}


sub new_record_id {
	my $caller    = $_[0];
	my $dbh       = $_[1];
	my $record_id = $_[2];

	my $selstmt = "select record_id, topic_name, namespace, topic_num, note, submit_time, submitter, go_live_time, objector, object_time, object_reason, proposed, replacement from topic where record_id = $record_id";
	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";

	$sth->execute() || die "Failed to execute $selstmt";

	my $rs = $sth->fetchrow_hashref();
	$sth->finish();

	if ($rs) {
		return(new_rs topic ($rs));
	} else {
		my topic $self = new_blank topic ();
		$self->{error_message} = "No topic record with record_id: $record_id.<br>\n";
		return($self);
	}
}


sub new_topic_num {
	my $caller     = $_[0];
	my $dbh        = $_[1];
	my $topic_num  = $_[2];
 	my $as_of_mode = $_[3];
 	my $as_of_date = $_[4];

	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		$as_of_clause = 'and go_live_time < ' . func::parse_as_of_date($as_of_date);
    } else {
		$as_of_clause = 'and go_live_time < ' . time;
    }

	my $selstmt = "select record_id, topic_name, namespace, topic_num, note, submit_time, submitter, go_live_time, objector, object_time, object_reason, proposed, replacement from topic where topic_num = $topic_num and objector is null $as_of_clause order by go_live_time desc limit 1";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";

	$sth->execute() || die "Failed to execute $selstmt";

	my $rs = $sth->fetchrow_hashref();
	$sth->finish();

	if ($rs) {
		return(new_rs topic ($rs));
	} else {
		my topic $self = new_blank topic ();
		$self->{error_message} = "No topic record with topic_num: $topic_num.<br>\n";
		return($self);
	}
}


sub new_form {
	my $caller  = $_[0];
	my $Request = $_[1];

	my topic $self = new_blank topic ();
	my $error_message = '';

	$self->{topic_name} = $Request->Form('topic_name');
	if (length($self->{topic_name}) < 1) {
		$error_message .= "<h2>A Topic Name is required.</h2>\n";
	}

	if ($Request->Form('namespace')) {
		$self->{namespace} = $Request->Form('namespace');
	} else {
		$self->{namespace} = '';
	}
	if ($self->{namespace} eq 'general') {
		$self->{namespace} = '';
	}

	$self->{note} = $Request->Form('note');
	if (length($self->{note}) < 1) {
		$error_message .= "<h2>A Note is required.</h2>\n";
	}

	if ($Request->Form('topic_num')) {
		$self->{topic_num} = $Request->Form('topic_num');
	}

	$self->{submitter} = int($Request->Form('submitter'));
	# should validate submitter nick name here!!!!

	$self->{proposed} = int($Request->Form('proposed'));

	$self->{error_message} = $error_message;

	return $self;
}


sub print_record {
    my $self  = $_[0];
    my $dbh   = $_[1];
    my $color = $_[2];

    my $object_link = '&nbsp';
    if ((time < $self->{go_live_time}) && ! $self->{objector}) {
	$object_link = '	    <a href="https://' . func::get_host() . '/secure/object.asp?class=topic&record_id=' . $self->{record_id} . "\">Object (cancel&nbsp;proposal)</a>\n";
    }

    print("	<table class='$color' cellpadding='0' cellspacing='0'>\n");
    print("	<tr><td colspan=3>Go Live Time: " . func::to_local_time($self->{go_live_time}) . "</td></tr>\n");

    print("	<tr><td>\n");
    print('	    <a href="https://' . func::get_host() . '/secure/edit.asp?class=topic&record_id=' . $self->{record_id} . "\">Propose modification based on this version</a>\n");
    print('	    </td><td>Name:</td><td>' . func::escape_html($self->{topic_name}) . "</td>\n");
    print("	</tr>\n");

    print("	<tr><td>\n");
    print($object_link);

    print('	    </td><td>Name Space: </td><td>' . func::escape_html($self->{namespace}) . "</td>\n");
    print("	</tr>\n");

    print('	<tr><td>&nbsp;</td><td>Version Note:</td><td>' . func::escape_html($self->{note}) . "</td></tr>\n");

    print("	<tr><td>\n");
    print('	</td><td>Submitter:</td><td><b>' . func::escape_html(func::get_nick_name($dbh, $self->{submitter})) . "</td></tr>\n");

    if ($self->{objector}) {
	print("	<tr><td colspan=3>",
	      func::get_nick_name($dbh, $self->{objector}),
	      " objected to this change on ",
	      func::to_local_time($self->{object_time}), "\n",
	      $self->{object_reason}, "</td><tr>\n"  );
    }

    print("</table>\n\n\n");
}


sub save {
    my $self  = $_[0];
    my $dbh   = $_[1];
	my $cid   = $_[2];

	my camp $old_tree;
	my %support_hash = ();

	my $new_record_id = func::get_next_id($dbh, 'topic', 'record_id');
	my $topic_num = 0;
	if ($self->{proposed}) {
		$topic_num = $self->{topic_num};
		$old_tree = new_tree camp ($dbh, $topic_num, 1);
		$old_tree->get_support($dbh, \%support_hash);
	} else {
		$topic_num = func::get_next_id($dbh, 'topic', 'topic_num');
	}
	$self->{topic_num} = $topic_num;

	my topic $old_rec = new_topic_num topic ($dbh, $topic_num);

	my @tmp_arr = (keys %support_hash);
	my $num_supporters = $#tmp_arr + 1;

	if ($support_hash{$cid}) {
		$num_supporters--; # go live immediately if I am the only supporter.
	}

	my $now_time = time;
	my $go_live_time;
	my $do_notify = 0;
	if (($self->{proposed}) && ($num_supporters > 0)) {
		$go_live_time = $now_time + (60 * 60 * 24 * 7); # add 7 days for review.
		$do_notify = 1;
	} else {
		$go_live_time = $now_time;
	}
	$self->{go_live_time} = $go_live_time;

	my $selstmt = "insert into topic (record_id,      topic_name, namespace, topic_num,  note, submit_time, submitter,          go_live_time ) values " .
									"($new_record_id, ?,          ?,         $topic_num, ?,    $now_time,   $self->{submitter}, $go_live_time)";

	my %dummy = ();
 	if (! $dbh->do($selstmt, \%dummy, $self->{topic_name}, $self->{namespace}, $self->{note})) {
		return("<h2>System Error: failed to save topic.</h2>\n");
	}

	$self->submit_notify($dbh, $old_rec, $old_tree, \%support_hash, $do_notify);
	return('');
}


sub submit_notify {
    my topic     $self         = $_[0];
	my           $dbh          = $_[1];
	my topic     $old_rec      = $_[2];
	my camp      $old_tree     = $_[3];
	my           $support_hash = $_[4];
	my           $do_notify    = $_[5];

	my $topic_num = $old_tree->{topic_num};
	my $camp_num  = $old_tree->{camp_num};

	my $diff_message = '';

	if ($self->{topic_name} ne $old_rec->{topic_name}) {
		$diff_message .= "* Topic name '$old_rec->{topic_name}' changed to '$self->{topic_name}'.\n";
	}
	if ($self->{namespace} ne $old_rec->{namespace}) {
		$diff_message .= "* Namespace '$old_rec->{namespace}' changed to '$self->{namespace}'.\n";
	}

	if (! $diff_message) {
		return; # don't notify if there are no changes.
	}

	my $topic_name = $old_rec->{topic_name};

	my $cid;

	my $go_live_time_str = gmtime($self->{go_live_time}) . ' (GMT)';

	# just to be sure brent also get's this e-mail.
	$support_hash->{1} = 1;
	my $subject = "Change submitted to the topic '$topic_name'";

	my $message = <<EOF;

\$name <\$email>,

A proposed change has been submitted to the Canonizer for
the topic: '$topic_name' which you directly support.

This note was given for this change: $self->{note}

Here are the specific changes from the current live version:

$diff_message

This not yet live change can be previewed here:
(Note: this link will set your as_of mode to include review.)
http://canonizer.com/topic.asp/$topic_num/$camp_num?as_of_mode=review

As a supporter, if you disagree with anything about this change, you
can object to it on the "manage" camp page which will prevent it
from going live.  If no supporters object to this change before
$go_live_time_str it will go live at that time.

You are receiving this e-mail because you are a direct supporter of
this camp.  If you prefer not to receive future e-mails about
this you can delegate your support to another trusted person in your
camp, or remove your support entirely on the camp page you are
supporting here:

\$supported_url

Thank You,

The Canonizer

EOF

	if ($diff_message and $do_notify) {
		person::send_email_to_hash($dbh, $support_hash, $subject, $message, $topic_num);
	} else { # just to brent
		$message =~ s|\$supported_url|http://canonizer.com/topic.asp/$topic_num/$camp_num|gi;
		$message .= "\n\n\nNo email was sent.\n";
		person::send_email_to_cid($dbh, 1, $subject, $message);
	}
}


1;

