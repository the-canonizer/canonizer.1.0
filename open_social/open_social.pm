package open_social;

use lib '/usr/local/webtools';

use Exporter;
our (@EXPORT, @ISA);

@ISA = qw(Exporter);
@EXPORT = qw(os_values_compare os_friend_finder);

use JSON;
use DBI;
use MIME::Base64;
use func;
use support;
use statement;


sub os_values_compare {
	my $oauth_consumer_key       = $_[0];
	my $open_social_ownerid      = $_[1];
	my $open_social_friend_array = $_[2];

	my $dbh = func::dbh_connect(1) || die "unable to connect to database";

	my @friend_array = @{from_json($open_social_friend_array)};

	my ($cid, $nick_id_to_os_id, $compare_hash) = lookup_canonizer_data($dbh, $oauth_consumer_key, $open_social_ownerid, \@friend_array);

	compare_friends($dbh, $cid, $nick_id_to_os_id, $compare_hash);

	my @compare_array = ();

	for ($idx = 0; $idx <= $#friend_array; $idx++) {
		for my $comparison (keys %{$compare_hash}) {
			if ($comparison eq $friend_array[$idx]) {
				$compare_array[$idx] = $compare_hash->{$comparison};
			}
		}
	}

	return(to_json(\@compare_array));
	# return(to_json($compare_hash));
}


sub os_friend_finder {
	my $oauth_consumer_key       = $_[0];
	my $open_social_ownerid      = $_[1];

	return("not yet implemented");
}


sub lookup_canonizer_data {
	my $dbh                 = $_[0];
	my $oauth_consumer_key  = $_[1];
	my $open_social_ownerid = $_[2];
	my $friend_array        = $_[3];

	my %compare_hash = ();
	my %nick_id_to_os_id = ();

	my $selstmt = 'select os_user_id_token, cid from open_social_link where os_container_id=?';
	my @args = ($oauth_consumer_key);

	if ($friend_array) {
		push(@args, $open_social_ownerid);
		$selstmt .= ' and (os_user_id_token = ?';
		foreach my $token (@{$friend_array}) {
			$selstmt .= " or os_user_id_token = ?";
			push(@args, $token);
		}
		$selstmt .= ')';
	}

	my $cid = 0;

	my $sth = $dbh->prepare($selstmt) || die "Error: failed to prepare: $selstmt.\n";
	$sth->execute(@args) || die "Error: failed to execute: $selstmt.\n";
	my $rs;
	while ($rs = $sth->fetch()) {
		my $this_open_social_ownerid = $rs->[0];
		my $this_cid = $rs->[1];

		if ($this_open_social_ownerid eq $open_social_ownerid) {
			$cid = $this_cid;
		} else {
			my %friend_nick_names = func::get_nick_name_hash($this_cid, $dbh);
			foreach my $nick_name_id (keys %friend_nick_names) {
				if ($friend_nick_names{$nick_name_id}->{'private'}) {
					next;
				}
				if (!exists($compare_hash{$this_open_social_ownerid})) {
					$compare_hash{$this_open_social_ownerid} = {'cid'       => $this_cid,
																'linked'    => 1,
																'same'      => [],
																'different' => [] };
				};
				$nick_id_to_os_id{$nick_name_id} = $this_open_social_ownerid;
			}
		}
	}

	if (! $cid) {
		return("Error: unknown user id (\"$open_social_ownerid\")");
	}

	return($cid, \%nick_id_to_os_id, \%compare_hash);
}



sub compare_friends {
	my $dbh              = $_[0];
	my $cid              = $_[1];
	my $nick_id_to_os_id = $_[2];
	my $compare_hash     = $_[3];

	my %owner_nick_names = func::get_nick_name_hash($cid, $dbh);
	my $nick_name_clause = func::get_nick_name_clause(\%owner_nick_names, 1); # 1 - public only

	if (!(length($nick_name_clause) > 0)) {
	    return("Error: User must have at least one non private nick name.\n");
	}

	my %topic_trees = ();

	$selstmt = 'select distinct(topic_num), nick_name_id from support where ' . $nick_name_clause;

	$sth = $dbh->prepare($selstmt) || die "Error: failed to prepare: $selstmt.\n";
	$sth->execute() || die "Error: failed to execute: $selstmt.\n";
	my $rs;
	while ($rs = $sth->fetch()) {
		my $topic_num = $rs->[0];
		my $nick_name_id = $rs->[1];
		my statement $statement = new_tree statement ($dbh, $topic_num, 1);
		my @support_array = @{$statement->{support_hash}->{$nick_name_id}};
		my support $support = $support_array[0];
		if ($support->{delegate_nick_name_id}) { # replace with delegated array
			$nick_name_id = $support->{support_order}; # support array's nick name
			@support_array = @{$statement->{support_hash}->{$nick_name_id}};
		}

		foreach my $friend_nick_name_id (keys %{$nick_id_to_os_id}) {

			if (! exists($statement->{support_hash}->{$friend_nick_name_id})) { # doesn't support this topic.
				next;
			}

			my @friend_support_array = @{$statement->{support_hash}->{$friend_nick_name_id}};
			my support $friend_support = $friend_support_array[0];
			if ($friend_support) { # friend supports this topic.
				my $delegated_nick = $friend_nick_name_id;

				if ($friend_support->{delegate_nick_name_id}) { # replace with delegated array
					$delegated_nick = $support->{support_order}; # support array's nick name
					@friend_support_array = @{$statement->{support_hash}->{$delegated_nick}};
				}
				# $ret_val = "friend_id: $delegated_nick, statement: 
				my $friend_os_id = $nick_id_to_os_id->{$friend_nick_name_id};

				if ($nick_name_id == $delegated_nick) { # delegated to same nick name.
					push(@{$compare_hash->{$friend_os_id}->{'same'}}, make_same_struct($statement, $nick_name_id));
				} else {
					my ($same, $matching_camps) = compare_camps($statement, \@support_array, \@friend_support_array);
					my $struct = {'topic'     => $statement->{title},
								  'topic_num' => $statement->{topic_num} };
					if ($same) {
						$struct->{'camps'} = $matching_camps;
						push(@{$compare_hash->{$friend_os_id}->{'same'}}, $struct);
					} else {
						$struct->{'my_camps'}     = make_camp_array($statement, \@support_array);
						$struct->{'friend_camps'} = make_camp_array($statement, \@friend_support_array);
						push(@{$compare_hash->{$friend_os_id}->{'different'}}, $struct);
					}
				}
			}
		}
	}
}


sub compare_camps {
	my statement $statement = $_[0];
	my @my_array          = @{$_[1]};
	my @friend_array      = @{$_[2]};

	my @matching_camps = ();

	for (my $idx = 0; $idx <= $#my_array; $idx++) {
		if ($idx > $#friend_array) { # don't compare additional camps.
			return(1, \@matching_camps);
		}
		my $matching_num = $my_array[$idx]->{'statement_num'};

		my statement $my_statement = $statement->{statement_tree_hash}->{$matching_num};

		if (! $my_statement->is_related($friend_array[$idx]->{'statement_num'})) {
			return(0, 0);
		}
		push(@matching_camps, {'title' => $statement->{statement_tree_hash}->{$matching_num}->{title},
							   'statement_num' => $matching_num                                       });
	}
	return(1, \@matching_camps);
}


sub make_same_struct {
	my statement $statement = $_[0];
	my $nick_name_id        = $_[1]; # can't be delegated, must be delegate

	my $same_struct = {
		'topic'     => $statement->{title},
		'topic_num' => $statement->{topic_num},
		'camps'     => make_camp_array($statement, $statement->{support_hash}->{$nick_name_id}) };

	return($same_struct);
}


sub make_camp_array {
	my statement $statement = $_[0];
	my $support_array_ref   = $_[1];

	my @camps = ();
	foreach my support $support (@{$support_array_ref}) {
		my $statement_num = $support->{statement_num};
		my statement $supported_statement = $statement->{statement_tree_hash}->{$statement_num};
		push(@camps, {'title'         => $supported_statement->{title},
					  'statement_num' => $statement_num                 });
	}
	return(\@camps);
}


1;

