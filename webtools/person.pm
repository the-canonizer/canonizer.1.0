package person;

use strict;

use fields qw (cid first_name middle_name last_name email password address_1 address_2 city state postal_code country create_time join_time);

use func;


sub new_blank {
	my $caller = $_[0];

    my $class = ref($caller) || $caller;
    no strict "refs";
    my person $self = [ \%{"${class}::FIELDS"} ];
    bless $self, $class;

	return($self);
}


sub new_rs {
    my $caller = $_[0];
	my $rs     = $_[1];

	my person $self = new_blank person ();

    $self->{cid}         = $rs->{'cid'};
    $self->{first_name}  = $rs->{'first_name'};
    $self->{middle_name} = $rs->{'middle_name'};
    $self->{last_name}   = $rs->{'last_name'};
    $self->{email}       = $rs->{'email'};
    $self->{password}    = $rs->{'password'};
    $self->{address_1}   = $rs->{address_1};
    $self->{address_2}   = $rs->{address_2};
	$self->{city}        = $rs->{'city'};
	$self->{state}       = $rs->{'state'};
	$self->{postal_code} = $rs->{'postal_code'};
	$self->{country}     = $rs->{'country'};
	$self->{create_time} = $rs->{'create_time'};
	$self->{join_time}   = $rs->{'join_time'};

    return($self);
}


sub new_cid {
    my $caller = $_[0];
	my $dbh    = $_[1];
	my $cid    = $_[2];

	if (!$cid) {
		return('');
	}

	my $selstmt = "select * from person where cid = $cid";

	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	if ($rs = $sth->fetchrow_hashref()) {
		return(new_rs person ($rs));
	}

	return('');
}


sub send_email_to_cid {
	my $dbh     = $_[0];
	my $cid     = $_[1];
	my $subject = $_[2];
	my $message = $_[3];

	my person $person_rec = new_cid person ($dbh, $cid);

	if (!$person_rec) {
		print(STDERR "statement::submit_notify failed to get person rec for cid $cid.\n");
		return(0);
	}

	$message =~ s|\$\$|\$gliptidy_wadaly|gi;
	$message =~ s|\$name|$person_rec->{first_name}|gi;
	$message =~ s|\$email|$person_rec->{email}|gi;
	$message =~ s|\$first_name|$person_rec->{first_name}|gi;
	$message =~ s|\$middle_name|$person_rec->{middle_name}|gi;
	$message =~ s|\$last_name|$person_rec->{last_name}|gi;
	$message =~ s|\$address_1|$person_rec->{address_1}|gi;
	$message =~ s|\$address_2|$person_rec->{address_2}|gi;
	$message =~ s|\$city|$person_rec->{city}|gi;
	$message =~ s|\$state|$person_rec->{state}|gi;
	$message =~ s|\$gliptidy_wadaly|\$|gi;

	func::send_email($subject, $message, $person_rec->{email});

	return(1);
}


sub send_email_to_hash {
	my $dbh          = $_[0];
	my $support_hash = $_[1]; # key: cid, val: supported statement num
	my $subject      = $_[2];
	my $message      = $_[3];
	my $topic_num    = $_[4];

	my $cid;
	foreach $cid (keys %{$support_hash}) {

		my $sub_message = $message;
		if ($topic_num) {
			$sub_message =~ s|\$supported_url|http://canonizer.com/topic.asp/$topic_num/$support_hash->{$cid}|gi;
		}

		send_email_to_cid($dbh, $cid, $subject, $sub_message);
	}
	return(1);
}


1;

