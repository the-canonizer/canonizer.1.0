package statement;

use strict;

use base   qw( managed_record );

use fields qw( topic_name camp_name value topic_num camp_num statement_size );

use camp;
use person;
use topic;

# this block markes static or class methods.
{

sub get_args {
	my $Request = $_[0];

	my %args = ();

	my $path_info = $ENV{'PATH_INFO'};
	my $pi_topic_num = 0;
	my $pi_camp_num = 0;
	if ($path_info =~ m|/(\d+)/?(\d*)|) {
		$pi_topic_num = $1;
		if ($2) {
			$pi_camp_num = $2;
		}
	}

	if ($Request->Form('topic_num')) {
		$args{'topic_num'} = int($Request->Form('topic_num'));
	} elsif ($pi_topic_num) {
		$args{'topic_num'} = $pi_topic_num;
	} elsif ($Request->QueryString('topic_num')) {
		$args{'topic_num'} = int($Request->QueryString('topic_num'));
	} else {
		$args{'error_message'} .= "Must have a valid topic_num to manage a statement record.\n";
	}

	if ($Request->Form('camp_num')) {
		$args{'camp_num'} = int($Request->Form('camp_num'));
	} elsif ($pi_camp_num) {
		$args{'camp_num'} = $pi_camp_num;
	} elsif ($Request->QueryString('camp_num')) {
		$args{'camp_num'} = int($Request->QueryString('camp_num'));
	} else {
		$args{'error_message'} .= "Must have a valid camp_num to manage a statement record.\n";
	}

	if ($Request->Form('statement_size')) {
		$args{'statement_size'} = $Request->Form('statement_size');
	} elsif ($Request->QueryString('long')) {
		$args{'statement_size'} = $Request->QueryString('long');
	} else {
		$args{'statement_size'} = 0; # default to short statement
	}

	return(\%args);
}


sub get_record_info {
	my $dbh  = $_[0];
	my $args = $_[1];

    my $topic_num      = $args->{'topic_num'};
	my $camp_num       = $args->{'camp_num'};
	my $statement_size = $args->{'statement_size'};

	my $error_message = '';
	my $selstmt;
	my $manage_ident = 'Unknown';

    if (! $topic_num) {
		$error_message .= "Error: invalid topic_num.\n";
	}

    if (! $camp_num) {
		$error_message .= "Error: invalid camp_num.\n";
	}

	if (! $statement_size) {
		$statement_size = 0;
	}

	if (! $error_message) {
		$manage_ident = get_manage_ident($dbh, $topic_num, $camp_num);
		if ($manage_ident =~ m|error|i) {
			$error_message = $manage_ident;
			$manage_ident = 'Unknown';
		} else {
			$selstmt = "select value, topic_num, camp_num, record_id, statement_size, note, submit_time, submitter, go_live_time, objector, object_time, object_reason, proposed, replacement from statement where topic_num=$topic_num and camp_num=$camp_num and statement_size = $statement_size order by go_live_time";
		}
	}
	if ($error_message) {
		return ($error_message, '');
    } else {
		return($selstmt, $manage_ident);
	}
}


}


sub get_manage_ident {
	my $dbh       = $_[0];
	my $topic_num = $_[1];
	my $camp_num  = $_[2];

	my ($topic_name, $camp_name, $error_message) = get_names($dbh, $topic_num, $camp_num);

	my $manage_ident;

	if ($error_message) {
		$manage_ident = $error_message;
	} else {
		$manage_ident = "statement for camp: $camp_name on topic: $topic_name";
	}

	return($manage_ident);
}


sub get_edit_ident {
	my $caller    = $_[0];
	my $dbh       = $_[1];
	my $topic_num = $_[2];
	my $camp_num  = $_[3];

	my ($topic_name, $camp_name, $error_message) = get_names($dbh, $topic_num, $camp_num);

	my $edit_ident;

	if ($error_message) {
		$edit_ident = 'Unknown';
	} else {
		$edit_ident = "Propose statement modification for camp: $camp_name on topic: $topic_name.";
	}

	return($edit_ident);
}


sub get_names {
	my $dbh       = $_[0];
	my $topic_num = $_[1];
	my $camp_num  = $_[2];

	return(camp::get_names($dbh, $topic_num, $camp_num));
}


sub new_blank {
	my $caller = $_[0];

    my $class = ref($caller) || $caller;
    no strict "refs";
    my statement $self = [ \%{"${class}::FIELDS"} ];
    bless $self, $class;

	return($self);
}



sub new_rs {
    my ($caller, $rs) = @_;

	my statement $self = new_blank statement ();

	$self->{topic_name}     = $rs->{'topic_name'};
	$self->{value}          = $rs->{'value'};
    $self->{topic_num}      = $rs->{'topic_num'};
	$self->{camp_num}       = $rs->{'camp_num'};
	$self->{statement_size} = $rs->{'statement_size'};
	$self->{record_id}      = $rs->{'record_id'};
    $self->{note}           = $rs->{'note'};
	$self->{submit_time}    = $rs->{'submit_time'};
    $self->{submitter}      = $rs->{'submitter'};
    $self->{go_live_time}   = $rs->{'go_live_time'};
    $self->{objector}       = $rs->{'objector'};
    $self->{object_time}    = $rs->{'object_time'};
    $self->{object_reason}  = $rs->{'object_reason'};
    $self->{proposed}       = $rs->{'proposed'};
    $self->{replacement}    = $rs->{'replacement'};

    return($self);
}


sub new_record_id {
	my $caller    = $_[0];
	my $dbh       = $_[1];
	my $record_id = $_[2];

	my $now_time = time;

	my $selstmt = "select s.camp_name, t.value, t.topic_num, t.camp_num, t.record_id, t.statement_size, t.note, t.submit_time, t.submitter, t.go_live_time, t.objector, t.object_time, t.object_Reason, t.proposed, t.replacement from camp s, statement t where t.record_id = $record_id and s.topic_num = t.topic_num and s.camp_num = t.camp_num and s.go_live_time in (select max(s.go_live_time) from camp s, statement t where t.record_id = $record_id and t.topic_num = s.topic_num and t.camp_num = s.camp_num and s.go_live_time < $now_time)";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";

	$sth->execute() || die "Failed to execute $selstmt";

	my $rs = $sth->fetchrow_hashref();
	$sth->finish();

	if ($rs) {
		return(new_rs statement ($rs));
	} else {
		my statement $self = new_blank statement ();
		$self->{error_message} = "No statement record with record_id: $record_id.\n";
		return($self);
	}
}


sub new_num {
	my $caller         = $_[0];
	my $dbh            = $_[1];
	my $topic_num      = $_[2];
	my $camp_num       = $_[3];
	my $statement_size = $_[4];
	my $as_of_mode     = $_[5];
	my $as_of_date     = $_[6];

	my $selstmt;

	if (! $statement_size) {
		$statement_size = 0;
	}

	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		$as_of_clause = 'and t.go_live_time < ' . func::parse_as_of_date($as_of_date);
    } else {
		$as_of_clause = 'and t.go_live_time < ' . time;
    }

	$selstmt = "select s.camp_name, t.value, t.topic_num, t.camp_num, t.record_id, t.statement_size, t.note, t.submit_time, t.submitter, t.go_live_time, t.objector, t.object_time, t.object_Reason, t.proposed, t.replacement from camp s, statement t where t.statement_size = $statement_size and t.topic_num = $topic_num and s.topic_num = $topic_num and t.camp_num = $camp_num and s.camp_num = $camp_num and t.objector is null $as_of_clause order by t.go_live_time desc limit 1";

#	my $old = "select s.camp_name, t.value, t.topic_num, t.statement_num, t.record_id, t.statement_size, t.note, t.submit_time, t.submitter, t.go_live_time, t.objector, t.object_time, t.object_Reason, t.proposed, t.replacement from camp s, statement t where t.statement_size = $statement_size and t.topic_num = $topic_num and t.replacement is null and t.proposed = 0 and s.topic_num = t.topic_num and s.camp_num = $camp_num and s.camp_num = t.camp_num and s.replacement is null and s.proposed = 0";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";

	$sth->execute() || die "Failed to execute $selstmt";

	my $rs = $sth->fetchrow_hashref();
	$sth->finish();

	if ($rs) {
		return(new_rs statement ($rs));
	} else {
		my statement $self = new_blank statement ();
		if ($statement_size) {
			$self->{error_message} = "No long ";
		} else {
			$self->{error_message} = "No short ";
		}
		$self->{error_message} .= "statement record for topic $topic_num and camp $camp_num.\n";
		return($self);
	}
}


sub new_form {
	my $caller  = $_[0];
	my $Request = $_[1];

	my statement $self = new_blank statement ();
	my $error_message = '';

	$self->{value} = $Request->Form('value');
	if (length($self->{value}) < 1) {
		$error_message .= "There must be some text.\n";
	}

	$self->{note} = $Request->Form('note');
	if (length($self->{note}) < 1) {
		$error_message .= "A Note is required.\n";
	}

	if ($Request->Form('topic_num')) {
		$self->{topic_num} = $Request->Form('topic_num');
	} else {
		$self->{topic_num} = 0;
	}

	if ($Request->Form('camp_num')) {
		$self->{camp_num} = $Request->Form('camp_num');
	} else {
		$self->{camp_num} = 1; # agreemement camp
	}

	if ($Request->Form('statement_size')) {
		$self->{statement_size} = $Request->Form('statement_size');
	} else {
		$self->{statement_size} = 0; # default to small
    }

	$self->{submitter} = int($Request->Form('submitter'));
	# should validate submitter nick name here!!!!

	$self->{proposed} = int($Request->Form('proposed'));

	$self->{error_message} = $error_message;

	return $self;
}


sub any_statement_check {
	my $dbh            = $_[0];
	my $topic_num      = $_[1];
	my $camp_num       = $_[2];
	my $statement_size = $_[3];

    my $selstmt = "select count(*) from statement where topic_num = $topic_num and camp_num = $camp_num and statement_size = $statement_size";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";

	$sth->execute() || die "Failed to execute $selstmt";

	my $rs = $sth->fetch();
	$sth->finish();

	if ($rs and $rs->[0]) {
		return(1);
	} else {
		return(0);
	}
}



sub print_record {
    my $self  = $_[0];
    my $dbh   = $_[1];
    my $color = $_[2];

    my $object_link = '&nbsp';
    if ((time < $self->{go_live_time}) && ! $self->{objector}) {
	$object_link = '<a href="https://' . func::get_host() . '/secure/object.asp?class=statement&record_id=' . $self->{record_id} . "\">Object&nbsp;(cancel&nbsp;proposal)</a>\n";
    }

    print("	<table class='$color' cellpadding='0' cellspacing='0'>\n");
    print("	<tr><td colspan=3>Go Live Time: " . func::to_local_time($self->{go_live_time}) . "</td></tr>\n");

    print("	<tr><td>\n");
    print('	    <a href="https://' . func::get_host() . '/secure/edit.asp?class=statement&record_id=' . $self->{record_id} . "\">Propose modification based on this version</a>\n");

	# firefox doesn't wrap unless there is white space.
	my $value = $self->{value};
	my $ua = $ENV{'HTTP_USER_AGENT'};
	if ($ua =~ /Firefox\//) {
		$value =~ s|(\S{50})|$1 |g;
	}

    print('	    </td><td>Value:</td><td>' . func::escape_html($value) . "</td>\n");
    print("	</tr>\n");

    print("	<tr><td>\n");
    print($object_link);

    print('	    </td><td>Version Note:</td><td>' . func::escape_html($self->{note}) . "</td>\n");
    print("	</tr>\n");

    print("	<tr><td>\n");
    print('	</td><td>Submitter:</td><td>' . func::escape_html(func::get_nick_name($dbh, $self->{submitter})) . "</td></tr>\n");

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

	my $new_record_id = func::get_next_id($dbh, 'statement', 'record_id');
	my $topic_num     = $self->{topic_num};
	my $camp_num      = $self->{camp_num};

	my camp $old_tree = new_tree camp ($dbh, $topic_num, $camp_num);
	my %support_hash = ();
	$old_tree->get_support($dbh, \%support_hash);
	my @tmp_arr = (keys %support_hash);
	my $num_supporters = $#tmp_arr + 1;
	if ($support_hash{$cid}) {
		$num_supporters--; # go live immediately if I am the only supporter.
	}

	my $now_time = time;
	my $go_live_time;
	my $do_notify = 0;
	if ($num_supporters > 0) {
		$go_live_time = $now_time + (60 * 60 * 24 * 7); # add 7 days.
		$do_notify = 1;
	} else {
		$go_live_time = $now_time;
	}
	$self->{go_live_time} = $go_live_time;

	my $submitter = $self->{submitter};

	my $selstmt = "insert into statement (record_id,     value, topic_num,  camp_num,  statement_size,          note, submit_time, submitter, go_live_time ) values " .
								       "($new_record_id, ?,     $topic_num, $camp_num, $self->{statement_size}, ?,    $now_time,  $submitter, $go_live_time)";

	my %dummy = ();
 	if (! $dbh->do($selstmt, \%dummy, $self->{value}, $self->{note})) {
		return("<h2>System Error: failed to save statement.</h2>\n");
	}

	$self->submit_notify($dbh, $old_tree, \%support_hash, $do_notify);
	return('');
}


sub submit_notify {
    my statement $self         = $_[0];
	my           $dbh          = $_[1];
	my camp      $old_tree     = $_[2];
	my           $support_hash = $_[3];
	my           $do_notify    = $_[4];

	my $topic_num = $self->{topic_num};
	my $camp_num  = $self->{camp_num};

	my ($topic_name, $camp_name, $msg) = camp::get_names($dbh, $topic_num, $camp_num);

	my $cid;

	my $go_live_time_str = gmtime($self->{go_live_time}) . ' (GMT)';

	# just to be sure brent also get's this e-mail.
	$support_hash->{1} = 1;
	my $camp_name;
	my $subject;

	if ($old_tree) {
		$camp_name = $old_tree->{camp_name};
		$subject = "Change submitted to the statement for the '$camp_name' camp on the topic '$topic_name'";
	} else {
		$camp_name = $self->{camp_name};
		$subject = "Creating new statement for the '$camp_name' camp on the topic '$topic_name'";
	}

	my $message = <<EOF;

\$name <\$email>,

A proposed change has been submitted to the Canonizer for
the statement of the camp: '$camp_name' on the topic: '$topic_name'
which you directly support.

This note was given for this change: $self->{note}

This not yet live change can be previewed here: (Note: this link will
set your as_of mode to include review.)
http://canonizer.com/topic.asp/$self->{topic_num}/$camp_num?as_of_mode=review

As a supporter, if you disagree with anything about this change, you
can object to it on the "manage" statement page which will prevent it
from going live.  If no supporters object to this change before
$go_live_time_str it will go live at that time.

You are receiving this e-mail because you are a direct supporter of
this statement.  If you prefer not to receive future e-mails about
this you can delegate your support to another trusted person in your
camp, or remove your support entirely on the statement page you are
supporting here:

\$supported_url

Thank You,

The Canonizer

EOF

	if ($do_notify) {
		person::send_email_to_hash($dbh, $support_hash, $subject, $message, $topic_num);
	} else { # just to brent
		$message =~ s|\$supported_url|http://canonizer.com/topic.asp?topic_num=$topic_num\&camp_num=$camp_num|gi;
		$message .= "\n\n\nNo email was sent.\n";
		person::send_email_to_cid($dbh, 1, $subject, $message);
	}
}


1;

