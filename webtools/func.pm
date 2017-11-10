package func;

use POSIX qw(ceil floor);

use bad_email;

# quite different than the pweb one but...


my $target_host = 'canonizer.com';
my $test_target_host = 'test.canonizer.com';


sub get_target_host {
	return ($target_host);
}


sub get_test_target_host {
	return ($test_target_host);
}


sub get_host {
    return ($ENV{'SERVER_NAME'});
	# if ($ENV{'SERVER_NAME'} eq $test_target_host) {
	# 	return($test_target_host);
	# } else {
	# 	return($target_host);
	# }
}


# use PurpleWiki::Config;
# use PurpleWiki::Parser::WikiText;
# use PurpleWiki::View::wikihtml;
# use PurpleWiki::View::text;

sub wikitext_to_html {
	my $wikitext = $_[0];

	# this must be created every call becaue the viewer colects what is to be printed in itself.
	my $config = PurpleWiki::Config->new('/var/www/wikidb');
	my $parser = PurpleWiki::Parser::WikiText->new;
	my $viewer = PurpleWiki::View::wikihtml->new(url => '', pageName => '', css_file => '');

	my $wiki_tree = $parser->parse($wikitext);
	my $html_text = $viewer->view($wiki_tree);

	return($html_text);
}


sub wikitext_to_text {
	my $wikitext = $_[0];

	# this must be created every call becaue the viewer colects what is to be printed in itself.
	my $config = PurpleWiki::Config->new('/var/www/wikidb');
	my $parser = PurpleWiki::Parser::WikiText->new;
	my $viewer = PurpleWiki::View::text->new(url => '', pageName => '', css_file => '');

	my $wiki_tree = $parser->parse($wikitext);
	my $html_text = $viewer->view($wiki_tree);

	return($html_text);
}


sub dbh_connect {

	my $autocommit = $_[0];

	if(!defined $autocommit){
		$autocommit = 1;
	}

# Oracle XE values
#	my $dsn = 'dbi:Oracle:host=127.0.0.1;sid=XE';
#	my $user = 'test.canonizer';
#	my $password = 'rational';

# MySQL values:
# 	my $dsn = 'DBI:mysql:database=canonizer_devel:host=127.0.0.1;port=3306';
#	my $dsn = 'DBI:mysql:database=canonizer_devel:host=localhost;port=3306';
#	my $dsn = 'DBI:mysql:database=canonizer_devel_3:host=localhost;port=3306';
#	my $user = 'root';
#	my $password = '1ularity';
#	my $password = 'rational';
#   my $user = 'apache';
#	my $password = 'themeaningofliff';

# MySQL xion:
#	my $dsn = 'DBI:mysql:database=canonizer:host=xion.canonizer.com;port=3306';
#	my $user = 'canonizer';
#	my $password = '1ularity';

# MySQL cooler:
	my $dsn = 'DBI:mysql:database=canonizer:host=cooler.canonizer.com;port=3306';
	my $user = 'canonizer';
	my $password = '1ularity';

	my $dbh = DBI->connect_cached($dsn, $user, $password, { RaiseError => 1, AutoCommit => $autocommit });

	return($dbh);

}


sub escape_html {
	my $val = $_[0];

	$val =~ s|<|&lt;|g;

	return($val);
}



sub escape_double {
	my $val = $_[0];

	$val =~ s|"|&quot;|g;

	return($val);
}



sub hex_encode{
	my $pfiltertext = shift;
	$pfiltertext =~ s/([^a-zA-Z0-9\._\n\r])/uc sprintf("%%%02x",ord($1))/eg;

#	$pfiltertext =~ s/\%25/'%'/eg;
#You can not remove double encoding capabilities...  Many things broke when this was added.  Why did it get added?
	return $pfiltertext;
}


sub hex_decode_change{
	my $charnum = hex(shift);
	my $char = pack("C",$charnum);
	my $htmlsafe = shift;
	if($htmlsafe == 1 && ($char !~ /[[:print:\r\n]]/ || $char =~ /[<>&'"]/)){
		$char = '&#' . $charnum . ";";
	}
	return $char;
}


sub hex_decode{
	my $pfiltertext = shift;
	my $htmlsafe = shift;
	if(!defined $pfiltertext){return "";}
	if(!$htmlsafe){$htmlsafe = 0;}
	$pfiltertext =~ s/%([0-9a-fA-F]{2})/&hex_decode_change($1,$htmlsafe)/sge;
	return $pfiltertext;
}


sub canon_encode {

    my $in_str = $_[0];
    my $salt = $_[1];

    if (!$salt) {
	$salt = 0;
    }

    $in_str = join('', map {chr (ord ($_) ^ $salt)} split //, $in_str);
    $in_str = 'Malia' . $in_str . 'Malia';
    $in_str = &MIME::Base64::encode_base64($in_str);

    chop($in_str); # remove trailing eol;

    return($in_str);
}


sub canon_decode {

    my $in_str = $_[0];
    my $salt = $_[1];

    if (!$salt) {
	$salt = 0;
    }

    $in_str .= "\n"; #replace trailing eol;

    $in_str = &MIME::Base64::decode_base64($in_str);
    substr($in_str, 0, 5, '');
    substr($in_str, -5, 5, '');
    $in_str = join('', map {chr (ord($_) ^ $salt)} split //, $in_str);

    return($in_str);
}


sub get_nick_name_clause {
	my %nick_names   = %{$_[0]};
	my $public_only  =   $_[1];

	my $nick_clause = '';
	my $nick_name;
	foreach $nick_name (keys %nick_names) {
		if ($public_only and $nick_names->{'private'}) {
			next;
		}
		$nick_clause .= "nick_name_id = $nick_name or ";
	}

	if (!$nick_clause) {
		return('');
	}

	chop($nick_clause); # remove extra or
	chop($nick_clause);
	chop($nick_clause);
	chop($nick_clause);

	return($nick_clause);
}


# I probably want to cach nick names?
sub get_nick_name {
	my $dbh          = $_[0];
	my $id           = $_[1];
	my $include_link = $_[2];

	if (length($id) < 1) {
		return('""');
	}

	my $nick_name = $id;

	my $selstmt = 'select nick_name from nick_name where nick_name_id = ' . $id;

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	if ($rs = $sth->fetch()) {
		$nick_name = $rs->[0];
	}
	$sth->finish();

	if ($include_link) {
		$nick_name = '<a href="http://' . func::get_host() . "/support_list.asp?nick_name_id=$id\">$nick_name</a>";
	}

	return($nick_name);
}


sub nick_name_count {
	my $dbh = $_[0];
	my $cid = $_[1];

	if (! $cid) {
		return(0);
	}

	my $owner_code = canon_encode($cid);

	my $selstmt = "select count(*) from nick_name where owner_code = '$owner_code'";

	my $count = 0;

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	if ($rs = $sth->fetch()) {
		$count = $rs->[0];
	}

	$sth->finish();

	return($count);
}


sub get_thread_subject {
	my $dbh        = $_[0];
	my $topic_num  = $_[1];
	my $camp_num   = $_[2];
	my $thread_num = $_[3];

	my $subject = '';

	if ($topic_num and $camp_num and $thread_num) {

		my $selstmt = "select subject from thread where topic_num=$topic_num and camp_num=$camp_num and thread_num=$thread_num";
		my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
		$sth->execute() or die "Failed to execute $selstmt.\n";
		my $rs;
		if ($rs = $sth->fetchrow_hashref()) {
			$subject = $rs->{'subject'};
		}
		$sth->finish();
	}

	return($subject);
}


# returns hash key = nick_id, value = nick_name
sub get_nick_name_hash {
	my $cid = $_[0];
	my $dbh = $_[1];

	my %nick_names = ();
	my $no_nick_name = 1;
	my $owner_code = &func::canon_encode($cid);
	my $selstmt = "select nick_name_id, nick_name, private from nick_name where owner_code = '$owner_code'";

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	my $rs;
	while($rs = $sth->fetch()) {
		$no_nick_name = 0;
		my $nick_name_id = $rs->[0];
		$nick_names{$nick_name_id}->{'nick_name'} = $rs->[1];
		$nick_names{$nick_name_id}->{'private'} = $rs->[2];
	}
	$sth->finish();

	my $profile_id_url = 'https://' . &func::get_host() . '/secure/profile_id.asp';

	if ($no_nick_name) {
		$nick_names{'error_message'} =
"		You must have a Nick Name before you can contribute.
		You can create a Nick Name on the <a href = \"$profile_id_url\">
		Personal Info Identity Page</a>.
";
	}

	return(%nick_names);
}


sub to_local_time {
	$unixtime = $_[0];

	return ("<script>document.write((new Date($unixtime * 1000)).toLocaleString())</script>");
}


sub get_next_id {
	$dbh = $_[0];
	$table_name = $_[1];
	$column_name = $_[2];
	$where_clause = $_[3];

	$selstmt = "select max($column_name) from $table_name";
	if ($where_clause) {
		$selstmt .= ' ' . $where_clause;
	}
	$sth = $dbh->prepare($selstmt) || die "Failed to prepair " . $selstmt;
	$sth->execute() || die "Failed to execute " . $selstmt;
	$rs = $sth->fetch();
	my $nextd_id = 1; # default to 1 if there is no records yet.
	if ($rs) {
	    $next_id = $rs->[0] + 1;
	}
	$sth->finish();

	return($next_id);
}


sub parse_as_of_date {
	my $as_of_str = $_[0];

	if ($as_of_str =~ m|(\d\d)/(\d\d)/(\d\d)|) {
		my $year = $1 + 100;
		my $month = $2 - 1;
		my $day = $3;
		$return_val = &Time::Local::timegm(0, 0, 0, $day, $month, $year);
		return($return_val);
	} else {
		return(0);
	}
}


sub send_email {
	my $subject = $_[0];
	my $message = $_[1];
	my $to      = $_[2];
	my $from    = $_[3];

	if (!$to) {
		$to = 'brent.allsop@canonizer.com';
	}

	if (bad_email::is_bad_email($to)) {
		return;
	}

	if (!$from) {
		# Got to put this back once I get e-mail configured right
		# at least reply works with this one for now.
		# $from = 'root@canonizer.com';
		# it is working now:
		$from = 'canonizer@canonizer.com';
	}

	my $sendmail = '/usr/lib/sendmail';
	open(MAIL, "|$sendmail -oi -t");
	print MAIL "From: $from\n";
	print MAIL "To: $to\n";
	print MAIL "Subject: $subject\n\n";
	print MAIL "$message\n";
	close(MAIL);
}


sub c_num_format {
	my $raw_val = $_[0];

	my $return_val = (ceil($raw_val * 100)) / 100;

	return($return_val);
}


sub get_name_spaces {
	my $dbh = $_[0];

	my $selstmt = 'select namespace from topic group by namespace order by namespace';

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
	$sth->execute() || die "Failed to execute $selstmt";
	my $rs;

	my @namespaces = ();

	while ($rs = $sth->fetch()) {
		push(@namespaces, $rs->[0]);
	}

	$namespaces[0] = 'general';

	return(@namespaces);

}


sub make_namespace_select_str {
	my $dbh           = $_[0];
	my $cur_namespace = $_[1];
    my $no_submit     = $_[2];

	my $selstmt = 'select namespace from topic group by namespace order by namespace';

	my $sth = $dbh->prepare($selstmt) || die "Failed to prepair $selstmt";
	$sth->execute() || die "Failed to execute $selstmt";
	my $rs;

	my @namespaces = func::get_name_spaces($dbh);

	if (length($cur_namespace) < 1) {
		$cur_namespace = 'general';
	}

	my $on_change_str = '';
	if (! $no_submit) {
		$on_change_str = "onchange=\"javascript:change_namespace(value)\"";
    }

	my $namespace_select_str = "<select name=\"namespace\" $on_change_str >";

	my $namespace;
	foreach $namespace (@namespaces) {
		$namespace_select_str .= "\t<option value=\"$namespace\" " . (($namespace eq $cur_namespace) ? 'selected' : '') . ">$namespace</option>\n";
	}

	$namespace_select_str .= "</select>\n";

	return($namespace_select_str);
}


1;

