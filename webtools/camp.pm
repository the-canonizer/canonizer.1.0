package camp;

use strict;

use base   qw( managed_record );
use fields qw( topic_name camp_name title key_words url nick_name_id topic_num camp_num parent_camp_num parent children score camp_tree_hash support_hash supporters);

# topic_name is not used in a camp record, it is a value of a topic record. I should remove this some day?

#temp fields:
#	parent:					pointer to parent record
#	children:				array of child records
#	score:					currently canonized score
#	camp_tree_hash:			everyone points to THE camp_tree_hash
#   support_hash:			for which 1 is the root agreement.  All topic support tree records are in the support_hash.
#	supporters:				supporters key: nick_name_id value: support record

use support;
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
		$args{'error_message'} .= "Must have a valid topic_num to manage a camp.<br>\n";
	}

	if ($Request->Form('camp_num')) {
		$args{'camp_num'} = int($Request->Form('camp_num'));
	} elsif ($pi_camp_num) {
		$args{'camp_num'} = $pi_camp_num;
	} elsif ($Request->QueryString('camp_num')) {
		$args{'camp_num'} = int($Request->QueryString('camp_num'));
	} else {
		$args{'error_message'} .= "Must have a valid camp_num to manage a camp.<br>\n";
	}

	return(\%args);
}


sub get_record_info {
	my $dbh  = $_[0];
	my $args = $_[1];

    my $topic_num = $args->{'topic_num'};
	my $camp_num  = $args->{'camp_num'};
	my $text_size = $args->{'text_size'};

	my $error_message = '';
	my $selstmt;
	my $manage_ident = 'Unknown';

    if (! $topic_num) {
		$error_message .= "Error: invalid topic_num.\n";
	}

    if (! $camp_num) {
		$error_message .= "Error: invalid camp_num.\n";
	}

	if (! $text_size) {
		$text_size = 0;
	}

	if (! $error_message) {
		$manage_ident = get_manage_ident($dbh, $topic_num, $camp_num);
		if ($manage_ident =~ m|error|i) {
			$error_message = $manage_ident;
			$manage_ident = 'Unknown';
		} else {
			$selstmt = "select topic_num, camp_num, camp_name, title, key_words, url, nick_name_id, parent_camp_num, record_id, note, submit_time, submit_time, submitter, go_live_time, objector, object_time, object_reason from camp where topic_num=$topic_num and camp_num=$camp_num order by go_live_time";
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
		$manage_ident = "camp: $camp_name on topic: $topic_name";
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
		$edit_ident = $error_message;
	} else {
		$edit_ident = "Propose modification to camp: $camp_name on topic: $topic_name";
	}

	return($edit_ident);
}


sub get_names {
	my $dbh       = $_[0];
	my $topic_num = $_[1];
	my $camp_num  = $_[2];

	my $topic_name     = 'Unknown';
	my $camp_name      = 'Unknown';
	my $error_message  = '';

	my $now_time = time();

	my $selstmt = "Select t.topic_name, s.camp_name from (select topic_name from topic where topic_num = $topic_num and objector is null and go_live_time in (select max(go_live_time) from topic where topic_num = $topic_num and objector is null and go_live_time < $now_time)) t, (select camp_name from camp where topic_num = $topic_num and camp_num = $camp_num and objector is null and go_live_time in (select max(go_live_time) from camp where topic_num = $topic_num and camp_num = $camp_num and objector is null and go_live_time < $now_time)) s";

	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	if ($rs = $sth->fetch()) {
		$topic_name = $rs->[0];
		$camp_name  = $rs->[1];
	} else {
		$error_message = "Error: can't find topic name and camp name.\n";
	}

	return($topic_name, $camp_name, $error_message);
}


sub new_blank {
	my $caller = $_[0];

    my $class = ref($caller) || $caller;
    no strict "refs";
    my camp $self = [ \%{"${class}::FIELDS"} ];
    bless $self, $class;

	return($self);
}


# may want to add an as_of ability (and change it to new as_of?) some day if we ever need that.
sub new_top {
    my $caller    = $_[0];
    my $dbh       = $_[1];
    my $topic_num = $_[2];
    my $camp_num  = $_[3];

    my camp $self;

    my $selstmt = "select * from camp where topic_num = $topic_num and camp_num = $camp_num and objector is null and go_live_time in (select max(go_live_time) from camp where topic_num = $topic_num and camp_num = $camp_num and objector is null)";

    my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
    $sth->execute() or die "Failed to execute $selstmt.\n";
    my $rs;
    if ($rs = $sth->fetchrow_hashref()) {
	$self = new_rs camp ($rs);
    }

    return($self);
}


sub new_rs {
    my ($caller, $rs) = @_;

    my camp $self = new_blank camp ();

    $self->{topic_num} = $rs->{'topic_num'};
    $self->{parent_camp_num} = $rs->{'parent_camp_num'};
    $self->{camp_name} = $rs->{'camp_name'};
    $self->{title} = $rs->{'title'};
    $self->{key_words} = $rs->{'key_words'};
    $self->{url} = $rs->{'url'};
    $self->{nick_name_id} = $rs->{'nick_name_id'};
	if (! $self->{nick_name_id}) {
		$self->{nick_name_id} = ''; # we never want '0'
	}
    $self->{record_id} = $rs->{'record_id'};
    $self->{camp_num} = $rs->{'camp_num'};
    $self->{note} = $rs->{'note'};
    $self->{submit_time} = $rs->{'submit_time'};
    $self->{submitter} = $rs->{'submitter'};
    $self->{go_live_time} = $rs->{'go_live_time'};
    $self->{objector} = $rs->{'objector'};
    $self->{object_time} = $rs->{'object_time'};
    $self->{object_reason} = $rs->{'object_reason'};

    return($self);
}


sub new_record_id {
	my $caller    = $_[0];
	my $dbh       = $_[1];
	my $record_id = $_[2];

	my $selstmt = "select topic_num, camp_num, parent_camp_num, camp_name, title, key_words, url, nick_name_id, record_id, note, submit_time, submit_time, submitter, go_live_time, objector, object_time, object_Reason from camp where record_id = $record_id";
	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";

	$sth->execute() || die "Failed to execute $selstmt";

	my $rs = $sth->fetchrow_hashref();
	$sth->finish();

	if ($rs) {
		return(new_rs camp ($rs));
	} else {
		my camp $self = new_blank camp ();
		$self->{error_message} = "No camp record with record_id: $record_id.<br>\n";
		return($self);
	}
}


sub new_form {
	my $caller  = $_[0];
	my $Request = $_[1];

	my camp $self = new_blank camp ();
	my $error_message = '';

	$self->{title} = $Request->Form('title');
	if (length($self->{title}) < 1) {
		$error_message .= "<h2>A Title is required.</h2>\n";
	}

	if (length($Request->Form('key_words')) > 0) {
		$self->{key_words} = $Request->Form('key_words');
	} else {
		$self->{key_words} = '';
	}

	if (length($Request->Form('canon_url')) > 0) {
		$self->{url} = $Request->Form('canon_url');
	} else {
		$self->{url} = '';
	}

	if (length($Request->Form('nick_name_id')) > 0) {
		my $nick_name_id = $self->{nick_name_id} = $Request->Form('nick_name_id');
		if (($nick_name_id =~ m|[^\d]|) || ($nick_name_id < 1)) {
			$error_message .= "<h2>Related Nick Name [$nick_name_id] must be a posotive integer</h2>\n";
		}
	} else {
		$self->{nick_name_id} = '';
	}

	$self->{note} = $Request->Form('note');
	if (length($self->{note}) < 1) {
		$error_message .= "<h2>A Note is required.</h2>\n";
	}

	$self->{submitter} = int($Request->Form('submitter'));
	# should validate submitter nick name here!!!!

	$self->{topic_num} = int($Request->Form('topic_num'));
	$self->{parent_camp_num} = int($Request->Form('parent_camp_num'));
	$self->{proposed} = int($Request->Form('proposed'));

	if ($self->{proposed}) {
		if ($Request->Form('camp_num')) {
			$self->{camp_num} = $Request->Form('camp_num');
		} else {
			$self->{camp_num} = 1; # agreemement camp
		}
	} else { # creating an entire new topic_num to be created on insert
		$self->{camp_num} = 0;
	}

	if ($self->{camp_num} == 1) {
		$self->{camp_name} = 'Agreement';
	} else {
		$self->{camp_name} = $Request->Form('camp_name');
	}

	if (length($self->{camp_name}) < 1) {
		$error_message .= "<h2>A Camp Name is required.</h2>\n";
	}

	$self->{error_message} = $error_message;

	return $self;
}


sub display_support_tree {
	my camp $self  = $_[0];
	my $topic_num  = $_[1];
	my $camp_num   = $_[2];
	my $nick_names = $_[3]; # nick names of the current cid.

	my $cur_host = func::get_host();

	my $ret_val = qq{
		<script  type="text/javascript"> <!--
			var remove_cache_img        = new Image ();
			var remove_cache_over_img   = new Image ();

			var delegate_cache_img      = new Image ();
			var delegate_cache_over_img = new Image ();

			remove_cache_img.src        = '/images/Remove_Your_Support.png';
			remove_cache_over_img.src   = '/images/Remove_Your_Support_Over.png';

			delegate_cache_img.src      = '/images/Delegate_Your_Support.png';
			delegate_cache_over_img.src = '/images/Delegate_Your_Support_Over.png';

			//to do: implement and utilize this as  a popup or something
			function delete_me_check(support_id) {

				alert("This function has not been implemented yet.\\nUse the modify support link instead.");
				return(false);

				var url = "https://$cur_host/secure/support.asp?topic_num=$topic_num&camp_num=$camp_num&delete_id=" + support_id;
				if (I_am_a_delegate) {
					alert('Do you want to remove your delegated supporters?');
				}
				alert('url: ' + url);
			}

		// --></script>
	};

	my support $current_support;
	foreach $current_support (sort {(($a->{scores}->[$a->{support_order}] <=> $b->{scores}->[$b->{support_order}]) * -1)} values %{$self->{supporters}}) {
		$ret_val .= $current_support->display_support_tree($topic_num, $camp_num, $nick_names, $current_support->{support_order});
	}

	if ($ret_val) {
		$ret_val = "<div class='support_tree'>\n" . $ret_val . "\t</div>\n";
	} else {
		$ret_val = "<p>No direct support for this camp at this time.</p>\n";
	}

	return($ret_val);
}


sub display_camp_tree {
	my camp $self      = $_[0];
	my $topic_name     = $_[1];
	my $topic_num      = $_[2];
	my $no_active_link = $_[3];
	my $topic_script   = $_[4]; # something like '/topic.asp/' or '/embedded_topic.asp/'
	my $popup_script   = $_[5];
	my $filter         = $_[6];

	if (! $topic_script) {
	    $topic_script = '/topic.asp/';
	}

	my $ret_val = '';

	if ($popup_script) {
	    $ret_val = <<EOF;
<SCRIPT LANGUAGE="JavaScript">

var new_page_blue = new Image();
new_page_blue.src = "/images/new_page_blue.png";
var new_page_red = new Image();
new_page_red.src = "/images/new_page_red.png";

function mouse_on(imgName) {
    document.images[imgName].src = new_page_red.src;
}

function mouse_off(imgName) {
    document.images[imgName].src = new_page_blue.src;
}

</SCRIPT> 
EOF

	}

	my camp $root = $self->{camp_tree_hash}->{1};

	my camp $active = undef;
	if ($no_active_link) {
		$active = $self;
	}

	$ret_val .= "<div>\n";
	my $score = func::c_num_format($self->{camp_tree_hash}->{1}->{score}); # get root score.
	my $camp_id = $self->{topic_num} . '/1';

	if ($no_active_link && $self == $root) {
		$ret_val .= '<div class="top_branch"><span id="score">' . $score . '</span> <span id="camp">' . $self->{camp_tree_hash}->{1}->{title} . "</span>";
		if ($popup_script) {
		    $ret_val .=
			'&nbsp;<a TARGET="_blank" ' .
			"onMouseOver=\"mouse_on('$camp_id')\" " .
			"onMouseOut=\"mouse_off('$camp_id')\" " .
			'href = "http://' . func::get_host() . $popup_script . $camp_id . '">' .
			'<img name="' . $camp_id . '" border=0 src=/images/new_page_blue.png></a></div>' . "\n";
		} else {
		    $ret_val .= "</div>\n";
		}

		if ($active) {
		    my $new_url = 'https://' . func::get_host() . '/secure/edit.asp?class=camp&topic_num=' . $self->{topic_num} . '&parent_camp_num=' . $self->{camp_num};
		    my $target_str = '';
		    if ($popup_script) {
			$target_str = 'TARGET="_blank"';
		    }

		    $ret_val .= <<EOF;
<div class='new_camp'>
	<div><a $target_str href="$new_url">&lt;Start new supporting camp here&gt;</a></div>
</div>
EOF

		}

	} else {
		my $camp_str = '';
		if ($popup_script) {
		    $camp_str = '/1'; # don't want the help statement.
		}
		$ret_val .= '<div class="top_branch"><span id="score">' . $score . '</span> <a href="http://' . func::get_host() . $topic_script . $topic_num . $camp_str . '">' . $self->{camp_tree_hash}->{1}->{title} . "</a>";
		if ($popup_script) {
		    $ret_val .=
			'&nbsp;<a TARGET="_blank" ' .
			"onMouseOver=\"mouse_on('$camp_id')\" " .
			"onMouseOut=\"mouse_off('$camp_id')\" " .
			'href = "http://' . func::get_host() . $popup_script . $camp_id . '">' .
			'<img name="' . $camp_id . '" border=0 src=/images/new_page_blue.png></a></div>' . "\n";
		} else {
		    $ret_val .= "</div>\n";
		}
	}

	$ret_val .= $root->display_camp_branches($active, '', $topic_script, $popup_script, $filter);

	$ret_val .= "</div>\n\n";

	return($ret_val);
}


# we want scores to descend, else alphabetical or numerical if possible on the name
sub camp_sort {
	my camp $a = $_[0];
	my camp $b = $_[1];

	if (($a->{score} <=> $b->{score}) == 0) {
		if (int($a->{camp_name}) && int($b->{camp_name})) {
			return ($a->{camp_name} <=> $b->{camp_name});
		} else {
			return (lc($a->{camp_name}) cmp lc($b->{camp_name}));
		}
	} else {
		return($b->{score} <=> $a->{score});
	}
}


sub display_camp_branches {
    my camp $self    = $_[0];
    my camp $active  = $_[1]; # pointer to current active or displayed camp.
    my $indent       = $_[2];
    my $topic_script = $_[3]; # something like '/topic.asp/' or '/embedded_topic.asp/'
    my $popup_script = $_[4];
	my $filter       = $_[5];

    if (!$indent) {
		$indent = '';
    }

    my $ret_val = '';

    if ($self->{children}) {
	$ret_val .= "<div class='branch'>";
	my camp $child;
	foreach $child (sort {&camp_sort($a, $b)} @{$self->{children}}) {
		if (($child->{score} < $filter) && ($active != $child)) { next; }; # must display active child.

	    my $score = func::c_num_format($child->{score});
	    my $camp_id = $child->{topic_num} . '/' . $child->{camp_num};
	    if ($active == $child) {
			$ret_val .= '<div><span id="score">' . $score . '</span> <span id="camp">' . $child->{title} . "</span>";
			if ($popup_script) {
				$ret_val .=
					'&nbsp;<a TARGET="_blank" ' .
					"onMouseOver=\"mouse_on('$camp_id')\" " .
					"onMouseOut=\"mouse_off('$camp_id')\" " .
					'href = "http://' . func::get_host() . $popup_script . $camp_id . '">' .
					'<img name="' . $camp_id . '" border=0 src=/images/new_page_blue.png></a></div>' . "\n";
			} else {
				$ret_val .= "</div>\n";
			}

			if ($active) {
				my $new_url = 'https://' . func::get_host() . '/secure/edit.asp?class=camp&topic_num=' . $child->{topic_num} . '&parent_camp_num=' . $child->{camp_num};
				my $target_str = '';
				if ($popup_script) {
					$target_str = 'TARGET="_blank"';
				}

				$ret_val .= <<EOF;
<div class='new_camp'>
	<div><a $target_str href="$new_url">&lt;Start new supporting camp here&gt;</a></div>
</div>
EOF

			}

	    } else {
			$ret_val .= '<div><span id="score">' . $score . '</span> <a href = "http://' . func::get_host() . $topic_script . $camp_id . '">' . $child->{title} . "</a>";
			if ($popup_script) {
				$ret_val .=
					'&nbsp;<a TARGET="_blank" ' .
					"onMouseOver=\"mouse_on('$camp_id')\" " .
					"onMouseOut=\"mouse_off('$camp_id')\" " .
					'href = "http://' . func::get_host() . $popup_script . $camp_id . '">' .
					'<img name="' . $camp_id . '" border=0 src=/images/new_page_blue.png></a></div>' . "\n";
			} else {
				$ret_val .= "</div>\n";
			}
	    }
	    $ret_val .= $child->display_camp_branches($active, $indent . '  ', $topic_script, $popup_script, $filter);
	}
		$ret_val .= "</div>";
    }

    if ($ret_val eq "<div class='branch'></div>") {
		return('');
    } else {
		return($ret_val);
    }
}


# this tree build does everything including linking up camp trees and support structures.
# all ready to be canonized.
sub new_tree {
	my $caller          = $_[0];
	my $dbh             = $_[1];
	my $topic_num       = $_[2];
	my $active_camp_num = $_[3]; # need not be the root, but will always get the entire tree from the root.
 	my $as_of_mode      = $_[4];
 	my $as_of_date      = $_[5];
	my $find_nick_camp  = $_[6]; # if given, return nick camp instead of active camp.

	my $as_of_time = time;

	my %camp_tree_hash = ();
	my %support_hash = ();

	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
	    # no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
	    $as_of_time = func::parse_as_of_date($as_of_date);
	    $as_of_clause = "and go_live_time < $as_of_time";
	} else {
	    $as_of_clause = 'and go_live_time < ' . time;
	}

	my camp $self = '';

	# load camps
	my $selstmt = "select topic_num, camp_num, parent_camp_num, camp_name, title, key_words, url, nick_name_id, record_id, note, submit_time, submitter, go_live_time, objector, object_time, object_Reason from camp where topic_num=$topic_num and objector is null $as_of_clause and go_live_time in (select max(go_live_time) from camp where topic_num=$topic_num and objector is null $as_of_clause group by camp_num)";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
	$sth->execute() || die "Failed to execute $selstmt";
	my $rs;
	my  camp $current_camp;

	while ($rs = $sth->fetchrow_hashref()) {
		$current_camp = new_rs camp ($rs);
		$camp_tree_hash{$current_camp->{camp_num}} = $current_camp;
		$current_camp->{camp_tree_hash} = \%camp_tree_hash;
		$current_camp->{support_hash} = \%support_hash;
		if ($find_nick_camp && ($current_camp->{nick_name_id} eq $find_nick_camp)) {
			$self = $current_camp;
		}
	}

	if ($find_nick_camp && ! $self) { # no need to canonized if no match.
		return('');
	}

	my $camp_num;
	my camp $parent_camp;

	# link up camp tree
	foreach $camp_num (keys %camp_tree_hash) {
		$current_camp = $camp_tree_hash{$camp_num};
		if ($camp_num > 1) { # I should have a parent
			$parent_camp = $camp_tree_hash{$current_camp->{parent_camp_num}};
			if ($parent_camp) {
				push(@{$parent_camp->{children}}, $current_camp);
				$current_camp->{parent} = $parent_camp;
			} else {
				print(STDERR 'For topic ' . $current_camp->{topic_num} . ", camp number $camp_num s parent " . $current_camp->{parent_camp_num} . " does not exist.\n");
			}
	    }
	}

	# load support
	$selstmt = "select support_id, nick_name, owner_code, s.nick_name_id, camp_num, delegate_nick_name_id, support_order from support s, nick_name n where s.nick_name_id = n.nick_name_id and topic_num = $topic_num and ((start < $as_of_time) and (end = 0 or end > $as_of_time))";
	$sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
	$sth->execute() || die "Failed to execute $selstmt";
	my support $current_support;
	my $current_support_order;
	while ($rs = $sth->fetchrow_hashref()) {
		$current_support = new_rs support ($rs);
		$current_support_order = 0;
		if ($current_support->{delegate_nick_name_id} == 0) {
			$current_support_order = $current_support->{support_order};
		}
		$support_hash{$current_support->{nick_name_id}}->[$current_support_order] = $current_support;
	}

	# link up support trees
	my $support_array_ref;
	my $current_delegate_id;
	my support $current_delegate;
	my support $virtual_delegate;
	my $delegate_order;
	my $current_support_array_ref;
	foreach $current_support_array_ref (values %support_hash) {
		foreach $current_support (@{$current_support_array_ref}) {

			next unless $current_support; # check for corrupt db.

			$current_delegate_id = $current_support->{delegate_nick_name_id};
			if ($current_delegate_id) { # delegator
				$delegate_order = 0;
				$current_delegate = $support_hash{$current_delegate_id}->[$delegate_order];
				if ($current_delegate) { # Just a saftey chack, can be optomized out latter
					$current_delegate->{delegators}->{$current_support->{nick_name_id}} = $current_support;
					if ($current_delegate->{delegate_nick_name_id} == 0) { # direct supporting delegate, virtually link non primary support trees
						while($support_hash{$current_delegate_id}->[++$delegate_order]) {
							$virtual_delegate = $support_hash{$current_delegate_id}->[$delegate_order];
							$virtual_delegate->{delegators}->{$current_support->{nick_name_id}} = $current_support;
						}
					}
				} else {
					if ($current_delegate) {
						print(STDERR "Non existant delegate for delegator " . $current_delegate->{nick_name_id} .
							  " in support tree for topic $topic_num.\n");
					} else {
						print(STDERR "Non existant delegate.\n");
					}
				}
			} else { # direct supporter
				$current_camp = $camp_tree_hash{$current_support->{camp_num}};
				if ($current_camp) { # Just a saftey chack, can be optomized out latter
					$current_camp->{supporters}->{$current_support->{nick_name_id}} = $current_support;
				} else {
					print(STDERR "Non existant camp for supporter " . $current_support->{nick_name_id} .
						  " in camp tree for topic $topic_num.\n");
				}
			}
		}
	}

	if (! $find_nick_camp) {
		if ($camp_tree_hash{$active_camp_num}) {
			$self = $camp_tree_hash{$active_camp_num};
		} else {
			$self = new_blank camp ();
			$self->{error_message} = 'No such camp YET.';
		}
	}

	return($self);
}


sub print_record {
    my camp $self  = $_[0];
    my      $dbh   = $_[1];
    my      $color = $_[2];

    my ($topic_name, $parent_camp_name, $error_message);

    my $agreement = 1;
    if ($self->{camp_num} && $self->{parent_camp_num}) {
	$agreement = 0;
	($topic_name, $parent_camp_name, $error_message) = get_names($dbh, $self->{topic_num}, $self->{parent_camp_num});
    }

    my $object_link = '&nbsp';
    if ((time < $self->{go_live_time}) && ! $self->{objector}) {
	$object_link = '<a href="https://' . func::get_host() . '/secure/object.asp?class=camp&record_id=' . $self->{record_id} . "\">Object (cancel proposal)</a>\n";
    }

    print("	<table class='$color' cellpadding='0' cellspacing='0'>\n");	
    print("	<tr><td colspan=3>Go Live Time: " . func::to_local_time($self->{go_live_time}) . "</td></tr>\n");

    print("	<tr><td>\n");
    print('	    <a href="https://' . func::get_host() . '/secure/edit.asp?class=camp&record_id=' . $self->{record_id} . "\">Propose modification based on this version</a>\n");
    print('	    </td><td>Camp Name:</td><td>' . func::escape_html($self->{camp_name}) . "</td>\n");
    print("	</tr>\n");

    print("	<tr bgcolor=$color><td>\n");
    print($object_link);

    print('	    </td><td>Version Note:</td><td>' . func::escape_html($self->{note}) . "</td>\n");
    print("	</tr>\n");

    print('	<tr><td>&nbsp;</td><td>Title:</td><td>' . func::escape_html($self->{title}) . "</td></tr>\n");

    print('	<tr><td>&nbsp;</td><td>Key Words:</td><td>' . func::escape_html($self->{key_words}) . "</td></tr>\n");

    print('	<tr><td>&nbsp;</td><td>Related URL:</td><td>' . $self->{url} . "</td></tr>\n");

    print('	<tr><td>&nbsp;</td><td>Related Nick Name:</td><td>' . ($self->{nick_name_id} ? func::get_nick_name($dbh, $self->{nick_name_id}, 1) : '') . "</td></tr>\n");

    if (! $agreement) {
	print('	<tr><td>&nbsp;</td><td>Parent:</td><td>' . func::escape_html($parent_camp_name) . "</td></tr>\n");
    }

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


sub move_camp_check {
	my camp $self        = $_[0];
	my $anc_sup_hash_ref = $_[1];
	my $conf_arr_ref     = $_[2];

	my support $supporter;
	foreach $supporter (values (%{$self->{supporters}})) {
		my $camp_num = $anc_sup_hash_ref->{$supporter->{nick_name_id}};
		if ($camp_num) {
			push(@{$conf_arr_ref},
				 { 'camp'   => $self,
				   'parent' => $self->{camp_tree_hash}->{$camp_num},
				   'name'   => $supporter->make_linked_nick_str()    } );
		}
	}
	my camp $child;
	foreach $child (@{$self->{children}}) {
		$child->move_camp_check($anc_sup_hash_ref, $conf_arr_ref);
	}
}


sub check_for_move_support_conflicts {
	my camp $self     = $_[0]; # new version of camp (no tree... data)
	my camp $old_tree = $_[1]; # old version of camp and old tree.

	if ($self->{parent_camp_num} == $old_tree->{parent_camp_num}) {
		return(''); # no change in parent camp.
	}

	# first, build hash of all new ancestor supporters and their camps, except agreement.
	# You really don't need to check any common parent, but agreement is only sure one.
	my support $supporter;
	my %new_ancestor_support_hash  = ();
	my $no_new_parent_supporters = 1;
	my camp $ancestor = $old_tree->{camp_tree_hash}->{$self->{parent_camp_num}};
	while ($ancestor->{camp_num} > 1) { # bail when we get to agreement - no supporters here to worry about.
		foreach $supporter (values (%{$ancestor->{supporters}})) {
			$new_ancestor_support_hash{$supporter->{nick_name_id}} = $ancestor->{camp_num};
			$no_new_parent_supporters = 0;
		}
		$ancestor = $old_tree->{camp_tree_hash}->{$ancestor->{parent_camp_num}};
	}

	if ($no_new_parent_supporters) {
		return('');
	}

	#  now if any supporters of each camp of moving camp tree are in new anc sup hash, collect these conflicts.
	my @conflicts = ();
	$old_tree->move_camp_check(\%new_ancestor_support_hash, \@conflicts);

	if ($#conflicts > -1) {
		return(\@conflicts);
	} else {
		return('');
	}
}


sub save {
	my camp $self  = $_[0];
	my      $dbh   = $_[1];
	my	    $cid   = $_[2];

	my $new_record_id = func::get_next_id($dbh, 'camp', 'record_id');
	my $topic_num = $self->{topic_num};
	my $camp_num = 1;

	my camp $old_tree;
	my %support_hash = ();

	if ($self->{proposed}) {
		$camp_num = $self->{camp_num};
		$old_tree = new_tree camp ($dbh, $topic_num, $camp_num);
		$old_tree->get_support($dbh, \%support_hash);
		my $support_conflicts = $self->check_for_move_support_conflicts($old_tree, \%support_hash);
		if ($support_conflicts) {
			return($support_conflicts);
		}
	} else {
		$camp_num = func::get_next_id($dbh, 'camp', 'camp_num', 'where topic_num=' . $self->{topic_num});
		$self->{camp_num} = $camp_num;
	}

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

	my $submitter = $self->{submitter};

	my $save_nick_name_id = $self->{nick_name_id};
	if (! $save_nick_name_id) {
		$save_nick_name_id = '';
	}

	my $selstmt = "insert into camp (record_id,      camp_name, title, key_words, url, nick_name_id, topic_num,  camp_num,  parent_camp_num,          note, submit_time, submitter,   go_live_time) values " .
					               "($new_record_id, ?,         ?,     ?,         ?,   ?,            $topic_num, $camp_num, $self->{parent_camp_num}, ?,    $now_time,   $submitter, $go_live_time)";

	my %dummy = ();
  	if (! $dbh->do($selstmt, \%dummy, $self->{camp_name}, $self->{title}, $self->{key_words}, $self->{url}, $save_nick_name_id, $self->{note})) {
		return("<h2>System Error: failed to save camp.</h2>\n");
	}

	$self->submit_notify($dbh, $old_tree, \%support_hash, $do_notify);
	return('');
}


# currently, both of these only get direct support.
sub get_support {
    my camp $self    = $_[0];
	my $dbh          = $_[1];
	my $support_hash = $_[2];

	# get support for this camp;
	my support $supporter;
	foreach $supporter (values (%{$self->{supporters}})) {
		my $cid = $supporter->get_cid($dbh);
		$support_hash->{$cid} = $supporter->{camp_num};
		# currently, we only want direct support;
		# $supporter->get_support($dbh, $support_hash);
	}

	my camp $child;
	foreach $child (@{$self->{children}}) {
		$child->get_support($dbh, $support_hash);
	}
}


sub get_support_nicks {
    my camp $self = $_[0];
	my $dbh       = $_[1];
	my $nick_hash = $_[2];

	# get support for this camp;
	my support $supporter;
	foreach $supporter (values (%{$self->{supporters}})) {
		my $nick_name = func::get_nick_name($dbh, $supporter->{nick_name_id});
		$nick_hash->{$nick_name} = $supporter->{nick_name_id};
		# currently, we only want direct support;
		# $supporter->get_support_nicks($dbh, $nick_hash);
	}

	my camp $child;
	foreach $child (@{$self->{children}}) {
		$child->get_support_nicks($dbh, $nick_hash);
	}
}


sub submit_notify {
    my camp $self         = $_[0];
	my      $dbh          = $_[1];
	my camp $old_tree     = $_[2];
	my      $support_hash = $_[3];
	my      $do_notify    = $_[4];

	my $topic_num = $self->{topic_num};
	my $camp_num  = $self->{camp_num};
	my $camp_name = $self->{camp_name};

	my $diff_message = '';

	if ($old_tree) { # don't do this for first version of camp
	    if ($self->{camp_name} ne $old_tree->{camp_name}) {
			$diff_message .= "* Camp name '$old_tree->{camp_name}' changed to '$self->{camp_name}'.\n";
	    }
	    if ($self->{title} ne $old_tree->{title}) {
			$diff_message .= "* Title '$old_tree->{title}' changed to '$self->{title}'.\n";
	    }
	    if ($self->{key_words} ne $old_tree->{key_words}) {
			$diff_message .= "* Key Words '$old_tree->{key_words}' changed to '$self->{key_words}'.\n";
	    }
	    if ($self->{url} ne $old_tree->{url}) {
			$diff_message .= "* URL '$old_tree->{url}' changed to '$self->{url}'.\n";
	    }
	    if ($self->{nick_name_id} ne $old_tree->{nick_name_id}) {
			$diff_message .= '* Related Nick Name ' . func::get_nick_name($dbh, $old_tree->{nick_name_id}) .
							 ' changed to ' . func::get_nick_name($dbh, $self->{nick_name_id}) . ".\n";
	    }
	    if (($camp_num > 1) and ($self->{parent_camp_num} != $old_tree->{parent_camp_num})) {
			$diff_message .= "* Parent '" .
		    $old_tree->{camp_tree_hash}->{$old_tree->{parent_camp_num}}->{camp_name} .
		    "' changed to '" .
		    $old_tree->{camp_tree_hash}->{   $self->{parent_camp_num}}->{camp_name} . "'.\n";
	    }
	}

	my ($topic_name, $msg) = topic::get_name($dbh, $topic_num);

	my $cid;

	my $go_live_time_str = gmtime($self->{go_live_time}) . ' (GMT)';

	# just to be sure brent also get's this e-mail.
	$support_hash->{1} = 1;

	my $subject;
	if ($old_tree) {
		$camp_name = $old_tree->{camp_name};
		$subject = "Change submitted to the '$camp_name' camp on the topic '$topic_name'";
	} else {
		$camp_name = $self->{camp_name};
		$subject = "Creating new camp '$camp_name' on the topic '$topic_name'";
	}

	my $message = <<EOF;

\$name <\$email>,

A proposed change has been submitted to the Canonizer for
camp: '$camp_name' on the topic: '$topic_name'
which you directly support.

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


sub make_camp_path {
    my camp $self  = $_[0];
	my $link_camp  = $_[1]; # flag: the actual camp name will be a link.

	my $camp_name = $self->{camp_name};
	$camp_name =~ s| |&nbsp;|g;

	my $camp_path = "<font id=green>$camp_name</font>";
	if ($link_camp) {
		$camp_path = '<a href="http://' . func::get_host() . '/topic.asp/' . $self->{topic_num} . '/' . $self->{camp_num} . '">' . $camp_path . '</a>';
	}

	my camp $camp = $self;

	while ($camp->{camp_num} > 1) { # have more parents.
		$camp = $camp->{parent};
		$camp_name = $camp->{camp_name};
		$camp_name =~ s| |&nbsp;|g;
		$camp_path = '<a href="http://' . func::get_host() . '/topic.asp/' . $camp->{topic_num} . '/' . $camp->{camp_num} . '">' . $camp_name . '</a>&nbsp;/ ' . $camp_path
	}

	return($camp_path);
}


sub is_ancestor {
    my camp $self = $_[0];
	my $camp_num  = $_[1];

	if ($self->{camp_num} == $camp_num) {
		return(1);
	}
	if ($self->{parent_camp_num}) {
		return($self->{parent}->is_ancestor($camp_num));
	}
	return(0);
}


sub is_descendant {
    my camp $self = $_[0];
	my $camp_num  = $_[1];

	if ($self->{camp_num} == $camp_num) {
		return(1);
	}
	my camp $child;
	foreach $child (@{$self->{children}}) {
		if ($child->is_descendant($camp_num)) {
			return(1);
		}
	}
	return(0);
}


# Yes, I am related to myself (or I am on the same belief branch as myself)
sub is_related {
    my camp $self = $_[0];
	my $camp_num  = $_[1];

	if ($self->is_ancestor($camp_num)) {
		return(1);
	}
	if ($self->is_descendant($camp_num)) {
		return(1);
	}
	return(0);
}


sub is_supporting {
    my camp $self  = $_[0];
	my $nick_names = $_[1];

	my $nick_id;
	my $support_array_ref;
	my support $support;
	my $delegated_support_array_ref;
	my support $delegated_support;
	foreach $nick_id (keys %{$nick_names}) {
		$support_array_ref = $self->{support_hash}->{$nick_id};
		foreach $support (@{$support_array_ref}) {
			if ($support) { # if support is deleted this could be null till renumbered.
				if ($support->{camp_num} == $self->{camp_num}) {
					return(1);
				} elsif ($support->{delegate_nick_name_id}) {
					$delegated_support_array_ref = $self->{support_hash}->{$support->{support_order}};
					foreach $delegated_support (@{$delegated_support_array_ref}) {
						if ($delegated_support->{camp_num} == $self->{camp_num}) {
							return(1);
						}
					}
				}
			}
		}
	}
	return(0);
}


# look up the agreement camp and canonize the entire topic camp tree.
sub canonize {
    my camp $self  = $_[0];
    my $dbh        = $_[1];
    my $canonizer  = $_[2];
    my $as_of_mode = $_[3];
    my $as_of_date = $_[4];

    my camp $agreement_camp = $self->{camp_tree_hash}->{1};

	my $score = 0;

	if (($self->{topic_num} == 81) && ($canonizer ==1)) {
		$score = $agreement_camp->canonize_branch($dbh, -1, $as_of_mode, $as_of_date)
	} else {
		$score = $agreement_camp->canonize_branch($dbh, $canonizer, $as_of_mode, $as_of_date)
	}

    return();
}


sub canonize_branch {
    my camp $self  = $_[0];
    my $dbh        = $_[1];
    my $canonizer  = $_[2];
    my $as_of_mode = $_[3];
    my $as_of_date = $_[4];

    my $score = 0;

    my camp $child;
    foreach $child (@{$self->{children}}) {
		$score += $child->canonize_branch($dbh, $canonizer, $as_of_mode, $as_of_date);
    }

    my $multi_supporter;

    my support $support;
    foreach $support (values %{$self->{supporters}}) { # these are all direct supporters
		if ($#{$self->{support_hash}->{$support->{nick_name_id}}} > 0) {
			$multi_supporter = 1;
		} else {
			$multi_supporter = 0;
		}

		$score += $support->canonize_support_tree($multi_supporter, $support->{support_order}, $canonizer, $as_of_mode, $as_of_date, $dbh);
    }

    $self->{score} = $score;

    return($score);
}


1;

