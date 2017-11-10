package canonizers;

use managed_record;
use topic;

@canonizer_array = (

	{'name' => 'One Person One Vote', 'algorithm' => \&blind_popularity},
	{'name' => 'Mind Experts', 'algorithm' => \&mind_experts},
	{'name' => 'Computer Science Experts', 'algorithm' => \&computer_science_experts},
	{'name' => 'Ph.D.', 'algorithm' => \&PhD},
	{'name' => 'Christian', 'algorithm' => \&christian},
	{'name' => 'Secular / Non Religious', 'algorithm' => \&secular},
	{'name' => 'Mormon', 'algorithm' => \&mormon},
	{'name' => 'Universal Unitarian', 'algorithm' => \&uu},
	{'name' => 'Atheist', 'algorithm' => \&atheist},
	{'name' => 'Transhumanist', 'algorithm' => \&transhumanist}

    );

#  for expert one off canonizers.
#  All this needs to be refactored so not so much duplicate code!!
@special_canonizer_array = (

	{}, # start at 1 (converted from -1)
	{'name' => 'Special Mind Experts', 'algorithm' => \&special_mind_experts},
	{'name' => 'Special Computer Science Experts', 'algorithm' => \&special_computer_science_experts}

	);


sub blind_popularity {
    my $dbh        = $_[0];
    my $owner_code = $_[1];

    return(1);
}


sub mind_experts {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

	my camp $expert_camp = new_tree camp ($dbh, 81, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $nick_name_id);

	if (! $expert_camp) { # not an expert canonized nick.
		return(0);
	}

	# start with one person one vote canonize.
	# then finish up with doing it again with experts at this level.
	$expert_camp->canonize_branch($dbh, -1, $as_of_mode, $as_of_date); # only need to canonize this branch
									  # -1: special mind experts canonizer.

	return($expert_camp->{score});
}


sub special_mind_experts {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

	my camp $expert_camp = new_tree camp ($dbh, 81, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $nick_name_id);

	if (! $expert_camp) { # not an expert canonized nick.
		return(0);
	}

	# start with one person one vote canonize.
	$expert_camp->canonize_branch($dbh, 0, $as_of_mode, $as_of_date); # only need to canonize this branch
									  # 0: one person one vote canonizer

	my $score = 0;

	if ((!$expert_camp->{supporters}->{$nick_name_id}) ||          # don't support yourself or
		$#{$expert_camp->{support_hash}->{$nick_name_id}} > 0 ) {  # support more than just yourself
		# give a significant reward for supporting more than yourself.
		$score = $expert_camp->{score} * 5;
	} else {
		$score = $expert_camp->{score} * 1;
	}

 	return($score);
}


sub computer_science_experts {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

	my camp $expert_camp = new_tree camp ($dbh, 124, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $nick_name_id);

	if (! $expert_camp) { # not an expert canonized nick.
		return(0);
	}

	# start with one person one vote canonize.
	# then finish up with doing it again with experts at this level.
	$expert_camp->canonize_branch($dbh, -1, $as_of_mode, $as_of_date); # only need to canonize this branch
									  # -1: special mind experts canonizer.

	return($expert_camp->{score});
}


sub special_computer_science_experts {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

	my camp $expert_camp = new_tree camp ($dbh, 124, 1, $Session->{'as_of_mode'}, $Session->{'as_of_date'}, $nick_name_id);

	if (! $expert_camp) { # not an expert canonized nick.
		return(0);
	}

	# start with one person one vote canonize.
	$expert_camp->canonize_branch($dbh, 0, $as_of_mode, $as_of_date); # only need to canonize this branch
									  # 0: one person one vote canonizer

	my $score = 0;

	if ((!$expert_camp->{supporters}->{$nick_name_id}) ||          # don't support yourself or
		$#{$expert_camp->{support_hash}->{$nick_name_id}} > 0 ) {  # support more than just yourself
		# give a significant reward for supporting more than yourself.
		$score = $expert_camp->{score} * 5;
	} else {
		$score = $expert_camp->{score} * 1;
	}

 	return($score);
}


sub PhD {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

    my $val = camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
						   '(topic_num = 55 and camp_num =  5) or ' .
						   '(topic_num = 55 and camp_num = 10) or ' .
						   '(topic_num = 55 and camp_num = 11) or ' .
						   '(topic_num = 55 and camp_num = 12) or ' .
						   '(topic_num = 55 and camp_num = 14) or ' .
						   '(topic_num = 55 and camp_num = 15) or ' .
						   '(topic_num = 55 and camp_num = 17)'            );
}


sub christian {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

    my $val = camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
			     '(topic_num = 54 and camp_num = 4) or ' .
			     '(topic_num = 54 and camp_num = 5) or ' .
			     '(topic_num = 54 and camp_num = 6) or ' .
			     '(topic_num = 54 and camp_num = 7) or ' .
			     '(topic_num = 54 and camp_num = 8) or ' .
			     '(topic_num = 54 and camp_num = 9) or ' .
			     '(topic_num = 54 and camp_num = 10) or ' .
			     '(topic_num = 54 and camp_num = 11) or ' .
			     '(topic_num = 54 and camp_num = 18)'       );
}


sub mormon {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

    my $val = camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
				'(topic_num = 54 and camp_num = 7) or ' .
				'(topic_num = 54 and camp_num = 8) or ' .
				'(topic_num = 54 and camp_num = 10) or ' .
				'(topic_num = 54 and camp_num = 11)'       );

    $val += 2 * camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
				  '(topic_num = 54 and camp_num = 9)'       ); # recommend holder
    return($val);
}


sub secular {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

    my $val = camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
				'(topic_num = 54 and camp_num = 3)'       );
    return($val);
}


sub atheist {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

    my $val = camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
				'(topic_num = 54 and camp_num = 2) or ' .
				'(topic_num = 2 and camp_num = 2) or ' .
				'(topic_num = 2 and camp_num = 4) or ' .
				'(topic_num = 2 and camp_num = 5)'       );
    return($val);
}


sub uu {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

    my $val = camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
				'(topic_num = 54 and camp_num = 15)'       );
    return($val);
}


sub transhumanist {
    my $dbh          = $_[0];
    my $nick_name_id = $_[1];
    my $as_of_mode   = $_[2];
    my $as_of_date   = $_[3];

    return(camp_counter($dbh, $nick_name_id, $as_of_mode, $as_of_date,
			     '(topic_num = 40 and camp_num = 2) or ' .
			     '(topic_num = 41 and camp_num = 2) or ' .
			     '(topic_num = 42 and camp_num = 2) or ' .
			     '(topic_num = 42 and camp_num = 4) or ' .
			     '(topic_num = 43 and camp_num = 2) or ' .
			     '(topic_num = 44 and camp_num = 3) or ' .
			     '(topic_num = 45 and camp_num = 2) or ' .
			     '(topic_num = 46 and camp_num = 2) or ' .
			     '(topic_num = 47 and camp_num = 2) or ' .
			     '(topic_num = 48 and camp_num = 2) or ' .
			     '(topic_num = 48 and camp_num = 3) or ' .
			     '(topic_num = 49 and camp_num = 2) '       ));
}


sub camp_counter {
    my $dbh           = $_[0];
    my $nick_name_id  = $_[1];
    my $as_of_mode    = $_[2];
    my $as_of_date    = $_[3];
    my $camp_str      = $_[4];

    my $as_of_time   = time;

    if ($as_of_mode eq 'as_of') {
	$as_of_time = &func::parse_as_of_date($as_of_date);
    }

#	Can't do this because it reveals how the anonymous nicks are related to open nicks.
#    my $selstmt = "select count(*) from support s, nick_name n where s.nick_name_id = n.nick_name_id and n.owner_code = '$owner_code' and (" .
#	$camp_str .
#	") and ((s.start < $as_of_time) and ((s.end = 0) or (s.end > $as_of_time)))";

# Currently, if support is delegated, only the precice delegeted
# camp (usually the first) is tracked in the camp num of the
# delegated record.  This will work with the large majority of the
# cases, but we'll probably want to cover all cases some day.
# (and if the delegate's vote changes?  this will be a problem.)

# We've also got to find some way to include sub camp support.
# so we don't have to update this with every sub camp added.
# there has to be an easear way to do this on the db side?

    my $selstmt = "select count(*) from support where nick_name_id = $nick_name_id and (" .
	$camp_str .
	") and ((start < $as_of_time) and ((end = 0) or (end > $as_of_time)))";

    # print(STDERR "selstmt: $selstmt.\n");

    my $sth = $dbh->prepare($selstmt) or die "Failed to prepair $selstmt.\n";
    $sth->execute() or die "Failed to execute $selstmt.\n";
    my $rs;
    if ($rs = $sth->fetch()) {
	return($rs->[0]);
    }
    return(0);
}





1;

