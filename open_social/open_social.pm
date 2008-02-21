package open_social;

use lib '/usr/local/webtools';

use Exporter;
our (@EXPORT, @ISA);

@ISA = qw(Exporter);
@EXPORT = qw(os_values_compare);

use JSON;
use DBI;
use MIME::Base64;
use func;
use support;

sub os_values_compare {
	my $oauth_consumer_key       = $_[0];
	my $open_social_ownerid      = $_[1];
	my $open_social_friend_array = $_[2];

	my $dbh = func::dbh_connect(1) || die "unable to connect to database";

	my $selstmt = 'select os_user_id_token, cid from open_social_link where os_container_id=? and os_user_id_token=?';
	my @args = ($oauth_consumer_key, $open_social_ownerid);

	$open_social_firend_array = '[]';

	my $friend_array = from_json($open_social_friend_array);

	foreach my $token (@{$friend_array}) {
		$selstmt .= " or os_user_id_token=?";
		push(@args, $token);
	}

	my %link_map = ();

	my $sth = $dbh->prepare($selstmt) || die "Error: failed to prepare: $selstmt.\n";
	$sth->execute(@args) || die "Error: failed to execute: $selstmt.\n";
	my $rs;
	while ($rs = $sth->fetch()) {
		$link_map{$rs->[0]} = $rs->[1];
	}

	my $cid = $link_map{$open_social_ownerid};

	if (! $cid) {
		return("Error: unknown user id (\"$open_social_ownerid\")");
	}

	my %owner_nick_names = func::get_nick_name_hash($cid, $dbh);
	my $my_support_struct = {};

	foreach my $nick_name_id (keys %owner_nick_names) {
		if (! $owner_nick_names{$nick_name_id}->{'private'}) {
			support::get_supported_statements($dbh, $nick_name_id, 'default', '', $my_support_struct);
		}
	}

	my $idx;
	my @support_array = ();
	my @friend_array = @{$friend_array};
	for ($idx = 0; $idx <= $#friend_array; $idx++) {
		my $friend_cid = $link_map{$friend_array[$idx]};
		if ($friend_cid) {
			my %friend_nick_names = func::get_nick_name_hash($friend_cid, $dbh);
			$support_array[$idx] = {};

			foreach my $nick_name_id (keys %friend_nick_names) {
				if (! $owner_nick_names{$nick_name_id}->{'private'}) {
					support::get_supported_statements($dbh, $nick_name_id, 'default', '', $support_array[$idx]);
				}
			}
		}
	}

	my @compare_array = ();
	for ($idx = 0; $idx <= $#friend_array; $idx++) {
		my $friend_cid = $link_map{$friend_array[$idx]};

		if ($friend_cid) { # otherwise user is not linked up, no entry in open_social_link table.
			my $friend_support_struct = $support_array[$idx];
			$compare_array[$idx]->{'cid'} = $friend_cid;
			$compare_array[$idx]->{'linked'} = 1;
			my @null = ();
			$compare_array[$idx]->{'same'} = \@null;
			my @null = (); # you get the same array without a my everywhere;
			$compare_array[$idx]->{'different'} = \@null;
			foreach my $topic_num (keys %{$my_support_struct}) {
				if (exists($support_array[$idx]->{$topic_num})) {
					my ($same, $use_friend) = compare_camps($my_support_struct->{$topic_num}->{'array'}, $friend_support_struct->{$topic_num}->{'array'});
					if ($same) {
						my $short_array = $my_support_struct->{$topic_num}->{'array'};
						if ($use_friend) {
							$short_array = $friend_support_struct->{$topic_num}->{'array'};
						}
						my $same_hash =      {'topic'        => $my_support_struct    ->{$topic_num}->{'topic_title'},
										      'topic_num'    => $topic_num,
										      'camps'        => $short_array                                           };
						push(@{$compare_array[$idx]->{'same'}},  $same_hash);
					} else {
						my $different_hash = {'topic'        => $my_support_struct    ->{$topic_num}->{'topic_title'},
											  'topic_num'    => $topic_num,
											  'my_camps'     => $my_support_struct    ->{$topic_num}->{'array'},
											  'friend_camps' => $friend_support_struct->{$topic_num}->{'array'} };
						push(@{$compare_array[$idx]->{'different'}}, $different_hash);
					}
				}
			}
		} else {
			$compare_array[$idx]->{'linked'} = 0;
		}
	}

	return(to_json(\@compare_array));
}


sub compare_camps {
	my @my_array     = @{$_[0]};
	my @friend_array = @{$_[1]};

	for (my $idx = 0; $idx <= $#my_array; $idx++) {
		if ($idx > $#friend_array) { # don't compare additional camps.
			return(1, 1);
		}
		if ($my_array[$idx]->{'statement_num'} != $friend_array[$idx]->{'statement_num'}) {
			return(0, 0);
		}
	}
	return(1, 0);
}

1;

