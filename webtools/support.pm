package support;

use strict;

use fields qw (support_id nick_name owner_code nick_name_id topic_num camp_num delegate_nick_name_id start end flags support_order scores delegators);

# temporary fields:
#	scores		(array to support multiple scores on single 'virtual' delegate trees)
#		index:	support order		(see visio diagram Camp_Data_STructure.vsd)
#		value:	canonized score
#	delegators	(hash)
#		key:	nick_name_id
#       value:	support record

use canonizers;

# this block markes static or class methods.
{

sub get_supported_camps {
    my $dbh            = $_[0];
    my $nick_name_id   = $_[1];
    my $as_of_mode     = $_[2];
    my $as_of_date     = $_[3];
    my $support_struct = $_[4];

    my $as_of_time = time;
    my $as_of_clause = '';
    if ($as_of_mode eq 'review') {
		# no as_of_clause;
    } elsif ($as_of_mode eq 'as_of') {
		$as_of_time = func::parse_as_of_date($as_of_date);
		$as_of_clause = "and go_live_time < $as_of_time";
    } else {
		$as_of_clause = 'and go_live_time < ' . $as_of_time;
    }

    my $selstmt = <<EOF;
select u.topic_num, u.camp_num, u.title, p.support_order, p.delegate_nick_name_id from support p, 

(select s.title, s.topic_num, s.camp_num from statement s,
(select topic_num, camp_num, max(go_live_time) as max_glt from camp where objector is null $as_of_clause group by topic_num, camp_num) t
where s.topic_num = t.topic_num and s.camp_num=t.camp_num and s.go_live_time = t.max_glt) u

where u.topic_num = p.topic_num and ((u.camp_num = p.camp_num) or (u.camp_num = 1)) and p.nick_name_id = $nick_name_id and
(p.start < $as_of_time) and ((p.end = 0) or (p.end > $as_of_time))
EOF

    my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
    $sth->execute() or die "Failed to execute $selstmt.\n";
    my $delegate_hash  = {};
    my $rs;
    my $topic_num;
    while ($rs = $sth->fetchrow_hashref()) {
		$topic_num     = $rs->{'topic_num'};
		my $camp_num = $rs->{'camp_num'};

		if ($rs->{'delegate_nick_name_id'}) {
			$delegate_hash->{$topic_num} = $rs->{'support_order'};
		} elsif ($camp_num == 1) {
			$support_struct->{$topic_num}->{'topic_title'} = $rs->{'title'};
			if (! $support_struct->{$topic_num}->{'array'}) {
				my @null = ();
				$support_struct->{$topic_num}->{'array'} = \@null;
			}
		} else {
			$support_struct->{$topic_num}->{'array'}->[$rs->{'support_order'}]->{'title'} = $rs->{'title'};
			$support_struct->{$topic_num}->{'array'}->[$rs->{'support_order'}]->{'camp_num'} = $camp_num;
		}
	}
	return($support_struct);
}

}

sub new_blank {
	my $caller = $_[0];

    my $class = ref($caller) || $caller;
    no strict "refs";
    my support $self = [ \%{"${class}::FIELDS"} ];
    bless $self, $class;

	return($self);
}


sub new_rs {
    my ($caller, $rs) = @_;

    my support $self = new_blank support ();

    $self->{support_id}            = $rs->{'support_id'};
    $self->{nick_name}             = $rs->{'nick_name'};
    $self->{owner_code}            = $rs->{'owner_code'};
    $self->{nick_name_id}          = $rs->{'nick_name_id'};
    $self->{topic_num}             = $rs->{'topic_num'};
    $self->{camp_num}              = $rs->{'camp_num'};
    $self->{delegate_nick_name_id} = $rs->{'delegate_nick_name_id'};
    $self->{support_order}         = $rs->{'support_order'};
    $self->{start}                 = $rs->{'start'};
    $self->{end}                   = $rs->{'end'};

    return($self);
}


sub display_support_tree {
	my support $self  = $_[0];
	my $topic_num     = $_[1];
	my $camp_num      = $_[2];
	my $nick_names    = $_[3]; # nick names of the current cid.
	my $support_order = $_[4];
	my $no_deligation = $_[5];

	my $this_is_me = 0;

	# got to add some checking here.
    # I don't want to have a delegate option unless I can really support and delegate.

	my $order_clause = '';
	if ((! $self->{delegate_nick_name_id}) && $self->{support_order}) {
		$order_clause = '(' . ($self->{support_order} + 1) . ') ';
	}

	my $my_nick_name_id = $self->{'nick_name_id'};
	my $cur_host = func::get_host();
	my $delegate_clause = '';
	if (! $no_deligation) {
		if ($nick_names->{$my_nick_name_id}) {
			$delegate_clause = qq{
- <a onMouseover="document.button_img_$my_nick_name_id.src=eval('remove_cache_over_img.src')"
     onMouseout="document.button_img_$my_nick_name_id.src=eval('remove_cache_img.src')"
	 onClick="delete_me_check($self->{support_id})">

	 <img src="/images/Remove_Your_Support.png" name="button_img_$my_nick_name_id" width=120 height=10 alt="Remove Your Support" border=0>
	 </a>
};
			$no_deligation = 1;
			$this_is_me = 1;
		} else {
			$delegate_clause = qq{
- <a onMouseover="document.button_img_$my_nick_name_id.src=eval('delegate_cache_over_img.src')"
     onMouseout="document.button_img_$my_nick_name_id.src=eval('delegate_cache_img.src')"
	 href="https://$cur_host/secure/support.asp?topic_num=$topic_num&camp_num=$camp_num&delegate_id=$my_nick_name_id">

	 <img src="/images/Delegate_Your_Support.png" name="button_img_$my_nick_name_id" width=130 height=10 alt="Delegate Your Support" border=0>
	 </a>
};
		}
	}

	my $delegate_str = '';

	my support $delegate_support;
	foreach $delegate_support (sort {(($a->{scores}->[$support_order] <=> $b->{scores}->[$support_order]) * -1)} values %{$self->{delegators}}) {
		$delegate_str .= $delegate_support->display_support_tree($topic_num, $camp_num, $nick_names, $support_order, $no_deligation);
		if ($nick_names->{$delegate_support->{'nick_name_id'}}) { # no delegate option if already deligated.
			$delegate_clause = '';
		}
	}

	my $ret_val = '<div><span id="score">' . func::c_num_format($self->{scores}->[$support_order]) . '</span> <span id="name">' . $self->make_linked_nick_str() . '</span> ' . $order_clause . $delegate_clause . "</div>\n";

	my $this_is_a_delegate = 0;
	if ($delegate_str) {
		$ret_val .= "<div class='branch'>\n" . $delegate_str . "\t</div>\n";
		$this_is_a_delegate = 1;
	}

	if ($this_is_me) {
		$ret_val .= qq{
			<script  type="text/javascript"> <!--
				var I_am_a_delegate = $this_is_a_delegate;
			// --></script>
		};
	}

	return($ret_val);
}


sub canonize_support_tree {
	my support $self    = $_[0];
	my $multi_supporter = $_[1];
	my $support_order   = $_[2];
	my $canonizer       = $_[3];
	my $as_of_mode      = $_[4];
	my $as_of_date      = $_[5];
	my $dbh             = $_[6];

	my support $delegated_support;

	my $score = 0;

	foreach $delegated_support (values %{$self->{delegators}}) {
		$score += $delegated_support->canonize_support_tree($multi_supporter, $support_order, $canonizer, $as_of_mode, $as_of_date, $dbh);
	}

	$score += $self->canonize($multi_supporter, $support_order, $canonizer, $as_of_mode, $as_of_date, $dbh);

	$self->{scores}->[$support_order] = $score;

	return($score);
}


sub canonize {
	my support $self    = $_[0];
	my $multi_supporter = $_[1];
	my $support_order   = $_[2];
	my $canonizer       = $_[3];
	my $as_of_mode      = $_[4];
	my $as_of_date      = $_[5];
	my $dbh             = $_[6];

	my $algorithm;

	if (($canonizer >= 0) && ($canonizer <= $#canonizers::canonizer_array)) {
		$algorithm = $canonizers::canonizer_array[$canonizer]->{'algorithm'};
	} elsif (((- $canonizer) > 0) && ((- $canonizer) <= $#canonizers::special_canonizer_array)) {
		$algorithm = $canonizers::special_canonizer_array[- $canonizer]->{'algorithm'};
	} else {
		$algorithm = $canonizers::canonizer_array[0]->{'algorithm'};
	}

	my $value = &$algorithm($dbh, $self->{nick_name_id}, $as_of_mode, $as_of_date);

	if ($multi_supporter) {
		return($value / (2 ** ($support_order + 1)));
	} else {
		return($value);
	}
}


# this really only gets all delegator support.
sub get_support {
    my support $self = $_[0];
    my          $dbh = $_[1];
    my $support_hash = $_[2];

    # get support for this camp;
    my support $supporter;
    foreach $supporter (values (%{$self->{delegators}})) {
		my $cid = $supporter->get_cid($dbh);
		$support_hash->{$cid} = $supporter->{camp_num};
		$supporter->get_support($dbh, $support_hash);
    }
}


sub get_cid {
    my support $self = $_[0];
    my         $dbh  = $_[1];

    my $selstmt = 'select owner_code from nick_name where nick_name_id = ' . $self->{nick_name_id};

    my $owner_code;
    my $sth = $dbh->prepare($selstmt) or die "Failed to prepair $selstmt.\n";
    $sth->execute() or die "Failed to execute $selstmt.\n";
    my $rs;
    if ($rs = $sth->fetch()) {
		$owner_code = $rs->[0];
		return(func::canon_decode($owner_code));
    }
    return(0);
}

sub make_linked_nick_str {
	my support $self = $_[0];

	return('<a href="http://' . func::get_host() . '/support_list.asp?nick_name_id=' . $self->{nick_name_id} . '">' . $self->{nick_name} . '</a>');
}


1;

